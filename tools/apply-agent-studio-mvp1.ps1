# tools\apply-agent-studio-mvp1.ps1
$ErrorActionPreference = "Stop"

function Write-FileUtf8NoBom([string]$path, [string]$content) {
  $dir = Split-Path $path -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Host "RepoRoot: $RepoRoot"

# ---- 1) Yeni Python dosyaları ----
$agentModelsPath   = Join-Path $RepoRoot "apps\api\app\models\agent_studio.py"
$agentServicePath  = Join-Path $RepoRoot "apps\api\app\services\agent_studio_service.py"
$agentRouterPath   = Join-Path $RepoRoot "apps\api\app\routers\agent_studio.py"

$agentModels = @'
from __future__ import annotations

from typing import Any, Dict, List, Literal, Optional
from pydantic import BaseModel, Field


class SessionCreateRequest(BaseModel):
    model: Optional[str] = Field(default=None, description="Varsayılan model. Boşsa SIMON_DEFAULT_MODEL kullanılır.")


class SessionCreateResponse(BaseModel):
    session_id: str
    model: str
    created_at: str


class AgentMessageRequest(BaseModel):
    content: str = Field(..., min_length=1)
    model: Optional[str] = Field(default=None, description="Bu mesaj için model override. Boşsa session model.")
    require_approval: bool = Field(default=False, description="Zorla approval akışı (demo/test için).")


class AgentMessageResponse(BaseModel):
    session_id: str
    step_id: str
    status: Literal["completed", "needs_approval"]
    assistant_message: str
    model: str
    usage: Dict[str, Any] = Field(default_factory=dict)
    approval_required: bool = False
    approval_reason: Optional[str] = None


class ApprovalRequest(BaseModel):
    approved: bool
    notes: Optional[str] = None


class SessionStateResponse(BaseModel):
    session_id: str
    model: str
    created_at: str
    updated_at: str
    pending_approval: bool
    pending_reason: Optional[str] = None
    messages: List[Dict[str, Any]] = Field(default_factory=list)
'@

$agentService = @'
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
    - JSONL audit log
    """

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._sessions: Dict[str, Dict[str, Any]] = {}

        self.litellm_base_url = os.getenv("LITELLM_BASE_URL", "http://litellm:4000").rstrip("/")
        self.default_model = os.getenv("SIMON_DEFAULT_MODEL", "qwen2.5")
        # allowlist boşsa sadece default model kullanılır
        allow = os.getenv("SIMON_MODEL_ALLOWLIST", "").strip()
        self.model_allowlist = [m.strip() for m in allow.split(",") if m.strip()] or [self.default_model]

        self.audit_path = os.getenv("SIMON_AUDIT_PATH", "/data/audit/agent_studio.jsonl")
        os.makedirs(os.path.dirname(self.audit_path), exist_ok=True)

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
        risky_keywords = ["rm -rf", "format", "drop database", "del /f", "remove-item -recurse -force", "docker system prune"]
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
            await self._audit("needs_approval", {"session_id": session_id, "step_id": step_id, "model": model, "content": content})
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
        # Sistem mesajını kurumsal, kısa tutuyoruz (MVP)
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
        payload = {
            "model": model,
            "messages": messages,
            "temperature": 0.2,
        }
        async with httpx.AsyncClient(timeout=90) as client:
            r = await client.post(url, json=payload)
            r.raise_for_status()
            data = r.json()

        content = data["choices"][0]["message"].get("content", "")
        usage = data.get("usage", {}) or {}
        return content, usage

    async def _audit(self, event: str, data: Dict[str, Any]) -> None:
        record = {
            "ts": _iso_now(),
            "event": event,
            "data": data,
        }
        line = json.dumps(record, ensure_ascii=False)
        # Basit dosya kilidi (append)
        try:
            with open(self.audit_path, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except Exception:
            # Audit log hatası prod'da ayrı ele alınır; MVP'de akışı bozmayalım
            pass
'@

$agentRouter = @'
from __future__ import annotations

from fastapi import APIRouter, HTTPException
from app.models.agent_studio import (
    SessionCreateRequest,
    SessionCreateResponse,
    AgentMessageRequest,
    AgentMessageResponse,
    ApprovalRequest,
    SessionStateResponse,
)
from app.services.agent_studio_service import AgentStudioService

router = APIRouter()
svc = AgentStudioService()


@router.post("/agent/sessions", response_model=SessionCreateResponse)
async def create_session(req: SessionCreateRequest) -> SessionCreateResponse:
    s = await svc.create_session(req.model)
    return SessionCreateResponse(session_id=s["session_id"], model=s["model"], created_at=s["created_at"])


@router.get("/agent/sessions/{session_id}", response_model=SessionStateResponse)
async def get_session(session_id: str) -> SessionStateResponse:
    try:
        s = await svc.get_session(session_id)
    except KeyError:
        raise HTTPException(status_code=404, detail="session_not_found")
    return SessionStateResponse(**s)


@router.post("/agent/sessions/{session_id}/messages", response_model=AgentMessageResponse)
async def post_message(session_id: str, req: AgentMessageRequest) -> AgentMessageResponse:
    try:
        s, step_id, assistant_message, usage, approval_required, approval_reason = await svc.post_message(
            session_id=session_id,
            content=req.content,
            model_override=req.model,
            require_approval=req.require_approval,
        )
    except KeyError:
        raise HTTPException(status_code=404, detail="session_not_found")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"agent_error: {type(e).__name__}")

    status = "needs_approval" if approval_required else "completed"
    model = (req.model or s["model"])
    return AgentMessageResponse(
        session_id=session_id,
        step_id=step_id,
        status=status,
        assistant_message=assistant_message,
        model=model,
        usage=usage,
        approval_required=approval_required,
        approval_reason=approval_reason,
    )


@router.post("/agent/sessions/{session_id}/approval", response_model=SessionStateResponse)
async def approval(session_id: str, req: ApprovalRequest) -> SessionStateResponse:
    try:
        s = await svc.approve(session_id=session_id, approved=req.approved, notes=req.notes)
    except KeyError:
        raise HTTPException(status_code=404, detail="session_not_found")
    return SessionStateResponse(**s)
'@

Write-FileUtf8NoBom $agentModelsPath  $agentModels
Write-FileUtf8NoBom $agentServicePath $agentService
Write-FileUtf8NoBom $agentRouterPath  $agentRouter

Write-Host "✅ Agent Studio dosyaları yazıldı."

# ---- 2) main.py patch (router include) ----
$mainPath = Join-Path $RepoRoot "apps\api\main.py"
if (!(Test-Path $mainPath)) { throw "apps\api\main.py bulunamadı: $mainPath" }

$main = Get-Content $mainPath -Raw

# Import ekle
if ($main -notmatch "agent_studio") {
  if ($main -match "from\s+app\.routers\s+import\s+([^\r\n]+)") {
    $importLine = $Matches[0]
    $imports    = $Matches[1]
    if ($imports -notmatch "agent_studio") {
      $newImports = $imports.Trim() + ", agent_studio"
      $main = $main -replace [regex]::Escape($importLine), ("from app.routers import " + $newImports)
    }
  } else {
    # fallback: dosyanın başına yakın ekle
    $main = "from app.routers import agent_studio`n" + $main
  }
}

# include_router ekle
if ($main -notmatch "include_router\(agent_studio\.router") {
  # models router satırını bulup altına ekle
  $pattern = "app\.include_router\(\s*models\.router[^\r\n]*\)"
  if ($main -match $pattern) {
    $main = [regex]::Replace(
      $main,
      $pattern,
      { param($m) $m.Value + "`n" + 'app.include_router(agent_studio.router, prefix="/api", tags=["Agent Studio"])' },
      1
    )
  } else {
    # fallback: app tanımının sonlarına ekle
    $main = $main + "`n" + 'app.include_router(agent_studio.router, prefix="/api", tags=["Agent Studio"])' + "`n"
  }
}

Write-FileUtf8NoBom $mainPath $main
Write-Host "✅ apps\api\main.py patch tamam."

# ---- 3) Test script'i ekle ----
$agentTestPath = Join-Path $RepoRoot "tools\agent-studio-test.ps1"
$agentTest = @'
# tools\agent-studio-test.ps1
$ErrorActionPreference = "Stop"

Write-Host "== Agent Studio MVP-1 Test =="

$base = "http://127.0.0.1:8000"

# 1) session create
$s = Invoke-RestMethod -Method Post -Uri "$base/api/agent/sessions" -ContentType "application/json" -Body '{}'
Write-Host "Session:" ($s | ConvertTo-Json -Depth 5)

# 2) message
$body = @{ content = "Merhaba Simon. Agent Studio MVP-1 test." } | ConvertTo-Json
$r = Invoke-RestMethod -Method Post -Uri "$base/api/agent/sessions/$($s.session_id)/messages" -ContentType "application/json" -Body $body
Write-Host "Response:" ($r | ConvertTo-Json -Depth 10)

# 3) state
$st = Invoke-RestMethod -Method Get -Uri "$base/api/agent/sessions/$($s.session_id)"
Write-Host "State:" ($st | ConvertTo-Json -Depth 10)

Write-Host "✅ Agent Studio endpoint test tamam."
'@
Write-FileUtf8NoBom $agentTestPath $agentTest

Write-Host "✅ tools\agent-studio-test.ps1 yazıldı."

Write-Host "`nDONE: Agent Studio MVP-1 eklendi. Şimdi docker restart + test çalıştır."
