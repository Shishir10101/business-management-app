"""Diff the app's BS calendar against an independent implementation.

Ground truth: `nepali-datetime` (pip), which carries its own BS month-length
table. The app uses `nepali_utils` plus a round-trip correction, so the two
implementations share no code — a disagreement is a real bug in one of them,
and every disagreement gets checked against the published calendar.

    python scripts/verify_calendar.py

Requires `dart` on PATH (or set DART) and `pip install nepali-datetime`.
"""

from __future__ import annotations

import datetime as dt
import os
import subprocess
import sys

import nepali_datetime as nd

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "apps", "mobile")
DART = os.environ.get("DART", "dart")
# On Windows `dart` is a .bat shim, which CreateProcess cannot execute directly.
if os.name == "nt" and not DART.lower().endswith((".exe", ".bat", ".cmd")):
    DART += ".bat"


def dart_dump(mode: str) -> list[tuple[str, str]]:
    result = subprocess.run(
        [DART, "run", "tool/verify_calendar.dart", mode],
        cwd=APP, capture_output=True, text=True, check=True,
    )
    rows = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line or "," not in line:
            continue
        a, b = line.split(",", 1)
        rows.append((a, b))
    return rows


def py_ad_to_bs() -> dict[str, str]:
    out = {}
    day = dt.date(1918, 1, 1)
    end = dt.date(2043, 12, 31)
    while day <= end:
        try:
            n = nd.date.from_datetime_date(day)
        except Exception:
            day += dt.timedelta(days=1)
            continue
        if 1975 <= n.year <= 2099:
            out[day.isoformat()] = f"{n.year}-{n.month}-{n.day}"
        day += dt.timedelta(days=1)
    return out


def py_bs_to_ad() -> dict[str, str]:
    out = {}
    for year in range(1975, 2100):
        for month in range(1, 13):
            try:
                probe = nd.date(year, month, 1)
            except Exception:
                continue
            # Walk forward while the month stays the same.
            day = 1
            while True:
                try:
                    n = nd.date(year, month, day)
                except Exception:
                    break
                if n.month != month:
                    break
                out[f"{year}-{month}-{day}"] = n.to_datetime_date().isoformat()
                day += 1
                if day > 32:
                    break
    return out


def compare(label: str, app: list[tuple[str, str]], truth: dict[str, str]) -> int:
    missing = 0
    wrong = []
    for key, value in app:
        expected = truth.get(key)
        if expected is None:
            missing += 1
            continue
        if value != expected:
            wrong.append((key, value, expected))

    print(f"\n{label}: {len(app)} app rows, {len(truth)} reference rows")
    print(f"  unmatched keys: {missing}")
    print(f"  wrong values  : {len(wrong)}")

    if wrong:
        # Which years are affected? A bug that only touches the 1920s is
        # history; one that reaches 2080+ is what a shopkeeper sees today.
        by_year: dict[int, int] = {}
        for key, _, want in wrong:
            year = int(want.split("-")[0])
            by_year[year] = by_year.get(year, 0) + 1
        years = sorted(by_year)
        print(f"  affected reference years: {years[0]}..{years[-1]}")
        decades = sorted({(y // 10) * 10 for y in years})
        print("  by decade: " + ", ".join(
            f"{d}s={sum(v for y, v in by_year.items() if (y // 10) * 10 == d)}"
            for d in decades))
        for key, got, want in wrong[:8]:
            print(f"    {key}: app={got} reference={want}")
        if len(wrong) > 8:
            print(f"    ... and {len(wrong) - 8} more")
    return len(wrong)


def main() -> int:
    ad_rows = dart_dump("ad")
    bs_rows = dart_dump("bs")
    bad = compare("AD -> BS", ad_rows, py_ad_to_bs())
    bad += compare("BS -> AD", bs_rows, py_bs_to_ad())
    print("\nRESULT:", "OK" if bad == 0 else f"{bad} mismatches")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
