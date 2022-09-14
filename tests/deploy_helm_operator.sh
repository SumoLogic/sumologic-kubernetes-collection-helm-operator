#!/usr/bin/env bash

date

readonly ROOT_DIR="$(dirname "$(dirname "${0}")")"

# shellcheck disable=SC1090
source "${ROOT_DIR}/tests/functions.sh"

readonly DEPLOYMENT_TYPE="${DEPLOYMENT_TYPE:=default}"
readonly IMG="${IMG:=public.ecr.aws/sumologic/sumologic-kubernetes-collection-helm-operator:2.14.1-0-rc.0}"
readonly NAMESPACE="sumologic-system"
readonly TIME=900

# Change container registry in bundle.yaml to public.ecr.aws and ghcr.io to not login to registry.connect.redhat.com
sed -i.bak "s#registry.connect.redhat.com/sumologic/kubernetes-setup@sha256:96de6f9352cabbddf7f0cb537108b41183e827be27d100ba6566bbb0d1c0f01d#public.ecr.aws/sumologic/kubernetes-setup@sha256:0039bd5e77d922b82293702fe5a81be78185e49c4ebd5039aa26e1d36f3619f3#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/node-exporter@sha256:7acec4473ddf508514dca1d08335cfd071e345d7eca660793d59e09ef9f0491f#public.ecr.aws/sumologic/node-exporter@sha256:685b59ebf0ce3c7e32f9de83359fdfc66a5143660f96b82c8ef8964c727bb2e5#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-state-metrics@sha256:094ad2a0136b7ded390763dd9c63acf282903d49d07385a806160e2cdad89345#public.ecr.aws/sumologic/kube-state-metrics@sha256:18fb3800783b26db6a131ab846a28186dc0e9c12401e72a12ad99bf11d33186a#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus-operator@sha256:79769d200a6d5b977fed1c05e1021ad83b89b817b30ab24131cf9d262f4b86fc#public.ecr.aws/sumologic/prometheus-operator@sha256:27384cfcd3bf32bee7584332b82188a7da5780dfc33f33ea8aa3afd2c10ca948#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus-config-reloader@sha256:bbc4ae3f769172545cd0ee7862066e6dab75045370f099e4bdacc344fe7c46a7#public.ecr.aws/sumologic/prometheus-config-reloader@sha256:7fc45d6c4cfa93363751277d3b761d30b1857be70d2c83568cabc36b19f47914#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus@sha256:f9fa9040c8e134a1e6be81dd6e14f1d1dee3e0651e4039cf9580e8e9cfbf8455#public.ecr.aws/sumologic/prometheus@sha256:47004a8f74aab2353e8d0ac5725e4206a53305e7766a19b1cbb1dd770c2e8e36#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/thanos@sha256:9772a1f329596cc4f0934b044f63b2c4f6e93952a44f1c68cc09f1a61f7f309a#public.ecr.aws/sumologic/thanos@sha256:3f5b6df4e423475f912cb2e48e55e89235c68b473b53e202b246e024307ea965#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/metrics-server@sha256:4a60b5f706e4ae2b79c91a90dd4d23d8fd87408beed9f0a14a29d639bbcb8a35#public.ecr.aws/sumologic/metrics-server@sha256:c4a41f333bf942fa21c08d0c5b1b6b649f878341886ba59593b73d808ad9d3b0#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-rbac-proxy@sha256:c1ea7aa4873a78d8d506e4dab8c281c6c72a65d1374312cd76b27ed881b043b5#public.ecr.aws/sumologic/kube-rbac-proxy@sha256:d47164d94803408071d68227798eadd3692d6705a6bcd55ccb31b025fc36d1d8#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-rbac-proxy:v0.5.0-ubi#public.ecr.aws/sumologic/kube-rbac-proxy:v0.5.0-ubi#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/tailing-sidecar-operator@sha256:e8b1d815666b69ab3047bc1d81afb51fb03caa99ca382c3f81949488072cd748#ghcr.io/sumologic/tailing-sidecar-operator@sha256:5829d4e03c0a473d27fba56774a6a0f19aed84e2ae1e501d706bd50b60241b6c#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/tailing-sidecar@sha256:34c7e3d6a15dcbb72ce498744baa5e6b4663af4838a6f6429458e2d73ecb4d09#ghcr.io/sumologic/tailing-sidecar@sha256:aff9aef3bbe41ffe1fc8e4b280533405a6065d48f7e3ff617458cd0a8e3b4ab5#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/telegraf-operator@sha256:e27d7a4d7c9947685641df6e238fbae5a48993530bd5c2c4bf6d7385c262715e#public.ecr.aws/sumologic/telegraf-operator-ubi@sha256:5ec540691a2db5032e117ff6f883ef75bfdd94b529d84fcb30f04acc5313724d#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/telegraf@sha256:ca396dad12a289aea9136da713020d31b179e9f49aae61c48332d61086d1d059#public.ecr.aws/sumologic/telegraf@sha256:f9883d1e9e0baf0d326a7c2c5503e011b36bf0bff22d6470c2f6d2b39fdd11fb#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kubernetes-fluentd@sha256:fdc41e366fa24046eb023ab76ca3bb571cdde5b35ea75ccdd9b9435091266562#public.ecr.aws/sumologic/kubernetes-fluentd@sha256:dca1e3854b2e7fd2540c53c8092e3105c6a4bdcce426035a2cd5fed28a8690bf#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/fluent-bit@sha256:f0457d3247567eb0bed47ea25c4b7c98b2d7bfcb297b5a1f580ec223b6777e2c#public.ecr.aws/sumologic/fluent-bit@sha256:5f676040c66bd3d5c6309366beeb4c7ca91e0a70df3995ef19cea1adfec9b5ce#g" bundle.yaml

# Change image in bundle.yaml to imag
sed -i.bak "s#public.ecr.aws/sumologic/sumologic-kubernetes-collection-helm-operator:2.14.1-0-rc.0#${IMG}#g" bundle.yaml

kubectl apply -f bundle.yaml

wait_for_resource "${NAMESPACE}" "${TIME}" deployment.apps/sumologic-helm-operator
kubectl wait --for=condition=ready --timeout 300s pod -l control-plane=sumologic-kubernetes-collection-helm-operator -n sumologic-system

kubectl apply -f tests/test_openshift.yaml -n sumologic-system

wait_for_collection_resources "${NAMESPACE}" "${TIME}"

helm get manifest -n "${NAMESPACE}" test-openshift > helm_operator_templates.yaml

kubectl delete -f tests/test_openshift.yaml -n sumologic-system
make undeploy

kubectl delete ns "${NAMESPACE}"
wait_for_ns_termination "${NAMESPACE}" "${TIME}"
