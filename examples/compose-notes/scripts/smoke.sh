#!/usr/bin/env bash
# Run from any directory. Uses Python inside the running API container.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
docker compose exec -T api python - <<'PY'
import json
import os
import urllib.error
import urllib.request

BASE = "http://web/api"
passed = 0

def request(method, path, expected, payload=None):
    global passed
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            status, raw = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, raw = error.code, error.read()
    assert status == expected, f"{method} {path}: {status}, expected {expected}"
    result = json.loads(raw) if raw else None
    passed += 1
    print(f"PASS {method} {path}: HTTP {status}")
    return result

health = request("GET", "/health", 200)
assert health["database"] == "postgres"
runtime = request("GET", "/runtime", 200)
assert os.getuid() == 10001 and runtime["storage"] == "postgres"
request("GET", "/notes", 200)
created_id = None
try:
    created = request("POST", "/notes", 201,
                      {"title": "Temporary smoke test", "content": "Dummy classroom data"})
    created_id = created["id"]
    fetched = request("GET", f"/notes/{created_id}", 200)
    assert fetched["title"] == "Temporary smoke test"
    request("POST", "/notes", 422, {"title": "", "content": "invalid"})
    request("GET", "/notes/999999999", 404)
finally:
    if created_id is not None:
        request("DELETE", f"/notes/{created_id}", 204)
        request("GET", f"/notes/{created_id}", 404)
print(f"{passed}/{passed} HTTP checks PASS through web -> api -> PostgreSQL")
print("Only the temporary note created by this script was removed.")
PY
