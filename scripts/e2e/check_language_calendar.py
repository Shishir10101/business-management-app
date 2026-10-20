"""Verify the language switcher (en/ne/hi) and the AD/BS calendar choice.

Flutter renders into a shadow DOM, so this drives the semantics tree and
clicks real bounding boxes. Menu items of a DropdownButtonFormField appear as
semantics nodes carrying the option text.
"""
import json
import sys

from playwright.sync_api import sync_playwright

URL = "http://127.0.0.1:8080/"
SHOTS = "E:/business-management-app/docs/screenshots"
CREDS = json.load(open("E:/business-management-app/scripts/e2e/demo_account.json"))

SEMANTICS_JS = """
() => Array.from(document.querySelectorAll('flt-semantics')).map(n => {
  const r = n.getBoundingClientRect();
  return {label: (n.getAttribute('aria-label') || n.textContent || '').trim(),
          role: n.getAttribute('role') || '',
          hasInput: !!n.querySelector('input, textarea'),
          cx: Math.round(r.x + r.width/2), cy: Math.round(r.y + r.height/2),
          w: Math.round(r.width), h: Math.round(r.height)};
}).filter(n => n.w > 0 && n.h > 0)
"""

results = []


def say(msg):
    print(msg, flush=True)


def nodes(page):
    return page.evaluate(SEMANTICS_JS)


def labels(page):
    return [n["label"] for n in nodes(page) if n["label"]]


def has(page, needle):
    return any(needle in l for l in labels(page))


def enable(page):
    page.evaluate("() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }")
    page.wait_for_timeout(1200)


def fill(page, text, index=0):
    fields = sorted(
        [n for n in nodes(page) if n["hasInput"] and 28 <= n["h"] <= 80 and n["w"] >= 100],
        key=lambda n: n["cy"],
    )
    if index >= len(fields):
        return False
    f = fields[index]
    page.mouse.click(f["cx"], f["cy"])
    page.wait_for_timeout(350)
    page.keyboard.type(text, delay=20)
    return True


def click_label(page, needle, exact=False):
    cands = [
        n for n in nodes(page)
        if n["label"].strip()
        and (n["label"].strip() == needle if exact else needle in n["label"])
        and 0 < n["cy"] < 880
    ]
    if not cands:
        say(f"   !! nothing clickable for {needle!r}")
        for n in nodes(page):
            if n["label"]:
                say(f"      {n['role']:>9} ({n['cx']},{n['cy']}) {n['w']}x{n['h']} "
                    f"{n['label'][:34]!r}")
        return False
    # prefer the smallest node: the text itself, not a page wrapper
    target = min(cands, key=lambda n: n["w"] * n["h"])
    page.mouse.click(target["cx"], target["cy"])
    return True


def open_profile(page):
    page.goto(URL + "#/profile", wait_until="load")
    page.wait_for_timeout(4500)
    enable(page)


def choose(page, field_needle, option, expected, name):
    """Open a dropdown by its field label, pick `option`, assert `expected`."""
    if not click_label(page, field_needle):
        results.append((name, False))
        return
    page.wait_for_timeout(1200)
    say(f"   menu: {[l[:22] for l in labels(page)][:10]}")
    if not click_label(page, option, exact=True):
        page.keyboard.press("Escape")
        page.wait_for_timeout(600)
        results.append((name, False))
        return
    page.wait_for_timeout(1800)
    ok = has(page, expected)
    say(f"   now: {[l[:22] for l in labels(page) if len(l) < 30][:10]}")
    results.append((name, ok))


with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", headless=True)
    page = b.new_page(viewport={"width": 420, "height": 880})
    page.goto(URL, wait_until="load", timeout=90000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90000)
    page.wait_for_timeout(7000)
    enable(page)
    fill(page, CREDS["email"], 0)
    fill(page, CREDS["password"], 1)
    click_label(page, "Sign In", exact=True)
    page.wait_for_timeout(9000)
    say(f"after login: {page.url}")

    # The account's saved locale (ne for the demo shop) must be applied.
    open_profile(page)
    say(f"profile: {[l[:24] for l in labels(page) if len(l) < 34][:10]}")
    results.append(("account locale applied", has(page, "पात्रो")))

    # --- to English ---
    choose(page, "भाषा", "अंग्रेजी", "Calendar", "switch to english")
    page.screenshot(path=f"{SHOTS}/lang-01-english.png")

    # --- to Nepali ---
    choose(page, "Language", "नेपाली", "पात्रो", "switch to nepali")
    page.screenshot(path=f"{SHOTS}/lang-02-nepali.png")

    # --- to Hindi ---
    choose(page, "भाषा", "हिन्दी", "कैलेंडर", "switch to hindi")
    page.screenshot(path=f"{SHOTS}/lang-03-hindi.png")

    # --- persistence ---
    open_profile(page)
    results.append(("hindi persists after reload", has(page, "कैलेंडर")))

    # --- calendar: BS ---
    choose(page, "कैलेंडर", "वि.सं. (बिक्रम संवत)", "वि.सं.", "calendar set to bs")
    page.goto(URL + "#/expenses/new", wait_until="load")
    page.wait_for_timeout(4500)
    enable(page)
    say(f"expense form (BS): {[l[:50] for l in labels(page) if len(l) < 70][:8]}")
    results.append(("bs date on form", has(page, "2083-")))
    page.screenshot(path=f"{SHOTS}/lang-04-bs-form.png")

    date_node = next((n for n in nodes(page) if "2083-" in n["label"]), None)
    if date_node:
        page.mouse.click(date_node["cx"], date_node["cy"])
        page.wait_for_timeout(2200)
        picker = [l for l in labels(page) if "वि.सं." in l or "BS" in l]
        say(f"picker: {[l[:40] for l in picker][:6]}")
        results.append(("bs picker opens", bool(picker)))
        page.screenshot(path=f"{SHOTS}/lang-05-bs-picker.png")
        page.keyboard.press("Escape")
        page.wait_for_timeout(900)
    else:
        results.append(("bs picker opens", False))

    # --- calendar: AD ---
    open_profile(page)
    choose(page, "कैलेंडर", "ईस्वी (AD)", "ईस्वी", "calendar set to ad")
    page.goto(URL + "#/expenses/new", wait_until="load")
    page.wait_for_timeout(4500)
    enable(page)
    say(f"expense form (AD): {[l[:50] for l in labels(page) if len(l) < 70][:8]}")
    results.append(("ad date on form", has(page, "2026-10-18")))
    page.screenshot(path=f"{SHOTS}/lang-06-ad-form.png")

    b.close()

say("")
for name, ok in results:
    say(f"  {'PASS' if ok else 'FAIL'}  {name}")
passed = sum(1 for _, ok in results if ok)
say(f"RESULT {passed}/{len(results)}")
sys.exit(0 if passed == len(results) else 1)
