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