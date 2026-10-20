"""Open a sale detail screen and report the summary-row labels.

Targeted check for the i18n fix: Subtotal/Total/Tax/Paid/Due were hardcoded
English inside an otherwise Nepali UI, even though the ARB had translations.
"""

from __future__ import annotations

import json
import os
import pathlib

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

from playwright.sync_api import sync_playwright  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
SHOTS = HERE / "audit_shots"
URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))

NODES_JS = """
Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {label:(n.getAttribute('aria-label')||n.textContent||'').trim(),
          role:n.getAttribute('role')||'', hasInput:!!n.querySelector('input, textarea'),
          cx:Math.round(r.x+r.width/2), cy:Math.round(r.y+r.height/2),
          w:Math.round(r.width), h:Math.round(r.height)};
})
"""


def enable(page) -> None:
    page.evaluate("() => { const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click(); }")
    page.wait_for_timeout(1200)


def click(page, needle: str) -> bool:
    for n in page.evaluate(NODES_JS) or []:
        if n["role"] == "button" and needle.lower() in n["label"].lower():
            page.mouse.click(n["cx"], n["cy"])
            return True
    return False


def main() -> int:
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 430, "height": 900})
        page = context.new_page()
        page.set_default_timeout(60_000)
        page.goto(URL, wait_until="load", timeout=90_000)
        page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        page.wait_for_timeout(6000)

        enable(page)
        click(page, "skip")
        page.wait_for_timeout(2500)
        enable(page)

        nodes = page.evaluate(NODES_JS) or []
        seen, fields = [], []
        for n in sorted([x for x in nodes if x["hasInput"] and 200 <= x["w"] <= 440 and 28 <= x["h"] <= 90],
                        key=lambda x: x["cy"]):
            if seen and abs(seen[-1] - n["cy"]) < 20:
                continue
            seen.append(n["cy"])
            fields.append(n)
        page.mouse.click(fields[0]["cx"], fields[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(account["email"], delay=10)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type(account["password"], delay=10)
        if not click(page, "sign"):
            page.keyboard.press("Enter")
        page.wait_for_timeout(6000)

        for route in ("#/sales/1", "#/invoices", "#/sales"):
            page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
            page.wait_for_timeout(5000)
            enable(page)
            labels = [n["label"] for n in (page.evaluate(NODES_JS) or []) if n["label"]]
            joined = " | ".join(labels)
            print(f"\n{route}: {page.url.split('#')[-1]}")
            for term in ("उपजम्मा", "जम्मा", "कर", "छुट", "भुक्तान", "बाँकी", "Subtotal", "Total", "Tax"):
                if term in joined:
                    print(f"   FOUND {term!r}")
            page.screenshot(path=str(SHOTS / f"i18n-{route.strip('#/').replace('/', '-')}.png"))

        browser.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
