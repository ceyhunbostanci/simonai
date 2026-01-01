"""
Audit Router - MVP-1
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from ..services.audit_service import AuditService

router = APIRouter(prefix="/api/audit", tags=["audit"])
audit_service = AuditService()

class CostLogRequest(BaseModel):
    session_id: str
    model: str
    provider: str
    input_tokens: int
    output_tokens: int
    cost_input: float
    cost_output: float

class ApprovalLogRequest(BaseModel):
    session_id: str
    action_id: str
    risk_level: str
    approved: bool
    approver: str
    reason: Optional[str] = None

@router.post("/cost")
async def log_cost(request: CostLogRequest):
    """Log AI model cost"""
    try:
        total_cost = audit_service.log_cost(
            session_id=request.session_id,
            model=request.model,
            provider=request.provider,
            input_tokens=request.input_tokens,
            output_tokens=request.output_tokens,
            cost_input=request.cost_input,
            cost_output=request.cost_output
        )
        return {"status": "logged", "total_cost": total_cost}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/approval")
async def log_approval(request: ApprovalLogRequest):
    """Log approval decision"""
    try:
        audit_service.log_approval(
            session_id=request.session_id,
            action_id=request.action_id,
            risk_level=request.risk_level,
            approved=request.approved,
            approver=request.approver,
            reason=request.reason
        )
        return {"status": "logged"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/cost/summary")
async def get_cost_summary(session_id: Optional[str] = None):
    """Get cost summary"""
    try:
        summary = audit_service.get_cost_summary(session_id)
        return summary
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
