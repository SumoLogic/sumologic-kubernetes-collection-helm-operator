# Update

This document describes steps required to update the Sumo Logic Kubernetes Collection Helm Operator.

## Components images update

1. Build and certify components container images, make steps from [this][container_cerification] list.

1. Save output of `make verify` from [sumologic-openshift-images][sumologic-openshift-images] to the file, e.g.

   ```bash
   make verify > images.txt
   ```

1. Check the content of `images.txt` and make sure that all images are available - no `MISSING` entries in the `images.txt`.

1. Check the content of `images.txt` and remove duplicated entries for single component (multiple versions of container images for single component).
   At this moment it is known that we have two versions for `busybox` and `kube-rbac-proxy`, remove one of the version leaving the only one.

   Example transformation:
   initial version:

   ```txt
    registry.connect.redhat.com/sumologic/busybox:1.36.0-ubi
    registry.connect.redhat.com/sumologic/busybox:@sha256:ceace4beb7db070ae30589a7ef11d68b0435916d6220abccac9396618c2514ed
    registry.connect.redhat.com/sumologic/busybox:latest-ubi
    registry.connect.redhat.com/sumologic/busybox:@sha256:bc4b632a545fb8b797aa99d1e7cee8c042332c7cc849df30c945a8a7bd9f6c3a
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:v0.11.0-ubi
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:@sha256:57a1e908005bd7ba6007bdf08db5a14fc71a467f80ebfd7de22b83ae80d325e7
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:v0.15.0-ubi
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:@sha256:1153a4592746b05e019bde4d818d176ff9350c013f84d49829032540de882841
   ```

   transformed version:

   ```txt
    registry.connect.redhat.com/sumologic/busybox:1.36.0-ubi
    registry.connect.redhat.com/sumologic/busybox:@sha256:ceace4beb7db070ae30589a7ef11d68b0435916d6220abccac9396618c2514ed
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:v0.15.0-ubi
    registry.connect.redhat.com/sumologic/kube-rbac-proxy:@sha256:1153a4592746b05e019bde4d818d176ff9350c013f84d49829032540de882841
   ```

1. From the root directory of the Sumo Logic Kubernetes Collection Helm Operator repository run:

   ```bash
   make update-components-images IMAGES_FILE=<PATH_TO_IMAGES.TXT> 
   ```

   This will create new version of following files containing references to components images:
    - `bundle/manifests/operator.clusterserviceversion.yaml`
    - `config/manager/manager.yaml`
    - `tests/replace_components_images.sh`
    - `tests/helm_install.sh`

1. Verify content of newly created files and correct them if needed:
    - `bundle/manifests/operator.clusterserviceversion_new.yaml`
    - `config/manager/manager_new.yaml`
    - `tests/replace_components_images_new.sh`
    - `tests/helm_install_new.sh`

1. Replace old version of files with newly generated files.

   ```bash
   mv bundle/manifests/operator.clusterserviceversion_new.yaml bundle/manifests/operator.clusterserviceversion.yaml
   mv config/manager/manager_new.yaml config/manager/manager.yaml
   mv tests/replace_components_images_new.sh tests/replace_components_images.sh
   mv tests/helm_install_new.sh tests/helm_install.sh
   ```

1. Generate new version of [watches.yaml][watches.yaml]:

   ```bash
   make generate-watches
   ```

   It will generated `watches_new.yaml`

1. Add new appropriate transformations of `RELATED_IMAGE_<COMPONENT>` variables for new keys in the `watches_new.yaml`.
   Configuration in `watches.yaml` should set image related keys from `values.yaml` using environmental variables containing image with `sha256`.

1. Replace old version of watches.yaml with the new version:

   ```bash
   mv watches_new.yaml watches.yaml
   ```

1. Prepare the commit with component images update.

[container_cerification]: https://github.com/SumoLogic/sumologic-openshift-images?tab=readme-ov-file#container-certification
[sumologic-openshift-images]: https://github.com/SumoLogic/sumologic-openshift-images
[watches.yaml]: https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/watches.yaml

## Helm operator image update

TODO

## Sumo Logic Kubernetes Collection Helm Chart update

TODO