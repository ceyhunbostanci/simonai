"""Task Decomposition Service - Basit Test"""
import asyncio
import httpx
import json

async def test():
    print("=== TASK DECOMPOSITION TEST ===")
    print("Ollama connection test...")
    
    try:
        client = httpx.AsyncClient(timeout=30.0)
        response = await client.get("http://simon-ollama:11434/api/tags")
        
        if response.status_code == 200:
            print("✓ Ollama connected")
            models = response.json()
            print(f"✓ Available models: {len(models.get('models', []))}")
        else:
            print(f"✗ Ollama error: {response.status_code}")
            
    except Exception as e:
        print(f"✗ Connection failed: {e}")
    finally:
        await client.aclose()
    
    print("\n=== TEST COMPLETED ===")

if __name__ == "__main__":
    asyncio.run(test())
