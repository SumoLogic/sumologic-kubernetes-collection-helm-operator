#!/usr/bin/env python3
"""Updates operator version in all necessary files for a new release."""

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path

import yaml


def detect_release_type(version):
    """Detect if version is RC or final."""
    return 'rc' if re.search(r'[-\.]rc[\.\-]\d+$', version) else 'final'


def get_previous_version_from_csv(csv_file):
    """Get current version from CSV file."""
    try:
        with open(csv_file, 'r') as f:
            csv_data = yaml.safe_load(f)
            current_version = csv_data.get('spec', {}).get('version', '')
            if current_version:
                return current_version
    except Exception as e:
        print(f"Error reading CSV: {e}")
        sys.exit(1)

    print("Cannot find version in CSV file")
    sys.exit(1)


def validate_version_format(version, release_type):
    """Validate version format."""
    if release_type == 'rc':
        if not re.match(r'^\d+\.\d+\.\d+-\d+[-\.]rc\.\d+$', version):
            print(f"RC version must match format: X.Y.Z-N-rc.M (got: {version})")
            sys.exit(1)
    else:
        if not re.match(r'^\d+\.\d+\.\d+-\d+$', version):
            print(f"Final version must match format: X.Y.Z-N (got: {version})")
            sys.exit(1)
        if 'rc' in version.lower():
            print("Final version should not contain 'rc'")
            sys.exit(1)


def update_csv(csv_file, version, previous_version, operator_name):
    """Update ClusterServiceVersion file."""
    with open(csv_file, 'r') as f:
        csv_data = yaml.safe_load(f)

    csv_data['spec']['version'] = version
    csv_data['metadata']['name'] = f"{operator_name}.v{version}"
    csv_data['metadata']['annotations']['createdAt'] = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

    operator_image = f"registry.connect.redhat.com/sumologic/{operator_name}:{version}"
    csv_data['metadata']['annotations']['containerImage'] = operator_image

    for deployment in csv_data['spec']['install']['spec']['deployments']:
        if deployment['name'] == operator_name:
            for container in deployment['spec']['template']['spec']['containers']:
                if container['name'] == 'manager':
                    container['image'] = operator_image

    if 'relatedImages' in csv_data['spec']:
        for img in csv_data['spec']['relatedImages']:
            if img.get('name') == operator_name:
                img['image'] = operator_image
                break

    with open(csv_file, 'w') as f:
        yaml.dump(csv_data, f, default_flow_style=False, sort_keys=False)


def update_makefile(makefile_path, version, operator_name):
    """Update IMG in Makefile."""
    if not Path(makefile_path).exists():
        return

    with open(makefile_path, 'r') as f:
        content = f.read()

    img_value = f"registry.connect.redhat.com/sumologic/{operator_name}:{version}"
    content = re.sub(r'^IMG\s*\?=\s*.*$', f'IMG ?= {img_value}', content, flags=re.MULTILINE)

    with open(makefile_path, 'w') as f:
        f.write(content)


def update_kustomization(kustomize_file, version):
    """Update config/manager/kustomization.yaml."""
    if not Path(kustomize_file).exists():
        return

    with open(kustomize_file, 'r') as f:
        kustomize_data = yaml.safe_load(f)

    if 'images' in kustomize_data:
        for image in kustomize_data['images']:
            if image.get('name') == 'controller':
                image['newTag'] = version
                break

    with open(kustomize_file, 'w') as f:
        yaml.dump(kustomize_data, f, default_flow_style=False, sort_keys=False)


def update_deploy_test_script(script_file, version, operator_name):
    """Update tests/deploy_helm_operator.sh."""
    if not Path(script_file).exists():
        return

    with open(script_file, 'r') as f:
        content = f.read()

    new_image = f"registry.connect.redhat.com/sumologic/{operator_name}:{version}"
    pattern = r'registry\.connect\.redhat\.com/sumologic/' + re.escape(operator_name) + r':[\d\.]+-[\d\.]+(?:[-\.]rc\.[\d]+)?'

    content = re.sub(
        r'readonly IMG="\$\{IMG:=' + pattern + r'\}"',
        f'readonly IMG="${{IMG:={new_image}}}"',
        content
    )

    content = re.sub(
        r'sed -i\.bak "s#' + pattern + r'#',
        f'sed -i.bak "s#{new_image}#',
        content
    )

    with open(script_file, 'w') as f:
        f.write(content)

def update_bundle_yaml(bundle_file, version, operator_name):
    """Update bundle.yaml file."""
    if not Path(bundle_file).exists():
        return

    with open(bundle_file, 'r') as f:
        content = f.read()

    pattern = r'(image:\s+registry\.connect\.redhat\.com/sumologic/' + re.escape(operator_name) + r'):[\d\.]+-[\d\.]+(?:[-\.]rc\.[\d]+)?'
    content = re.sub(pattern, f'\\1:{version}', content)

    with open(bundle_file, 'w') as f:
        f.write(content)

def main():
    parser = argparse.ArgumentParser(description='Update operator version')
    parser.add_argument('--operator-version', required=True, help='Operator version')
    parser.add_argument('--operator-repo-dir', default='./', help='Repository directory')

    args = parser.parse_args()

    version = args.operator_version
    repo_dir = Path(args.operator_repo_dir)

    operator_name = "sumologic-kubernetes-collection-helm-operator"
    csv_file = repo_dir / "bundle/manifests/operator.clusterserviceversion.yaml"

    release_type = detect_release_type(version)
    validate_version_format(version, release_type)
    previous_version = get_previous_version_from_csv(csv_file)

    update_csv(csv_file, version, previous_version, operator_name)
    update_makefile(repo_dir / "Makefile", version, operator_name)
    update_bundle_yaml(repo_dir / "bundle.yaml", version, operator_name)
    update_kustomization(repo_dir / "config/manager/kustomization.yaml", version)
    update_deploy_test_script(repo_dir / "tests/deploy_helm_operator.sh", version, operator_name)

    print(f"::set-output name=release_type::{release_type}")
    print(f"::set-output name=previous_version::{previous_version}")


if __name__ == '__main__':
    main()
