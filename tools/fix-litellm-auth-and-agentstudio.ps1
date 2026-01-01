# tools\fix-litellm-auth-and-agentstudio.ps1
$ErrorActionPreference = "Stop"

function Write-FileUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path $path -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

function Try-ExtractKeyFromLine([string]$line) {
  # master_key: "xxx"  | master_key: xxx | LITELLM_MASTER_KEY=xxx
  if ($line -match "master_key\s*:\s*['""]?([^'""]+?)['""]?\s*$") { return $Matches[1].Trim() }
  if ($line -match "LITELLM_(MASTER_KEY|API_KEY)\s*=\s*['""]?([^'""]+?)['""]?\s*$") { return $Matches[2].Trim() }
  return $null
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Host "RepoRoot: $RepoRoot"

# 1) LiteLLM key ara (repo içinde)
$key = $null

$searchFiles = Get-ChildItem -Path $RepoRoot -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match "\.(ya?ml|env)$" -or $_.Name -match "litellm" }

foreach ($f in $searchFiles) {
  try {
    $hits = Select-String -Path $f.FullName -Pattern "master_key\s*:", "LITELLM_MASTER_KEY\s*=", "LITELLM_API_KEY\s*=" -SimpleMatch:$false -ErrorAction SilentlyContinue
    foreach ($h in $hits) {
      $maybe = Try-ExtractKeyFromLine($h.Line)
      if ($maybe) { $key = $maybe; break }
    }
  } catch {}
  if ($key) { break }
}

if (-not $key) {
  Write-Host "❌ LITELLM key repo içinde bulunamadı. LiteLLM config container içinde olabilir."
  Write-Host "Bu durumda şu komutu çalıştırıp çıktıyı buraya yapıştır:"
  Write-Host 'docker exec -it simon-litellm sh -lc "ls -la; find / -maxdepth 4 -type f \( -name '\''*.yml'\'' -o -name '\''*.yaml'\'' \) 2>/dev/null | head -n 50; echo ---; grep -R \"master_key\" -n / 2>/dev/null | head -n 50"'
  exit 1
}

Write-Host "✅ Bulunan LiteLLM key: (gizli) length=$($key.Length)"

# 2) Agent Studio service'i auth header gönderecek şekilde overwrite et
$svcPath = Join-Path $RepoRoot "apps\api\app\services\agent_studio_service.py"
if (!(Test-Path $svcPath)) { throw "agent_studio_service.py yok: $svcPath" }

$svc = @'
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
    MVP-1 Stabilize:
    - In-memory session
    - LiteLLM /chat/completions (Authorization + x-api-key)
    - Model allowlist
    - Audit: /tmp varsayılan
    """

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._sessions: Dict[str, Dict[str, Any]] = {}

        self.litellm_base_url = os.getenv("LITELLM_BASE_URL", "http://litellm:4000").rstrip("/")

        # LiteLLM auth key (proxy user_api_key_auth açık)
        self.litellm_api_key = (
            os.getenv("LITELLM_API_KEY")
            or os.getenv("LITELLM_MASTER_KEY")
            or os.getenv("LITELLM_KEY")
            or ""
        ).strip()

        self.default_model = os.getenv("SIMON_DEFAULT_MODEL", "qwen2.5").strip()
        allow = os.getenv("SIMON_MODEL_ALLOWLIST", "").strip()
        self.model_allowlist = [m.strip() for m in allow.split(",") if m.strip()] or [self.default_model]

        self.audit_path = os.getenv("SIMON_AUDIT_PATH", "/tmp/simon-audit/agent_studio.jsonl")
        self._ensure_audit_dir()

    def _ensure_audit_dir(self) -> None:
        try:
            os.makedirs(os.path.dirname(self.audit_path), exist_ok=True)
        except Exception:
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
            "messages": [],
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

            s["messages"].append({"role": "user", "content": content, "ts": _iso_now()})
            s["updated_at"] = _iso_now()

        risky_keywords = [
            "rm -rf",
            "format",
            "drop database",
            "del /f",
            "remove-item -recurse -force",
            "docker system prune",
        ]
        needs_approval = bool(require_approval or any(k in content.lower() for k in risky_keywords))

        if needs_approval:
            async with self._lock:
                s = self._sessions[session_id]
                s["pending_approval"] = True
                s["pending_reason"] = "Request flagged by approval gate (MVP)."
                s["updated_at"] = _iso_now()

            step_id = str(uuid.uuid4())
            msg = (
                "Bu istek, güvenlik/operasyon riski içerebileceği için onay gerektiriyor. "
                "Onay verirsen bir sonraki adımda ilerleyeceğim."
            )
            await self._audit("needs_approval", {"session_id": session_id, "step_id": step_id, "model": model})
            return (await self.get_session(session_id), step_id, msg, {}, True, "Approval required (MVP gate).")

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
                "Avoid destructive actions unless explicitly approved."
            ),
        }
        msgs = [sys]
        for m in s["messages"]:
            msgs.append({"role": m["role"], "content": m["content"]})
        return msgs

    async def _call_litellm(self, messages: List[Dict[str, str]], model: str) -> Tuple[str, Dict[str, Any]]:
        url = f"{self.litellm_base_url}/chat/completions"
        payload = {"model": model, "messages": messages, "temperature": 0.2}

        headers: Dict[str, str] = {}
        if self.litellm_api_key:
            headers["Authorization"] = f"Bearer {self.litellm_api_key}"
            headers["x-api-key"] = self.litellm_api_key  # bazı kurulumlar bunu bekliyor

        async with httpx.AsyncClient(timeout=120) as client:
            r = await client.post(url, json=payload, headers=headers)
            r.raise_for_status()
            data = r.json()

        content = data["choices"][0]["message"].get("content", "")
        usage = data.get("usage", {}) or {}
        return content, usage

    async def _audit(self, event: str, data: Dict[str, Any]) -> None:
        record = {"ts": _iso_now(), "event": event, "data": data}
        line = json.dumps(record, ensure_ascii=False)
        try:
            self._ensure_audit_dir()
            with open(self.audit_path, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except Exception:
            pass
'@

Write-FileUtf8NoBom $svcPath $svc
Write-Host "✅ agent_studio_service.py auth header desteği eklendi."

# 3) Compose override'a key'i yaz
$overridePath = Join-Path $RepoRoot "docker-compose.agentstudio.override.yml"
$override = @"
services:
  api:
    environment:
      SIMON_AUDIT_PATH: /tmp/simon-audit/agent_studio.jsonl
      SIMON_DEFAULT_MODEL: qwen2.5
      SIMON_MODEL_ALLOWLIST: qwen2.5
      LITELLM_API_KEY: "$key"
"@
Write-FileUtf8NoBom $overridePath $override
Write-Host "✅ docker-compose.agentstudio.override.yml güncellendi (LITELLM_API_KEY eklendi)."

Write-Host "DONE"
