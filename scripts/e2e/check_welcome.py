"""Verify the first-run welcome: language before sign-in, a working Skip, and
that the tour never comes back.

Usage:
  python scripts/e2e/check_welcome.py
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
    n = needle.lower()
    return any(n in l.lower() for l in labels(page))


def enable(page):
    page.evaluate(
        "() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) p.click(); }"
    )
    page.wait_for_timeout(1200)


def click_label(page, needle, exact=False, max_y=880):
    cands = [
        n for n in nodes(page)
        if n["label"].strip()
        and (n["label"].strip() == needle if exact else needle in n["label"])
        and 0 < n["cy"] < max_y
    ]
    if not cands:
        say(f"   !! nothing clickable for {needle!r}")
        for n in nodes(page):
            if n["label"]:
                say(f"      {n['role']:>9} ({n['cx']},{n['cy']}) {n['w']}x{n['h']} "
                    f"{n['label'][:34]!r}")
        return False
    target = min(cands, key=lambda n: n["w"] * n["h"])
    page.mouse.click(target["cx"], target["cy"])
    return True


with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", headless=True)
    # A fresh context = a fresh profile, i.e. no `welcome_seen` in prefs.
    ctx = b.new_context(viewport={"width": 420, "height": 880})
    page = ctx.new_page()
    page.goto(URL, wait_until="load", timeout=90000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90000)
    page.wait_for_timeout(7000)
    enable(page)

    say(f"first launch url: {page.url}")
    results.append(("first launch opens the welcome", "/welcome" in page.url))
    results.append(("welcome offers the language choice",
                    has(page, "Choose your language") or has(page, "भाषा")))
    page.screenshot(path=f"{SHOTS}/welcome-01-english.png")

    # --- language applies before sign-in --------------------------------
    if click_label(page, "नेपाली", exact=True):
        page.wait_for_timeout(1800)
        enable(page)
        ne = has(page, "तपाईंको भाषा छान्नुहोस्")
        say(f"after nepali: {[l[:26] for l in labels(page)][:8]}")
        results.append(("language switches on the welcome screen", ne))
        page.screenshot(path=f"{SHOTS}/welcome-02-nepali.png")
    else:
        results.append(("language switches on the welcome screen", False))

    # --- paging ---------------------------------------------------------
    if click_label(page, "अर्को") or click_label(page, "Next"):
        page.wait_for_timeout(1200)
        enable(page)
        results.append(("next advances the tour", has(page, "स्टक") or has(page, "Stock")))
        page.screenshot(path=f"{SHOTS}/welcome-03-slide2.png")
    else:
        results.append(("next advances the tour", False))

    # --- skip -----------------------------------------------------------
    if click_label(page, "छोड्नुहोस्", exact=True) or click_label(page, "Skip", exact=True):
        page.wait_for_timeout(2500)
        enable(page)
        say(f"after skip: {page.url}")
        results.append(("skip lands on sign-in", "/login" in page.url))
        results.append(("sign-in is in the chosen language", has(page, "साइन इन")))
        page.screenshot(path=f"{SHOTS}/welcome-04-login-nepali.png")
    else:
        results.append(("skip lands on sign-in", False))

    # --- it must not come back ------------------------------------------
    page.reload(wait_until="load")
    page.wait_for_timeout(8000)
    enable(page)
    say(f"after reload: {page.url}")
    results.append(("tour does not reappear after a restart", "/login" in page.url))

    # --- sign in still works --------------------------------------------
    fields = sorted(
        [n for n in nodes(page) if n["hasInput"] and 28 <= n["h"] <= 80 and n["w"] >= 100],
        key=lambda n: n["cy"],
    )
    if len(fields) >= 2:
        page.mouse.click(fields[0]["cx"], fields[0]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(CREDS["email"], delay=15)
        page.mouse.click(fields[1]["cx"], fields[1]["cy"])
        page.wait_for_timeout(300)
        page.keyboard.type(CREDS["password"], delay=15)
        page.keyboard.press("Enter")
        page.wait_for_timeout(9000)
        enable(page)
        say(f"after login: {page.url}")
        results.append(("sign-in reaches the shop", "/login" not in page.url))
        page.screenshot(path=f"{SHOTS}/welcome-05-after-login.png")
    else:
        results.append(("sign-in reaches the shop", False))

    b.close()

say("")
for name, ok in results:
    say(f"  {'PASS' if ok else 'FAIL'}  {name}")
passed = sum(1 for _, ok in results if ok)
say(f"RESULT {passed}/{len(results)}")
sys.exit(0 if passed == len(results) else 1)
