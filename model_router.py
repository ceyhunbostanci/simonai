"""Model Router - Akıllı model seçimi ve failover"""
import asyncio
import httpx
from typing import Optional, Dict, List
from datetime import datetime

class ModelRouter:
    """Görev karmaşıklığına göre model seçer"""
    
    def __init__(self):
        self.models = {
            "simple": {
                "name": "qwen2.5:1.5b",
                "endpoint": "http://simon-ollama:11434",
                "cost_per_1k": 0.0,
                "max_tokens": 2048
            },
            "standard": {
                "name": "qwen2.5:1.5b",
                "endpoint": "http://simon-ollama:11434", 
                "cost_per_1k": 0.0,
                "max_tokens": 4096
            },
            "complex": {
                "name": "claude-sonnet-4-5",
                "endpoint": "http://simon-litellm:4000",
                "cost_per_1k": 0.003,
                "max_tokens": 8192
            }
        }
        
        self.budget_limit = 10.0  # $10 limit
        self.current_spend = 0.0
        self.request_count = 0
    
    def select_model(self, task_type: str, estimated_tokens: int) -> Dict:
        """Görev tipine göre model seç"""
        
        # Budget kontrolü
        if self.current_spend >= self.budget_limit:
            print(f"⚠ Budget limit reached: ${self.current_spend:.2f}")
            return self.models["simple"]  # Fallback to free
        
        # Karmaşıklık analizi
        if task_type in ["research", "document"] or estimated_tokens < 500:
            selected = "simple"
        elif task_type in ["test", "ui_action"] or estimated_tokens < 2000:
            selected = "standard"
        else:
            selected = "complex"
        
        model = self.models[selected]
        
        # Maliyet tahmini
        estimated_cost = (estimated_tokens / 1000) * model["cost_per_1k"]
        
        print(f"Selected: {selected} ({model['name']})")
        print(f"  Estimated cost: ${estimated_cost:.4f}")
        
        return model
    
    def update_spend(self, tokens_used: int, model_name: str):
        """Harcama güncelle"""
        for tier, model in self.models.items():
            if model["name"] == model_name:
                cost = (tokens_used / 1000) * model["cost_per_1k"]
                self.current_spend += cost
                self.request_count += 1
                print(f"  Spend updated: +${cost:.4f} (total: ${self.current_spend:.4f})")
                break
    
    async def call_model(self, model: Dict, messages: List[Dict]) -> Optional[Dict]:
        """Model çağrısı yap"""
        
        try:
            client = httpx.AsyncClient(timeout=120.0)
            
            url = f"{model['endpoint']}/v1/chat/completions"
            
            response = await client.post(
                url,
                json={
                    "model": model["name"],
                    "messages": messages,
                    "max_tokens": min(model["max_tokens"], 2000)
                },
                headers={"Authorization": "Bearer sk-simon-local-master"}
            )
            
            if response.status_code == 200:
                result = response.json()
                tokens = result.get("usage", {}).get("total_tokens", 0)
                self.update_spend(tokens, model["name"])
                return result
            else:
                print(f"  Error: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"  Exception: {e}")
            return None
        finally:
            await client.aclose()

async def test_routing():
    print("=== MODEL ROUTING TEST ===\n")
    
    router = ModelRouter()
    
    # Test 1: Basit görev
    print("Test 1: Basit görev (log parse)")
    model = router.select_model("research", 200)
    result = await router.call_model(model, [
        {"role": "user", "content": "1+1 kaçtır? Sadece sayı söyle."}
    ])
    
    if result:
        print(f"  Response: {result['choices'][0]['message']['content'][:50]}")
    
    print(f"\nBudget status: ${router.current_spend:.4f} / ${router.budget_limit:.2f}")
    print(f"Requests: {router.request_count}\n")
    
    # Test 2: Standart görev
    print("Test 2: Standart görev (kod)")
    model = router.select_model("code", 800)
    
    print(f"\nBudget status: ${router.current_spend:.4f} / ${router.budget_limit:.2f}")
    print(f"Requests: {router.request_count}\n")
    
    print("=== TEST COMPLETED ===")

if __name__ == "__main__":
    asyncio.run(test_routing())
