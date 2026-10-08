#!/usr/bin/env python3
import asyncio
import nodriver as nd

async def main():
    browser = await nd.start(
        headless=False,
        browser_executable_path="/usr/bin/chromium",
        browser_args=[
            "--no-sandbox",
            "--disable-dev-shm-usage",
            "--disable-ipv6",
            "--disable-gpu",
        ],
    )
    page = await browser.get("https://example.com")
    await asyncio.sleep(5)
    print("Title:", await page.evaluate("document.title"))
    await asyncio.sleep(3)
    browser.stop()

asyncio.run(main())
