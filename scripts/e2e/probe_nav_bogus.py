"""Reproduce the intermittent bogus hash navigation under the real walk.

The earlier trap probes only *sat* on one route. The bogus location
(`#C:/Users/.../PortableGit/`) was observed during full route walks, so this
script walks every route with the JS trap installed and logs every navigation
event (including fragment-only ones) plus anything the trap captures.

Run: KHATA_ATTEMPTS=3 python scripts/e2e/probe_nav_bogus.py
"""
from __future__ import annotations

import json
import os
import pathlib
import sys

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"
os.environ["no_proxy"] = "*"

from playwright.sync_api import sync_playwright  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from walk_app import ROUTES, sign_in  # noqa: E402

URL = os.environ.get("KHATA_WEB", "http://127.0.0.1:8080")
ATTEMPTS = int(os.environ.get("KHATA_ATTEMPTS", "3"))

HOOK_JS = """
(() => {
  window.__hashTraps = [];
  const push = (how, value) => {
    window.__hashTraps.push({
      how: how,
      value: String(value).slice(0, 160),
      at: new Date().toISOString(),
      stack: (new Error().stack || '').split('\\n').slice(0, 10).join(' | '),
    });
  };
  const loc = window.location;
  try {
    const proto = Object.getPrototypeOf(loc);
    for (const prop of ['hash', 'href']) {
      const desc = Object.getOwnPropertyDescriptor(proto, prop);
      if (desc && desc.set) {
        Object.defineProperty(loc, prop, {
          configurable: true,
          get: desc.get,
          set: function (v) { push('location.' + prop + '=', v); return desc.set.call(loc, v); },
        });
      }
    }
  } catch (e) {}
  for (const name of ['pushState', 'replaceState']) {
    const real = history[name].bind(history);
    history[name] = function (state, title, url) {
      push(name, url); return real(state, title, url);
    };
  }
})();
"""

BAD = "PortableGit"


def one_attempt(playwright, index: int) -> str:
    browser = playwright.chromium.launch(channel="chrome", headless=True)
    context = browser.new_context(viewport={"width": 430, "height": 900})
    page = context.new_page()
    page.set_default_timeout(45_000)

    hits: list[str] = []

    def on_nav(frame) -> None:
        if frame is page.main_frame:
            hits.append(f"NAVIGATED -> {frame.url}")

    page.on("framenavigated", on_nav)
    page.on("pageerror", lambda e: hits.append(f"PAGE ERROR: {str(e)[:200]}"))
    page.add_init_script(HOOK_JS)

    page.goto(URL, wait_until="load", timeout=90_000)
    page.wait_for_selector("flt-glass-pane", state="attached", timeout=90_000)
    page.wait_for_timeout(6000)
    if not sign_in(page):
        browser.close()
        return f"[{index}] SIGN-IN FAILED"

    # Full walk, exactly like walk_app.py.
    for name, route in ROUTES[1:]:
        page.goto(f"{URL}/{route}", wait_until="load", timeout=45_000)
        page.wait_for_timeout(1800)

    # Also sit on the dashboard for a while: the bogus nav was seen "shortly
    # after the dashboard loaded".
    page.goto(f"{URL}/", wait_until="load", timeout=45_000)
    for _ in range(20):
        page.wait_for_timeout(1000)
        hits.append(f"IDLE-URL {page.url}")

    traps = page.evaluate("() => window.__hashTraps || []")
    browser.close()

    bad_nav = [h for h in hits if BAD in h]
    bad_traps = [t for t in traps if BAD in str(t.get("value"))]

    report = [f"[{index}] navigations={len(hits)} traps={len(traps)}"]
    if bad_nav or bad_traps:
        report.append(f"[{index}] *** REPRODUCED *** bad_nav={len(bad_nav)} bad_traps={len(bad_traps)}")
        for h in bad_nav:
            report.append(f"[{index}]   {h}")
        for t in bad_traps[:4]:
            report.append(f"[{index}]   {t['how']} -> {t['value']!r}")
            report.append(f"[{index}]      stack: {t['stack'][:500]}")
        # Dump every trap around the first bad one for context.
        first = next(i for i, t in enumerate(traps) if BAD in str(t.get("value")))
        for t in traps[max(0, first - 3):first + 2]:
            report.append(f"[{index}]   ctx {t['how']} -> {t['value']!r} | {t['stack'][:200]}")
    else:
        report.append(f"[{index}] no bogus navigation")
    return "\n".join(report)


def main() -> int:
    with sync_playwright() as playwright:
        for index in range(1, ATTEMPTS + 1):
            print(one_attempt(playwright, index), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
