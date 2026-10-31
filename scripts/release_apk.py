#!/usr/bin/env python3
"""Cut a versioned APK release: bump, build, tag, publish.

The app checks GitHub's *latest release* for updates, so publishing a release
is the entire act of shipping a version. This script does the four things that
have to happen in order, so a release is one command rather than a checklist:

    python scripts/release_apk.py --bump patch
    python scripts/release_apk.py --version 1.2.0
    python scripts/release_apk.py --bump patch --dry-run

Release notes come from `CHANGELOG.md` — the section for the version being cut
becomes the GitHub release body, so the two cannot drift apart. `--notes` is an
override for a one-off, not the normal path.

Why the GitHub REST API and not `gh`: the `gh` CLI is not installed here, and
adding it would mean a second login. The token comes from the git credential
store that `git push` already uses, so there is no secret in this file and
nothing new to authorise.

The APK is a release *asset*, never a committed file — a 60 MB binary in git
history is unrecoverable debt.
"""

from __future__ import annotations

import argparse
import datetime
import ipaddress
import json
import mimetypes
import pathlib
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOBILE = ROOT / "apps" / "mobile"
PUBSPEC = MOBILE / "pubspec.yaml"
CHANGELOG = ROOT / "CHANGELOG.md"
APK = MOBILE / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"

VERSION_RE = re.compile(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$", re.MULTILINE)

# `## [1.2.0] - 2026-10-31` or `## [Unreleased]`
CHANGELOG_HEADING_RE = re.compile(
    r"^## \[(?P<label>[^\]]+)\](?: - (?P<date>\d{4}-\d{2}-\d{2}))?[ \t]*$",
    re.MULTILINE,
)
CHANGELOG_LINK_RE = re.compile(r"^\[[^\]]+\]:\s*\S+[ \t]*$", re.MULTILINE)
HTML_COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)
UNRELEASED_LINK_RE = re.compile(r"^\[Unreleased\]:\s*(?P<base>\S+?)/compare/\S*[ \t]*$", re.MULTILINE)


def run(cmd: list[str], cwd: pathlib.Path = ROOT, check: bool = True) -> subprocess.CompletedProcess:
    print(f"  $ {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, text=True, capture_output=True)
    if check and result.returncode != 0:
        sys.stderr.write(result.stdout)
        sys.stderr.write(result.stderr)
        raise SystemExit(f"command failed ({result.returncode}): {' '.join(cmd)}")
    return result


def read_version() -> tuple[int, int, int, int]:
    match = VERSION_RE.search(PUBSPEC.read_text(encoding="utf-8"))
    if not match:
        raise SystemExit("could not read `version: X.Y.Z+N` from pubspec.yaml")
    return tuple(int(part) for part in match.groups())  # type: ignore[return-value]


def write_version(major: int, minor: int, patch: int, build: int) -> None:
    text = PUBSPEC.read_text(encoding="utf-8")
    text = VERSION_RE.sub(f"version: {major}.{minor}.{patch}+{build}", text, count=1)
    PUBSPEC.write_text(text, encoding="utf-8")


def bump(current: tuple[int, int, int, int], kind: str) -> tuple[int, int, int]:
    major, minor, patch, _ = current
    if kind == "major":
        return major + 1, 0, 0
    if kind == "minor":
        return major, minor + 1, 0
    if kind == "patch":
        return major, minor, patch + 1
    return major, minor, patch


def changelog_body(text: str, label: str) -> str | None:
    """Body under `## [label]`, or None. Link definitions are not part of it."""
    headings = list(CHANGELOG_HEADING_RE.finditer(text))
    for index, match in enumerate(headings):
        if match.group("label").strip().lower() != label.strip().lower():
            continue
        end = headings[index + 1].start() if index + 1 < len(headings) else len(text)
        body = HTML_COMMENT_RE.sub("", text[match.end():end])
        body = CHANGELOG_LINK_RE.sub("", body)
        return body.strip()
    return None


def promote_unreleased(text: str, version: str, today: str) -> str:
    """Turn `## [Unreleased]` into `## [version] - today`, leaving a fresh one."""
    promoted = re.sub(
        r"^## \[Unreleased\][ \t]*$",
        f"## [Unreleased]\n\n## [{version}] - {today}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    # Keep the compare links honest: Unreleased now diffs against the new tag.
    promoted = UNRELEASED_LINK_RE.sub(
        lambda m: (
            f"[Unreleased]: {m.group('base')}/compare/v{version}...HEAD\n"
            f"[{version}]: {m.group('base')}/releases/tag/v{version}"
        ),
        promoted,
        count=1,
    )
    return promoted


def release_notes(version: str, today: str) -> tuple[str, str | None]:
    """(release body, new CHANGELOG text or None when nothing needs rewriting).

    The changelog is the single source of truth for release notes, so the notes
    on GitHub cannot drift from the repository. An explicit `--notes` still wins
    for the published body, but the version heading is promoted either way.
    """
    if not CHANGELOG.exists():
        raise SystemExit(f"{CHANGELOG} is missing; it is the source of release notes")

    text = CHANGELOG.read_text(encoding="utf-8")
    existing = changelog_body(text, version)
    if existing:
        return existing, None

    unreleased = changelog_body(text, "Unreleased")
    if not unreleased:
        raise SystemExit(
            f"CHANGELOG.md has neither `## [{version}]` nor a non-empty "
            f"`## [Unreleased]` section — write the notes before releasing"
        )

    return unreleased, promote_unreleased(text, version, today)


def flutter_binary() -> str:
    found = shutil.which("flutter")
    if found:
        return found
    # This machine keeps Flutter outside PATH; the folder name lies about the
    # version (it is 3.41.6), but the binary is real.
    fallback = pathlib.Path("E:/Flutter window/flutter_windows_3.16.0-stable/flutter/bin/flutter.bat")
    if fallback.exists():
        return str(fallback)
    raise SystemExit("flutter not found on PATH and the fallback path is missing; pass --flutter")


def git_remote() -> tuple[str, str]:
    url = run(["git", "remote", "get-url", "origin"]).stdout.strip()
    match = re.search(r"github\.com[:/](?P<owner>[^/]+)/(?P<repo>[^/.]+)", url)
    if not match:
        raise SystemExit(f"could not parse owner/repo from remote: {url}")
    return match.group("owner"), match.group("repo")


def github_token() -> str:
    result = subprocess.run(
        ["git", "credential", "fill"],
        input="protocol=https\nhost=github.com\n\n",
        text=True,
        capture_output=True,
    )
    for line in result.stdout.splitlines():
        if line.startswith("password="):
            return line.split("=", 1)[1]
    raise SystemExit(
        "no GitHub credential in the store. Run `git push` once so the credential "
        "manager saves one, then retry."
    )


def api(method: str, url: str, token: str, payload: dict | None = None) -> dict:
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(url, data=data, method=method)
    request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Accept", "application/vnd.github+json")
    request.add_header("X-GitHub-Api-Version", "2022-11-28")
    if data is not None:
        request.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read() or b"{}")


def upload_asset(owner: str, repo: str, release_id: int, token: str, apk: pathlib.Path) -> dict:
    content_type = mimetypes.guess_type(apk.name)[0] or "application/vnd.android.package-archive"
    body = apk.read_bytes()
    request = urllib.request.Request(
        f"https://uploads.github.com/repos/{owner}/{repo}/releases/{release_id}/assets"
        f"?name={apk.name}",
        data=body,
        method="POST",
    )
    request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Accept", "application/vnd.github+json")
    request.add_header("Content-Type", content_type)
    request.add_header("Content-Length", str(len(body)))
    with urllib.request.urlopen(request, timeout=600) as response:
        return json.loads(response.read())


def require_public_api_base(value: str | None) -> str:
    """Refuse to publish an APK that cannot reach a server.

    `AppConfig.apiBaseUrl` falls back to `http://localhost:5000` when no
    `--dart-define` is supplied. Such an APK installs cleanly, shows the login
    screen, and then fails every request — on the user's phone, after the
    release is already public. Both checks below catch a mistake that a build
    log will not.
    """
    if not value:
        raise SystemExit(
            "--api-base is required. The APK's default API URL is http://localhost:5000, "
            "which a phone resolves to itself, so the build would install and then be "
            "unable to reach the server.\n"
            "  e.g. --api-base https://khata-api.onrender.com\n"
            "Pass --allow-local-api only for an internal test build."
        )

    parsed = urllib.parse.urlparse(value)
    host = (parsed.hostname or "").lower()

    if parsed.scheme != "https":
        raise SystemExit(
            f"--api-base must be https:// (got {value!r}). "
            "android/app/src/main/res/xml/network_security_config.xml refuses cleartext "
            "HTTP to every host except localhost and the listed dev addresses, so an "
            "http:// APK cannot connect at all."
        )

    private = host in {"localhost", "0.0.0.0", "::1"}
    try:
        address = ipaddress.ip_address(host)
        private = private or address.is_private or address.is_loopback or address.is_link_local
    except ValueError:
        # A hostname: only the names above are inherently local.
        pass

    if private and not value.startswith("https://localhost"):
        raise SystemExit(
            f"--api-base points at a private/loopback address ({host}); no shop's phone can "
            "reach it. Deploy the API first, or pass --allow-local-api for an internal build."
        )

    return value


def main() -> int:
    parser = argparse.ArgumentParser(description="Cut a versioned APK release.")
    parser.add_argument("--bump", choices=["patch", "minor", "major"], default="patch")
    parser.add_argument("--version", help="explicit X.Y.Z, overrides --bump")
    parser.add_argument("--api-base", default=None,
                        help="API_BASE_URL compiled into the APK. Required for a real "
                             "build: AppConfig.apiBaseUrl defaults to http://localhost:5000, "
                             "which every phone resolves to itself.")
    parser.add_argument("--allow-local-api", action="store_true",
                        help="permit a loopback/LAN --api-base (internal test builds only)")
    parser.add_argument("--notes", default="",
                        help="override the release body (default: the CHANGELOG.md "
                             "section for this version)")
    parser.add_argument("--flutter", default=None)
    parser.add_argument("--skip-build", action="store_true",
                        help="publish the existing APK without bumping or rebuilding")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    # Checked before anything is written, so a dry run catches it too.
    if not args.skip_build and not args.allow_local_api:
        args.api_base = require_public_api_base(args.api_base)

    current = read_version()
    if args.version:
        parts = args.version.lstrip("v").split(".")
        if len(parts) != 3 or not all(p.isdigit() for p in parts):
            raise SystemExit(f"--version must be X.Y.Z, got {args.version}")
        target = tuple(int(p) for p in parts)
    else:
        target = bump(current, args.bump)

    build_number = current[3] + 1
    tag = "v" + ".".join(map(str, target))

    # Re-releasing the same version would move a tag that installed apps may
    # already be comparing against, so that is the thing worth refusing — not
    # "the version did not change", which is legitimate when the APK was built
    # by hand and only needs publishing.
    if run(["git", "tag", "-l", tag], check=False).stdout.strip():
        raise SystemExit(f"tag {tag} already exists; bump the version instead")

    if args.skip_build:
        print(f"publishing existing APK as {tag} (no bump, no rebuild)")
    else:
        if target == current[:3]:
            raise SystemExit(f"version is already {'.'.join(map(str, target))}; pass --bump or --version")
        print(f"version {current[0]}.{current[1]}.{current[2]}+{current[3]} -> "
              f"{'.'.join(map(str, target))}+{build_number}  ({tag})")

    # Resolved before the dry-run exit so a dry run also proves the changelog
    # has notes for this version.
    version_text = ".".join(map(str, target))
    body, promoted_changelog = release_notes(version_text, datetime.date.today().isoformat())
    if args.notes.strip():
        print(f"notes     : --notes ({len(args.notes.strip())} chars, overrides CHANGELOG.md)")
        body = args.notes.strip()
    else:
        first = body.splitlines()[0] if body else ""
        print(f"notes     : CHANGELOG.md [{version_text}] ({len(body)} chars) — {first[:60]}")

    if args.dry_run:
        print("dry run: stopping before any write")
        return 0

    if not args.skip_build:
        write_version(*target, build_number)
        flutter = args.flutter or flutter_binary()
        build_cmd = [flutter, "build", "apk", "--release"]
        if args.api_base:
            build_cmd.append(f"--dart-define=API_BASE_URL={args.api_base}")

        print("building APK (several minutes)...")
        run(build_cmd, cwd=MOBILE)

    if promoted_changelog is not None:
        CHANGELOG.write_text(promoted_changelog, encoding="utf-8")
        print(f"CHANGELOG.md: [Unreleased] promoted to [{version_text}]")

    if not APK.exists():
        raise SystemExit(f"{APK} is missing — build first, or drop --skip-build")
    size_mb = APK.stat().st_size / (1024 * 1024)
    print(f"APK: {APK}  ({size_mb:.1f} MB)")

    # Upload under a versioned name: app-release.apk tells a human nothing when
    # it lands in their Downloads folder next to three older copies.
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    asset_path = dist / f"khata-{'.'.join(map(str, target))}.apk"
    shutil.copyfile(APK, asset_path)

    owner, repo = git_remote()
    token = github_token()

    print("committing and tagging...")
    run(["git", "add", str(PUBSPEC.relative_to(ROOT)), str(CHANGELOG.relative_to(ROOT))])
    staged = run(["git", "diff", "--cached", "--quiet"], check=False).returncode != 0
    if staged:
        run(["git", "commit", "-m", f"Release {tag}"])
    else:
        print("  (no version change to commit)")
    run(["git", "tag", "-a", tag, "-m", f"Release {tag}"])
    run(["git", "push", "origin", "HEAD"])
    run(["git", "push", "origin", tag])

    print("creating release...")
    release = api("POST", f"https://api.github.com/repos/{owner}/{repo}/releases", token, {
        "tag_name": tag,
        "name": f"Khata {'.'.join(map(str, target))}",
        "body": body,
        "draft": False,
        "prerelease": False,
    })

    print(f"uploading {size_mb:.1f} MB...")
    asset = upload_asset(owner, repo, release["id"], token, asset_path)

    print()
    print(f"release  : {release['html_url']}")
    print(f"download : {asset['browser_download_url']}")
    print(f"size     : {asset['size'] / (1024 * 1024):.1f} MB")
    print()
    print("Installed builds will see this on their next launch (the check reads")
    print("/releases/latest, so nothing else needs publishing).")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.HTTPError as error:
        body = error.read().decode(errors="replace")
        sys.stderr.write(f"GitHub API {error.code}: {body[:600]}\n")
        raise SystemExit(1)
