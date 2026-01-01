"""
Model catalog endpoints
"""

from fastapi import APIRouter
from typing import List, Dict
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/models")
async def list_models():
    """
    List all available models across all key modes
    """
    return {
        "models": [
            # FREE (Ollama)
            {
                "id": "gemma3",
                "name": "Gemma 3",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Google Gemma 3 - Genel amaçlı model",
                "context_window": 8192,
                "capabilities": ["chat"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "qwen2.5",
                "name": "Qwen 2.5",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Alibaba Qwen 2.5 - Genel amaçlı",
                "context_window": 8192,
                "capabilities": ["chat"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "qwen2.5-coder",
                "name": "Qwen 2.5 Coder",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Kod üretimi ve analiz",
                "context_window": 8192,
                "capabilities": ["chat", "code"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "phi4",
                "name": "Phi 4",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Microsoft Phi 4 - Kompakt ve hızlı",
                "context_window": 4096,
                "capabilities": ["chat"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "llama3.3",
                "name": "Llama 3.3",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Meta Llama 3.3 - Genel amaçlı",
                "context_window": 8192,
                "capabilities": ["chat"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "mistral",
                "name": "Mistral",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Mistral AI - Genel amaçlı",
                "context_window": 8192,
                "capabilities": ["chat"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "deepseek-r1",
                "name": "DeepSeek R1",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Akıl yürütme odaklı model",
                "context_window": 4096,
                "capabilities": ["chat", "reasoning"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            {
                "id": "llava",
                "name": "LLaVA",
                "provider": "ollama",
                "key_mode": "free",
                "description": "Görsel analiz modeli",
                "context_window": 4096,
                "capabilities": ["chat", "vision"],
                "cost": {"input_per_1m": 0, "output_per_1m": 0},
            },
            
            # BYOK (Paid APIs)
            {
                "id": "claude-sonnet-4.5",
                "name": "Claude Sonnet 4.5",
                "provider": "anthropic",
                "key_mode": "byok",
                "description": "En akıllı model - günlük kullanım için verimli",
                "context_window": 200000,
                "capabilities": ["chat", "code", "vision", "tools", "computer_use"],
                "cost": {"input_per_1m": 3.0, "output_per_1m": 15.0},
            },
            {
                "id": "claude-opus-4.5",
                "name": "Claude Opus 4.5",
                "provider": "anthropic",
                "key_mode": "byok",
                "description": "Premium - karmaşık görevler için",
                "context_window": 200000,
                "capabilities": ["chat", "code", "vision", "tools", "computer_use"],
                "cost": {"input_per_1m": 5.0, "output_per_1m": 25.0},
            },
            {
                "id": "gpt-4o",
                "name": "GPT-4o",
                "provider": "openai",
                "key_mode": "byok",
                "description": "OpenAI multimodal model",
                "context_window": 128000,
                "capabilities": ["chat", "code", "vision", "tools"],
                "cost": {"input_per_1m": 2.5, "output_per_1m": 10.0},
            },
            {
                "id": "gemini-1.5-pro",
                "name": "Gemini 1.5 Pro",
                "provider": "google",
                "key_mode": "byok",
                "description": "Google multimodal - 1M context",
                "context_window": 1000000,
                "capabilities": ["chat", "code", "vision", "tools"],
                "cost": {"input_per_1m": 1.25, "output_per_1m": 5.0},
            },
        ]
    }


@router.get("/models/{model_id}")
async def get_model_info(model_id: str):
    """
    Get detailed information about a specific model
    """
    models = await list_models()
    
    for model in models["models"]:
        if model["id"] == model_id:
            return model
    
    return {"error": "Model not found", "model_id": model_id}


@router.get("/providers")
async def list_providers():
    """
    List all AI providers
    """
    return {
        "providers": [
            {
                "id": "anthropic",
                "name": "Anthropic",
                "models": ["claude-sonnet-4.5", "claude-opus-4.5"],
                "key_required": True,
            },
            {
                "id": "openai",
                "name": "OpenAI",
                "models": ["gpt-4o", "gpt-4o-mini"],
                "key_required": True,
            },
            {
                "id": "google",
                "name": "Google",
                "models": ["gemini-1.5-pro"],
                "key_required": True,
            },
            {
                "id": "ollama",
                "name": "Ollama",
                "models": ["gemma3", "qwen2.5", "phi4", "llama3.3", "mistral", "deepseek-r1", "llava"],
                "key_required": False,
            },
        ]
    }
