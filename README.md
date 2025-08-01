# sumologic-kubernetes-collection-helm-operator

Sumo Logic Kubernetes Collection Helm Operator for the [Sumo Logic Kubernetes Collection Helm Chart][helm-chart-repo].

This project was generated using [Operator SDK][operator-sdk].

**Supported platforms:**

| Sumo Logic Kubernetes Collection Helm Operator version | OpenShift version                                                      |
|--------------------------------------------------------|------------------------------------------------------------------------|
| v4.13.0-2                                              | 4.13<br/>4.14<br/>4.15<br/>4.16<br/>4.17<br/>4.18<br/><br>4.19<br/>.   |
| v4.13.0-1                                              | 4.13<br/>4.14<br/>4.15<br/>4.16<br/>4.17<br/>4.18<br/>                 |
| v4.13.0-0 [**Deprecated]                               | 4.13<br/>4.14<br/>4.15<br/>4.16<br/>4.17<br/>4.18<br/>                 | 
| v4.9.0-3                                               | 4.13<br/>4.14<br/>4.15<br/>4.16<br/>4.17<br/>4.18<br/>                 |
| v4.9.0-1 [**Deprecated**]                              | 4.13<br/>4.14<br/>4.15                                                 | 
| v2.19.1-0                                              | 4.11<br/>4.12 [special configuration for OpenShift v4.12][config_4.12] |
| v2.17.0-0                                              | 4.8<br/>4.9<br/>4.10                                                   |
| v2.1.4-0                                               | 4.6<br/>4.7                                                            |

**Note:** using Sumo Logic Kubernetes Collection Helm Operator on OpenShift v4.12 requires special configuration with `PodSecurityPolicy` disabled
because`PodSecurityPolicy` was completely removed on Kubernetes 1.25+.

Following changes needs to be added to configuration to use Sumo Logic Kubernetes Collection Helm Operator on OpenShift v4.12:

```yaml
kube-prometheus-stack:
  global:
    rbac:
      pspEnabled: false
  kube-state-metrics:
    podSecurityPolicy:
      enabled: false
  prometheus-node-exporter:
    rbac:
      pspEnabled: false
```

Example configuration for Sumo Logic Kubernetes Collection Helm Operator on OpenShift v4.12 is available [here][config_4.12].

[config_4.12]: config/samples/default_openshift_4_12.yaml

## Installation

### Prerequisites

- If you don’t already have a Sumo account, you can create one by clicking the Free Trial button on https://www.sumologic.com/.
  To set up Sumo Logic Kubernetes collection it is required to have an [Access ID and Access Key][access_keys].
  with [Manage Collectors][role_capabilities] capability.

- Sumo Logic Kubernetes Collection Helm Operator deploys [Sumo Logic Kubernetes Collection Helm Chart][helm-chart-repo] so before starting with Sumo Logic Kubernetes Collection Helm Operator please review [documentation][helm-docs] for Helm chart.

- To interact with Kubernetes cluster please install [kubectl][kubectl_install] or [OpenShift CLI][oc_install].

[access_keys]: https://help.sumologic.com/Manage/Security/Access-Keys
[role_capabilities]: https://help.sumologic.com/Manage/Users-and-Roles/Manage-Roles/05-Role-Capabilities#data-management
[helm-chart-repo]: https://github.com/SumoLogic/sumologic-kubernetes-collection
[helm-docs]: https://github.com/SumoLogic/sumologic-kubernetes-collection/tree/release-v2.1/deploy/docs
[kubectl_install]: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
[oc_install]: https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html

### Configuration

Configuration for Sumo Logic Kubernetes Collection Helm Operator needs to be provided in `SumologicCollection` resource.
Custom Resource Definition for `SumologicCollection` is defined in
[helm-operator.sumologic.com_sumologiccollections.yaml][crd].

`SumologicCollection.spec` allows to configure all parameters from [values.yaml][values.yaml] for the
[Sumo Logic Kubernetes Collection Helm Chart][helm-chart-repo].
All possible parameters with descriptions can be found in [Configuration][helm-chart-configuration]
section for Sumo Logic Kubernetes Collection Helm Chart.

Example configurations for Sumo Logic Kubernetes Collection Helm Operator are available in [config/samples](config/samples) directory.

### Installation from Red Hat Marketplace

Detailed instruction for installation from Red Hat Marketplace is available in [this](docs/install_from_redhat_marketplace.md) documentation.

### Installation using bundle.yaml

- Deploy Sumo Logic Kubernetes Collection Helm Operator using [bundle.yaml](bundle.yaml)

  ```bash
  kubectl apply -f bundle.yaml
  ```

- Create `SumologicCollection` resource with proper configuration, see [Configuration](#configuration) section, e.g.

  ```bash
  kubeclt apply -f config/samples/default_openshift.yaml
  ```

### Verification

Verify that Pod related to Sumologic Kubernetes Collection are running,
for default configuration you should see similar list of Pods:

```bash
$ kubectl get pods -n openshift-operators
NAME                                                   READY   STATUS    RESTARTS   AGE
collection-kube-state-metrics-75bfd69587-5gchw                  1/1     Running   0               3m
collection-opentelemetry-operator-5f99bfbf4d-v4v2l              2/2     Running   0               3m
collection-prometheus-node-exporter-4rnqv                       1/1     Running   0               2m59s
collection-prometheus-node-exporter-8wfw7                       1/1     Running   0               2m59s
collection-prometheus-node-exporter-9g7c5                       1/1     Running   0               3m
collection-prometheus-node-exporter-k6xfz                       1/1     Running   0               3m
collection-prometheus-node-exporter-lh88z                       1/1     Running   0               3m
collection-prometheus-node-exporter-s4bql                       1/1     Running   0               2m59s
collection-prometheus-node-exporter-xgrrd                       1/1     Running   0               2m59s
collection-prometheus-node-exporter-zq4ld                       1/1     Running   0               2m59s
collection-sumologic-metrics-collector-0                        1/1     Running   0               2m36s
collection-sumologic-metrics-targetallocator-6db5f4dc9d-8dzd5   1/1     Running   0               2m36s
collection-sumologic-otelcol-events-0                           1/1     Running   0               3m
collection-sumologic-otelcol-instrumentation-0                  1/1     Running   0               3m
collection-sumologic-otelcol-instrumentation-1                  1/1     Running   0               2m45s
collection-sumologic-otelcol-instrumentation-2                  1/1     Running   0               2m45s
collection-sumologic-otelcol-logs-0                             1/1     Running   0               3m
collection-sumologic-otelcol-logs-1                             1/1     Running   0               2m45s
collection-sumologic-otelcol-logs-2                             1/1     Running   0               2m45s
collection-sumologic-otelcol-logs-collector-7562c               1/1     Running   0               3m
collection-sumologic-otelcol-logs-collector-8phqz               1/1     Running   0               3m
collection-sumologic-otelcol-logs-collector-9xscf               1/1     Running   0               3m
collection-sumologic-otelcol-logs-collector-b96f6               1/1     Running   0               3m
collection-sumologic-otelcol-logs-collector-kq924               1/1     Running   0               2m59s
collection-sumologic-otelcol-logs-collector-l8nsh               1/1     Running   0               3m
collection-sumologic-otelcol-logs-collector-pmdn7               1/1     Running   0               3m
collection-sumologic-otelcol-logs-collector-tp9xx               1/1     Running   0               3m
collection-sumologic-otelcol-metrics-0                          1/1     Running   0               3m
collection-sumologic-otelcol-metrics-1                          1/1     Running   0               2m45s
collection-sumologic-otelcol-metrics-2                          1/1     Running   0               2m45s
collection-sumologic-traces-gateway-876fb5c65-mkzqs             1/1     Running   0               3m
collection-sumologic-traces-sampler-ff74c5cf4-wlsw4             1/1     Running   0               3m
sumologic-helm-operator-7bcd46469b-nglnz                        2/2     Running   0               9m36s
```

### Viewing Data In Sumo Logic

Once you have completed installation, you can [install the Kubernetes App and view the dashboards][install_apps]
or [open a new Explore tab][k8s_tab] in Sumo Logic.

[install_apps]: https://help.sumologic.com/07Sumo-Logic-Apps/10Containers_and_Orchestration/Kubernetes/Install_the_Kubernetes_App%2C_Alerts%2C_and_view_the_Dashboards
[k8s_tab]: https://help.sumologic.com/Observability_Solution/Kubernetes_Solution/Navigate_your_Kubernetes_environment

## License

This project is released under the [Apache 2.0 License](licenses/LICENSE).

## Contributing

Please refer to our [Contributing](CONTRIBUTING.md) documentation to get started.

[helm-chart-repo]: https://github.com/SumoLogic/sumologic-kubernetes-collection
[helm-chart-configuration]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2.1/deploy/helm/sumologic/README.md#configuration
[crd]: config/crd/bases/helm-operator.sumologic.com_sumologiccollections.yaml
[values.yaml]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2.1/deploy/helm/sumologic/values.yaml
[operator-sdk]: https://github.com/operator-framework/operator-sdk
