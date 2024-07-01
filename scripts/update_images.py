#!/usr/bin/env python3

"""Updates components container images in:
- bundle/manifests/operator.clusterserviceversion.yaml
- config/manager/manager.yaml
- tests/replace_components_images.sh
- tests/helm_install.sh
"""

import argparse
import os
import subprocess
import yaml

from get_image_config_keys import get_image_keys

RED_HAT_REGISTRY = "registry.connect.redhat.com/sumologic/"
PUBLIC_ECR_REGISTRY = "public.ecr.aws/sumologic/"
ENV_PREFIX = "RELATED_IMAGE_"
CLUSTER_SERVICE_VERSION_PATH = "bundle/manifests/operator.clusterserviceversion.yaml"
MANAGER_PATH = "config/manager/manager.yaml"
REPLACE_COMPONENTS_IMAGES_PATH = "tests/replace_components_images.sh"
HELM_INSTALL_SCRIPT_PATH = "tests/helm_install.sh"
BASH_HEADER = "#!/usr/bin/env bash\n\n"

HELM_INSTALL_COMMAND_HEADER = """readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

helm install test-openshift sumologic/sumologic \\
  --set sumologic.accessId="dummy" \\
  --set sumologic.accessKey="dummy" \\
  --set sumologic.endpoint="http://receiver-mock.receiver-mock:3000/terraform/api/" \\
  --set sumologic.scc.create=true \\
  --set fluent-bit.securityContext.privileged=true \\
  --set kube-prometheus-stack.prometheus-node-exporter.service.port=9200 \\
  --set kube-prometheus-stack.prometheus-node-exporter.service.targetPort=9200 \\
  --set fluentd.logs.containers.multiline.enabled=false \\
  --set metrics-server.enabled=true \\
  --set metrics-server.apiService.create=false \\
  --set otelagent.enabled=true \\
  --set telegraf-operator.enabled=true \\
  --set falco.enabled=true \\
  --set tailing-sidecar-operator.enabled=true \\
  --set opentelemetry-operator.enabled=true \\
  --version 2.19.1 \\
  -n sumologic-system \\
  --create-namespace -f "${ROOT_DIR}/tests/values.yaml" \\\n"""

# COMPONENTS_CONFIG_MAP maps helm chart configuration keys into components names
COMPONENTS_CONFIG_MAP = {
    "instrumentation.instrumentationJobImage.image": "kubernetes-tools-kubectl",
    "kube-prometheus-stack.kube-state-metrics.image": "kube-state-metrics",
    "kube-prometheus-stack.prometheus-node-exporter.image": "node-exporter",
    "kube-prometheus-stack.prometheus.prometheusSpec.image": "prometheus",
    "kube-prometheus-stack.prometheusOperator.image": "prometheus-operator",
    "kube-prometheus-stack.prometheusOperator.prometheusConfigReloader.image": "prometheus-config-reloader",
    "kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage": "prometheus-config-reloader",
    "kube-prometheus-stack.prometheusOperator.thanosImage": "thanos",
    "metadata.image": "sumologic-otel-collector",
    "metrics-server.image": "metrics-server",
    "opentelemetry-operator.kubeRBACProxy.image": "kube-rbac-proxy",
    "opentelemetry-operator.manager.autoInstrumentationImage.dotnet": "autoinstrumentation-dotnet",
    "opentelemetry-operator.manager.autoInstrumentationImage.java": "autoinstrumentation-java",
    "opentelemetry-operator.manager.autoInstrumentationImage.nodejs": "autoinstrumentation-nodejs",
    "opentelemetry-operator.manager.autoInstrumentationImage.python": "autoinstrumentation-nodejs",
    "opentelemetry-operator.manager.collectorImage": "sumologic-otel-collector",
    "opentelemetry-operator.manager.image": "opentelemetry-operator",
    "otelcolInstrumentation.statefulset.image": "sumologic-otel-collector",
    "otelevents.image": "sumologic-otel-collector",
    "otellogs.daemonset.initContainers.changeowner.image": "busybox",
    "otellogs.image": "sumologic-otel-collector",
    "pvcCleaner.job.image": "kubernetes-tools-kubectl",
    "sumologic.metrics.collector.otelcol.image": "sumologic-otel-collector",
    "sumologic.metrics.remoteWriteProxy.image": "nginx-unprivileged",
    "sumologic.otelcolImage": "sumologic-otel-collector",
    "sumologic.setup.job.image": "kubernetes-setup",
    "sumologic.setup.job.initContainerImage": "busybox",
    "tailing-sidecar-operator.kubeRbacProxy.image": "kube-rbac-proxy",
    "tailing-sidecar-operator.operator.image": "tailing-sidecar-operator",
    "tailing-sidecar-operator.sidecar.image": "tailing-sidecar",
    "telegraf-operator.image": "telegraf-operator",
    "telegraf-operator.image.sidecarImage": "telegraf",
    "tracesGateway.deployment.image": "sumologic-otel-collector",
    "tracesSampler.deployment.image": "sumologic-otel-collector",
}


def pairwise(iterable: list) -> list:
    """Transforms list in following way:
    [s0 s1 s2 s3 s4 s5] -> [(s0, s1), (s2, s3), (s4, s5)]

    Args: list
        iterable (list): any list for pairs to be created
    Returns:
        list: list with pairs created from the input list
    """
    element = iter(iterable)
    return zip(element, element)


def get_lines(file_path: str) -> list:
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
        file_path (str): path to the output of get_images_sha256.sh, see: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/scripts/get_images_sha256.sh

    Returns:
        list: lines with information about container images from the output of get_images_sha256.sh
    """
    lines = []
    with open(file_path, encoding="utf-8") as file:
        lines = file.read().split("\n")
        if RED_HAT_REGISTRY not in lines[0]:
            lines = lines[1:]
    return lines


def generate_image_lists(image_list_file: str):
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
        component, _ = image_with_tag.removeprefix(RED_HAT_REGISTRY).split(":")
        component = component.upper().replace("-", "_")
        env_name = f"{ENV_PREFIX}{component}"
        related_images.append({"name": env_name, "image": image_with_sha256})
        image_envs.append({"name": env_name, "value": image_with_sha256})
    return related_images, image_envs


def create_new_file_path(file_path: str, create_new_file: bool, extension=".yaml") -> str:
    """Creates path for the file with updated list of components images

    Args:
        file_path (str): path to file in which components images should be updated
        create_new_file: determines whether new yaml should be created or the exiting file should be overwritten

    Returns:
        str: path to file in which changes will be save
    """
    new_path = file_path
    if create_new_file:
        new_path = file_path.replace(extension, f"_new{extension}")
    return new_path


def get_helm_operator_image(images: list) -> dict:
    """Get the settings for Helm Operator in the list of related images

    Args:
        images (str): list of related images

    Returns:
        dict: Helm Operator setting in the list of related images
    """
    operator_image = None
    for image in images:
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
    """Updates components images in bundle/manifests/operator.clusterserviceversion.yaml

    Args:
        file_path (str): absolute path to bundle/manifests/operator.clusterserviceversion.yaml
        new_related_images (list): list of new related images
        new_image_envs (list): list of new environment variables with information about components images
        create_new_file (bool): determines whether new yaml should be created or the exiting file should be overwritten
    """
    with open(file_path, encoding="utf-8") as cluster_service_version_file:
        cluster_service_version = yaml.safe_load(cluster_service_version_file)
        images = cluster_service_version["spec"]["relatedImages"]

        helm_operator_image = get_helm_operator_image(images)
        new_related_images.insert(0, helm_operator_image)
        cluster_service_version["spec"]["relatedImages"] = new_related_images

        containers = cluster_service_version["spec"]["install"]["spec"]["deployments"][0]["spec"]["template"]["spec"]["containers"]
        # pylint: disable=C0200
        for i in range(len(containers)):
            name = containers[i]["name"]
            if name == "operator":
                envs = containers[i]["env"]
                containers[i]["env"] = update_envs(envs, new_image_envs)

    new_file_path = create_new_file_path(file_path, create_new_file)
    with open(new_file_path, "w", encoding="utf-8") as cluster_service_version_file_new:
        yaml.dump(cluster_service_version, cluster_service_version_file_new)


def update_manager(file_path: str, new_image_envs: list, create_new_file):
    """Updates components images in config/manager/manager.yaml

    Args:
        file_path (str): absolute path to config/manager/manager.yaml
        new_image_envs (list): list of new environment variables with information about components images
        create_new_file (bool): determines whether new yaml should be created or the exiting file should be overwritten
    """
    with open(file_path, encoding="utf-8") as manager_file:
        yaml_contents = yaml.safe_load_all(manager_file)

        new_contents = []
        for yaml_content in yaml_contents:
            if yaml_content["kind"] != "Deployment":
                new_contents.append(yaml_content)
            else:
                envs = yaml_content["spec"]["template"]["spec"]["containers"][0]["env"]
                yaml_content["spec"]["template"]["spec"]["containers"][0]["env"] = update_envs(envs, new_image_envs)
                new_contents.append(yaml_content)

        new_file_path = create_new_file_path(file_path, create_new_file)
        with open(new_file_path, "w", encoding="utf-8") as manager_file_new:
            yaml.safe_dump_all(new_contents, manager_file_new)


def update_replace_components_images(image_file_path: str, create_new_file: bool):
    """Updates components images in tests/replace_components_images.sh

    Args:
        file_path (str): path to the output of get_images_sha256.sh, see: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/scripts/get_images_sha256.sh
        create_new_file (bool): determines whether new file should be created or the exiting file should be overwritten
    """
    cmd_lines = []
    for image_with_tag, image_with_sha256 in pairwise(get_lines(image_file_path)):
        public_ecr_image_with_tag = image_with_tag.replace(RED_HAT_REGISTRY, PUBLIC_ECR_REGISTRY)
        docker_output = subprocess.run(["docker", "pull", public_ecr_image_with_tag], stdout=subprocess.PIPE, check=False)

        for line in str(docker_output.stdout).split("\\n"):
            if "Digest" in line:
                digest = line.removeprefix("Digest:").strip()
                component, _ = image_with_tag.removeprefix(RED_HAT_REGISTRY).split(":")
                public_ecr_image_with_sha256 = f"{PUBLIC_ECR_REGISTRY}{component}@{digest}"
                cmd_lines.append(f'sed -i.bak "s#{image_with_sha256}#{public_ecr_image_with_sha256}#g" bundle.yaml')

        new_file_path = create_new_file_path(REPLACE_COMPONENTS_IMAGES_PATH, create_new_file, ".sh")
        with open(new_file_path, "w", encoding="utf-8") as new_file:
            new_file.write(BASH_HEADER)
            for cmd in cmd_lines:
                new_file.write(f"{cmd}\n")


def prepare_components_images_map(file_path: str) -> dict:
    """Prepares components dict containing information about container images

    Args:
        file_path (str): path to the output of get_images_sha256.sh, see: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/scripts/get_images_sha256.sh
        create_new_file (bool): determines whether new file should be created or the exiting file should be overwritten

    Returns
        dict: dict with information about container images
    """
    components_images = {}
    for image_with_tag, image_with_sha256 in pairwise(get_lines(file_path)):
        component, tag = image_with_tag.removeprefix(RED_HAT_REGISTRY).split(":")
        sha = image_with_sha256.split(":")[-1]
        components_images[component] = {"image_with_tag": image_with_tag, "image_with_sha256": image_with_sha256, "tag": tag, "sha": sha}
    return components_images


def update_helm_install(image_file_path: str, create_new_file: bool):
    """Updates helm install command in tests/helm_install.sh"

    Args:
        file_path (str): path to the output of get_images_sha256.sh, see: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/scripts/get_images_sha256.sh
    """
    # pylint: disable=R0912,R0914
    image_config_keys = get_image_keys()
    components_images = prepare_components_images_map(image_file_path)
    set_args = []

    for image_config in image_config_keys:
        image_config_root = ".".join(image_config.split(".")[:-1])

        if image_config_root not in COMPONENTS_CONFIG_MAP:
            print(f"WARNING: missing key in components map, key: {image_config_root}")
            continue

        component = COMPONENTS_CONFIG_MAP[image_config_root]

        if component not in components_images:
            print(f"WARNING: missing key in components_images, key: {component}")
            set_arg = f"  --set {image_config}='' \\"
            set_args.append(set_arg)
            continue

        config = image_config.split(".")[-1]
        if config == "repository":
            if image_config_root + ".registry" not in image_config_keys:
                set_arg = f"  --set {image_config}={PUBLIC_ECR_REGISTRY}{component}@sha256 \\"
            else:
                set_arg = f"  --set {image_config}={component}@sha256 \\"
        elif config == "tag":
            if image_config_root + ".sha" not in image_config_keys:
                tag = components_images[component]["sha"]
            else:
                tag = components_images[component]["tag"]

            set_arg = f"  --set {image_config}={tag} \\"
        elif config == "registry":
            registry = PUBLIC_ECR_REGISTRY[:-1]
            set_arg = f"  --set {image_config}={registry} \\"
        elif config == "sha":
            sha = components_images[component]["sha"]
            set_arg = f"  --set {image_config}={sha} \\"
        elif config == "sidecarImage":
            # special case for telegraf-operator.image.sidecarImage
            component = component.removesuffix("-operator")
            sidecar = components_images[component]["image_with_sha256"]
            set_arg = f"  --set {image_config}={sidecar} \\"
        else:
            set_arg = f"  --set {image_config}='' \\"
        set_args.append(set_arg)

    new_file_path = create_new_file_path(HELM_INSTALL_SCRIPT_PATH, create_new_file, ".sh")
    with open(new_file_path, "w", encoding="utf-8") as new_file:
        file_content = BASH_HEADER + HELM_INSTALL_COMMAND_HEADER + "\n".join(set_args)
        file_content = file_content.removesuffix(" \\")  # remove last \ after last helm install argument
        new_file.write(f"{file_content}\n")


def parse_args():
    """Parses command line arguments"""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--images-file",
        help="file with the list of container images, output of get_images_sha256.sh from sumologic-openshift-images repository",
        required=True,
    )
    parser.add_argument(
        "--operator-repo-dir",
        help="path to directory with Helm Operator repository, e.g. /operator/",
        default="./",
    )
    parser.add_argument(
        "--create-new-file",
        help="determines whether new file should be created or the exiting file should be overwritten",
        default=True,
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    related_images_list, image_envs_list = generate_image_lists(args.images_file)

    csv_path = os.path.join(args.operator_repo_dir, CLUSTER_SERVICE_VERSION_PATH)
    update_cluster_service_version(csv_path, related_images_list, image_envs_list, args.create_new_file)

    m_path = os.path.join(args.operator_repo_dir, MANAGER_PATH)
    update_manager(m_path, image_envs_list, args.create_new_file)

    update_replace_components_images(args.images_file, args.create_new_file)

    update_helm_install(args.images_file, args.create_new_file)
