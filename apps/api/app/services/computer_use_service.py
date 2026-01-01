"""
Computer Use Service - Full Loop Implementation
"""
import asyncio
import base64
import os
from typing import Dict, Optional, List
from datetime import datetime
from playwright.async_api import async_playwright, Browser, Page
import httpx

class ComputerUseService:
    def __init__(self):
        self.browser: Optional[Browser] = None
        self.page: Optional[Page] = None
        self._playwright = None
        self.litellm_url = os.getenv("LITELLM_BASE_URL", "http://simon-litellm:4000")
        
    async def initialize(self):
        """Browser başlat"""
        if not self.browser:
            self._playwright = await async_playwright().start()
            self.browser = await self._playwright.chromium.launch(
                headless=True,
                args=['--no-sandbox', '--disable-setuid-sandbox']
            )
            self.page = await self.browser.new_page()
            
    async def cleanup(self):
        """Browser kapat"""
        if self.page:
            await self.page.close()
        if self.browser:
            await self.browser.close()
        if self._playwright:
            await self._playwright.stop()
            
    async def take_screenshot(self, url: Optional[str] = None) -> Dict:
        """Screenshot al"""
        await self.initialize()
        
        if url:
            await self.page.goto(url, wait_until="networkidle")
        
        screenshot_bytes = await self.page.screenshot(full_page=False)
        screenshot_b64 = base64.b64encode(screenshot_bytes).decode()
        
        return {
            "screenshot": screenshot_b64,
            "url": self.page.url,
            "title": await self.page.title(),
            "timestamp": datetime.utcnow().isoformat(),
            "size_chars": len(screenshot_b64)
        }
    
    async def execute_action(self, action_type: str, **kwargs) -> Dict:
        """Action çalıştır"""
        await self.initialize()
        
        try:
            if action_type == "click":
                x, y = kwargs.get("x", 0), kwargs.get("y", 0)
                await self.page.mouse.click(x, y)
                result = f"Clicked at ({x}, {y})"
                
            elif action_type == "type":
                text = kwargs.get("text", "")
                await self.page.keyboard.type(text)
                result = f"Typed: {text}"
                
            elif action_type == "goto":
                url = kwargs.get("url", "")
                await self.page.goto(url, wait_until="networkidle")
                result = f"Navigated to: {url}"
                
            elif action_type == "scroll":
                delta_y = kwargs.get("delta_y", 100)
                await self.page.mouse.wheel(0, delta_y)
                result = f"Scrolled {delta_y}px"
                
            elif action_type == "DONE":
                result = "Task completed"
                
            else:
                return {"status": "error", "message": f"Unknown action: {action_type}"}
            
            # Action sonrası screenshot
            screenshot = await self.take_screenshot()
            
            return {
                "status": "success",
                "action": action_type,
                "result": result,
                "screenshot": screenshot["screenshot"],
                "url": screenshot["url"]
            }
            
        except Exception as e:
            return {
                "status": "error",
                "action": action_type,
                "message": str(e)
            }
    
    async def computer_use_loop(self, goal: str, max_iterations: int = 5) -> Dict:
        """Computer Use Loop: Screenshot → AI → Action → Repeat"""
        await self.initialize()
        
        iterations = []
        
        for i in range(max_iterations):
            # 1. Screenshot al
            screenshot_data = await self.take_screenshot()
            
            # 2. AI'dan next action iste
            action = await self._get_next_action(goal, screenshot_data, iterations)
            
            if action["action_type"] == "DONE":
                return {
                    "status": "completed",
                    "goal": goal,
                    "iterations": len(iterations),
                    "final_url": self.page.url,
                    "history": iterations
                }
            
            # 3. Action çalıştır
            result = await self.execute_action(action["action_type"], **action.get("params", {}))
            
            iterations.append({
                "iteration": i + 1,
                "action": action,
                "result": result,
                "url": self.page.url
            })
            
            await asyncio.sleep(1)  # Rate limit
        
        return {
            "status": "max_iterations_reached",
            "goal": goal,
            "iterations": len(iterations),
            "final_url": self.page.url,
            "history": iterations
        }
    
    async def _get_next_action(self, goal: str, screenshot_data: Dict, history: List) -> Dict:
        """AI'dan next action al (basitleştirilmiş)"""
        
        # Basit heuristic (AI yerine)
        url = screenshot_data["url"]
        
        if "google.com" not in url:
            return {"action_type": "goto", "params": {"url": "https://www.google.com"}}
        elif len(history) == 0:
            return {"action_type": "type", "params": {"text": goal}}
        elif len(history) == 1:
            return {"action_type": "click", "params": {"x": 500, "y": 400}}
        else:
            return {"action_type": "DONE"}

# Singleton
_service = None

async def get_service() -> ComputerUseService:
    """Service instance al"""
    global _service
    if _service is None:
        _service = ComputerUseService()
    return _service
