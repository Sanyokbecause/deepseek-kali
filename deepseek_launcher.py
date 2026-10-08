#!/usr/bin/env python3
import asyncio
import os
import sys
import logging
from pathlib import Path
from datetime import date

import nodriver as nd

PROFILE = Path.home() / "antidetect" / "profiles" / "deepseek"
LOG_DIR = Path.home() / "antidetect" / "logs"
URL = "https://chat.deepseek.com"
CHROME = "/usr/bin/chromium"

PROFILE.mkdir(parents=True, exist_ok=True)
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / f"deepseek-{date.today()}.log"),
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("ds")

BROWSER_ARGS = [
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--disable-ipv6",
    "--disable-gpu",
    "--lang=ru-RU",
    "--window-size=1600,900",
    f"--user-data-dir={PROFILE}",
]

proxy = os.environ.get("DS_PROXY")
if proxy:
    BROWSER_ARGS.append(f"--proxy-server={proxy}")
    log.info(f"Прокси: {proxy[:40]}...")


async def main():
    log.info(f"Запускаю Chrome. Профиль: {PROFILE}")
    try:
        browser = await nd.start(
            headless=False,
            browser_executable_path=CHROME,
            browser_args=BROWSER_ARGS,
        )
    except Exception as e:
        log.error(f"Chrome не запустился: {e}")
        sys.exit(1)

    log.info(f"Открываю {URL}")
    try:
        page = await browser.get(URL)
        await asyncio.sleep(8)
        title = await page.evaluate("document.title")
        log.info(f"Загружено. Title: {title}")
    except Exception as e:
        log.error(f"Ошибка загрузки: {e}")

    log.info("Браузер работает. Ctrl+C — закрыть.")

    try:
        while True:
            try:
                _ = await page.evaluate("1")
            except Exception:
                log.info("Браузер закрыт.")
                break
            await asyncio.sleep(2)
    except KeyboardInterrupt:
        log.info("Останавливаюсь...")
    finally:
        try:
            browser.stop()
        except Exception:
            pass


if __name__ == "__main__":
    asyncio.run(main())
