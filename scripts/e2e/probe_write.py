"""Create a customer through the form and prove it persisted.

Reading screens proves widgets paint. This performs a real mutation the way a
shopkeeper would — open the form, type, save — then checks the record is in the
list, and reloads to confirm it came back from the server rather than from
in-memory state.
"""

from __future__ import annotations

import json
import os
import pathlib
import time

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


def fields(page) -> list[dict]:
    nodes = page.evaluate(NODES_JS) or []
    out, seen = [], []
    for n in sorted([x for x in nodes if x["hasInput"] and 200 <= x["w"] <= 440 and 28 <= x["h"] <= 90],
                    key=lambda x: x["cy"]):
        if seen and abs(seen[-1] - n["cy"]) < 20:
            continue
        seen.append(n["cy"])
        out.append(n)
    return out


def click_button(page, needles: tuple[str, ...]) -> str | None:
    for n in page.evaluate(NODES_JS) or []:
        if n["role"] == "button" and any(k.lower() in n["label"].lower() for k in needles):
            page.mouse.click(n["cx"], n["cy"])
            return n["label"]
    return None


def labels(page) -> str:
    return " | ".join(n["label"] for n in (page.evaluate(NODES_JS) or []) if n["label"])


def main() -> int:
    name = f"UI Audit {int(time.time()) % 100000}"
    print(f"will create customer: {name}")

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        context = browser.new_context(viewport={"width": 430, "height": 900})
        page = context.new_page()
        page.set_default_timeout(60_000)
        page.goto(URL, wait_until="load", timeout=90_000)
        page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
        page.wait_for_timeout(6000)

        enable(page)
        click_button(page, ("skip",))
        page.wait_for_timeout(2500)
        enable(page)

        f = fields(page)
        page.mouse.click(f[0]["cx"], f[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(account["email"], delay=10)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type(account["password"], delay=10)
        if not click_button(page, ("sign",)):
            page.keyboard.press("Enter")
        page.wait_for_timeout(6000)
        print(f"signed in: {page.url}")

        page.goto(f"{URL}/#/customers/new", wait_until="load", timeout=45_000)
        page.wait_for_timeout(3500)
        enable(page)
        page.screenshot(path=str(SHOTS / "write-01-form.png"))

        f = fields(page)
        print(f"form fields: {len(f)}")
        page.mouse.click(f[0]["cx"], f[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(name, delay=25)
        page.keyboard.press("Tab")
        page.wait_for_timeout(200)
        page.keyboard.type("9800000099", delay=20)
        page.wait_for_timeout(400)
        page.screenshot(path=str(SHOTS / "write-02-filled.png"))

        clicked = click_button(page, ("बनाउनुहोस्", "create", "save"))
        print(f"save button: {clicked!r}")
        page.wait_for_timeout(5000)
        page.screenshot(path=str(SHOTS / "write-03-after-save.png"))
        print(f"url after save: {page.url}")

        page.goto(f"{URL}/#/customers", wait_until="load", timeout=45_000)
        page.wait_for_timeout(5000)
        enable(page)
        found_before = name in labels(page)
        print(f"visible in list (before reload): {found_before}")
        page.screenshot(path=str(SHOTS / "write-04-list.png"))

        page.reload(wait_until="load", timeout=90_000)
        page.wait_for_timeout(7000)
        page.goto(f"{URL}/#/customers", wait_until="load", timeout=45_000)
        page.wait_for_timeout(5000)
        enable(page)
        found_after = name in labels(page)
        print(f"visible after reload: {found_after}")
        page.screenshot(path=str(SHOTS / "write-05-after-reload.png"))

        browser.close()

    print("\nRESULT:", "PASS — created and survived a reload" if found_after else
          ("PARTIAL — created but did not survive reload" if found_before else "FAIL — not created"))
    return 0 if found_after else 1


if __name__ == "__main__":
    raise SystemExit(main())
