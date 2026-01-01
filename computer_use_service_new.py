"""
Computer Use Service - Gerçek Playwright entegrasyonu
Screenshot capture + action execution
"""
import asyncio
import base64
from typing import Dict, Optional
from datetime import datetime
from playwright.async_api import async_playwright, Browser, Page

class ComputerUseService:
    def __init__(self):
        self.browser: Optional[Browser] = None
        self.page: Optional[Page] = None
        self._playwright = None
        
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

# Singleton instance
_service = None

async def get_service() -> ComputerUseService:
    """Service instance al"""
    global _service
    if _service is None:
        _service = ComputerUseService()
    return _service
