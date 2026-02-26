# Sumo Logic Kubernetes Collection Helm Operator - Release Workflow

Complete end-to-end release process using automated GitHub Actions workflows.

## Release Flow

```
Phase 1: Detect Image Updates (sumologic-openshift-images) → AUTOMATED
    ↓
Phase 2: Build & Certify Components (sumologic-openshift-images) → AUTOMATED
    ↓
Phase 3: Update Operator Components (sumologic-kubernetes-collection-helm-operator) → AUTOMATED
    ↓
Phase 3.5: Update Dockerfile & OpenShift Versions → MANUAL
    ↓
Phase 4: Prepare Release PR (sumologic-kubernetes-collection-helm-operator) → AUTOMATED
    ↓
Phase 5: Build & Certify Operator (sumologic-kubernetes-collection-helm-operator) → AUTOMATED
    ↓
Phase 6: Marketplace Submission → MANUAL
```

## Prerequisites

- Access to [Red Hat Connect Portal](https://connect.redhat.com/) and Slack `#op-assist-sumologic`
- GitHub write access to both repositories
- GitHub PAT, Red Hat API token, Quay.io robot credentials (configured in secrets)
- RHEL 8.0+ or Fedora 34.0+ for manual testing

---

## Detailed Workflow

### Phase 1: Detect Image Updates (AUTOMATED)

**Repository**: `sumologic-openshift-images`  
**Workflow**: `detect_image_updates.yml`

**Inputs**: `helm_chart_version` (e.g., `4.18.0`)

**What it does**:
- Compares Helm chart component versions with certified RedHat images
- Generates `images-to-update.json` artifact

**Output**: List of images needing certification

---

### Phase 2: Build & Certify Components (AUTOMATED)

**Repository**: `sumologic-openshift-images`  
**Workflow**: `build_and_certify.yml`

**Inputs**: `phase1_run_id`

**What it does**:
1. Downloads images list from Phase 1
2. For each image: builds UBI version (if needed), pushes to Quay.io, runs preflight certification
3. Generates `certified-images.json` with SHA256 digests

**Output**: Certified images with SHA256 references

---

### Phase 3: Update Operator Components (AUTOMATED)

**Repository**: `sumologic-kubernetes-collection-helm-operator`  
**Workflow**: `update_operator_images.yml`

**Inputs**: 
- `phase2_run_id`
- `helm_chart_version`

**What it does**:
1. Downloads certified images from Phase 2
2. Updates CSV, manager.yaml, test scripts with new image SHA256s
3. Updates Helm chart submodule to specified version
4. Generates watches.yaml and bundle.yaml
5. Creates PR with all changes

**Output**: PR with component updates (`prepare_<version>` branch)

**Action Required**: Review and merge the PR after validating changes

---

### Phase 3.5: Update Dockerfile & OpenShift Versions (MANUAL)

**When**: After Phase 3 PR is merged, before Phase 4

**Steps**:

1. **Update dependencies in Dockerfile**
   - File: [Dockerfile](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/Dockerfile)
   - Update base image versions, Go dependencies, and system packages as needed

2. **Update supported OpenShift versions**
   - File: [bundle/metadata/annotations.yaml](https://github.com/SumoLogic/sumologic-kubernetes-collection-helm-operator/blob/main/bundle/metadata/annotations.yaml)
   - Update the `com.redhat.openshift.versions` annotation
   - Example: `"v4.12-v4.16"` → `"v4.13-v4.17"`

---

### Phase 4: Prepare Operator Release (AUTOMATED)

**Repository**: `sumologic-kubernetes-collection-helm-operator`  
**Workflow**: `prepare_release_pr.yml`

**Inputs**: `operator_version` 
- RC: `X.Y.Z-N-rc.M` (e.g., `4.18.0-0-rc.0`)
- Final: `X.Y.Z-N` (e.g., `4.18.0-0`)



**What it does**:
1. Validates version format
2. Updates version in 5 files: CSV, Makefile, kustomization.yaml, deploy script, bundle.yaml
3. Creates PR with branch `release-v<version>`

**Output**: PR with version updates

**Action Required After PR Merge**:
1. Create and push release tag (required for Phase 5):
   ```bash
   git tag -a v4.18.0-0-rc.0 -m "Release v4.18.0-0-rc.0"
   git push origin v4.18.0-0-rc.0
   ```
2. Create release branch (major/minor releases only):
   ```bash
   git checkout -b release-v4.18.0
   git push origin release-v4.18.0
   ```

---

### Phase 5: Build & Certify Operator (AUTOMATED)

**Repository**: `sumologic-kubernetes-collection-helm-operator`  
**Workflow**: `build_and_certify_operator.yml`

**Inputs**: `operator_version` (must have git tag created)

**What it does**:
1. Builds operator image
2. Pushes to Quay.io
3. Runs preflight certification
4. Polls for certification status (10 min timeout)
5. Updates CSV with certified image SHA256
6. Creates PR with certified image

**Output**: PR with certified operator SHA256

**Action Required**:

**For RC Versions**:
1. Merge PR with certified image SHA256
2. Draft GitHub release with changelog
3. Test RC version (see [test.md](./test.md))
4. If tests pass: Go back to Phase 4 with final version

**For Final Versions**:
1. Merge PR with certified image SHA256
2. Draft GitHub release with changelog
3. Test the final version as RC
4. Proceed to Phase 6

---

### Phase 6: Test RC & Prepare Final Release (MANUAL)

**This phase differs for RC vs Final releases**

#### For RC Versions (e.g., 4.18.0-0-rc.0):

1. **Test new Helm Operator RC version**
   - Use [testing instructions](./test.md) (omit first step and use images created for the new Helm Operator version)
   - Run comprehensive tests on OpenShift cluster

2. **Once RC testing is completed**
   - Go back to Phase 4 and tag the actual release tag (final version, e.g., `4.18.0-0`)
   - Complete Phase 5 to certify final version
   - Once certified, proceed with marketplace steps below

#### For Final Versions (e.g., 4.18.0-0):

- **Test final version as RC**

**Before submitting marketplace PRs**:
- You need to be an operator owner to raise PRs to certified-operators and redhat-marketplace-operators repositories
- To get added as an operator owner, ask an existing team member to add you via Red Hat Connect Console (Components → sumologic-kubernetes-collection-helm-operator-bundle → Repository Information → Authorized Github User accounts)

1. **Prepare pull request to certified-operators**
   - Repository: https://github.com/redhat-openshift-ecosystem/certified-operators
   - Example PR: https://github.com/redhat-openshift-ecosystem/certified-operators/pull/2754

2. **Prepare pull request to redhat-marketplace-operators**
   - Repository: https://github.com/redhat-openshift-ecosystem/redhat-marketplace-operators
   - Example PR: https://github.com/redhat-openshift-ecosystem/redhat-marketplace-operators/pull/546

3. **Make sure that new version of Helm Operator is available on the desired platforms**

---

## Summary: Complete Release Flow

### For RC Release:
1. Run Phases 1-3 (Component updates)
2. Complete Phase 3.5 (Manual Dockerfile/OpenShift updates)
3. Run Phase 4 (Prepare RC release)
4. Run Phase 5 (Build & certify RC)
5. Test RC (Phase 6)
6. If tests pass: **Go back to Phase 4 with final version**

### For Final Release:
1. Run Phase 4 with final version
2. Run Phase 5 (Build & certify final)
3. Complete Phase 6 (Marketplace submission)

---

## Resources

**Documentation**:
- [Testing Guide](./test.md)
- [Old Manual Process](./update.md) (reference only)

**Contacts**:
- Slack: `#op-assist-sumologic` (Red Hat support)
- Slack: `#pd-priv-opensource-collection` (Team)

**Workflows**: `.github/workflows/`
- `detect_image_updates.yml`
- `build_and_certify.yml`
- `update_operator_images.yml`
- `prepare_release_pr.yml`
- `build_and_certify_operator.yml`

---

## Version Format

**RC**: `X.Y.Z-N-rc.M` → Example: `4.18.0-0-rc.0`  
**Final**: `X.Y.Z-N` → Example: `4.18.0-0`

**Branches**:
- RC: `release-vX.Y.Z-rc`
- Final: `release-vX.Y.Z-N`

**Tags**: `vX.Y.Z-N[-rc.M]`

---

## Quick Reference

### Trigger Workflows (via GitHub Actions UI or CLI)
```bash
# Phase 1
gh workflow run detect_image_updates.yml -f helm_chart_version=4.18.0

# Phase 2
gh workflow run build_and_certify.yml -f phase1_run_id=<RUN_ID>

# Phase 3
gh workflow run update_operator_images.yml \
  -f phase2_run_id=<RUN_ID> -f helm_chart_version=4.18.0

# Phase 4
gh workflow run prepare_release_pr.yml -f operator_version=4.18.0-0-rc.0

# Phase 5
gh workflow run build_and_certify_operator.yml -f operator_version=4.18.0-0-rc.0
```

### Common Commands
```bash
# Check workflow status
gh run list --repo SumoLogic/<repo> --limit 5

# Create tag
git tag -a v4.18.0-0-rc.0 -m "Release v4.18.0-0-rc.0"
git push origin v4.18.0-0-rc.0

# Test locally
make deploy-helm-operator-using-public-images IMG="${CERTIFIED_IMAGE}"
