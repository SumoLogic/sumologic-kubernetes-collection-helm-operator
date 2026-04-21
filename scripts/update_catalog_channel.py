#!/usr/bin/env python3
"""Update FBC channel.yaml and prune N-3 bundles on each release."""

import argparse
import re
import sys
from pathlib import Path

import yaml

OPERATOR_PACKAGE = "sumologic-kubernetes-collection-helm-operator"
CATALOG_DIR = Path("catalog") / OPERATOR_PACKAGE


def load_channel(channel_file: Path) -> dict:
    """Load channel.yaml as a dict."""
    with open(channel_file, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return {} if data is None else data


def save_channel(channel_file: Path, data: dict) -> None:
    """Write channel data back to channel.yaml."""
    with open(channel_file, "w", encoding="utf-8") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False)


def csv_name(version: str) -> str:
    """Return the full CSV name for a version, e.g. operator.v4.22.0-0."""
    return f"{OPERATOR_PACKAGE}.v{version}"


def is_rc(version: str) -> bool:
    """Return True if the version is a release candidate (contains -rc.N)."""
    return bool(re.search(r"-rc\.\d+$", version))


def base_of_rc(rc_version: str) -> str:
    """Strip the -rc.N suffix to get the base release version."""
    return re.sub(r"-rc\.\d+$", "", rc_version)


def append_version(data: dict, version: str, previous_version: str) -> None:
    """Add a new channel entry for version with replaces pointing to previous_version."""
    entries: list = data.setdefault("entries", [])
    if any(e.get("name") == csv_name(version) for e in entries):
        print(f"Version {version} already present - skipping.")
        return
    entry: dict = {"name": csv_name(version)}
    if previous_version:
        entry["replaces"] = csv_name(previous_version)
    entries.append(entry)


def find_chain_root(entries: list) -> str | None:
    """Walk replaces chain from HEAD to find the oldest in-catalog entry."""
    by_name = {e["name"]: e for e in entries}
    all_replaces = {e["replaces"] for e in entries if "replaces" in e}
    heads = [e["name"] for e in entries if e["name"] not in all_replaces]
    if len(heads) != 1:
        return None
    current, visited, tail = heads[0], set(), heads[0]
    while True:
        if current in visited:
            return None
        visited.add(current)
        entry = by_name.get(current)
        if entry is None:
            break
        tail = current
        next_name = entry.get("replaces")
        if next_name is None or next_name not in by_name:
            break
        current = next_name
    return tail


def prune_channel(data: dict) -> str | None:
    """Remove the oldest channel entry if there are more than 3. Returns the pruned CSV name."""
    entries: list = data.get("entries", [])
    if len(entries) <= 3:
        return None
    oldest = find_chain_root(entries)
    if oldest is None:
        print("Could not identify chain root - skipping prune.")
        return None
    data["entries"] = [e for e in entries if e["name"] != oldest]
    print(f"Pruned: {oldest}")
    return oldest


def promote_rc_to_final(data: dict, previous_version: str, bundles_file: Path) -> str:
    """
    When a final release follows an RC of the same base version, clean up the RC:
    1. Remove the RC entry from channel entries.
    2. Remove the RC bundle document from bundles.yaml.
    3. Return the version the RC was replacing, to use as the new 'replaces'.
    """
    rc_csv = csv_name(previous_version)
    entries: list = data.get("entries", [])
    rc_entry = next((e for e in entries if e.get("name") == rc_csv), None)
    actual_previous = ""
    if rc_entry and "replaces" in rc_entry:
        actual_previous = rc_entry["replaces"].split(".v")[-1]
    data["entries"] = [e for e in entries if e.get("name") != rc_csv]
    print(f"Removed RC entry from channel: {rc_csv}")
    prune_bundles_yaml(bundles_file, rc_csv)
    return actual_previous


def prune_bundles_yaml(bundles_file: Path, n3_csv_name: str) -> None:
    """Remove the olm.bundle document for the pruned version from bundles.yaml."""
    if not bundles_file.exists():
        return
    with open(bundles_file, "r", encoding="utf-8") as f:
        raw = f.read()
    sep = "\n---\n"
    chunks = raw.split(sep)
    pattern = re.compile(rf"^name: {re.escape(n3_csv_name)}\s*$", re.MULTILINE)
    filtered = [c for c in chunks if not pattern.search(c)]
    if len(filtered) == len(chunks):
        return
    content = sep.join(filtered)
    if not content.endswith("\n"):
        content += "\n"
    with open(bundles_file, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Pruned bundle: {n3_csv_name}")


def validate_upgrade_path(data: dict) -> None:
    """Verify the channel has exactly one head and no cycles. Exits on error."""
    entries: list = data.get("entries", [])
    if not entries:
        print("ERROR: channel has no entries.", file=sys.stderr)
        sys.exit(1)
    all_replaces = {e["replaces"] for e in entries if "replaces" in e}
    heads = [e["name"] for e in entries if e["name"] not in all_replaces]
    if len(heads) != 1:
        print(f"ERROR: expected 1 head, found {len(heads)}: {heads}", file=sys.stderr)
        sys.exit(1)
    by_name = {e["name"]: e for e in entries}
    current, visited = heads[0], set()
    while current is not None and current in by_name:
        if current in visited:
            print(f"ERROR: cycle at {current}", file=sys.stderr)
            sys.exit(1)
        visited.add(current)
        current = by_name[current].get("replaces")
    print(f"Upgrade path valid: {len(entries)} versions, head={heads[0]}")


def main() -> None:
    """Parse arguments and orchestrate channel update and pruning."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--previous-version", required=True)
    parser.add_argument("--prune", action="store_true")
    parser.add_argument("--catalog-dir", default=str(CATALOG_DIR))
    args = parser.parse_args()

    catalog_dir = Path(args.catalog_dir)
    channel_file = catalog_dir / "channel.yaml"
    bundles_file = catalog_dir / "bundles.yaml"

    if not channel_file.exists():
        print(f"ERROR: {channel_file} not found.", file=sys.stderr)
        sys.exit(1)

    data = load_channel(channel_file)

    # When promoting an RC to its final version, strip the RC from the catalog
    # first and use the RC's own predecessor as the 'replaces' target.
    if not is_rc(args.version) and is_rc(args.previous_version) and base_of_rc(args.previous_version) == args.version:
        actual_previous = promote_rc_to_final(data, args.previous_version, bundles_file)
        print(f"Promoting RC {args.previous_version} → final {args.version}, " f"actual previous: {actual_previous or '(none)'}")
    else:
        actual_previous = args.previous_version

    append_version(data, args.version, actual_previous)
    n3 = prune_channel(data) if args.prune else None
    validate_upgrade_path(data)
    save_channel(channel_file, data)

    if n3:
        prune_bundles_yaml(bundles_file, n3)


if __name__ == "__main__":
    main()
