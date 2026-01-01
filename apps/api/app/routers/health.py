"""
Health check endpoints
"""

from fastapi import APIRouter, status
from datetime import datetime
import psutil
import os

router = APIRouter()


@router.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """
    Basic health check endpoint
    Returns service status and basic metrics
    """
    return {
        "status": "healthy",
        "service": "orchestrator",
        "version": "3.1.0",
        "timestamp": datetime.utcnow().isoformat(),
        "uptime_seconds": int(psutil.Process(os.getpid()).create_time()),
    }


@router.get("/health/detailed", status_code=status.HTTP_200_OK)
async def detailed_health_check():
    """
    Detailed health check with system metrics
    """
    process = psutil.Process(os.getpid())
    
    return {
        "status": "healthy",
        "service": "orchestrator",
        "version": "3.1.0",
        "timestamp": datetime.utcnow().isoformat(),
        "system": {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_percent": psutil.disk_usage('/').percent,
        },
        "process": {
            "memory_mb": process.memory_info().rss / 1024 / 1024,
            "cpu_percent": process.cpu_percent(interval=1),
            "threads": process.num_threads(),
        },
        "dependencies": {
            "database": "not_configured",  # TODO: Add DB check
            "redis": "not_configured",  # TODO: Add Redis check
            "litellm": "not_configured",  # TODO: Add LiteLLM check
        }
    }


@router.get("/health/ready", status_code=status.HTTP_200_OK)
async def readiness_check():
    """
    Readiness probe for Kubernetes
    """
    # TODO: Check if all dependencies are ready
    return {
        "ready": True,
        "timestamp": datetime.utcnow().isoformat(),
    }


@router.get("/health/live", status_code=status.HTTP_200_OK)
async def liveness_check():
    """
    Liveness probe for Kubernetes
    """
    return {
        "alive": True,
        "timestamp": datetime.utcnow().isoformat(),
    }
