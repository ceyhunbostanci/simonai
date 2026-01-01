# tools\fix-agent-audit-perms.ps1
$ErrorActionPreference = "Stop"

function Write-FileUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path $path -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$target = Join-Path $RepoRoot "apps\api\app\services\agent_studio_service.py"
if (!(Test-Path $target)) { throw "Dosya bulunamadı: $target" }

$content = @'
from __future__ import annotations

import asyncio
import json
import os
import time
import uuid
from typing import Any, Dict, List, Optional, Tuple

import httpx


def _iso_now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


class AgentStudioService:
    """
    MVP-1:
    - In-memory session store (tek container için yeterli)
    - LiteLLM'e doğrudan OpenAI uyumlu /chat/completions çağrısı
    - Basit approval gate (demo): require_approval=true veya riskli anahtar kelime -> needs_approval
    - JSONL audit log (yazılabilir path + fallback)
    """

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._sessions: Dict[str, Dict[str, Any]] = {}

        self.litellm_base_url = os.getenv("LITELLM_BASE_URL", "http://litellm:4000").rstrip("/")
        self.default_model = os.getenv("SIMON_DEFAULT_MODEL", "qwen2.5")

        # allowlist boşsa sadece default model kullanılır
        allow = os.getenv("SIMON_MODEL_ALLOWLIST", "").strip()
        self.model_allowlist = [m.strip() for m in allow.split(",") if m.strip()] or [self.default_model]

        # ✅ ÖNEMLİ: /data permission sorunu var -> varsayılanı /app altına alıyoruz
        # /app genelde bind mount olduğu için yazılabilir; olmazsa /tmp'ye düşeceğiz.
        self.audit_path = os.getenv("SIMON_AUDIT_PATH", "/app/.data/audit/agent_studio.jsonl")

        self._ensure_audit_dir()

    def _ensure_audit_dir(self) -> None:
        try:
            os.makedirs(os.path.dirname(self.audit_path), exist_ok=True)
        except PermissionError:
            # Son çare: /tmp
            self.audit_path = "/tmp/simon-audit/agent_studio.jsonl"
            os.makedirs(os.path.dirname(self.audit_path), exist_ok=True)
        except Exception:
            # MVP: akışı bozma, audit devre dışı kalabilir
            pass

    async def create_session(self, model: Optional[str]) -> Dict[str, Any]:
        chosen = (model or self.default_model).strip()
        if chosen not in self.model_allowlist:
            chosen = self.default_model

        sid = str(uuid.uuid4())
        now = _iso_now()
        session = {
            "session_id": sid,
            "model": chosen,
            "created_at": now,
            "updated_at": now,
            "pending_approval": False,
            "pending_reason": None,
            "messages": [],  # list of {"role": "...", "content": "...", "ts": "..."}
        }
        async with self._lock:
            self._sessions[sid] = session

        await self._audit("session_create", {"session_id": sid, "model": chosen})
        return session

    async def get_session(self, session_id: str) -> Dict[str, Any]:
        async with self._lock:
            s = self._sessions.get(session_id)
            if not s:
                raise KeyError("session_not_found")
            return s

    async def post_message(
        self, session_id: str, content: str, model_override: Optional[str], require_approval: bool
    ) -> Tuple[Dict[str, Any], str, str, Dict[str, Any], bool, Optional[str]]:
        async with self._lock:
            s = self._sessions.get(session_id)
            if not s:
                raise KeyError("session_not_found")

            model = (model_override or s["model"]).strip()
            if model not in self.model_allowlist:
                model = self.default_model

            user_msg = {"role": "user", "content": content, "ts": _iso_now()}
            s["messages"].append(user_msg)
            s["updated_at"] = _iso_now()

        # Basit risk tespiti (MVP)
        risky_keywords = [
            "rm -rf",
            "format",
            "drop database",
            "del /f",
            "remove-item -recurse -force",
            "docker system prune",
        ]
        risk_hit = any(k in content.lower() for k in risky_keywords)
        needs_approval = bool(require_approval or risk_hit)

        if needs_approval:
            async with self._lock:
                s = self._sessions[session_id]
                s["pending_approval"] = True
                s["pending_reason"] = "Request flagged by approval gate (MVP)."
                s["updated_at"] = _iso_now()

            step_id = str(uuid.uuid4())
            assistant_message = (
                "Bu istek, güvenlik/operasyon riski içerebileceği için onay gerektiriyor. "
                "Onay verirsen bir sonraki adımda ilerleyeceğim."
            )
            usage: Dict[str, Any] = {}
            await self._audit(
                "needs_approval",
                {"session_id": session_id, "step_id": step_id, "model": model, "content": content},
            )
            return (await self.get_session(session_id), step_id, assistant_message, usage, True, "Approval required (MVP gate).")

        # LLM çağrısı
        messages = await self._build_messages(session_id)
        assistant_message, usage = await self._call_litellm(messages, model=model)

        async with self._lock:
            s = self._sessions[session_id]
            s["messages"].append({"role": "assistant", "content": assistant_message, "ts": _iso_now()})
            s["updated_at"] = _iso_now()

        step_id = str(uuid.uuid4())
        await self._audit("message_complete", {"session_id": session_id, "step_id": step_id, "model": model, "usage": usage})
        return (await self.get_session(session_id), step_id, assistant_message, usage, False, None)

    async def approve(self, session_id: str, approved: bool, notes: Optional[str]) -> Dict[str, Any]:
        async with self._lock:
            s = self._sessions.get(session_id)
            if not s:
                raise KeyError("session_not_found")

            s["pending_approval"] = False
            s["pending_reason"] = None
            s["updated_at"] = _iso_now()

        await self._audit("approval_decision", {"session_id": session_id, "approved": approved, "notes": notes})
        return await self.get_session(session_id)

    async def _build_messages(self, session_id: str) -> List[Dict[str, str]]:
        s = await self.get_session(session_id)
        sys = {
            "role": "system",
            "content": (
                "You are Simon AI Agent Studio. Be precise, corporate, and safe. "
                "If a request implies destructive actions, ask for confirmation."
            ),
        }
        msgs = [sys]
        for m in s["messages"]:
            msgs.append({"role": m["role"], "content": m["content"]})
        return msgs

    async def _call_litellm(self, messages: List[Dict[str, str]], model: str) -> Tuple[str, Dict[str, Any]]:
        url = f"{self.litellm_base_url}/chat/completions"
        payload = {"model": model, "messages": messages, "temperature": 0.2}
        async with httpx.AsyncClient(timeout=90) as client:
            r = await client.post(url, json=payload)
            r.raise_for_status()
            data = r.json()

        content = data["choices"][0]["message"].get("content", "")
        usage = data.get("usage", {}) or {}
        return content, usage

    async def _audit(self, event: str, data: Dict[str, Any]) -> None:
        record = {"ts": _iso_now(), "event": event, "data": data}
        line = json.dumps(record, ensure_ascii=False)

        try:
            # klasör yoksa oluşturmayı tekrar dene (runtime’da env değişmiş olabilir)
            self._ensure_audit_dir()
            with open(self.audit_path, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except Exception:
            # MVP: audit hatası akışı bozmasın
            pass
'@

Write-FileUtf8NoBom $target $content
Write-Host "✅ agent_studio_service.py güncellendi: $target"
