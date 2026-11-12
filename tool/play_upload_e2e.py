#!/usr/bin/env python3
"""End-to-end check of tool/play_upload.py against a local fake of Google Play.

The fake implements the parts of Google's OAuth token endpoint and the Play
Developer API (androidpublisher v3) that the upload uses, keeps state across
calls like Play does, and verifies the signed JWT the script sends. A throwaway
RSA key is generated per run, so no real key is involved.

Ways the upload can go wrong, each covered below:
  1. Key secret is not JSON, or not a service account key.
  2. Key was revoked: the token endpoint refuses it.
  3. App never had a bundle uploaded by hand, so Play answers 404.
  4. Service account was not given release rights: 403.
  5. Bundle upload dies part way: the open edit must be deleted.
  6. Track already has a release testers use plus an older draft: the live
     release must survive and the old draft be replaced, never rolled out.
  7. Play refuses to commit unless changesNotSentForReview=true.
  8. Release notes missing or over Play's 500 character limit.
  9. The private key must never appear in the script's output.

Writes a reproducible record of every request and outcome to
tool/test-output/play_upload_e2e.json.

Run: python3 tool/play_upload_e2e.py --listing store/<app>/listing.md --package <id>
"""

import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

HERE = os.path.dirname(os.path.abspath(__file__))


class FakePlay:
    def __init__(self, package):
        self.package = package
        self.known = False  # becomes True once a bundle is "uploaded by hand"
        self.allowed = True
        self.revoked = False
        self.fail_upload = False
        self.require_not_sent_flag = False
        self.next_code = 1
        self.tracks = {}  # committed state: track -> releases
        self.edits = {}  # edit id -> {"tracks": {...}, "bundles": []}
        self.log = []
        self.public_key = None
        self.sent_for_review = False

    def handle(self, h, method):
        url = urlparse(h.path)
        q = parse_qs(url.query)
        length = int(h.headers.get("Content-Length") or 0)
        body = h.rfile.read(length) if length else b""
        entry = {"method": method, "path": url.path, "query": url.query}
        status, out = self.route(h, method, url.path, q, body, entry)
        entry["status"] = status
        self.log.append(entry)
        data = json.dumps(out).encode()
        h.send_response(status)
        h.send_header("Content-Type", "application/json")
        h.send_header("Content-Length", str(len(data)))
        h.end_headers()
        h.wfile.write(data)

    def route(self, h, method, path, q, body, entry):
        if path == "/token":
            assertion = parse_qs(body.decode())["assertion"][0]
            head, claims, sig = assertion.split(".")
            pad = lambda s: base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))
            self.public_key.verify(pad(sig), f"{head}.{claims}".encode(),
                                   padding.PKCS1v15(), hashes.SHA256())
            entry["scope"] = json.loads(pad(claims))["scope"]
            if self.revoked:
                return 400, {"error": "invalid_grant", "error_description": "Invalid JWT Signature."}
            return 200, {"access_token": "fake-token", "expires_in": 3600, "token_type": "Bearer"}

        if h.headers.get("Authorization") != "Bearer fake-token":
            return 401, {"error": {"message": "Request had invalid authentication credentials."}}
        prefix = f"/androidpublisher/v3/applications/{self.package}"
        upload_prefix = f"/upload{prefix}"
        if not (path.startswith(prefix) or path.startswith(upload_prefix)):
            return 404, {"error": {"message": "Package not found: " + path.split("/")[4]}}
        if not self.known:
            return 404, {"error": {"message": f"Package not found: {self.package}."}}
        if not self.allowed:
            return 403, {"error": {"message": "The caller does not have permission"}}

        if method == "POST" and path == f"{prefix}/edits":
            eid = f"edit{len(self.edits) + 1}"
            self.edits[eid] = {"tracks": json.loads(json.dumps(self.tracks)), "bundles": []}
            return 200, {"id": eid}
        parts = path.split("/")
        if method == "POST" and path.startswith(upload_prefix) and path.endswith("/bundles"):
            eid = parts[-2]
            entry["bytes"] = len(body)
            entry["content_type"] = h.headers.get("Content-Type")
            if self.fail_upload:
                return 503, {"error": {"message": "Backend Error"}}
            code = self.next_code
            self.next_code += 1
            self.edits[eid]["bundles"].append(code)
            return 200, {"versionCode": code, "sha256": "x"}
        if "/tracks/" in path:
            eid, track = parts[-3], parts[-1]
            edit = self.edits[eid]
            if method == "GET":
                return 200, {"track": track, "releases": edit["tracks"].get(track, [])}
            if method == "PUT":
                payload = json.loads(body)
                entry["body"] = payload
                edit["tracks"][track] = payload["releases"]
                return 200, payload
        if method == "POST" and path.endswith(":commit"):
            eid = parts[-1].split(":")[0]
            flag = q.get("changesNotSentForReview") == ["true"]
            if self.require_not_sent_flag and not flag:
                return 400, {"error": {"message": "Changes cannot be sent for review automatically. "
                                                  "Please set the query parameter changesNotSentForReview to true."}}
            self.tracks = self.edits.pop(eid)["tracks"]
            if not flag and any(r["status"] != "draft" for rs in self.tracks.values() for r in rs):
                self.sent_for_review = True
            return 200, {"id": eid}
        if method == "DELETE" and "/edits/" in path:
            self.edits.pop(parts[-1], None)
            return 204, {}
        return 404, {"error": {"message": f"unhandled {method} {path}"}}


def make_handler(fake):
    class H(BaseHTTPRequestHandler):
        def do_GET(self): fake.handle(self, "GET")
        def do_POST(self): fake.handle(self, "POST")
        def do_PUT(self): fake.handle(self, "PUT")
        def do_DELETE(self): fake.handle(self, "DELETE")
        def log_message(self, *a): pass
    return H


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--listing", required=True)
    ap.add_argument("--package", required=True)
    a = ap.parse_args()

    fake = FakePlay(a.package)
    server = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(fake))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{server.server_port}"

    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    fake.public_key = key.public_key()
    pem = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                            serialization.NoEncryption()).decode()
    sa = json.dumps({
        "type": "service_account", "project_id": "test", "private_key_id": "k1",
        "private_key": pem, "client_email": "uploader@test.iam.gserviceaccount.com",
        "client_id": "1", "token_uri": f"{base}/token",
    })
    pem_marker = pem.splitlines()[1][:40]

    tmp = tempfile.mkdtemp()
    aab = os.path.join(tmp, "app-release.aab")
    with open(aab, "wb") as f:
        f.write(os.urandom(3 * 1024 * 1024))
    long_listing = os.path.join(tmp, "long.md")
    with open(long_listing, "w") as f:
        f.write("## What's new\n\n```text\n" + "x" * 501 + "\n```\n")

    results, failures = [], []

    def run(name, secret=sa, listing=a.listing, expect_ok=True, expect_text=None):
        env = dict(os.environ, PLAY_API_BASE=base, PLAY_SERVICE_ACCOUNT_JSON=secret)
        env.pop("GITHUB_ACTIONS", None)
        start = len(fake.log)
        p = subprocess.run([sys.executable, os.path.join(HERE, "play_upload.py"),
                            "--package", a.package, "--aab", aab, "--listing", listing],
                           env=env, capture_output=True, text=True, timeout=120)
        out = p.stdout + p.stderr
        ok = p.returncode == 0
        problems = []
        if ok != expect_ok:
            problems.append(f"exit {p.returncode}, expected {'0' if expect_ok else 'non-zero'}")
        if expect_text and expect_text not in out:
            problems.append(f"output lacks {expect_text!r}")
        if pem_marker in out or "PRIVATE KEY" in out:
            problems.append("private key appeared in output")
        results.append({"scenario": name, "exit": p.returncode, "output": out.strip(),
                        "requests": fake.log[start:], "problems": problems})
        failures.extend(f"{name}: {x}" for x in problems)
        return out

    # The realistic sequence: Play doesn't know the app yet, then the first
    # bundle is uploaded by hand, then CI takes over on every push.
    run("before the first manual upload", expect_ok=False,
        expect_text="first bundle has to be uploaded by hand")
    if fake.edits:
        failures.append("an edit was left open after the 404")

    fake.known = True  # Rajat uploads build 1 by hand in Play Console
    fake.next_code = 2
    fake.tracks = {"alpha": [{"name": "1", "versionCodes": ["1"], "status": "draft"}]}

    fake.allowed = False
    run("service account without release rights", expect_ok=False, expect_text="release rights")
    fake.allowed = True

    run("first automatic upload", expect_text="Draft release 2")
    alpha = fake.tracks.get("alpha", [])
    if [r["versionCodes"] for r in alpha] != [["2"]] or alpha[0]["status"] != "draft":
        failures.append(f"first automatic upload: alpha track is {alpha}, want one draft of 2")
    notes = alpha[0].get("releaseNotes", [{}])[0].get("text", "") if alpha else ""
    if not notes.startswith("First release"):
        failures.append(f"release notes not taken from listing: {notes[:60]!r}")
    up = [e for e in fake.log if e["path"].endswith("/bundles")][-1]
    if up["bytes"] != 3 * 1024 * 1024 or up["content_type"] != "application/octet-stream":
        failures.append(f"bundle upload sent {up['bytes']} bytes as {up['content_type']}")

    # Rajat rolls build 2 out to testers by hand; a later push must not touch it.
    fake.tracks["alpha"][0]["status"] = "completed"
    fake.tracks["alpha"].append({"name": "old", "versionCodes": ["1"], "status": "draft"})
    fake.require_not_sent_flag = True
    run("upload while testers have a live build", expect_text="Draft release 3")
    alpha = fake.tracks["alpha"]
    by_status = {r["status"]: r["versionCodes"] for r in alpha}
    if by_status != {"completed": ["2"], "draft": ["3"]} or len(alpha) != 2:
        failures.append(f"live build not kept or old draft not replaced: {alpha}")
    commits = [e for e in fake.log if e["path"].endswith(":commit")][-2:]
    if [e["status"] for e in commits] != [400, 200] or "changesNotSentForReview=true" not in commits[-1]["query"]:
        failures.append(f"commit retry with changesNotSentForReview didn't happen: {commits}")
    if fake.sent_for_review:
        failures.append("a change was sent for review")
    fake.require_not_sent_flag = False

    fake.fail_upload = True
    run("bundle upload fails part way", expect_ok=False, expect_text="upload the bundle")
    if fake.edits:
        failures.append(f"edit left open after failed upload: {list(fake.edits)}")
    fake.fail_upload = False

    fake.revoked = True
    run("revoked key", expect_ok=False, expect_text="refused the service account key")
    fake.revoked = False

    run("secret pasted wrong", secret=pem, expect_ok=False, expect_text="not valid JSON")
    run("wrong kind of key", secret=json.dumps({"type": "authorized_user"}),
        expect_ok=False, expect_text="not a service account key")
    run("release notes too long", listing=long_listing, expect_ok=False, expect_text="Play allows 500")

    statuses = {r.get("status") for e in fake.log if e.get("body") for r in e["body"]["releases"]
                if r["versionCodes"] != ["2"]}
    if statuses - {"draft"}:
        failures.append(f"script sent release status {statuses}")
    scopes = {e["scope"] for e in fake.log if "scope" in e}
    if scopes != {"https://www.googleapis.com/auth/androidpublisher"}:
        failures.append(f"unexpected OAuth scope {scopes}")

    server.shutdown()
    outdir = os.path.join(HERE, "test-output")
    os.makedirs(outdir, exist_ok=True)
    record = os.path.join(outdir, "play_upload_e2e.json")
    with open(record, "w") as f:
        json.dump({"package": a.package, "scenarios": results, "final_tracks": fake.tracks,
                   "failures": failures}, f, indent=2)
    for r in results:
        print(f"{'FAIL' if r['problems'] else 'ok  '} {r['scenario']}")
    for x in failures:
        print("FAIL", x)
    print(f"{len(results)} scenarios, {len(failures)} failures. Record: {record}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
