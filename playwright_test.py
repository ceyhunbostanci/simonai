import asyncio
from playwright.async_api import async_playwright
import base64
from datetime import datetime

async def test_playwright():
    print("[1/4] Playwright başlatılıyor...")
    async with async_playwright() as p:
        # Chromium browser başlat
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        print("[2/4] Google'a gidiliyor...")
        await page.goto("https://www.google.com")
        
        print("[3/4] Screenshot alınıyor...")
        screenshot = await page.screenshot()
        screenshot_b64 = base64.b64encode(screenshot).decode()
        
        print(f"[4/4] Başarılı! Screenshot boyutu: {len(screenshot_b64)} chars")
        print(f"Sayfa başlığı: {await page.title()}")
        
        await browser.close()
        
        return {
            "status": "success",
            "screenshot_size": len(screenshot_b64),
            "title": await page.title(),
            "timestamp": datetime.utcnow().isoformat()
        }

if __name__ == "__main__":
    result = asyncio.run(test_playwright())
    print(f"\nSONUÇ: {result}")
