#!/usr/bin/env python3
"""Updates operator version in all necessary files for a new release."""

import argparse
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

import yaml


def detect_release_type(version):
    """Detect if version is RC or final."""
    return "rc" if re.search(r"[-\.]rc[\.\-]\d+$", version) else "final"


def base_of_rc(version):
    """Strip the -rc.N suffix to get the base release version."""
    return re.sub(r"[-\.]rc\.\d+$", "", version)


def get_previous_version_from_csv(csv_file, operator_name, version):
    """Return the version the new CSV should replace.

    First RC of a release: the version currently in the CSV (the last release).
    Any later RC or the final of the same base version: whatever the current RC
    replaced, so RCs never end up in the upgrade path.
    """
    try:
        with open(csv_file, "r", encoding="utf-8") as f:
            csv_data = yaml.safe_load(f)
    except (IOError, yaml.YAMLError) as e:
        print(f"Error reading CSV: {e}")
        sys.exit(1)

    spec = csv_data.get("spec", {})
    current_version = spec.get("version", "")
    if not current_version:
        print("Cannot find version in CSV file")
        sys.exit(1)

    same_release = base_of_rc(current_version) == base_of_rc(version)
    if same_release and (detect_release_type(current_version) == "rc" or current_version == version):
        replaces = spec.get("replaces", "")
        prefix = f"{operator_name}.v"
        if not replaces.startswith(prefix):
            print(f"CSV is at RC {current_version} but spec.replaces is missing or invalid: '{replaces}'")
            sys.exit(1)
        return replaces[len(prefix) :]

    return current_version


def validate_version_format(version, release_type):
    """Validate version format."""
    if release_type == "rc":
        if not re.match(r"^\d+\.\d+\.\d+-\d+[-\.]rc\.\d+$", version):
            print(f"RC version must match format: X.Y.Z-N-rc.M (got: {version})")
            sys.exit(1)
    else:
        if not re.match(r"^\d+\.\d+\.\d+-\d+$", version):
            print(f"Final version must match format: X.Y.Z-N (got: {version})")
            sys.exit(1)
        if "rc" in version.lower():
            print("Final version should not contain 'rc'")
            sys.exit(1)


def update_csv(csv_file, version, operator_name, previous_version=None):
    """Update ClusterServiceVersion file."""
    with open(csv_file, "r", encoding="utf-8") as f:
        csv_data = yaml.safe_load(f)

    csv_data["spec"]["version"] = version
    csv_data["metadata"]["name"] = f"{operator_name}.v{version}"
    csv_data["metadata"]["annotations"]["createdAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Set spec.replaces so OLM can build the upgrade path N-1 → N
    if previous_version:
        csv_data["spec"]["replaces"] = f"{operator_name}.v{previous_version}"

    with open(csv_file, "w", encoding="utf-8") as f:
        yaml.dump(csv_data, f, default_flow_style=False, sort_keys=False)


def update_makefile(makefile_path, version, operator_name):
    """Update IMG in Makefile."""
    if not Path(makefile_path).exists():
        return

    with open(makefile_path, "r", encoding="utf-8") as f:
        content = f.read()

    img_value = f"registry.connect.redhat.com/sumologic/{operator_name}:{version}"
    content = re.sub(r"^IMG\s*\?=\s*.*$", f"IMG ?= {img_value}", content, flags=re.MULTILINE)

    with open(makefile_path, "w", encoding="utf-8") as f:
        f.write(content)


def update_kustomization(kustomize_file, version):
    """Update config/manager/kustomization.yaml."""
    if not Path(kustomize_file).exists():
        return

    with open(kustomize_file, "r", encoding="utf-8") as f:
        kustomize_data = yaml.safe_load(f)

    if "images" in kustomize_data:
        for image in kustomize_data["images"]:
            if image.get("name") == "controller":
                image["newTag"] = version
                break

    with open(kustomize_file, "w", encoding="utf-8") as f:
        yaml.dump(kustomize_data, f, default_flow_style=False, sort_keys=False)


def update_deploy_test_script(script_file, version, operator_name):
    """Update tests/deploy_helm_operator.sh."""
    if not Path(script_file).exists():
        return

    with open(script_file, "r", encoding="utf-8") as f:
        content = f.read()

    new_image = f"registry.connect.redhat.com/sumologic/{operator_name}:{version}"
    pattern = r"registry\.connect\.redhat\.com/sumologic/" + re.escape(operator_name) + r":[\d\.]+-[\d\.]+(?:[-\.]rc\.[\d]+)?"

    content = re.sub(r'readonly IMG="\$\{IMG:=' + pattern + r'\}"', f'readonly IMG="${{IMG:={new_image}}}"', content)

    content = re.sub(r'sed -i\.bak "s#' + pattern + r"#", f'sed -i.bak "s#{new_image}#', content)

    with open(script_file, "w", encoding="utf-8") as f:
        f.write(content)


def update_bundle_yaml(bundle_file, version, operator_name):
    """Update bundle.yaml file."""
    if not Path(bundle_file).exists():
        return

    with open(bundle_file, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = r"(image:\s+registry\.connect\.redhat\.com/sumologic/" + re.escape(operator_name) + r"):[\d\.]+-[\d\.]+(?:[-\.]rc\.[\d]+)?"
    content = re.sub(pattern, f"\\1:{version}", content)

    with open(bundle_file, "w", encoding="utf-8") as f:
        f.write(content)


def main():
    """Main function to update operator version in all required files."""
    parser = argparse.ArgumentParser(description="Update operator version")
    parser.add_argument("--operator-version", required=True, help="Operator version")
    parser.add_argument("--operator-repo-dir", default="./", help="Repository directory")

    args = parser.parse_args()

    version = args.operator_version
    repo_dir = Path(args.operator_repo_dir)

    operator_name = "sumologic-kubernetes-collection-helm-operator"
    csv_file = repo_dir / "bundle/manifests/operator.clusterserviceversion.yaml"

    release_type = detect_release_type(version)
    validate_version_format(version, release_type)
    previous_version = get_previous_version_from_csv(csv_file, operator_name, version)

    update_csv(csv_file, version, operator_name, previous_version=previous_version)
    update_makefile(repo_dir / "Makefile", version, operator_name)
    update_bundle_yaml(repo_dir / "bundle.yaml", version, operator_name)
    update_kustomization(repo_dir / "config/manager/kustomization.yaml", version)
    update_deploy_test_script(repo_dir / "tests/deploy_helm_operator.sh", version, operator_name)

    # Write outputs to GITHUB_OUTPUT
    github_output = os.getenv("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as f:
            f.write(f"release_type={release_type}\n")
            f.write(f"previous_version={previous_version}\n")


if __name__ == "__main__":
    main()
