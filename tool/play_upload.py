#!/usr/bin/env python3
"""Upload a signed .aab to a Google Play testing track as a DRAFT release.

Run by the Android build workflow after the signed bundle is built. The
service account key is read from the PLAY_SERVICE_ACCOUNT_JSON environment
variable (a repo secret) and is never printed or written to disk.

Nothing this script does reaches testers or users: the release is always
created with status "draft", so it sits in Play Console until someone opens
it there and rolls it out by hand.

Usage:
  python3 tool/play_upload.py --package com.example.app \
      --aab path/to/app-release.aab --listing store/app/listing.md

Needs: pip install google-auth requests
"""

import argparse
import json
import os
import re
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

SCOPE = "https://www.googleapis.com/auth/androidpublisher"
# Overridable only so the end-to-end test can point at a local fake server.
API_BASE = os.environ.get("PLAY_API_BASE", "https://androidpublisher.googleapis.com")
RELEASE_STATUS = "draft"  # deliberately not configurable
NOTES_LIMIT = 500  # Play's limit for release notes per language


class PlayError(Exception):
    pass


def whats_new(listing_path):
    """The text block under '## What's new' in the store listing."""
    with open(listing_path, encoding="utf-8") as f:
        text = f.read()
    m = re.search(r"^## What's new\s*\n+```text\n(.*?)\n```", text, re.S | re.M)
    if not m:
        raise PlayError(f"No \"## What's new\" text block in {listing_path}")
    notes = m.group(1).strip()
    if len(notes) > NOTES_LIMIT:
        raise PlayError(f"Release notes are {len(notes)} characters; Play allows {NOTES_LIMIT}.")
    return notes


def credentials_from_env():
    raw = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", "")
    if not raw.strip():
        raise PlayError("PLAY_SERVICE_ACCOUNT_JSON is empty.")
    try:
        info = json.loads(raw)
    except json.JSONDecodeError:
        # Never echo the value: it is a private key.
        raise PlayError("PLAY_SERVICE_ACCOUNT_JSON is not valid JSON. "
                        "Set it from the downloaded key file, unchanged.") from None
    if info.get("type") != "service_account":
        raise PlayError("PLAY_SERVICE_ACCOUNT_JSON is not a service account key "
                        "(its \"type\" is not \"service_account\").")
    creds = service_account.Credentials.from_service_account_info(info, scopes=[SCOPE])
    try:
        creds.refresh(Request())
    except Exception as e:  # google.auth raises several types here
        raise PlayError(f"Google refused the service account key: {type(e).__name__}. "
                        "The key may have been deleted or the account disabled.") from None
    print(f"Signed in as service account {info.get('client_email', '?')}")
    return creds


class Play:
    def __init__(self, creds, package):
        self.package = package
        self.s = requests.Session()
        self.s.headers["Authorization"] = f"Bearer {creds.token}"
        self.app = f"{API_BASE}/androidpublisher/v3/applications/{package}"

    def call(self, method, url, what, **kw):
        r = self.s.request(method, url, timeout=kw.pop("timeout", 60), **kw)
        if r.status_code >= 400:
            raise PlayError(explain(r, what, self.package))
        return r.json() if r.content else {}

    def upload(self, aab, notes, track):
        edit = self.call("POST", f"{self.app}/edits", "open an edit")["id"]
        try:
            with open(aab, "rb") as f:
                bundle = self.call(
                    "POST",
                    f"{API_BASE}/upload/androidpublisher/v3/applications/{self.package}"
                    f"/edits/{edit}/bundles?uploadType=media",
                    "upload the bundle",
                    data=f,
                    headers={"Content-Type": "application/octet-stream"},
                    timeout=900,
                )
            code = str(bundle["versionCode"])
            print(f"Uploaded bundle, version code {code}")

            current = self.call("GET", f"{self.app}/edits/{edit}/tracks/{track}", "read the track")
            # Keep whatever is live or halted on the track; replace older drafts
            # with this one so the track holds one draft, the newest.
            kept = [rel for rel in current.get("releases", []) if rel.get("status") != "draft"]
            release = {
                "name": code,
                "versionCodes": [code],
                "status": RELEASE_STATUS,
                "releaseNotes": [{"language": "en-US", "text": notes}],
            }
            self.call("PUT", f"{self.app}/edits/{edit}/tracks/{track}", "set the track",
                      json={"track": track, "releases": kept + [release]})
            self.commit(edit)
        except Exception:
            # An edit left open blocks nothing, but tidy up so Play shows no stray edit.
            try:
                self.s.delete(f"{self.app}/edits/{edit}", timeout=30)
            except requests.RequestException:
                pass
            raise
        print(f"Draft release {code} is on the '{track}' track. "
              "Nothing is rolled out: open it in Play Console to review and roll it out.")
        return code

    def commit(self, edit):
        r = self.s.post(f"{self.app}/edits/{edit}:commit", timeout=60)
        if r.status_code >= 400 and "changesNotSentForReview" in r.text:
            # Play asks for this flag when it cannot send changes for review on its
            # own. Setting it keeps the change out of review, which is what we want.
            r = self.s.post(f"{self.app}/edits/{edit}:commit?changesNotSentForReview=true",
                            timeout=60)
        if r.status_code >= 400:
            raise PlayError(explain(r, "commit the edit", self.package))


def explain(r, what, package):
    try:
        msg = r.json().get("error", {}).get("message", "")
    except ValueError:
        msg = ""
    msg = msg or r.text[:300]
    hint = ""
    if r.status_code == 404 or "Package not found" in msg:
        hint = (f" Play doesn't know {package} yet through the API. For a new app the "
                "first bundle has to be uploaded by hand in Play Console; after that "
                "this upload works.")
    elif r.status_code in (401, 403):
        hint = (" The service account lacks permission for this app. In Play Console, "
                "Users and permissions, give it release rights for this app.")
    elif "version code" in msg.lower() and "already been used" in msg.lower():
        hint = " That version code is already in Play. Re-run the workflow to get a new one."
    return f"Couldn't {what} (HTTP {r.status_code}): {msg}{hint}"


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--package", required=True)
    p.add_argument("--aab", required=True)
    p.add_argument("--listing", required=True, help="store listing.md with a What's new block")
    p.add_argument("--track", default="alpha", help="Play track id; 'alpha' is Closed testing - Alpha")
    a = p.parse_args(argv)
    try:
        if not os.path.isfile(a.aab):
            raise PlayError(f"No bundle at {a.aab}")
        notes = whats_new(a.listing)
        creds = credentials_from_env()
        Play(creds, a.package).upload(a.aab, notes, a.track)
    except PlayError as e:
        print(f"::error::{e}" if os.environ.get("GITHUB_ACTIONS") else f"error: {e}",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
