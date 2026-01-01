import os

def litellm_headers() -> dict:
    """
    LiteLLM proxy auth:
      - Prefer LITELLM_API_KEY, fallback LITELLM_MASTER_KEY
      - Send both Authorization Bearer + x-api-key for maximum compatibility
    """
    key = os.getenv("LITELLM_API_KEY") or os.getenv("LITELLM_MASTER_KEY") or ""
    key = key.strip()
    if not key:
        return {}

    # If user accidentally sets "Bearer sk-..." keep it clean
    if key.lower().startswith("bearer "):
        raw = key.split(" ", 1)[1].strip()
        return {"Authorization": f"Bearer {raw}", "x-api-key": raw}

    return {"Authorization": f"Bearer {key}", "x-api-key": key}
