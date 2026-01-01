"""
Prometheus Metrics Instrumentation for Simon AI API

Bu dosyayı apps/api/app/metrics.py olarak kaydedin.
"""

from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry, generate_latest
from prometheus_fastapi_instrumentator import Instrumentator
from typing import Callable
import time

# Registry
registry = CollectorRegistry()

# HTTP Metrics (FastAPI instrumentator tarafından otomatik oluşturulur)
# - http_requests_total
# - http_request_duration_seconds

# Custom Business Metrics

# Cost Tracking
cost_ledger_total = Counter(
    'cost_ledger_total_usd',
    'Total cost in USD',
    ['model', 'task_type'],
    registry=registry
)

tokens_used = Counter(
    'tokens_used_total',
    'Total tokens used',
    ['model', 'direction'],  # direction: input/output
    registry=registry
)

# Task Metrics
tasks_started = Counter(
    'tasks_started_total',
    'Total tasks started',
    ['task_type'],
    registry=registry
)

tasks_completed = Counter(
    'tasks_completed_total',
    'Total tasks completed successfully',
    ['task_type'],
    registry=registry
)

tasks_failed = Counter(
    'tasks_failed_total',
    'Total tasks failed',
    ['task_type', 'reason'],
    registry=registry
)

tasks_in_progress = Gauge(
    'tasks_in_progress',
    'Number of tasks currently in progress',
    ['task_type'],
    registry=registry
)

task_duration = Histogram(
    'task_duration_seconds',
    'Task duration in seconds',
    ['task_type'],
    buckets=[1, 5, 10, 30, 60, 120, 300, 600, 1800],
    registry=registry
)

# Model & Failover Metrics
model_failover = Counter(
    'model_failover_total',
    'Model failover events',
    ['from_model', 'to_model', 'reason'],
    registry=registry
)

# Computer Use Metrics
computer_use_actions = Counter(
    'computer_use_actions_total',
    'Computer use action executions',
    ['action_type'],
    registry=registry
)

screenshots_captured = Counter(
    'screenshots_captured_total',
    'Screenshots captured',
    registry=registry
)

screenshot_storage_bytes = Gauge(
    'screenshot_storage_bytes',
    'Total screenshot storage in bytes',
    registry=registry
)

# Celery Metrics
celery_queue_length = Gauge(
    'celery_queue_length',
    'Celery queue length',
    ['queue'],
    registry=registry
)

# Budget Metrics
cost_budget_monthly = Gauge(
    'cost_budget_monthly_usd',
    'Monthly cost budget in USD',
    registry=registry
)

# Initialize budget
cost_budget_monthly.set(100)  # Default $100/month


# Instrumentator setup
def setup_metrics(app):
    """
    FastAPI uygulamasına metrics instrumentation ekler.
    
    Usage:
        from app.metrics import setup_metrics
        
        app = FastAPI()
        setup_metrics(app)
    """
    instrumentator = Instrumentator(
        should_group_status_codes=True,
        should_ignore_untemplated=True,
        should_respect_env_var=True,
        should_instrument_requests_inprogress=True,
        excluded_handlers=["/metrics", "/health"],
        env_var_name="ENABLE_METRICS",
        inprogress_name="http_requests_inprogress",
        inprogress_labels=True
    )
    
    instrumentator.instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
    
    return instrumentator


# Helper functions for tracking
def track_cost(model: str, task_type: str, cost_usd: float):
    """Track cost for a model/task"""
    cost_ledger_total.labels(model=model, task_type=task_type).inc(cost_usd)


def track_tokens(model: str, input_tokens: int, output_tokens: int):
    """Track token usage"""
    tokens_used.labels(model=model, direction='input').inc(input_tokens)
    tokens_used.labels(model=model, direction='output').inc(output_tokens)


def track_task_start(task_type: str):
    """Track task start"""
    tasks_started.labels(task_type=task_type).inc()
    tasks_in_progress.labels(task_type=task_type).inc()


def track_task_complete(task_type: str, duration_seconds: float):
    """Track successful task completion"""
    tasks_completed.labels(task_type=task_type).inc()
    tasks_in_progress.labels(task_type=task_type).dec()
    task_duration.labels(task_type=task_type).observe(duration_seconds)


def track_task_failure(task_type: str, reason: str):
    """Track task failure"""
    tasks_failed.labels(task_type=task_type, reason=reason).inc()
    tasks_in_progress.labels(task_type=task_type).dec()


def track_model_failover(from_model: str, to_model: str, reason: str):
    """Track model failover event"""
    model_failover.labels(from_model=from_model, to_model=to_model, reason=reason).inc()


def track_computer_use_action(action_type: str):
    """Track computer use action"""
    computer_use_actions.labels(action_type=action_type).inc()


def track_screenshot():
    """Track screenshot capture"""
    screenshots_captured.inc()


def update_queue_length(queue: str, length: int):
    """Update Celery queue length"""
    celery_queue_length.labels(queue=queue).set(length)


def update_screenshot_storage(bytes_used: int):
    """Update screenshot storage gauge"""
    screenshot_storage_bytes.set(bytes_used)


# Context manager for task tracking
class TaskTracker:
    """
    Context manager for tracking task lifecycle.
    
    Usage:
        with TaskTracker('code_generation') as tracker:
            # do work
            tracker.set_cost(0.05, 'claude-sonnet-4-5')
            tracker.set_tokens(1000, 500, 'claude-sonnet-4-5')
    """
    def __init__(self, task_type: str):
        self.task_type = task_type
        self.start_time = None
        
    def __enter__(self):
        self.start_time = time.time()
        track_task_start(self.task_type)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        duration = time.time() - self.start_time
        
        if exc_type is None:
            # Success
            track_task_complete(self.task_type, duration)
        else:
            # Failure
            reason = exc_type.__name__ if exc_type else 'unknown'
            track_task_failure(self.task_type, reason)
        
        return False  # Don't suppress exceptions
    
    def set_cost(self, cost_usd: float, model: str):
        """Track cost for this task"""
        track_cost(model, self.task_type, cost_usd)
    
    def set_tokens(self, input_tokens: int, output_tokens: int, model: str):
        """Track tokens for this task"""
        track_tokens(model, input_tokens, output_tokens)
