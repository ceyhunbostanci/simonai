"""
Chat endpoints - Main MVP functionality
"""

from fastapi import APIRouter, HTTPException, status, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Optional, Literal
import uuid
import json
import logging
from datetime import datetime

from app.services.ai_router import AIRouter
from app.services.cost_tracker import CostTracker
from app.models.chat import ChatMessage, ChatRequest, ChatResponse

router = APIRouter()
logger = logging.getLogger(__name__)


class StreamingChatRequest(BaseModel):
    """Streaming chat request"""
    messages: List[ChatMessage]
    model: str = "claude-sonnet-4.5"
    key_mode: Literal["free", "free_plus", "byok"] = "free"
    user_api_key: Optional[str] = None
    temperature: float = Field(default=1.0, ge=0.0, le=2.0)
    max_tokens: int = Field(default=4096, ge=1, le=8192)
    stream: bool = True
    project_id: Optional[str] = None
    chat_id: Optional[str] = None


@router.post("/chat")
async def chat_completion(request: ChatRequest):
    """
    Non-streaming chat completion
    """
    request_id = str(uuid.uuid4())
    
    try:
        logger.info(f"[{request_id}] Chat request: model={request.model}, messages={len(request.messages)}")
        
        # Initialize AI Router
        ai_router = AIRouter()
        
        # Get completion
        response = await ai_router.complete(
            messages=request.messages,
            model=request.model,
            key_mode=request.key_mode,
            user_api_key=request.user_api_key,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
        )
        
        # Track cost
        cost_tracker = CostTracker()
        await cost_tracker.record(
            request_id=request_id,
            model=request.model,
            tokens_input=response.get("usage", {}).get("input_tokens", 0),
            tokens_output=response.get("usage", {}).get("output_tokens", 0),
            cost=response.get("cost", 0.0),
        )
        
        logger.info(f"[{request_id}] Completion success: tokens={response.get('usage', {})}")
        
        return ChatResponse(
            id=request_id,
            model=request.model,
            content=response["content"],
            usage=response.get("usage", {}),
            cost=response.get("cost", 0.0),
            created_at=datetime.utcnow(),
        )
        
    except Exception as e:
        logger.error(f"[{request_id}] Chat error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Chat completion failed: {str(e)}"
        )


@router.post("/chat/stream")
async def streaming_chat_completion(request: StreamingChatRequest):
    """
    Streaming chat completion (Server-Sent Events)
    """
    request_id = str(uuid.uuid4())
    
    try:
        logger.info(f"[{request_id}] Streaming chat request: model={request.model}")
        
        # Initialize AI Router
        ai_router = AIRouter()
        
        # Create streaming generator
        async def generate():
            try:
                # Send initial metadata
                yield f"data: {json.dumps({'type': 'start', 'request_id': request_id, 'model': request.model})}\n\n"
                
                # Stream completion
                total_tokens_input = 0
                total_tokens_output = 0
                accumulated_content = ""
                
                async for chunk in ai_router.stream_complete(
                    messages=request.messages,
                    model=request.model,
                    key_mode=request.key_mode,
                    user_api_key=request.user_api_key,
                    temperature=request.temperature,
                    max_tokens=request.max_tokens,
                ):
                    # Extract content delta
                    delta = chunk.get("delta", {})
                    content = delta.get("text", "")
                    
                    if content:
                        accumulated_content += content
                        
                        # Send content chunk
                        yield f"data: {json.dumps({'type': 'content', 'content': content})}\n\n"
                    
                    # Track token usage
                    usage = chunk.get("usage", {})
                    if usage:
                        total_tokens_input = usage.get("input_tokens", 0)
                        total_tokens_output = usage.get("output_tokens", 0)
                
                # Calculate cost
                cost_tracker = CostTracker()
                cost = await cost_tracker.calculate_cost(
                    model=request.model,
                    tokens_input=total_tokens_input,
                    tokens_output=total_tokens_output,
                )
                
                # Record cost
                await cost_tracker.record(
                    request_id=request_id,
                    model=request.model,
                    tokens_input=total_tokens_input,
                    tokens_output=total_tokens_output,
                    cost=cost,
                )
                
                # Send completion metadata
                yield f"data: {json.dumps({'type': 'done', 'usage': {'input_tokens': total_tokens_input, 'output_tokens': total_tokens_output}, 'cost': cost})}\n\n"
                
                logger.info(f"[{request_id}] Streaming complete: input={total_tokens_input}, output={total_tokens_output}, cost=${cost:.4f}")
                
            except Exception as e:
                logger.error(f"[{request_id}] Streaming error: {e}", exc_info=True)
                yield f"data: {json.dumps({'type': 'error', 'error': str(e)})}\n\n"
        
        return StreamingResponse(
            generate(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Request-ID": request_id,
            }
        )
        
    except Exception as e:
        logger.error(f"[{request_id}] Streaming setup error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Streaming setup failed: {str(e)}"
        )


@router.get("/chat/models")
async def list_available_models():
    """
    List available models by key mode
    """
    return {
        "free": [
            {"id": "gemma3", "name": "Gemma 3", "provider": "ollama"},
            {"id": "qwen2.5", "name": "Qwen 2.5", "provider": "ollama"},
            {"id": "qwen2.5-coder", "name": "Qwen 2.5 Coder", "provider": "ollama"},
            {"id": "phi4", "name": "Phi 4", "provider": "ollama"},
            {"id": "llama3.3", "name": "Llama 3.3", "provider": "ollama"},
            {"id": "mistral", "name": "Mistral", "provider": "ollama"},
            {"id": "deepseek-r1", "name": "DeepSeek R1", "provider": "ollama"},
            {"id": "llava", "name": "LLaVA", "provider": "ollama"},
        ],
        "byok": [
            {"id": "claude-sonnet-4.5", "name": "Claude Sonnet 4.5", "provider": "anthropic"},
            {"id": "claude-opus-4.5", "name": "Claude Opus 4.5", "provider": "anthropic"},
            {"id": "gpt-4o", "name": "GPT-4o", "provider": "openai"},
            {"id": "gemini-1.5-pro", "name": "Gemini 1.5 Pro", "provider": "google"},
        ]
    }
