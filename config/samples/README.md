# Example configurations for Helm Operator

- [default_openshift.yaml](default_openshift.yaml) - contains minimal set of parameters required for OpenShift
- [all_enabled_openshift.yaml](all_enabled_openshift.yaml) - contains minimal set of parameters required for OpenShift
to enable all subcharts of Sumo Logic Kubernetes Collection Helm Chart
- [all_enabled_openshift_with_images.yaml](all_enabled_openshift_with_images.yaml) - contains minimal set of parameters required for OpenShift
to enable all subcharts of Sumo Logic Kubernetes Collection Helm Chart and [UBI](https://developers.redhat.com/products/rhel/ubi) based container images in configuration
- [full_config_openshift_with_images.yaml](full_config_openshift_with_images.yaml) - contains all parameters from values.yaml for Sumo Logic Kubernetes Collection Helm Chart adjusted to OpenShift environment with [UBI](https://developers.redhat.com/products/rhel/ubi) based images in configuration
- [full_config.yaml](full_config.yaml) - contains all parameters from values.yaml for Sumo Logic Kubernetes Collection Helm Chart
- [receiver_mock_openshift.yaml](receiver_mock_openshift.yaml) - contains all parameters from values.yaml for Sumo Logic Kubernetes Collection Helm Chart adjusted to OpenShift environment and parameters required to test with receiver-mock
