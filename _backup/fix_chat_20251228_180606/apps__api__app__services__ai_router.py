"""
AI Router Service - LiteLLM Integration
Handles model routing, failover, and API abstraction
"""

import httpx
import logging
from typing import List, Dict, Any, AsyncGenerator
import json

from app.config import settings
from app.models.chat import ChatMessage

logger = logging.getLogger(__name__)


class AIRouter:
    """
    AI Router for multi-model orchestration
    Integrates with LiteLLM Gateway
    """

    def __init__(self):
        self.litellm_url = settings.LITELLM_URL
        self.master_key = settings.LITELLM_MASTER_KEY
        self.timeout = httpx.Timeout(60.0, connect=10.0)

    def _format_messages(self, messages: List[ChatMessage]) -> List[Dict[str, str]]:
        """Convert ChatMessage to LiteLLM format"""
        return [{"role": msg.role, "content": msg.content} for msg in messages]

    def _normalize_free_model_id(self, model: str) -> str:
        """
        LiteLLM /v1/models çıktısındaki 'id' alanı ile uyumlu hale getirir.
        Örn:
          - "ollama/qwen2.5"        -> "qwen2.5"
          - "ollama/qwen2.5:1.5b"   -> "qwen2.5"
          - "qwen2.5:1.5b"          -> "qwen2.5"
          - "qwen2.5"               -> "qwen2.5"
        """
        m = (model or "").strip()
        if m.startswith("ollama/"):
            m = m[len("ollama/") :]
        m = m.split(":", 1)[0]
        return m

    def _get_model_mapping(self, model: str, key_mode: str) -> str:
        """
        Map Simon AI model names to LiteLLM model names
        """
        km = (key_mode or "free").lower()

        # FREE (Ollama via LiteLLM): LiteLLM model id'si gönderilmeli (qwen2.5 / gemma3 / phi4)
        if km == "free":
            return self._normalize_free_model_id(model)

        # BYOK: doğrudan model adı
        return model

    async def complete(
        self,
        messages: List[ChatMessage],
        model: str,
        key_mode: str = "free",
        user_api_key: str | None = None,
        temperature: float = 1.0,
        max_tokens: int = 4096,
    ) -> Dict[str, Any]:
        """
        Non-streaming completion
        """
        try:
            km = (key_mode or "free").lower()
            litellm_model = self._get_model_mapping(model, km)
            formatted_messages = self._format_messages(messages)

            headers = {
                "Authorization": f"Bearer {self.master_key}",
                "Content-Type": "application/json",
            }

            # Add user API key if BYOK mode
            if km == "byok" and user_api_key:
                headers["X-User-API-Key"] = user_api_key

            payload = {
                "model": litellm_model,
                "messages": formatted_messages,
                "temperature": temperature,
                "max_tokens": max_tokens,
                "stream": False,
            }

            logger.info(f"Calling LiteLLM: model={litellm_model}, messages={len(messages)}, key_mode={km}")

            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.litellm_url}/chat/completions",
                    headers=headers,
                    json=payload,
                )

                response.raise_for_status()
                data = response.json()

                # Extract response
                content = data["choices"][0]["message"]["content"]
                usage = data.get("usage", {})

                # Calculate cost (basic estimation)
                cost = self._estimate_cost(model, usage, km)

                return {
                    "content": content,
                    "usage": {
                        "input_tokens": usage.get("prompt_tokens", 0),
                        "output_tokens": usage.get("completion_tokens", 0),
                        "total_tokens": usage.get("total_tokens", 0),
                    },
                    "cost": cost,
                    "model": litellm_model,
                }

        except httpx.HTTPError as e:
            logger.error(f"LiteLLM HTTP error: {e}")
            raise Exception(f"AI Router error: {str(e)}")
        except Exception as e:
            logger.error(f"AI Router error: {e}", exc_info=True)
            raise

    async def stream_complete(
        self,
        messages: List[ChatMessage],
        model: str,
        key_mode: str = "free",
        user_api_key: str | None = None,
        temperature: float = 1.0,
        max_tokens: int = 4096,
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Streaming completion
        """
        try:
            km = (key_mode or "free").lower()
            litellm_model = self._get_model_mapping(model, km)
            formatted_messages = self._format_messages(messages)

            headers = {
                "Authorization": f"Bearer {self.master_key}",
                "Content-Type": "application/json",
            }

            if km == "byok" and user_api_key:
                headers["X-User-API-Key"] = user_api_key

            payload = {
                "model": litellm_model,
                "messages": formatted_messages,
                "temperature": temperature,
                "max_tokens": max_tokens,
                "stream": True,
            }

            logger.info(f"Streaming LiteLLM: model={litellm_model}, messages={len(messages)}, key_mode={km}")

            async with httpx.AsyncClient(timeout=self.timeout) as client:
                async with client.stream(
                    "POST",
                    f"{self.litellm_url}/chat/completions",
                    headers=headers,
                    json=payload,
                ) as response:
                    response.raise_for_status()

                    async for line in response.aiter_lines():
                        if line.startswith("data: "):
                            data_str = line[6:]  # Remove "data: " prefix

                            if data_str.strip() == "[DONE]":
                                break

                            try:
                                data = json.loads(data_str)

                                # Extract delta
                                delta = data["choices"][0].get("delta", {})
                                content = delta.get("content", "")

                                # Usage info (last chunk)
                                usage = data.get("usage", {})

                                yield {
                                    "delta": {"text": content},
                                    "usage": {
                                        "input_tokens": usage.get("prompt_tokens", 0),
                                        "output_tokens": usage.get("completion_tokens", 0),
                                    } if usage else {},
                                }

                            except json.JSONDecodeError:
                                continue

        except httpx.HTTPError as e:
            logger.error(f"LiteLLM streaming error: {e}")
            raise Exception(f"AI Router streaming error: {str(e)}")
        except Exception as e:
            logger.error(f"AI Router streaming error: {e}", exc_info=True)
            raise

    def _estimate_cost(self, model: str, usage: Dict[str, int], key_mode: str) -> float:
        """
        Estimate cost based on model and token usage
        """
        # FREE (Ollama/LiteLLM local): cost = 0
        if (key_mode or "").lower() == "free":
            return 0.0

        # Cost per 1M tokens
        cost_map = {
            "claude-sonnet-4.5": {"input": 3.0, "output": 15.0},
            "claude-opus-4.5": {"input": 5.0, "output": 25.0},
            "gpt-4o": {"input": 2.5, "output": 10.0},
            "gemini-1.5-pro": {"input": 1.25, "output": 5.0},
        }

        base_model = (model or "").replace("ollama/", "")
        if base_model not in cost_map:
            return 0.0

        costs = cost_map[base_model]
        input_tokens = usage.get("prompt_tokens", 0)
        output_tokens = usage.get("completion_tokens", 0)

        cost = (input_tokens * costs["input"] + output_tokens * costs["output"]) / 1_000_000
        return round(cost, 6)
