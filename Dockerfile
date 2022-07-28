# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.11.0

ARG VERSION=${VERSION}
ARG RELEASE_NUMBER=${RELEASE_NUMBER}
ARG HELM_VERSION=3.2.4

LABEL name="Sumologic Kubernetes Collection Helm Operator"
LABEL maintainer="collection@sumologic.com"
LABEL vendor="sumologic"
LABEL version=${VERSION}
LABEL release=${RELEASE_NUMBER}
LABEL summary="Sumologic Kubernetes Collection Helm Operator for the Sumo Logic Kubernetes Collection Helm Chart"
LABEL description="Sumologic Kubernetes Collection Helm Operator deploys https://github.com/SumoLogic/sumologic-kubernetes-collection"

USER root

RUN microdnf update && microdnf install -y tar gzip wget patch && microdnf clean all

RUN wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" && \
    tar -xzvf "helm-v${HELM_VERSION}-linux-amd64.tar.gz" && \
    mv linux-amd64/helm /usr/local/bin/helm

ENV HOME=/opt/helm
COPY licenses /licenses
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts/sumologic-kubernetes-collection/deploy/helm/sumologic  ${HOME}/helm-charts/sumologic

# patch for Telegraf Operator Helm chart
# can be removed when Telegraf Operator is updated in sumologic kubernetes collection to version with
# https://github.com/influxdata/helm-charts/pull/349
WORKDIR ${HOME}/helm-charts/sumologic
RUN helm dependency update && cd charts && for subchart in *.tgz; do tar -xf "${subchart}" && rm -f "${subchart}"; done;
RUN sed -i "s#{{ .Values.image.repository }}:{{ .Chart.AppVersion }}#{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}#g" charts/telegraf-operator/templates/deployment.yaml

# patch for prometheus specification to use sha in image path
COPY patches/kube-prometheus-stack/12.10.0/prometheus.patch /tmp/prometheus.patch
RUN patch charts/kube-prometheus-stack/templates/prometheus/prometheus.yaml /tmp/prometheus.patch && \
    rm /tmp/prometheus.patch

WORKDIR ${HOME}
USER ${USER_UID}
