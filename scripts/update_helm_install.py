#!/usr/bin/env python3
"""Update helm_install.sh with certified image SHA256 digests."""

import argparse
import re
import sys


def parse_images_file(images_file_path):
    """Parse images.txt and return dict of component -> {version, SHA256}."""
    components = {}
    
    with open(images_file_path, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    for i in range(0, len(lines), 2):
        if i + 1 >= len(lines):
            break
        
        # Format: registry.connect.redhat.com/sumologic/COMPONENT:VERSION-ubi
        tag_match = re.search(r'/sumologic/([^:]+):(.+)', lines[i])
        # Format: registry.connect.redhat.com/sumologic/COMPONENT:@sha256:HASH
        sha_match = re.search(r'@sha256:([a-f0-9]+)', lines[i + 1])
        
        if tag_match and sha_match:
            components[tag_match.group(1)] = {
                'version': tag_match.group(2),
                'sha': sha_match.group(1)
            }
    
    return components


def update_helm_install(helm_install_path, certified_components, helm_chart_version, output_path):
    """Update helm_install.sh with certified images by parsing repository URLs."""
    
    with open(helm_install_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    updated_lines = []
    update_count = 0
    current_component = None
    
    for line in lines:
        updated_line = line
        
        # Update Helm chart version
        if '--version' in line and 'helm upgrade' not in line:
            version_match = re.search(r'--version\s+([\d.]+)', line)
            if version_match:
                updated_line = line.replace(f'--version {version_match.group(1)}', f'--version {helm_chart_version}')
                if updated_line != line:
                    update_count += 1
        
        # Extract component from repository URL (but don't modify it)
        repo_match = re.search(r'\.repository=([^\s\\]+)', line)
        if repo_match:
            repo_url = repo_match.group(1)
            # Try full URL format first: public.ecr.aws/sumologic/COMPONENT
            comp_match = re.search(r'/sumologic/([^@\s\\]+)', repo_url)
            if comp_match:
                component = comp_match.group(1)
            else:
                # Try short format: just COMPONENT@sha256
                comp_match = re.search(r'^([^@\s\\]+)', repo_url)
                if comp_match:
                    component = comp_match.group(1)
                else:
                    component = None
            
            if component:
                current_component = component if component in certified_components else None
            else:
                current_component = None
        
        # Update .tag field - use SHA if original has SHA (64 hex chars), otherwise use VERSION
        elif '.tag=' in line and current_component:
            tag_match = re.search(r'\.tag=([^\s\\]+)', line)
            if tag_match:
                current_tag = tag_match.group(1)
                # Check if current tag is a SHA hash (64 hex characters)
                is_sha_format = len(current_tag) == 64 and all(c in '0123456789abcdef' for c in current_tag.lower())
                
                if is_sha_format:
                    # Original uses SHA in .tag field, so update with SHA
                    new_tag = certified_components[current_component]['sha']
                else:
                    # Original uses version in .tag field, so update with version
                    new_tag = certified_components[current_component]['version']
                
                if current_tag != new_tag:
                    updated_line = re.sub(r'\.tag=[^\s\\]+', f'.tag={new_tag}', line)
                    update_count += 1
        
        # Update .sha field with SHA256
        elif '.sha=' in line and current_component:
            sha_match = re.search(r'\.sha=([^\s\\]+)', line)
            if sha_match:
                new_sha = certified_components[current_component]['sha']
                if sha_match.group(1) != new_sha:
                    updated_line = re.sub(r'\.sha=[^\s\\]+', f'.sha={new_sha}', line)
                    update_count += 1
        
        updated_lines.append(updated_line)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(updated_lines)
    
    print(f"✅ Updated {update_count} fields", file=sys.stderr)
    return update_count


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--images-file', required=True)
    parser.add_argument('--helm-install', required=True)
    parser.add_argument('--helm-chart-version', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    
    components = parse_images_file(args.images_file)
    if not components:
        print("ERROR: No certified components found", file=sys.stderr)
        sys.exit(1)
    
    update_helm_install(args.helm_install, components, args.helm_chart_version, args.output)


if __name__ == '__main__':
    main()
