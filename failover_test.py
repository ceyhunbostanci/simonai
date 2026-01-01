"""Failover Test - Primary model başarısız olursa fallback"""
import asyncio
import httpx
from typing import List, Dict, Optional

class FailoverRouter:
    """Primary -> Fallback cascading"""
    
    def __init__(self):
        self.models = [
            {
                "name": "qwen2.5:1.5b",
                "endpoint": "http://simon-ollama:11434",
                "priority": 1
            },
            {
                "name": "gemma3",
                "endpoint": "http://simon-ollama:11434",
                "priority": 2
            }
        ]
    
    async def call_with_failover(self, messages: List[Dict]) -> Optional[Dict]:
        """Cascading failover ile çağrı"""
        
        for model in self.models:
            print(f"Trying: {model['name']} (priority {model['priority']})")
            
            try:
                client = httpx.AsyncClient(timeout=30.0)
                
                response = await client.post(
                    f"{model['endpoint']}/v1/chat/completions",
                    json={
                        "model": model["name"],
                        "messages": messages,
                        "max_tokens": 100
                    }
                )
                
                await client.aclose()
                
                if response.status_code == 200:
                    print(f"  ✓ Success with {model['name']}")
                    return response.json()
                else:
                    print(f"  ✗ Failed: {response.status_code}")
                    continue
                    
            except Exception as e:
                print(f"  ✗ Exception: {e}")
                continue
        
        print("✗ All models failed")
        return None

async def test():
    print("=== FAILOVER TEST ===\n")
    
    router = FailoverRouter()
    
    result = await router.call_with_failover([
        {"role": "user", "content": "Merhaba! Kısa cevap ver."}
    ])
    
    if result:
        content = result["choices"][0]["message"]["content"]
        print(f"\nFinal response: {content[:100]}")
    
    print("\n=== TEST COMPLETED ===")

if __name__ == "__main__":
    asyncio.run(test())
