# sumologic-kubernetes-collection-helm-operator

Sumo Logic Kubernetes Collection Helm Operator for the [Sumo Logic Kubernetes Collection Helm Chart][helm-chart-repo].

**Supported platforms:**

- OpenShift 4.6
- OpenShift 4.7

## Installation

### From OperatorHub

- Install Sumo Logic Kubernetes Collection Helm Operator from Operator Hub

- Create `SumologicCollection` resource with proper configuration, see [Configuration](#configuration) section, e.g.

  ```bash
  kubeclt apply -f config/samples/default_openshift.yaml
  ```

### Using bundle.yaml

- Deploy Sumo Logic Kubernetes Collection Helm Operator using [bundle.yaml](bundle.yaml)

  ```bash
  kubectl apply -f bundle.yaml
  ```

- Create `SumologicCollection` resource with proper configuration, see [Configuration](#configuration) section, e.g.

  ```bash
  kubeclt apply -f config/samples/default_openshift.yaml
  ```

## Configuration

Configuration for Sumo Logic Kubernetes Collection Helm Operator needs to be provided in `SumologicCollection` resource.
Custom Resource Definition for `SumologicCollection` is defined in
[helm-operator.sumologic.com_sumologiccollections.yaml][crd].

`SumologicCollection.spec` allows to configure all parameters from [values.yaml][values.yaml] for the
[Sumo Logic Kubernetes Collection Helm Chart][helm-chart-repo].
All possible parameters with descriptions can be found in [Configuration][helm-chart-configuration]
section for Sumo Logic Kubernetes Collection Helm Chart.

Example configurations for Sumo Logic Kubernetes Collection Helm Operator are available in [config/samples](config/samples) directory.

## License

This project is released under the [Apache 2.0 License](licenses/LICENSE).

## Contributing

Please refer to our [Contributing](CONTRIBUTING.md) documentation to get started.

[helm-chart-repo]: https://github.com/SumoLogic/sumologic-kubernetes-collection
[helm-chart-configuration]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2.1/deploy/helm/sumologic/README.md#configuration
[crd]: config/crd/bases/helm-operator.sumologic.com_sumologiccollections.yaml
[values.yaml]: https://github.com/SumoLogic/sumologic-kubernetes-collection/blob/release-v2.1/deploy/helm/sumologic/values.yaml
