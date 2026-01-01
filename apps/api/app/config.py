"""
Application configuration from environment variables
"""

from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    """Application settings"""
    
    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    LOG_LEVEL: str = "INFO"
    
    # API
    API_V1_PREFIX: str = "/api/v1"
    SECRET_KEY: str = "change-me-in-production"
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:3001",
        "https://simonai.com",
        "https://*.vercel.app",
    ]
    
    # Database
    DATABASE_URL: str | None = None
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # LiteLLM Gateway
    LITELLM_URL: str = "http://localhost:4000"
    LITELLM_MASTER_KEY: str = "sk-1234"
    
    # AI Provider Keys (for direct access if needed)
    CLAUDE_API_KEY: str | None = None
    OPENAI_API_KEY: str | None = None
    GOOGLE_API_KEY: str | None = None
    XAI_API_KEY: str | None = None
    
    # Egress Proxy
    EGRESS_PROXY: str | None = None
    
    # Budget & Limits
    DEFAULT_MONTHLY_BUDGET: float = 100.0
    COST_ALERT_THRESHOLD: float = 0.8
    ENABLE_BUDGET_ENFORCEMENT: bool = True
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_PER_HOUR: int = 1000
    
    # Approval Gates
    HIGH_RISK_APPROVAL_TIMEOUT_MINUTES: int = 5
    AUTO_APPROVE_LOW_RISK: bool = True
    REQUIRE_ADMIN_FOR_PRODUCTION_DEPLOY: bool = True
    
    # Streaming
    STREAM_CHUNK_SIZE: int = 1024
    STREAM_TIMEOUT_SECONDS: int = 60
    
    # Celery (UI Runner)
    CELERY_BROKER_URL: str = "redis://localhost:6379/2"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
