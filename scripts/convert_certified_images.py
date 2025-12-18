#!/usr/bin/env python3
"""
Converts certified_images.json from Phase 2 into the format expected by update_images.py

Input: certified_images.json from Phase 2
Output: images.txt in the format expected by update_images.py

Format expected by update_images.py (pairs of lines):
  registry. connect.redhat.com/sumologic/fluent-bit:3.0.0-ubi
  registry.connect.redhat. com/sumologic/fluent-bit:@sha256:abc123...
  registry.connect.redhat.com/sumologic/node-exporter:v1.3.1-ubi
  registry.connect.redhat.com/sumologic/node-exporter: @sha256:1934ef...
"""

import json
import argparse
import sys


def convert_certified_images_to_text(json_file:  str, output_file: str):
    """
    Convert certified_images.json to text format expected by update_images.py

    Args:
        json_file: Path to certified_images.json from Phase 2
        output_file: Path to output text file
    """
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    lines = []
    skipped = []

    for img in data['certified_images']:
        # Skip failed or pending certifications
        if img['certification_status'] != 'success':
            skipped.append(f"{img['name']} - Status: {img['certification_status']}")
            continue

        # Extract components
        name = img['name']
        version = img['version']
        sha256 = img['sha256']

        # Validate required fields
        if not name or not version or not sha256:
            skipped.append(f"{name} - Missing required fields")
            continue

        # Generate the two lines expected by update_images.py
        # Line 1: registry.connect.redhat.com/sumologic/{name}:{version}-ubi
        image_with_tag = f"registry.connect.redhat.com/sumologic/{name}:{version}-ubi"

        # Line 2: registry.connect.redhat.com/sumologic/{name}:@{sha256}
        # Remove 'sha256:' prefix if present
        sha256_clean = sha256.replace('sha256:', '')
        image_with_sha = f"registry.connect.redhat.com/sumologic/{name}:@sha256:{sha256_clean}"

        lines.append(image_with_tag)
        lines.append(image_with_sha)

    # Report skipped images
    if skipped:
        print("⚠️  Skipped images:", file=sys.stderr)
        for skip in skipped:
            print(f"   - {skip}", file=sys. stderr)

    # Write to output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'. join(lines))
        if lines:  # Add final newline only if there's content
            f.write('\n')

    print(f"✅ Converted {len(lines)//2} images to {output_file}")

    # Return count for validation
    return len(lines) // 2


def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Convert certified_images.json to update_images.py format'
    )
    parser.add_argument(
        '--input',
        required=True,
        help='Path to certified_images.json'
    )
    parser.add_argument(
        '--output',
        default='images.txt',
        help='Path to output file (default: images.txt)'
    )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    count = convert_certified_images_to_text(args.input, args.output)

    if count == 0:
        print("❌ No images converted", file=sys.stderr)
        sys.exit(1)
