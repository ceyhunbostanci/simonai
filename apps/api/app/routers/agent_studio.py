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