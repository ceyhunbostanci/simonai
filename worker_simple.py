"""
Celery Worker Tasks - Simplified for MVP
"""
from celery import Celery
import os
import json

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
app = Celery("worker", broker=redis_url, backend=redis_url)

app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
)

@app.task(name="health.ping")
def ping():
    """Health check"""
    return {"status": "healthy", "worker": "simon-celery-worker"}

@app.task(name="ui_runner.execute_action", bind=True)
def execute_action(self, action_data: dict):
    """
    UI Runner action with idempotency
    """
    action_id = action_data.get("action_id")
    
    # Idempotency check
    cache_key = f"action_result:{action_id}"
    cached = app.backend.get(cache_key)
    
    if cached:
        result = json.loads(cached)
        result["from_cache"] = True
        return result
    
    # Execute action (simplified for now)
    result = {
        "status": "success",
        "action_id": action_id,
        "action_type": action_data.get("action_type"),
        "params": action_data.get("params", {}),
        "executed_at": str(self.request.id)
    }
    
    # Cache result (1 hour)
    app.backend.set(cache_key, json.dumps(result), ex=3600)
    
    return result
