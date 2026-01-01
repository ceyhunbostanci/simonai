"""
Chat data models
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Literal, Dict, Any
from datetime import datetime


class ChatMessage(BaseModel):
    """Single chat message"""
    role: Literal["user", "assistant", "system"]
    content: str
    
    class Config:
        json_schema_extra = {
            "example": {
                "role": "user",
                "content": "Merhaba! React'te bir button component'i nasıl oluştururum?"
            }
        }


class ChatRequest(BaseModel):
    """Chat completion request"""
    messages: List[ChatMessage] = Field(..., min_length=1)
    model: str = "claude-sonnet-4.5"
    key_mode: Literal["free", "free_plus", "byok"] = "free"
    user_api_key: Optional[str] = None
    temperature: float = Field(default=1.0, ge=0.0, le=2.0)
    max_tokens: int = Field(default=4096, ge=1, le=8192)
    stream: bool = False
    
    # Optional context
    project_id: Optional[str] = None
    chat_id: Optional[str] = None
    
    class Config:
        json_schema_extra = {
            "example": {
                "messages": [
                    {"role": "user", "content": "Python'da bir REST API nasıl yaparım?"}
                ],
                "model": "claude-sonnet-4.5",
                "key_mode": "byok",
                "temperature": 1.0,
                "max_tokens": 4096
            }
        }


class ChatResponse(BaseModel):
    """Chat completion response"""
    id: str
    model: str
    content: str
    usage: Dict[str, int] = {}
    cost: float = 0.0
    created_at: datetime
    
    class Config:
        json_schema_extra = {
            "example": {
                "id": "req_abc123",
                "model": "claude-sonnet-4.5",
                "content": "Python'da REST API yapmak için FastAPI kullanabilirsiniz...",
                "usage": {
                    "input_tokens": 100,
                    "output_tokens": 200,
                    "total_tokens": 300
                },
                "cost": 0.0045,
                "created_at": "2025-12-27T10:30:00Z"
            }
        }


class ModelInfo(BaseModel):
    """Model information"""
    id: str
    name: str
    provider: str
    key_mode: Literal["free", "free_plus", "byok"]
    description: str
    context_window: int
    capabilities: List[str]
    cost: Dict[str, float]


class UsageStats(BaseModel):
    """Usage statistics"""
    input_tokens: int
    output_tokens: int
    total_tokens: int
    cost: float
    
    
class StreamChunk(BaseModel):
    """Streaming response chunk"""
    type: Literal["start", "content", "done", "error"]
    content: Optional[str] = None
    usage: Optional[UsageStats] = None
    error: Optional[str] = None
    request_id: Optional[str] = None
    model: Optional[str] = None
