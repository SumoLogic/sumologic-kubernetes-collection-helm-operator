# AGENTS.md

## Commands

- Setup: `git submodule update --init`
- Build: `make docker-build`
- Lint: `make shellcheck && make pylint && make black-check`
- Test (integration, requires k3d cluster): `make test-using-public-images`
- Check bundle is up to date: `make test-bundle-status`
- Regenerate watches.yaml: `make generate-watches`
- Regenerate bundle.yaml: `make generate-bundle`

## Tooling

- Build system: Make
- No Go code — pure Helm-based operator; `helm-operator` binary (auto-downloaded to `bin/`) does all reconciliation
- Python scripts in `scripts/` are release automation only (not app code)

## Boundaries

- Never: commit secrets or credentials
- Never edit `watches.yaml` directly — regenerate with `make generate-watches`
- Never edit `bundle.yaml` directly — regenerate with `make generate-bundle`; verify with `make test-bundle-status`
- Never edit `helm-charts/` directly — it is a git submodule

## Testing

- All tests are integration/end-to-end against a live Kubernetes cluster (k3d in CI); no unit tests
- `make test` requires Red Hat registry credentials; use `make test-using-public-images` locally

## Git workflow

- Branch naming: Jira ticket prefix (e.g., `SUMO-XXXXX/description`)

## Gotchas / context

- `watches.yaml` is the sole runtime config — maps CRD to Helm chart and overrides ~35 image paths for OpenShift
- `bundle_tmp*/` dirs at repo root are stale build artifacts; safe to ignore

<!-- See README for project overview — not duplicated here. -->
