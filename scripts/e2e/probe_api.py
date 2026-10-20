"""Call every endpoint the app touches and print the status codes.

Uses the account created by seed_demo_account.py. Any 5xx here is a real defect
that a screen would show as "could not load".

Run: python scripts/e2e/probe_api.py
"""

from __future__ import annotations

import json
import os
import pathlib
import urllib.error
import urllib.request

for key in ("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "ALL_PROXY", "all_proxy"):
    os.environ.pop(key, None)
os.environ["NO_PROXY"] = "*"

HERE = pathlib.Path(__file__).resolve().parent
API = os.environ.get("KHATA_API", "http://127.0.0.1:5182/api")
account = json.loads((HERE / "demo_account.json").read_text(encoding="utf-8"))


def call(method: str, path: str, body=None, token: str | None = None):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(f"{API}{path}", data=data, method=method)
    request.add_header("Content-Type", "application/json")
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            raw = response.read()
            return response.status, raw
    except urllib.error.HTTPError as error:
        return error.code, error.read()


def main() -> int:
    status, raw = call("POST", "/auth/login", {
        "email": account["email"],
        "password": account["password"],
    })
    if status != 200:
        print("login failed", status, raw[:200])
        return 1
    auth = json.loads(raw)
    token = auth["accessToken"]

    status, raw = call("POST", f"/businesses/{account['businessId']}/switch", {}, token)
    if status == 200:
        token = json.loads(raw)["accessToken"]

    paths = [
        "/dashboard",
        "/products?pageSize=50",
        "/categories",
        "/units",
        "/customers?pageSize=50",
        "/suppliers?pageSize=50",
        "/sales?pageSize=20",
        "/purchases?pageSize=20",
        "/expenses?pageSize=20",
        "/incomes?pageSize=20",
        "/payments?pageSize=20",
        "/payments/summary",
        "/payment-methods",
        "/invoices?pageSize=20",
        "/quotations?pageSize=20",
        "/inventory/low-stock",
        "/reports/sales?from=2026-10-01&to=2026-10-31",
        "/reports/profit-loss?from=2026-10-01&to=2026-10-31",
        "/reports/stock",
        "/reports/receivable-payable",
        "/notifications",
        "/notifications/unread-count",
        "/notifications/settings",
        "/notifications/devices",
        "/reminders",
        "/backup/export",
        f"/businesses/{account['businessId']}",
        f"/businesses/{account['businessId']}/bank-accounts",
        f"/businesses/{account['businessId']}/members",
        "/sync/status",
    ]

    failures = 0
    for path in paths:
        code, body = call("GET", path, None, token)
        marker = "ok  " if code < 400 else "FAIL"
        if code >= 500:
            failures += 1
        note = ""
        if code >= 400:
            text = body.decode("utf-8", "replace")
            note = " :: " + text[:160].replace("\n", " ")
        print(f"{marker} {code} GET {path}{note}")

    print(f"\n{failures} server error(s)")
    return 0 if failures == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
