"""
Computer Use Router - Full Implementation
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from ..services.computer_use_service import get_service

router = APIRouter(prefix="/api/computer-use", tags=["computer_use"])

class ScreenshotRequest(BaseModel):
    url: Optional[str] = None

class ActionRequest(BaseModel):
    action_type: str
    x: Optional[int] = None
    y: Optional[int] = None
    text: Optional[str] = None
    url: Optional[str] = None
    delta_y: Optional[int] = None

class LoopRequest(BaseModel):
    goal: str
    max_iterations: int = 5

@router.post("/screenshot")
async def take_screenshot(request: ScreenshotRequest):
    """Screenshot al"""
    try:
        service = await get_service()
        result = await service.take_screenshot(url=request.url)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/action")
async def execute_action(request: ActionRequest):
    """Action çalıştır"""
    try:
        service = await get_service()
        kwargs = {k: v for k, v in request.dict().items() if v is not None and k != "action_type"}
        result = await service.execute_action(request.action_type, **kwargs)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/loop")
async def run_loop(request: LoopRequest):
    """Computer Use Loop çalıştır"""
    try:
        service = await get_service()
        result = await service.computer_use_loop(request.goal, request.max_iterations)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
