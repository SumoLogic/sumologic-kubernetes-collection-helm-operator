#!/usr/bin/env bash

sed -i.bak "s#registry.connect.redhat.com/sumologic/autoinstrumentation-dotnet@sha256:e99182dd7c0c8611cdc852bcc2e0866e635077b50b7e739022269cc8721f4109#public.ecr.aws/sumologic/autoinstrumentation-dotnet@sha256:e99182dd7c0c8611cdc852bcc2e0866e635077b50b7e739022269cc8721f4109#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/autoinstrumentation-java@sha256:7fdb03d08173964f234f8262e872f67a42527173195b2e39cf56581c6a784f92#public.ecr.aws/sumologic/autoinstrumentation-java@sha256:7fdb03d08173964f234f8262e872f67a42527173195b2e39cf56581c6a784f92#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/autoinstrumentation-nodejs@sha256:f6d2109be49cbfc725ca7f0ebbc06b74c699e55a7f18690e9959de8bcf294028#public.ecr.aws/sumologic/autoinstrumentation-nodejs@sha256:f6d2109be49cbfc725ca7f0ebbc06b74c699e55a7f18690e9959de8bcf294028#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/autoinstrumentation-python@sha256:2cf6a7fb9680539a1c352c24827cd01e152e27d865916e6112a07c8c94f32973#public.ecr.aws/sumologic/autoinstrumentation-python@sha256:2cf6a7fb9680539a1c352c24827cd01e152e27d865916e6112a07c8c94f32973#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/busybox@sha256:ceace4beb7db070ae30589a7ef11d68b0435916d6220abccac9396618c2514ed#public.ecr.aws/sumologic/busybox@sha256:bc4b632a545fb8b797aa99d1e7cee8c042332c7cc849df30c945a8a7bd9f6c3a#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-rbac-proxy@sha256:6081af347a86a9cd51232f60e9f5567bdaddf0377927a462ced91524ce80bf95#public.ecr.aws/sumologic/kube-rbac-proxy@sha256:6081af347a86a9cd51232f60e9f5567bdaddf0377927a462ced91524ce80bf95#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kube-state-metrics@sha256:473614d1c0de0f9f0b5314eab40d3172f5180332a2009be590ce474b85cb898e#public.ecr.aws/sumologic/kube-state-metrics@sha256:473614d1c0de0f9f0b5314eab40d3172f5180332a2009be590ce474b85cb898e#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kubernetes-setup@sha256:157290d458724d63dde2d8b2b81b8184618ae07de6776f56ab33f3e3cb0566b5#public.ecr.aws/sumologic/kubernetes-setup@sha256:21819dcc791144843ebed17abf7304e2cefd711995027a8737f2d9ae14418811#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/kubernetes-tools-kubectl@sha256:0beabc526fbd99db0bae9f34d6f1cf806b5b29354d03b21766edec82c26c3353#public.ecr.aws/sumologic/kubernetes-tools-kubectl@sha256:89ae5ef9c85f6a01d520c8e237e614131cdc81a09f2eade54c9b091b2993e856#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/metrics-server@sha256:d57ba890f7ea80a3afef709f6aa60b2ee989bc575e81565bfa664cd2fcfd2980#public.ecr.aws/sumologic/metrics-server@sha256:6398a46ccf68a28f647d4f05bb9a273580deb063efc501dfed0ccf1bcac44f98#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/nginx-unprivileged@sha256:9aef85eed423d0bf6bce16eb0dce3d56d18c0aa7929627ed4fe7aef7aa749c1f#public.ecr.aws/sumologic/nginx-unprivileged@sha256:9aef85eed423d0bf6bce16eb0dce3d56d18c0aa7929627ed4fe7aef7aa749c1f#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/node-exporter@sha256:7acec4473ddf508514dca1d08335cfd071e345d7eca660793d59e09ef9f0491f#public.ecr.aws/sumologic/node-exporter@sha256:685b59ebf0ce3c7e32f9de83359fdfc66a5143660f96b82c8ef8964c727bb2e5#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/opentelemetry-operator@sha256:a714dd6995f5c3f479488c8ca281fe1a5dd92b1103c4b00b9c68f47826172267#public.ecr.aws/sumologic/opentelemetry-operator@sha256:a714dd6995f5c3f479488c8ca281fe1a5dd92b1103c4b00b9c68f47826172267#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus-config-reloader@sha256:03d3ca5b7c96c88ff8de363371d89ead3be6ac0b74653da1ac2231bd1b0e386d#public.ecr.aws/sumologic/prometheus-config-reloader@sha256:03d3ca5b7c96c88ff8de363371d89ead3be6ac0b74653da1ac2231bd1b0e386d#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus-operator@sha256:f98f265fd0609da354ca6cbb6ea3b56a88ebccfb2daff14896f7004aa4ffa174#public.ecr.aws/sumologic/prometheus-operator@sha256:f98f265fd0609da354ca6cbb6ea3b56a88ebccfb2daff14896f7004aa4ffa174#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/prometheus@sha256:92c173c757018178920385bbb93d826ae5b5cab4706ac6b239e919ae6b3520b4#public.ecr.aws/sumologic/prometheus@sha256:92c173c757018178920385bbb93d826ae5b5cab4706ac6b239e919ae6b3520b4#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/sumologic-otel-collector@sha256:986d8432eb84cad7c2ac69bdf5a48831a76d23d9d9cb08595e091b4f1f802533#public.ecr.aws/sumologic/sumologic-otel-collector@sha256:fd5c8b496f522ae91279ff96ef977d12815c55e2b15519a27705f27286507bcb#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/tailing-sidecar-operator@sha256:faf736cd82ceee3e97990da0346487e51ddc9fbc9a0647042f640d2012ef9f35#public.ecr.aws/sumologic/tailing-sidecar-operator@sha256:faf736cd82ceee3e97990da0346487e51ddc9fbc9a0647042f640d2012ef9f35#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/tailing-sidecar@sha256:48203fa961951147802711ed4769ab2d42e4adb4593a6e50c639d9cc4fb75242#public.ecr.aws/sumologic/tailing-sidecar@sha256:48203fa961951147802711ed4769ab2d42e4adb4593a6e50c639d9cc4fb75242#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/telegraf-operator@sha256:88c3b5d9f8e9a419131c39e6e22c5aa7cfaab5157fe4c5cc928574f5a3cfda2c#public.ecr.aws/sumologic/telegraf-operator@sha256:88c3b5d9f8e9a419131c39e6e22c5aa7cfaab5157fe4c5cc928574f5a3cfda2c#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/telegraf@sha256:ca396dad12a289aea9136da713020d31b179e9f49aae61c48332d61086d1d059#public.ecr.aws/sumologic/telegraf@sha256:f9883d1e9e0baf0d326a7c2c5503e011b36bf0bff22d6470c2f6d2b39fdd11fb#g" bundle.yaml
sed -i.bak "s#registry.connect.redhat.com/sumologic/thanos@sha256:323ff1e3500fdbf594acfca19639911b5ed8d0a527b9742c264d5f5b1ce5d4cc#public.ecr.aws/sumologic/thanos@sha256:323ff1e3500fdbf594acfca19639911b5ed8d0a527b9742c264d5f5b1ce5d4cc#g" bundle.yaml
