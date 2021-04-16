# Build the manager binary
FROM quay.io/operator-framework/helm-operator:v1.6.1

ENV HOME=/opt/helm
COPY watches.yaml ${HOME}/watches.yaml
COPY helm-charts/sumologic-kubernetes-collection/deploy/helm/sumologic  ${HOME}/helm-charts/sumologic
WORKDIR ${HOME}
