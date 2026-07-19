#!/usr/bin/env python3
"""Merge gradle verification-metadata.xml files into the central lockfile.

Usage: merge-verification-metadata.py <verification-metadata.xml>... [--lock lib/maven-lock.json]

For every <component>/<artifact>/<sha256> in the given XML files, adds
"group:name:version" -> {"artifact-file": "sha256hex"} entries to the lock.

If a coordinate+file already exists in the lock with a DIFFERENT hash, the
merge fails loudly: a published Maven artifact must never change bytes. A
mismatch means either an upstream repository rebuilt/replaced the artifact
(JitPack is notorious for this) or something is tampering with it. Inspect
before overriding with --force, which keeps the NEW hash.
"""

import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def strip_ns(tag: str) -> str:
    return re.sub(r"\{.*\}", "", tag)


def parse_metadata(path: Path) -> dict:
    entries: dict[str, dict[str, str]] = {}
    root = ET.parse(path).getroot()
    for component in root.iter():
        if strip_ns(component.tag) != "component":
            continue
        coord = ":".join(component.attrib[k] for k in ("group", "name", "version"))
        for artifact in component:
            if strip_ns(artifact.tag) != "artifact":
                continue
            for checksum in artifact:
                if strip_ns(checksum.tag) == "sha256":
                    entries.setdefault(coord, {})[artifact.attrib["name"]] = (
                        checksum.attrib["value"]
                    )
    return entries


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("xml_files", nargs="+", type=Path)
    parser.add_argument(
        "--lock",
        type=Path,
        default=Path(__file__).parent.parent / "maven-lock.json",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="on hash conflict, keep the new hash instead of failing",
    )
    args = parser.parse_args()

    lock = json.loads(args.lock.read_text()) if args.lock.exists() else {}
    conflicts, added = [], 0

    for xml_file in args.xml_files:
        for coord, files in parse_metadata(xml_file).items():
            for fname, sha in files.items():
                known = lock.get(coord, {}).get(fname)
                if known is None:
                    lock.setdefault(coord, {})[fname] = sha
                    added += 1
                elif known != sha:
                    conflicts.append((coord, fname, known, sha))
                    if args.force:
                        lock[coord][fname] = sha

    for coord, fname, old, new in conflicts:
        print(f"HASH CONFLICT {coord} ({fname})", file=sys.stderr)
        print(f"  locked: {old}", file=sys.stderr)
        print(f"  new:    {new}", file=sys.stderr)

    if conflicts and not args.force:
        print(
            f"\n{len(conflicts)} conflict(s): an already-locked artifact changed "
            "bytes upstream. Investigate; re-run with --force to accept the new "
            "hashes.",
            file=sys.stderr,
        )
        return 1

    args.lock.write_text(json.dumps(lock, indent=2, sort_keys=True) + "\n")
    print(f"{args.lock}: +{added} entries, {len(lock)} components total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
