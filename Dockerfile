# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.6.1

ARG VERSION=${VERSION}
ARG RELEASE_NUMBER=${RELEASE_NUMBER}

LABEL name="Sumologic Kubernetes Collection Helm Operator"
LABEL maintainer="collection@sumologic.com"
LABEL vendor="sumologic"
LABEL version=${VERSION}
LABEL release=${RELEASE_NUMBER}
LABEL summary="Sumologic Kubernetes Collection Helm Operator for the Sumo Logic Kubernetes Collection Helm Chart"
LABEL description="Sumologic Kubernetes Collection Helm Operator deploys https://github.com/SumoLogic/sumologic-kubernetes-collection"

ENV HOME=/opt/helm
COPY licenses /licenses
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts/sumologic-kubernetes-collection/deploy/helm/sumologic  ${HOME}/helm-charts/sumologic
WORKDIR ${HOME}
