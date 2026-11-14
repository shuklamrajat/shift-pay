#!/usr/bin/env python3
"""Send one closed-test draft and the new listing art to Google review.

Run only on Rajat's yes. In one Play edit it:
  1. replaces the en-US phone screenshots and feature graphic with
     store/<app>/listing-screenshots/*.png and store/<app>/feature-graphic.png;
  2. finds the draft release on the alpha track that holds exactly
     --version-code and makes it the track's completed release (older
     drafts and the previous completed release on that track are dropped);
  3. validates the edit, then commits it. These apps have managed
     publishing off, so the commit sends everything to Google review.

It refuses, and saves nothing, if the alpha track has no draft with exactly
that version code. The key comes from PLAY_SERVICE_ACCOUNT_JSON and is never
printed or written to disk.

Usage: python3 tool/play_submit.py --package P --store store/app --version-code N
"""
import argparse
import glob
import json
import os
import sys

import requests

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from play_upload import API_BASE, PlayError, credentials_from_env, explain  # noqa: E402

LANG = "en-US"
TRACK = "alpha"


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--package", required=True)
    p.add_argument("--store", required=True)
    p.add_argument("--version-code", required=True)
    p.add_argument("--listing-only", action="store_true",
                   help="send only the listing art; leave the alpha track as it is")
    p.add_argument("--dry-run", action="store_true",
                   help="do everything up to validate, then delete the edit: nothing is saved or sent")
    a = p.parse_args(argv)
    vc = str(int(a.version_code))
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
            if a.listing_only:
                print("Listing only: the alpha track is left as it is")
            else:
                track = call("GET", f"{app}/edits/{edit}/tracks/{TRACK}", f"read the {TRACK} track")
                print("Track before:", json.dumps([{k: r.get(k) for k in ("name", "status", "versionCodes")}
                                                   for r in track.get("releases", [])]))
                target = [r for r in track.get("releases", [])
                          if r.get("status") == "draft" and r.get("versionCodes") == [vc]]
                if len(target) != 1:
                    raise PlayError(f"Expected one draft with version code {vc} on {TRACK}; found {len(target)}. Nothing saved.")
                rel = dict(target[0])
                rel["status"] = "completed"
                rel.pop("userFraction", None)
                call("PUT", f"{app}/edits/{edit}/tracks/{TRACK}", f"set release {vc} on {TRACK}",
                     json={"track": TRACK, "releases": [rel]})
                print(f"Release {rel.get('name')} ({vc}) set to completed on {TRACK}")
            for kind, files in (("phoneScreenshots", shots), ("featureGraphic", [graphic])):
                call("DELETE", f"{app}/edits/{edit}/listings/{LANG}/{kind}", f"clear the old {kind}")
                for f in files:
                    with open(f, "rb") as fh:
                        call("POST", f"{up}/edits/{edit}/listings/{LANG}/{kind}?uploadType=media",
                             f"upload {os.path.basename(f)} as {kind}", data=fh,
                             headers={"Content-Type": "image/png"})
                    print(f"{kind}: {os.path.basename(f)}")
            call("POST", f"{app}/edits/{edit}:validate", "validate the edit")
            print("Edit validated")
            if a.dry_run:
                call("DELETE", f"{app}/edits/{edit}", "delete the dry-run edit")
                print("Dry run: edit deleted. Nothing saved, nothing sent to Google.")
                return 0
            call("POST", f"{app}/edits/{edit}:commit", "commit the edit")
        except Exception:
            try:
                s.delete(f"{app}/edits/{edit}", timeout=30)
            except requests.RequestException:
                pass
            raise
        print(f"Committed: release {vc} on {TRACK} plus {len(shots)} screenshots and the feature graphic. "
              "Sent to Google review.")
    except PlayError as e:
        print(f"::error::{e}" if os.environ.get("GITHUB_ACTIONS") else f"error: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
