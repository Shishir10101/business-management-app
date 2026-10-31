#!/usr/bin/env python3
"""Black-box security / traffic probe for the Khata API.

Run against a live instance:

    python scripts/security_probe.py http://127.0.0.1:5099

Every check prints PASS (the control held) or FAIL (a finding). Exit code is
the number of failures, so it can gate a build.
"""

from __future__ import annotations

import base64
import json
import random
import string
import sys
import time
import urllib3

import requests

urllib3.disable_warnings()

BASE = (sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:5099").rstrip("/")

results: list[tuple[str, str, str]] = []


def record(control: str, ok: bool, detail: str) -> None:
    results.append(("PASS" if ok else "FAIL", control, detail))
    print(f"[{'PASS' if ok else 'FAIL'}] {control}\n        {detail}")


def rand(n: int = 8) -> str:
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=n))


def call(method: str, path: str, token: str | None = None, **kwargs) -> requests.Response:
    headers = kwargs.pop("headers", {})
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return requests.request(method, f"{BASE}{path}", headers=headers, timeout=30, **kwargs)


def decode_jwt(token: str) -> dict:
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return json.loads(base64.urlsafe_b64decode(payload))


def register(email: str, password: str = "Probe9-Pass-9x", locale: str = "en") -> dict:
    r = call("POST", "/api/auth/register", json={
        "fullName": f"Probe {email[:6]}",
        "email": email,
        "password": password,
        "phoneNumber": None,
        "locale": locale,
    })
    return {"status": r.status_code, "body": safe_json(r), "raw": r.text}


def login(email: str, password: str = "Probe9-Pass-9x", xff: str | None = None) -> dict:
    headers = {"X-Forwarded-For": xff} if xff else {}
    r = call("POST", "/api/auth/login", json={"email": email, "password": password}, headers=headers)
    return {"status": r.status_code, "body": safe_json(r), "raw": r.text}


def safe_json(r: requests.Response):
    try:
        return r.json()
    except Exception:
        return None


def new_tenant(label: str) -> dict:
    """Register a user, create a business, return tokens + ids."""
    email = f"probe-{label}-{rand()}@khata.local"
    reg = register(email)
    token = reg["body"]["accessToken"]
    r = call("POST", "/api/businesses", token, json={
        "name": f"Probe Shop {label}",
        "type": "Retail",
        "currency": "NPR",
    })
    business = safe_json(r) or {}
    sw = call("POST", f"/api/businesses/{business.get('id')}/switch", token)
    body = safe_json(sw) or {}
    return {
        "email": email,
        "password": "Probe9-Pass-9x",
        "userId": reg["body"]["userId"],
        "businessId": business.get("id"),
        "token": body.get("accessToken", token),
        "refresh": body.get("refreshToken"),
    }


# ---------------------------------------------------------------- rate limiting
def run_rate_limit_checks() -> None:
    """Only meaningful against a deployment with the shipped limits (10/min)."""
    print("\n=== Rate limiting / traffic ===")
    victim_email = f"probe-rl-{rand()}@khata.local"
    register(victim_email)

    fixed = f"203.0.113.{random.randint(1, 250)}"
    codes = [login(victim_email, "Wrong-Password-1", xff=fixed)["status"] for _ in range(14)]
    record("auth rate limit trips at 10/min", 429 in codes, f"codes={codes}")

    # Let the window expire, then try to dodge it by rotating the header.
    time.sleep(61)
    rotating = [login(victim_email, "Wrong-Password-1", xff=f"198.51.100.{i}")["status"]
                for i in range(1, 13)]
    record("X-Forwarded-For cannot reset the limiter", 429 in rotating,
           f"codes={rotating} (no 429 means the client IP is spoofable)")


if "--rate-limit-only" in sys.argv:
    run_rate_limit_checks()
    fails = [x for x in results if x[0] == "FAIL"]
    print(f"\n{len(results) - len(fails)} passed, {len(fails)} failed")
    sys.exit(len(fails))

# ---------------------------------------------------------------- headers
print("\n=== 1. Transport headers and information disclosure ===")
r = call("GET", "/health")
h = {k.lower(): v for k, v in r.headers.items()}
for name in ("x-content-type-options", "x-frame-options", "referrer-policy"):
    record(f"header {name}", name in h, f"{name}={h.get(name)}")
record("no Server banner", "server" not in h, f"server={h.get('server')}")
health = safe_json(r) or {}
leaks = [k for k in ("provider", "database", "error") if k in json.dumps(health.get("checks", {}))]
record("health does not expose internals", not leaks,
       f"checks={json.dumps(health.get('checks'))[:220]}")

# ---------------------------------------------------------------- auth basics
print("\n=== 2. Authentication behaviour ===")
email_a = f"probe-a-{rand()}@khata.local"
reg = register(email_a)
record("register returns 201", reg["status"] == 201, f"status={reg['status']}")

dup = register(email_a)
record("duplicate email is rejected", dup["status"] == 400, f"status={dup['status']}")
record("duplicate email does not enumerate", "already registered" not in dup["raw"].lower(),
       f"body={dup['raw'][:160]}")

weak = register(f"probe-w-{rand()}@khata.local", password="password1")
record("weak password rejected", weak["status"] == 400, f"status={weak['status']}")

bad = login(email_a, "Wrong-Password-1")
record("wrong password is 401", bad["status"] == 401, f"status={bad['status']}")

# token forgery: alg=none
good = login(email_a)
token_a = good["body"]["accessToken"]
header = base64.urlsafe_b64encode(json.dumps({"alg": "none", "typ": "JWT"}).encode()).decode().rstrip("=")
payload = token_a.split(".")[1]
forged_none = f"{header}.{payload}."
r = call("GET", "/api/auth/me", forged_none)
record("alg=none token rejected", r.status_code == 401, f"status={r.status_code}")

# tampered claim (bid escalation) with original signature
claims = decode_jwt(token_a)
claims["bid"] = "999"
tampered_payload = base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip("=")
tampered = f"{token_a.split('.')[0]}.{tampered_payload}.{token_a.split('.')[2]}"
r = call("GET", "/api/customers", tampered)
record("tampered bid claim rejected", r.status_code == 401, f"status={r.status_code}")

# ---------------------------------------------------------------- tenant isolation
print("\n=== 3. Tenant isolation (IDOR) ===")
tenant_a = new_tenant("a")
tenant_b = new_tenant("b")

r = call("POST", "/api/customers", tenant_a["token"], json={"name": "Alice Customer"})
customer = safe_json(r) or {}
customer_id = customer.get("id")
record("owner can create a customer", r.status_code == 201, f"status={r.status_code} id={customer_id}")

for method, path, kwargs in [
    ("GET", f"/api/customers/{customer_id}", {}),
    ("PUT", f"/api/customers/{customer_id}", {"json": {"name": "Hijacked"}}),
    ("DELETE", f"/api/customers/{customer_id}", {}),
    ("GET", f"/api/customers/{customer_id}/ledger", {}),
]:
    r = call(method, path, tenant_b["token"], **kwargs)
    record(f"cross-tenant {method} customer blocked", r.status_code in (403, 404),
           f"status={r.status_code} body={r.text[:120]}")

r = call("GET", f"/api/businesses/{tenant_a['businessId']}", tenant_b["token"])
record("cross-tenant business read blocked", r.status_code in (403, 404), f"status={r.status_code}")

r = call("POST", f"/api/businesses/{tenant_a['businessId']}/switch", tenant_b["token"])
record("cross-tenant business switch blocked", r.status_code in (403, 404), f"status={r.status_code}")

r = call("GET", "/api/customers?page=1&pageSize=1000", tenant_b["token"])
data = safe_json(r) or {}
record("pagination is clamped", len(data.get("data", [])) <= 100,
       f"pageSize=1000 returned {len(data.get('data', []))} rows")

# ---------------------------------------------------------------- privilege escalation
print("\n=== 4. Privilege escalation ===")
viewer_email = f"probe-viewer-{rand()}@khata.local"
register(viewer_email)
r = call("POST", f"/api/businesses/{tenant_a['businessId']}/members", tenant_a["token"],
         json={"email": viewer_email, "role": "Viewer"})
record("owner can invite a Viewer", r.status_code == 201, f"status={r.status_code} {r.text[:100]}")

viewer = login(viewer_email)
viewer_token = viewer["body"]["accessToken"]
r = call("POST", "/api/customers", viewer_token, json={"name": "Viewer Created"})
record("Viewer cannot create via REST", r.status_code == 403, f"status={r.status_code}")

r = call("POST", "/api/sync/push", viewer_token, json={"operations": [{
    "operationId": f"probe-{rand(12)}",
    "entityType": "customer",
    "operation": "create",
    "entityId": 0,
    "payload": {"name": "Viewer Created Via Sync"},
}]})
push = safe_json(r) or {}
statuses = [o.get("status") for o in push.get("operations", [])]
record("Viewer cannot write through sync push", "applied" not in statuses,
       f"http={r.status_code} operationStatuses={statuses}")

# A SalesStaff holds sync.use but not product/expense rights. Push multiplexes
# every entity behind one endpoint, so the entity permission has to be checked
# there too or the role boundary is bypassed by choosing a different URL.
staff_email = f"probe-staff-{rand()}@khata.local"
register(staff_email)
call("POST", f"/api/businesses/{tenant_a['businessId']}/members", tenant_a["token"],
     json={"email": staff_email, "role": "SalesStaff"})
staff_token = login(staff_email)["body"]["accessToken"]
r = call("POST", "/api/sync/push", staff_token, json={"operations": [
    {
        "operationId": f"probe-{rand(12)}",
        "entityType": "product",
        "operation": "delete",
        "entityId": 1,
        "payload": None,
    },
    {
        "operationId": f"probe-{rand(12)}",
        "entityType": "expense",
        "operation": "create",
        "entityId": 0,
        "payload": {"category": "Rent", "amount": 100000, "expenseDate": "2026-10-20"},
    },
]})
push = safe_json(r) or {}
statuses = [o.get("status") for o in push.get("operations", [])]
record("sync push enforces the entity permission", "applied" not in statuses,
       f"http={r.status_code} operationStatuses={statuses} (SalesStaff must not edit products or expenses)")

# Admin -> Owner escalation
admin_email = f"probe-admin-{rand()}@khata.local"
register(admin_email)
r = call("POST", f"/api/businesses/{tenant_a['businessId']}/members", tenant_a["token"],
         json={"email": admin_email, "role": "Admin"})
admin_login = login(admin_email)
admin_token = admin_login["body"]["accessToken"]
r = call("GET", f"/api/businesses/{tenant_a['businessId']}/members", admin_token)
members = safe_json(r) or []
admin_member = next((m for m in members if m.get("email") == admin_email), None)
r = call("PUT", f"/api/businesses/{tenant_a['businessId']}/members/{admin_member['id']}",
         admin_token, json={"role": "Owner"})
record("Admin cannot promote to Owner", r.status_code == 403,
       f"status={r.status_code} body={r.text[:160]}")

# ---------------------------------------------------------------- session lifecycle
print("\n=== 5. Session lifecycle ===")
sess = new_tenant("sess")
r = call("POST", "/api/auth/logout", sess["token"], json={"refreshToken": sess["refresh"]})
record("logout returns 204", r.status_code == 204, f"status={r.status_code}")
r = call("POST", "/api/auth/refresh", json={"refreshToken": sess["refresh"]})
record("refresh token dead after logout", r.status_code == 401, f"status={r.status_code}")

sess2 = new_tenant("sess2")
r = call("POST", "/api/auth/change-password", sess2["token"], json={
    "currentPassword": sess2["password"], "newPassword": "Probe9-Pass-9y"})
record("password change succeeds", r.status_code == 204, f"status={r.status_code}")
r = call("POST", "/api/auth/refresh", json={"refreshToken": sess2["refresh"]})
record("refresh token revoked by password change", r.status_code == 401,
       f"status={r.status_code} (200 means a stolen session survives the password change)")

# suspended user
admin = login("admin@khata.local", "Admin@12345")
admin_token = (admin.get("body") or {}).get("accessToken")
if admin_token:
    victim = new_tenant("victim")
    r = call("POST", f"/api/admin/users/{victim['userId']}/suspend", admin_token,
             json={"reason": "probe"})
    record("admin can suspend a user", r.status_code == 200, f"status={r.status_code}")
    r = call("POST", "/api/auth/refresh", json={"refreshToken": victim["refresh"]})
    record("suspended user cannot refresh", r.status_code == 401,
           f"status={r.status_code} (200 means suspension is bypassable for 30 days)")
    r = call("GET", "/api/auth/me", victim["token"])
    record("suspended user's access token is rejected", r.status_code == 401,
           f"status={r.status_code} (expected: 401)")

    # Suspending a business must actually stop its tenant, not just hide it in
    # the admin list.
    r = call("POST", f"/api/admin/businesses/{tenant_b['businessId']}/suspend", admin_token,
             json={"reason": "probe"})
    record("admin can suspend a business", r.status_code == 200, f"status={r.status_code}")
    r = call("GET", "/api/customers", tenant_b["token"])
    record("suspended business is refused", r.status_code == 403,
           f"status={r.status_code} body={r.text[:120]}")
    call("POST", f"/api/admin/businesses/{tenant_b['businessId']}/activate", admin_token,
         json={"reason": "probe cleanup"})
else:
    record("admin bootstrap account available", False, "admin login failed")

# ---------------------------------------------------------------- statement links
print("\n=== 6. Public statement links ===")
r = call("POST", f"/api/customers/{customer_id}/statement-link?ttlDays=999999999",
         tenant_a["token"])
minted = safe_json(r) or {}
expires = minted.get("expiresAt", "")
record("absurd statement TTL is bounded, not a 500",
       r.status_code != 500 and (r.status_code != 200 or "9999" not in expires),
       f"status={r.status_code} expiresAt={expires}")

r = call("POST", f"/api/customers/{customer_id}/statement-link?ttlDays=7", tenant_a["token"])
link = (safe_json(r) or {}).get("url", "")
record("statement link minted", bool(link), f"url={link[:90]}")
if link:
    path = link.split(BASE)[-1] if BASE in link else "/s/" + link.rsplit("/s/", 1)[-1]
    r = call("GET", path)
    record("statement renders", r.status_code == 200, f"status={r.status_code}")
    body = r.text
    record("statement escapes HTML", "<script>" not in body.lower() or "&lt;script" in body,
           "no raw script tag in output")
    r = call("GET", path + "x")
    record("tampered statement token rejected", r.status_code == 401, f"status={r.status_code}")

# ---------------------------------------------------------------- business selection
print("\n=== 7. Active business selection ===")
multi = new_tenant("multi")
r = call("POST", "/api/businesses", multi["token"], json={"name": "Second Shop", "type": "Retail"})
second = safe_json(r) or {}
call("POST", f"/api/businesses/{second['id']}/switch", multi["token"])
relogin = login(multi["email"], multi["password"])
claims = decode_jwt(relogin["body"]["accessToken"])
record("login honours the selected active business", str(second["id"]) == claims.get("bid"),
       f"selected={second['id']} token bid={claims.get('bid')}")

# ---------------------------------------------------------------- locale
print("\n=== 8. Locale handling ===")
r = register(f"probe-hi-{rand()}@khata.local", locale="hi")
record("Hindi locale accepted", r["status"] == 201, f"status={r['status']} body={r['raw'][:160]}")

# ---------------------------------------------------------------- rate limiting
# Run separately: the checks above need more than 10 auth calls per minute, so
# they are executed against a deployment with raised limits (or via
# --rate-limit-only against the shipped defaults).

# ---------------------------------------------------------------- input handling
print("\n=== 10. Input handling ===")
r = call("GET", "/api/customers?search=%27%20OR%201%3D1--", tenant_a["token"])
record("SQL metacharacters in search are harmless", r.status_code == 200, f"status={r.status_code}")

r = call("POST", "/api/customers", tenant_a["token"], json={"name": "<script>alert(1)</script>"})
record("XSS payload stored as data (not executed server-side)", r.status_code == 201,
       f"status={r.status_code}")

r = call("POST", "/api/import/products", tenant_a["token"], json={"csv": "name\n" + "x" * 3_000_000})
record("oversized import rejected with 4xx", 400 <= r.status_code < 500,
       f"status={r.status_code} body={r.text[:120]}")

r = call("POST", "/api/auth/login", json={"email": "not-an-email", "password": "x"})
record("malformed login is 400", r.status_code == 400, f"status={r.status_code}")

# ---------------------------------------------------------------- summary
print("\n" + "=" * 72)
fails = [x for x in results if x[0] == "FAIL"]
print(f"{len(results) - len(fails)} passed, {len(fails)} failed")
for _, control, detail in fails:
    print(f"  FAIL  {control} :: {detail[:140]}")
print("=" * 72)
sys.exit(len(fails))
