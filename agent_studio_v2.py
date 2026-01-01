"""Agent Studio Service - Faz 1 Update"""
import asyncio
import httpx
import json
from typing import Dict, List, Optional
from datetime import datetime
import uuid

class AgentStudioServiceV2:
    """Task decomposition + Model routing ile geliştirilmiş orchestrator"""
    
    def __init__(self):
        self.litellm_url = "http://simon-litellm:4000"
        self.ollama_url = "http://simon-ollama:11434"
        self.tasks = {}  # In-memory task store
        self.budget_limit = 10.0
        self.current_spend = 0.0
    
    def select_model(self, task_type: str, tokens: int) -> Dict:
        """Akıllı model seçimi"""
        if self.current_spend >= self.budget_limit:
            return {"name": "qwen2.5:1.5b", "endpoint": self.ollama_url, "cost": 0.0}
        
        if tokens < 500 or task_type in ["research", "document"]:
            return {"name": "qwen2.5:1.5b", "endpoint": self.ollama_url, "cost": 0.0}
        else:
            return {"name": "qwen2.5:1.5b", "endpoint": self.ollama_url, "cost": 0.0}
    
    async def decompose(self, prompt: str) -> Dict:
        """Görevi alt-görevlere böl"""
        task_prompt = f"""Görevi JSON formatında alt-görevlere böl:

Görev: {prompt}

Format:
{{
  "subtasks": [
    {{"id": "task_1", "description": "...", "type": "code", "tokens": 500, "deps": []}}
  ],
  "strategy": "sequential"
}}"""

        client = httpx.AsyncClient(timeout=120.0)
        
        try:
            response = await client.post(
                f"{self.ollama_url}/v1/chat/completions",
                json={
                    "model": "qwen2.5:1.5b",
                    "messages": [{"role": "user", "content": task_prompt}],
                    "temperature": 0.3
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                content = result["choices"][0]["message"]["content"]
                
                # JSON parse
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                
                return json.loads(content)
            else:
                return {"subtasks": [{"id": "task_1", "description": prompt, "type": "code", "tokens": 1000, "deps": []}], "strategy": "sequential"}
                
        except Exception as e:
            return {"subtasks": [{"id": "task_1", "description": prompt, "type": "code", "tokens": 1000, "deps": []}], "strategy": "sequential"}
        finally:
            await client.aclose()
    
    async def create_task(self, prompt: str) -> Dict:
        """Yeni görev oluştur"""
        task_id = str(uuid.uuid4())[:8]
        
        print(f"[{task_id}] Creating task...")
        
        # Decompose
        decomposition = await self.decompose(prompt)
        
        task = {
            "id": task_id,
            "prompt": prompt,
            "subtasks": decomposition["subtasks"],
            "strategy": decomposition["strategy"],
            "status": "ready",
            "created_at": datetime.utcnow().isoformat(),
            "results": {}
        }
        
        self.tasks[task_id] = task
        
        print(f"[{task_id}] Decomposed into {len(task['subtasks'])} subtasks")
        
        return task
    
    async def execute_subtask(self, task_id: str, subtask_id: str) -> Dict:
        """Tek alt-görev çalıştır"""
        task = self.tasks[task_id]
        subtask = next(st for st in task["subtasks"] if st["id"] == subtask_id)
        
        print(f"  [{subtask_id}] Executing: {subtask['description'][:50]}...")
        
        # Model seç
        model = self.select_model(subtask["type"], subtask["tokens"])
        
        # Çalıştır
        client = httpx.AsyncClient(timeout=120.0)
        
        try:
            response = await client.post(
                f"{model['endpoint']}/v1/chat/completions",
                json={
                    "model": model["name"],
                    "messages": [
                        {"role": "user", "content": subtask["description"]}
                    ],
                    "max_tokens": 500
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                output = result["choices"][0]["message"]["content"]
                tokens = result.get("usage", {}).get("total_tokens", 0)
                
                self.current_spend += (tokens / 1000) * model["cost"]
                
                print(f"  [{subtask_id}] ✓ Completed ({tokens} tokens)")
                
                return {
                    "status": "completed",
                    "output": output[:200] + "..." if len(output) > 200 else output,
                    "tokens": tokens
                }
            else:
                return {"status": "failed", "error": f"HTTP {response.status_code}"}
                
        except Exception as e:
            return {"status": "failed", "error": str(e)}
        finally:
            await client.aclose()
    
    async def execute_task(self, task_id: str) -> Dict:
        """Görevi çalıştır (batch execution)"""
        task = self.tasks[task_id]
        
        print(f"[{task_id}] Executing {len(task['subtasks'])} subtasks...")
        
        task["status"] = "running"
        
        # Basit sıralı çalıştırma
        for subtask in task["subtasks"]:
            result = await self.execute_subtask(task_id, subtask["id"])
            task["results"][subtask["id"]] = result
        
        task["status"] = "completed"
        
        print(f"[{task_id}] ✓ Task completed")
        
        return task
    
    def get_status(self) -> Dict:
        """Sistem durumu"""
        return {
            "tasks": len(self.tasks),
            "budget": f"${self.current_spend:.4f} / ${self.budget_limit:.2f}",
            "budget_remaining": self.budget_limit - self.current_spend
        }

async def test():
    print("=== AGENT STUDIO V2 TEST ===\n")
    
    service = AgentStudioServiceV2()
    
    # Task oluştur
    task = await service.create_task("Python ile Fibonacci fonksiyonu yaz ve test et")
    
    print(f"\nTask ID: {task['id']}")
    print(f"Strategy: {task['strategy']}")
    print(f"Subtasks: {len(task['subtasks'])}")
    
    # Çalıştır
    print(f"\n--- Execution ---")
    result = await service.execute_task(task['id'])
    
    # Sonuçlar
    print(f"\n--- Results ---")
    for subtask_id, res in result['results'].items():
        print(f"\n[{subtask_id}] {res['status']}")
        if res['status'] == 'completed':
            print(f"  Tokens: {res['tokens']}")
            print(f"  Output: {res['output'][:100]}...")
    
    # Durum
    print(f"\n--- Status ---")
    status = service.get_status()
    print(f"Total tasks: {status['tasks']}")
    print(f"Budget: {status['budget']}")
    
    print("\n=== TEST COMPLETED ===")

if __name__ == "__main__":
    asyncio.run(test())
