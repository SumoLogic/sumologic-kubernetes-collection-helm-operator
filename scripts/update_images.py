#!/usr/bin/env python3

import yaml
import argparse

RED_HAT_REGISTRY = "registry.connect.redhat.com/sumologic/"
ENV_PREFIX = "RELATED_IMAGE_"
CLUSTER_SERVICE_VERSION_PATH = "bundle/manifests/operator.clusterserviceversion.yaml"
MANAGER_PATH = "config/manager/manager.yaml"

def pairwise(iterable: list) -> list:
    """Transforms list in following way:
    [s0 s1 s2 s3 s4 s5] -> [(s0, s1), (s2, s3), (s4, s5)]

    Args: list
        iterable (list): any list for pairs to be created
    Returns:
        list: list with pairs created from the input list
    """
    a = iter(iterable)
    return zip(a, a)

def get_lines(file: str) -> list:
    """Read file line by line removing unnecessary string at the beginning,
    e.g. output of get_images_sha256.sh:
    ./scripts/get_images_sha256.sh
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:v0.11.0-ubi
    MISSING
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:v0.15.0-ubi
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:@sha256:1153a4592746b05e019bde4d818d176ff9350c013f84d49829032540de882841
    registry.connect.redhat.com/sumologic/kube-state-metrics:v2.7.0-ubi
    MISSING

    Args:
        file (str): path to the output of get_images_sha256.sh, see: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/scripts/get_images_sha256.sh

    Returns:
        list: lines with information about container images from the output of get_images_sha256.sh
    """
    lines = []
    with open(file) as f:
        lines = f.read().split("\n")
        if RED_HAT_REGISTRY not in lines[0]:
            lines = lines[1:]
    return lines

def generate_image_lists(image_list_file: str) -> tuple[list, list]:
    """Generate images lists:
        - list of related images
        - list of environment variables with information about components images
    Args:
        image_list_file (str): path to the output of get_images_sha256.sh, see: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/scripts/get_images_sha256.sh

     Returns:
        list: list of related images
        list: list of environment variables with information about components images
    """
    lines = get_lines(image_list_file)
    related_images = []
    image_envs = []
    for image_with_tag, image_with_sha256 in pairwise(lines):
        component_and_tag = image_with_tag.removeprefix(RED_HAT_REGISTRY).split(":")
        component = component_and_tag[0]
        tag = component_and_tag[1]
        env_name = "{}{}".format(ENV_PREFIX, component.upper().replace("-", "_"))
        related_images.append({"name": env_name, "image": image_with_sha256 })
        image_envs.append({"name": env_name, "value": image_with_sha256 })
    return related_images, image_envs

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

def get_helm_operator_image(related_images: list)->dict:
    """Get the settings for Helm Operator in the list of related images
    
    Args:
        related_images (str): list of related images
    
    Returns:
        dict: Helm Operator setting in the list of related images
    """
    operator_image = None
    for image in related_images:
        if image["name"] == "sumologic-kubernetes-collection-helm-operator":
            operator_image = image
    return operator_image

def update_envs(envs: list, new_image_envs) -> list:
    """Updates environment variables, add new environment variables with information about components images
    and preserves not image related environment variables

    Args:
        envs (list): list of environment variables
        new_image_envs (list): list of new environment variables with information about components images
        create_new_file (bool): determines whether new yaml should be created or the exiting file should be overwritten 

    Returns
        list: update list of list of environment variables
    """
    not_image_envs = []    
    for env in envs:
        if ENV_PREFIX not in env["name"]:
            not_image_envs.append(env)
    return not_image_envs + new_image_envs

def update_cluster_service_version(file_path: str, new_related_images: list, new_image_envs: list, create_new_file):
    """ Updates components images in bundle/manifests/operator.clusterserviceversion.yaml

    Args:
        file_path (str): absolute path to bundle/manifests/operator.clusterserviceversion.yaml
        new_related_images (list): list of new related images
        new_image_envs (list): list of new environment variables with information about components images
        create_new_file (bool): determines whether new yaml should be created or the exiting file should be overwritten 
    """
    with open(file_path) as cr:
        cluster_service_version = yaml.safe_load(cr)
        related_images = cluster_service_version["spec"]["relatedImages"]

        helm_operator_image = get_helm_operator_image(related_images)
        new_related_images.insert(0, helm_operator_image)
        cluster_service_version["spec"]["relatedImages"] = new_related_images

        containers = cluster_service_version["spec"]["install"]["spec"]["deployments"][0]["spec"]["template"]["spec"]["containers"]
        for i in range(len(containers)):
            name = containers[i]["name"]
            if name == "operator":
                envs = containers[i]["env"]
                containers[i]["env"] = update_envs(envs, new_image_envs)

    with open(create_new_file_path(file_path, create_new_file), 'w') as cw:
        yaml.dump(cluster_service_version, cw)

def update_manager(file_path: str,new_image_envs: list, create_new_file):
    """ Updates components images in config/manager/manager.yaml

    Args:
        file_path (str): absolute path to config/manager/manager.yaml
        new_image_envs (list): list of new environment variables with information about components images
        create_new_file (bool): determines whether new yaml should be created or the exiting file should be overwritten 
    """
    with open(file_path) as mr:
        yaml_contents = yaml.safe_load_all(mr)
        
        new_contents = []
        for yaml_content in yaml_contents:
            if yaml_content["kind"] != "Deployment":
                new_contents.append(yaml_content)
            else:
                envs = yaml_content["spec"]["template"]["spec"]["containers"][0]["env"]
                yaml_content["spec"]["template"]["spec"]["containers"][0]["env"] = update_envs(envs, new_image_envs)
                new_contents.append(yaml_content)

        with open(create_new_file_path(file_path, create_new_file), 'w') as cw:
            yaml.safe_dump_all(new_contents, cw)

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--images-file", help="file with the list of container images, output of get_images_sha256.sh from sumologic-openshift-images repository", required=True)
    parser.add_argument("--operator-repo-dir", help="path to directory with Helm Operator repository, e.g. /operator/", default="./")
    parser.add_argument("--create-new-file", help="determines whether new yaml should be created or the exiting file should be overwritten", default=True)
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_args()

    related_images, image_envs = generate_image_lists(args.images_file)

    csv_path = args.operator_repo_dir + CLUSTER_SERVICE_VERSION_PATH
    update_cluster_service_version(csv_path, related_images, image_envs, args.create_new_file)

    m_path = args.operator_repo_dir  + MANAGER_PATH
    update_manager(m_path, image_envs, args.create_new_file)
