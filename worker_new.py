"""
Celery Worker Tasks - UI Runner
"""
from celery import Celery
import os
import asyncio

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
app = Celery("worker", broker=redis_url, backend=redis_url)

app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

@app.task(name="health.ping")
def ping():
    """Health check task"""
    return {"status": "healthy", "worker": "simon-celery-worker"}

@app.task(
    name="ui_runner.execute_action",
    bind=True,
    max_retries=3,
    default_retry_delay=5
)
def execute_action(self, action_data: dict):
    """
    UI Runner action executor - idempotency korumalı
    action_data: {
        "action_id": "unique-id",
        "action_type": "click|type|goto|scroll",
        "params": {...}
    }
    """
    from app.services.computer_use_service import get_service
    
    action_id = action_data.get("action_id")
    
    # Idempotency check (Redis'te bu action_id var mı?)
    if app.backend.get(f"action_result:{action_id}"):
        return {"status": "skipped", "reason": "already_executed", "action_id": action_id}
    
    try:
        # Async service'i sync wrapper ile çalıştır
        async def _execute():
            service = await get_service()
            return await service.execute_action(
                action_data["action_type"],
                **action_data.get("params", {})
            )
        
        result = asyncio.run(_execute())
        
        # Sonucu cache'le (1 saat)
        app.backend.set(f"action_result:{action_id}", result, ex=3600)
        
        return result
        
    except Exception as e:
        # Retry logic
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e, countdown=5)
        
        return {
            "status": "error",
            "action_id": action_id,
            "message": str(e),
            "retries": self.request.retries
        }
