# Update

This document describes steps required to update the Sumo Logic Kubernetes Collection Helm Operator.

## Components images update

1. Build and certify components container images, make steps from [this][container_cerification] list.

1. Save output of `make verify` from [sumologic-openshift-images][sumologic-openshift-images] to the file, e.g.

   ```bash
   make verify > images.txt
   ```

1. Check the content of `images.txt` and make sure that all images are available - no `MISSING` entries in the `images.txt`, e.g.

   ```bash
   cat images.txt | grep 'MISSING'
   ```

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
   chmod +x tests/helm_install.sh
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

[container_cerification]: https://github.com/SumoLogic/sumologic-openshift-images/blob/main/README.md#container-certification
[sumologic-openshift-images]: https://github.com/SumoLogic/sumologic-openshift-images
[watches.yaml]: https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/watches.yaml

## Sumo Logic Kubernetes Collection Helm Chart update

 1. Update submodule with the reference to Sumo Logic Kubernetes Collection Helm Chart use following commands:

   ```bash
   cd helm-charts/sumologic-kubernetes-collection
   git fetch --tags
   git checkout <TAG FROM HELM CHART REPOSITORY>
   cd ..
   git add sumologic-kubernetes-collection
   git commit -m "chore: update Sumologic Kubernetes Collection Helm Chart to <HELM CHART VERSION>"
   git push origin <BRANCH NAME>
   ```

1. Update Sumo Logic Kubernetes Collection Helm Chart version in [tests](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/tree/main/tests).
1. Update command used in tests to install the Helm Chart and example configurations for the Helm Operator according to changes in the new version of the Helm Chart, update following files:

   - [helm_install.sh](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/tests/helm_install.sh)
   - [test_openshift.yaml](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/tests/test_openshift.yaml)
   - files in [samples directory](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/tree/main/config/samples)
1. Update example configuration in [bundle/manifests/operator.clusterserviceversion.yaml](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/bundle/manifests/operator.clusterserviceversion.yaml)

   ```bash
   cat config/samples/default_openshift.yaml | python3 -c 'import sys, yaml, json; json.dump([yaml.safe_load(sys.stdin)], sys.stdout, indent=4)' > config/samples/default_openshift.json
   EXAMPLE=$(cat config/samples/default_openshift.json) yq eval '.metadata.annotations.alm-examples |= strenv(EXAMPLE)' -P -i bundle/manifests/operator.clusterserviceversion.yaml
   ```

1. Test the Sumo Logic Kubernetes Collection Helm Chart with UBI based container images and fix issues.
   To test you can use:

   ```bash
   make deploy-helm-chart
   ```

1. Build Helm Operator image and test the Sumo Logic Kubernetes Collection Helm Operator, fix occurring issues.
   To test you can use following commands:

   ```bash
   echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
   export IMG=ghcr.io/<YOUR GITHUB ID>/sumologic-kubernetes-collection-helm-operator:<IMAGE TAG>
   make docker-build IMG="${IMG}"
   docker push "${IMG}"
   make deploy-helm-operator-using-public-images IMG="${IMG}"
   ```

## bundle.yaml update

To update [bundle.yaml](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/bundle.yaml) use following command:

```bash
make generate-bundle
mv generated_bundle.yaml bundle.yaml 
```

## Helm operator image update

1. Update dependencies in [Dockerfile](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/Dockerfile)

1. Update supported OpenShift versions, please see [com.redhat.openshift.versions](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/315922c7b75d2359c674505833da40c25aa5aae3/bundle/metadata/annotations.yaml#L18) annotation.

## Prepare new version of Helm Operator

1. Prepare new release, using the instruction below:

   - Prepare release pull request with changes necessary to create new version of Helm operator
      (update version, names, description, creation date),
      see [example pull request](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/pull/35).

   - Create the release tag for commit with Helm Chart version change, e.g.

      ```bash
      git tag -a v2.1.1-0-rc.0 -m "Release v2.1.1-0-rc.0"
      ```

   - Push the release tag, e.g.

      ```bash
      git push origin v2.1.1-0-rc.0
      ```

   - For major and minor version change prepare release branch, e.g.

       ```bash
       git checkout -b release-v2.1.0
       git push origin release-v2.1.0
       ```

   - Cut the release
      - Go to https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/releases and click "Draft a new release".
      - Compare changes since the last release.
      - Prepare release notes.

1. Test new Helm Operator version, please use [this](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/docs/dev/test.md) instruction (please omit first step and use images created for the new Helm Operator version).

1. Submit Helm Operator image for certification in [http://connect.redhat.com/](http://connect.redhat.com/).

1. Update Helm Operator image in ClusterServiceVersion, please see example [pull request](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/pull/129).

1. Prepare pull request to [certified-operators](https://github.com/redhat-openshift-ecosystem/certified-operators), please see [example pull request](https://github.com/redhat-openshift-ecosystem/certified-operators/pull/2754).

1. Prepare pull request to [redhat-marketplace-operators](https://github.com/redhat-openshift-ecosystem/redhat-marketplace-operators), please see [example pull request](https://github.com/redhat-openshift-ecosystem/redhat-marketplace-operators/pull/546).

1. Make sure that new version of Helm Operator is available on the desired platforms.
