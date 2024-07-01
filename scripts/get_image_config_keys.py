#!/usr/bin/env python

"""Gets list of image configuration keys for the Sumo Logic Kubernetes Collection Helm Chart"""

import re
import urllib.request
import yaml
from yaml.loader import SafeLoader


def values_to_dictionary(url: str) -> dict:
    """Downloads and reads given url as values.yaml and returns it as dict

    Args:
        path (str): path to the value.yaml

    Returns:
        dict: values.yaml as dict
    """
    with urllib.request.urlopen(url) as response:
        values = response.read().decode(response.headers.get_content_charset())
        values = re.sub(r"(\[\]|\{\})\n(\s+# )", r"\n\2", values, flags=re.M)
        values = re.sub(r"^(\s+)# ", r"\1", values, flags=re.M)
        return yaml.load(values, Loader=SafeLoader)


def extract_keys(dictionary: dict) -> list:
    """Extracts list of keys from the dictionary and returns as list.
    Uses dot as separator for nested dicts.

    Args:
        dictionary (dict): dictionary to extract keys from

    Returns:
        list: list of extracted keys
    """
    keys = []
    if not isinstance(dictionary, dict):
        return None

    if not dictionary:
        return None

    for key, value in dictionary.items():
        more_keys = extract_keys(value)

        if more_keys is None:
            keys.append(key)
        else:
            keys.extend(f"{key}.{mk}" for mk in more_keys)

    return keys


# known_image_keys contains list of image configuration keys which are not available in values.yaml
known_image_keys = [
    "tailing-sidecar-operator.sidecar.image.repository",
    "tailing-sidecar-operator.sidecar.image.tag",
    "tailing-sidecar-operator.operator.image.repository",
    "tailing-sidecar-operator.operator.image.tag",
    "tailing-sidecar-operator.kubeRbacProxy.image.tag",
    "opentelemetry-operator.manager.image.tag",
    "opentelemetry-operator.kubeRBACProxy.image.tag",
    "opentelemetry-operator.manager.collectorImage.tag",
    "telegraf-operator.image.tag",
    "kube-prometheus-stack.prometheus.prometheusSpec.image.tag",
    "kube-prometheus-stack.prometheus.prometheusSpec.image.sha",
    "kube-prometheus-stack.prometheus-node-exporter.image.tag",
    "kube-prometheus-stack.prometheusOperator.thanosImage.tag",
    "kube-prometheus-stack.prometheusOperator.thanosImage.sha",
    "kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.tag",
    "kube-prometheus-stack.prometheusOperator.prometheusConfigReloaderImage.sha",
    "kube-prometheus-stack.prometheusOperator.image.tag",
    "kube-prometheus-stack.prometheusOperator.image.sha",
    "metrics-server.image.tag",
]

not_needed_image_keys = ["Percentage", "falco", "pullPolicy", "pullSecrets", "imagePullSecrets", "debug.sumologicMock.image", "otellogswindows", "testFramework"]
needed_image_keys = ["image", "tag", "repository"]


def get_image_keys() -> list:
    """Gets list of image configuration keys for the Sumo Logic Kubernetes Collection Helm Chart

    Returns:
        list: list of image configuration keys for the Sumo Logic Kubernetes Collection Helm Chart
    """
    values_url = "https://raw.githubusercontent.com/SumoLogic/sumologic-kubernetes-collection/main/deploy/helm/sumologic/values.yaml"

    values = values_to_dictionary(values_url)
    values_keys = extract_keys(values)
    image_keys = []

    for key in values_keys:
        needed_key = True
        for not_needed in not_needed_image_keys:
            # to eliminate keys which are related to image but not related to image repository and tag, e.g.
            # sumologic.metrics.remoteWriteProxy.image.pullPolicy
            # kube-prometheus-stack.global.imagePullSecrets
            if not_needed in key:
                needed_key = False
                break

        for needed in needed_image_keys:
            if needed in key and needed_key:
                image_keys.append(key)
                break

    image_keys.extend(known_image_keys)
    image_keys.sort()
    return image_keys


def generate_components_map(keys) -> list:
    """Generates image configuration keys for components map used in update_images.py

    Args:
        keys (list): list of Helm Chart image configuration keys from values.yaml
    Returns:
        list: image configuration keys for components map used in update_images.py
    """
    unique_root_keys = set()
    for key in keys:
        keys_parts = key.split(".")[:-1]
        new_key = ".".join(keys_parts)
        unique_root_keys.add(f'"{new_key}": "",')

    return sorted(unique_root_keys)


if __name__ == "__main__":
    print("---------- Helm Chart image configuration keys from values.yaml, used in watches.yaml ---------------")
    image_config_keys = get_image_keys()
    print("\n".join(image_config_keys))
    print("---------- Image configuration keys for components map used in update_images.py ---------------------")
    components_map_keys = generate_components_map(image_config_keys)
    print("\n".join(sorted(components_map_keys)))
