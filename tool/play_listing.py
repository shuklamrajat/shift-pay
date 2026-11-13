#!/usr/bin/env python3
"""Put the store art in a Play listing as a change that is NOT sent for review.

Replaces the en-US phone screenshots with store/<app>/listing-screenshots/*.png
(in name order) and the feature graphic with store/<app>/feature-graphic.png,
then commits the edit with changesNotSentForReview=true, always. The change
waits in Play Console's Publishing overview until someone sends it for review
there by hand.

The service account key comes from PLAY_SERVICE_ACCOUNT_JSON (a repo secret)
and is never printed or written to disk.

Usage: python3 tool/play_listing.py --package com.example.app --store store/app
"""
import argparse
import glob
import os
import sys

import requests

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from play_upload import API_BASE, PlayError, credentials_from_env, explain  # noqa: E402

LANG = "en-US"


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--package", required=True)
    p.add_argument("--store", required=True)
    a = p.parse_args(argv)
    shots = sorted(glob.glob(os.path.join(a.store, "listing-screenshots", "*.png")))
    graphic = os.path.join(a.store, "feature-graphic.png")
    try:
        if not 2 <= len(shots) <= 8:
            raise PlayError(f"Play takes 2 to 8 phone screenshots; found {len(shots)} in {a.store}")
        if not os.path.isfile(graphic):
            raise PlayError(f"No feature graphic at {graphic}")
        creds = credentials_from_env()
        s = requests.Session()
        s.headers["Authorization"] = f"Bearer {creds.token}"
        app = f"{API_BASE}/androidpublisher/v3/applications/{a.package}"
        up = f"{API_BASE}/upload/androidpublisher/v3/applications/{a.package}"

        def call(method, url, what, **kw):
            r = s.request(method, url, timeout=kw.pop("timeout", 120), **kw)
            if r.status_code >= 400:
                raise PlayError(explain(r, what, a.package))
            return r.json() if r.content else {}

        edit = call("POST", f"{app}/edits", "open an edit")["id"]
        try:
            for kind, files in (("phoneScreenshots", shots), ("featureGraphic", [graphic])):
                call("DELETE", f"{app}/edits/{edit}/listings/{LANG}/{kind}", f"clear the old {kind}")
                for f in files:
                    with open(f, "rb") as fh:
                        call("POST", f"{up}/edits/{edit}/listings/{LANG}/{kind}?uploadType=media",
                             f"upload {os.path.basename(f)} as {kind}", data=fh,
                             headers={"Content-Type": "image/png"})
                    print(f"{kind}: {os.path.basename(f)}")
            # Always kept out of review: Rajat sends changes for review himself.
            call("POST", f"{app}/edits/{edit}:commit?changesNotSentForReview=true", "save the edit")
        except Exception:
            try:
                s.delete(f"{app}/edits/{edit}", timeout=30)
            except requests.RequestException:
                pass
            raise
        print(f"Saved {len(shots)} screenshots and the feature graphic to the {LANG} listing. "
              "Not sent for review.")
    except PlayError as e:
        print(f"::error::{e}" if os.environ.get("GITHUB_ACTIONS") else f"error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
