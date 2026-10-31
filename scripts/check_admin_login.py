"""Browser check for the admin console sign-in (CSRF token + admin gate)."""

import sys

from playwright.sync_api import sync_playwright

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:5182"
EMAIL = sys.argv[2] if len(sys.argv) > 2 else "admin@khata.local"
PASSWORD = sys.argv[3] if len(sys.argv) > 3 else "Admin@12345"
RETURN_URL = sys.argv[4] if len(sys.argv) > 4 else None

with sync_playwright() as p:
    # Use the installed Chrome rather than downloading Playwright's bundle.
    browser = p.chromium.launch(channel="chrome")
    page = browser.new_page()

    page.goto(f"{BASE}/login", wait_until="networkidle")
    page.wait_for_selector("input#email", timeout=20000)

    token_input = page.query_selector("input[name='__RequestVerificationToken']")
    print("antiforgery field present:", token_input is not None)
    if token_input:
        print("token length:", len(token_input.get_attribute("value") or ""))

    page.fill("input#email", EMAIL)
    page.fill("input#password", PASSWORD)
    if RETURN_URL:
        page.eval_on_selector("input[name='returnUrl']", "(el, v) => el.value = v", RETURN_URL)
    page.click("button[type=submit]")

    try:
        page.wait_for_load_state("networkidle", timeout=15000)
    except Exception:
        pass

    print("final url:", page.url)
    body = page.inner_text("body")[:400].replace("\n", " | ")
    print("body:", body)

    browser.close()
