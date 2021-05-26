# Test Instruction

## Test Helm Operator using local instance of OperatorHub on OpenShift

1. Build and push to container registry index image:

   ```bash
   make catalog-build catalog-push CATALOG_IMG=<INDEX_IMAGE> BUNDLE_IMGS=<BUNDLE_IMAGE_1>,<BUNDLE_IMAGE_2>
   ```

   e.g.

   ```bash
   make catalog-build catalog-push && \
       CATALOG_IMG=ghcr.io/kkujawa-sumo/sumologic-kubernetes-collection-helm-operator-index:2.1.1-0-rc.0 && \
       BUNDLE_IMGS=public.ecr.aws/sumologic/sumologic-kubernetes-collection-helm-operator-bundle:2.1.1-0-rc.0
   ```

    **Notice**: Operator Package Manager (OPM) is required to build index image,
    OPM is available in Vagrant environment for Helm Operator.

2. Create `CatalogSource`:

   ```bash
   kubectl apply -f tests/catalogsource.yaml
   ```

3. Check that `CatalogSource` was created e.g.

   ```bash
   $ kubectl get CatalogSource -n openshift-marketplace
   NAME                            DISPLAY                    TYPE   PUBLISHER    AGE
   certified-operators             Certified Operators        grpc   Red Hat      57m
   community-operators             Community Operators        grpc   Red Hat      57m
   redhat-marketplace              Red Hat Marketplace        grpc   Red Hat      57m
   redhat-operators                Red Hat Operators          grpc   Red Hat      57m
   sumologic-helm-operator-index   Sumo Logic Helm Operator   grpc   Sumo Logic   37s
   ```

4. Check that Pod for `sumologic-helm-operator-index` was created in `openshift-marketplace`  namespace e.g.

   ```bash
   $ kubectl get pods -n openshift-marketplace
   NAME                                    READY   STATUS    RESTARTS   AGE
   certified-operators-zhjl4               1/1     Running   0          68m
   community-operators-sf8q6               1/1     Running   0          68m
   marketplace-operator-5bbff88564-zc8bs   1/1     Running   0          75m
   redhat-marketplace-8dvnb                1/1     Running   0          68m
   redhat-operators-jt64g                  1/1     Running   0          68m
   sumologic-helm-operator-index-pd5t9     1/1     Running   0          11m
   ```

5. Go to OpenShift web-console and install Sumo Logic Helm Operator from local instance of OperatorHub on OpenShift.
6. Create instance of `SumologicCollection` with proper configuration, see [examples](../config/samples/).
