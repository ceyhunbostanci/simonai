"""Task Decomposition Service"""
import asyncio
import httpx
import json
from typing import List, Dict

async def decompose_task(task: str):
    """Görevi alt-görevlere böl"""
    
    prompt = f"""Görevi alt-görevlere böl ve JSON döndür:

Görev: {task}

JSON format:
{{
  "subtasks": [
    {{"id": "task_1", "description": "...", "type": "code", "tokens": 500, "deps": []}},
    {{"id": "task_2", "description": "...", "type": "test", "tokens": 300, "deps": ["task_1"]}}
  ],
  "strategy": "sequential"
}}

Sadece JSON döndür, başka açıklama yapma."""

    try:
        client = httpx.AsyncClient(timeout=120.0)
        
        response = await client.post(
            "http://simon-ollama:11434/v1/chat/completions",
            json={
                "model": "qwen2.5:1.5b",
                "messages": [
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.3
            }
        )
        
        if response.status_code == 200:
            result = response.json()
            content = result["choices"][0]["message"]["content"]
            
            # JSON temizle
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
            
            data = json.loads(content)
            return data
        else:
            print(f"Error: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"Exception: {e}")
        return None
    finally:
        await client.aclose()

async def main():
    print("=== TASK DECOMPOSITION TEST ===\n")
    
    task = "React ile todo uygulaması yap, backend API ekle, test yaz"
    print(f"Görev: {task}\n")
    
    result = await decompose_task(task)
    
    if result:
        print(f"Strategy: {result['strategy']}")
        print(f"\nSubtasks ({len(result['subtasks'])}):")
        
        total_tokens = 0
        for st in result['subtasks']:
            print(f"\n  [{st['id']}] {st['description']}")
            print(f"    Type: {st['type']} | Tokens: {st.get('tokens', 0)} | Deps: {st.get('deps', [])}")
            total_tokens += st.get('tokens', 0)
        
        print(f"\nTotal estimated tokens: {total_tokens}")
        print(f"Estimated cost: $0.00 (local model)")
        
        # Execution order hesapla
        print("\n=== EXECUTION ORDER ===")
        
        completed = set()
        batch_num = 1
        subtasks = {st['id']: st for st in result['subtasks']}
        
        while subtasks:
            # Bu turda çalışabilecek görevler
            ready = [
                task_id for task_id, st in subtasks.items()
                if all(dep in completed for dep in st.get('deps', []))
            ]
            
            if not ready:
                print(f"Batch {batch_num}: {', '.join(subtasks.keys())} (forced)")
                break
            
            print(f"Batch {batch_num} (parallel): {', '.join(ready)}")
            
            for task_id in ready:
                completed.add(task_id)
                del subtasks[task_id]
            
            batch_num += 1
    else:
        print("✗ Decomposition failed")
    
    print("\n=== TEST COMPLETED ===")

if __name__ == "__main__":
    asyncio.run(main())
