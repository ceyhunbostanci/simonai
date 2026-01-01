"""
Cost Tracker Service
Tracks token usage and costs for budget enforcement
"""

import logging
from typing import Dict, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class CostTracker:
    """
    Cost tracking and budget enforcement
    MVP: In-memory tracking (Faz 3: PostgreSQL)
    """
    
    def __init__(self):
        # MVP: Simple in-memory storage
        # TODO: Replace with PostgreSQL in Faz 3
        self._costs = []
    
    async def calculate_cost(
        self,
        model: str,
        tokens_input: int,
        tokens_output: int,
    ) -> float:
        """
        Calculate cost based on model and token usage
        """
        # Cost per 1M tokens
        cost_map = {
            "claude-sonnet-4.5": {"input": 3.0, "output": 15.0},
            "claude-opus-4.5": {"input": 5.0, "output": 25.0},
            "gpt-4o": {"input": 2.5, "output": 10.0},
            "gpt-4o-mini": {"input": 0.15, "output": 0.6},
            "gemini-1.5-pro": {"input": 1.25, "output": 5.0},
        }
        
        # Ollama models are free
        if model.startswith("ollama/") or model in ["gemma3", "qwen2.5", "phi4", "llama3.3", "mistral", "deepseek-r1", "llava"]:
            return 0.0
        
        # Get base model costs
        if model not in cost_map:
            logger.warning(f"Unknown model for cost calculation: {model}")
            return 0.0
        
        costs = cost_map[model]
        
        # Calculate cost
        input_cost = (tokens_input * costs["input"]) / 1_000_000
        output_cost = (tokens_output * costs["output"]) / 1_000_000
        total_cost = input_cost + output_cost
        
        return round(total_cost, 6)
    
    async def record(
        self,
        request_id: str,
        model: str,
        tokens_input: int,
        tokens_output: int,
        cost: float,
        user_id: Optional[str] = None,
        project_id: Optional[str] = None,
    ):
        """
        Record cost entry
        """
        entry = {
            "request_id": request_id,
            "model": model,
            "tokens_input": tokens_input,
            "tokens_output": tokens_output,
            "cost": cost,
            "user_id": user_id,
            "project_id": project_id,
            "timestamp": datetime.utcnow(),
        }
        
        # MVP: Store in memory
        self._costs.append(entry)
        
        logger.info(
            f"Cost recorded: request_id={request_id}, model={model}, "
            f"tokens_in={tokens_input}, tokens_out={tokens_output}, cost=${cost:.6f}"
        )
        
        # TODO Faz 3: Store in PostgreSQL cost_ledger table
    
    async def get_total_cost(
        self,
        user_id: Optional[str] = None,
        project_id: Optional[str] = None,
        since: Optional[datetime] = None,
    ) -> float:
        """
        Get total cost for user/project
        """
        total = 0.0
        
        for entry in self._costs:
            # Filter by user_id
            if user_id and entry.get("user_id") != user_id:
                continue
            
            # Filter by project_id
            if project_id and entry.get("project_id") != project_id:
                continue
            
            # Filter by date
            if since and entry["timestamp"] < since:
                continue
            
            total += entry["cost"]
        
        return round(total, 6)
    
    async def check_budget(
        self,
        user_id: str,
        budget_limit: float,
    ) -> Dict[str, any]:
        """
        Check if user is within budget
        """
        total_cost = await self.get_total_cost(user_id=user_id)
        remaining = budget_limit - total_cost
        percentage_used = (total_cost / budget_limit) * 100 if budget_limit > 0 else 0
        
        return {
            "total_cost": total_cost,
            "budget_limit": budget_limit,
            "remaining": remaining,
            "percentage_used": percentage_used,
            "is_over_budget": total_cost >= budget_limit,
        }
    
    async def get_usage_stats(self) -> Dict[str, any]:
        """
        Get overall usage statistics
        """
        if not self._costs:
            return {
                "total_requests": 0,
                "total_cost": 0.0,
                "total_tokens_input": 0,
                "total_tokens_output": 0,
            }
        
        total_cost = sum(entry["cost"] for entry in self._costs)
        total_tokens_input = sum(entry["tokens_input"] for entry in self._costs)
        total_tokens_output = sum(entry["tokens_output"] for entry in self._costs)
        
        return {
            "total_requests": len(self._costs),
            "total_cost": round(total_cost, 6),
            "total_tokens_input": total_tokens_input,
            "total_tokens_output": total_tokens_output,
            "average_cost_per_request": round(total_cost / len(self._costs), 6) if self._costs else 0.0,
        }
