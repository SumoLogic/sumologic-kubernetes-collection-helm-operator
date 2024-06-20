#!/usr/bin/env python

"""
Generates watches.yaml based on values.yaml for the Sumo Logic Kubernetes Collection Helm Chart
Environment variables related to new image keys need to be manually filled out
"""

import argparse
import os
import yaml

from get_image_config_keys import get_image_keys

WATCHES_PATH = "watches.yaml"


def create_new_file_path(file_path: str, create_new_file: bool) -> str:
    """Creates path for the file with updated list of components images

    Args:
        file_path (str): path to file in which components images should be updated
        create_new_file: determines whether new yaml should be created or the exiting file should be overwritten

    Returns:
        str: path to file in which changes will be save
    """
    new_file_path = file_path
    if create_new_file:
        new_file_path = file_path.replace(".yaml", "_new.yaml")
    return new_file_path


def parse_args():
    """ Parses command line arguments"""
    parser = argparse.ArgumentParser()
    parser.add_argument("--operator-repo-dir",
                        help="path to directory with Helm Operator repository, e.g. /operator/", default="./")
    parser.add_argument(
        "--create-new-file", help="determines whether new yaml should be created or the exiting file should be overwritten", default=True)
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    image_keys = get_image_keys()
    watches_file_path = os.path.join(args.operator_repo_dir, WATCHES_PATH)

    with open(watches_file_path, encoding="utf-8") as w:
        watches = yaml.safe_load(w)
        overrideValues = watches[0]["overrideValues"]

        for image_key in image_keys:
            if image_key not in watches[0]["overrideValues"].keys():
                overrideValues[image_key] = ""

        with open(create_new_file_path(watches_file_path, args.create_new_file), 'w', encoding="utf-8") as nw:
            yaml.safe_dump(watches, nw)
