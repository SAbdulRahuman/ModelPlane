# ModelPlane — The Kubernetes Control Plane for LLM Workloads

**Project Title:** ModelPlane  
**Description:** Kubernetes operator enabling enterprise LLM deployment with support for offline and air-gapped AI infrastructure.  
**Created:** 2026-02-21  
**Status:** Planning

---

## 1. Vision & Goals

| Goal | Description |
|------|-------------|
| **Enterprise LLM Operator** | Build a Kubernetes operator that automates the full lifecycle of LLM deployments — provisioning, scaling, updating, and teardown. |
| **Kubernetes + OpenShift First** | Target both vanilla Kubernetes and Red Hat OpenShift as first-class platforms, with one-click install via OpenShift OperatorHub. |
| **Offline / Air-Gapped Support** | Enable model serving in environments with no internet access via local model registries, bundled dependencies, and offline-first design. |
| **Single CR Deployment** | Deploy a fully functional LLM inference stack from a single `LLMDeployment` Custom Resource — zero manual steps. |
| **Multi-Model Management** | Support deploying and routing across multiple LLM models (open-weight and fine-tuned) from a single control plane. |
| **Infrastructure Abstraction** | Hide GPU scheduling, node affinity, storage, and networking complexity behind declarative Custom Resources. |

---

## 2. Key Features

> **Development Workflow:** Each feature is developed → tested → merged independently.  
> Every phase ends with a **Verification Gate** — a set of concrete checks that must pass before moving to the next phase.  
> Phases are sequential (each builds on the previous), but features *within* a phase can be parallelized.

---

### Phase 1 — Project Scaffolding & Go Module (Week 1)

| # | Feature | Description |
|---|---------|-------------|
| 1.1 | **Project Scaffolding** | Initialize Go module (`modelplane.io/modelplane`), Kubebuilder/Operator SDK project structure. Configure `Makefile` with standard targets (`generate`, `manifests`, `test`, `build`, `docker-build`). |
| 1.2 | **Dockerfile & Container Build** | Multi-stage Dockerfile for the operator binary. Podman-compatible build. Distroless or UBI-minimal base image. `make docker-build` target. |
| 1.3 | **Repository Structure** | Establish directory layout: `api/`, `internal/controller/`, `cmd/`, `config/`, `hack/`, `charts/`, `docs/`, `test/`. Add `.gitignore`, `.editorconfig`, `.golangci.yaml`. |

**Verification Gate:**
- [ ] `make build` compiles without errors
- [ ] `make docker-build` produces a valid container image
- [ ] `golangci-lint run` passes with zero issues
- [ ] Repository structure follows Kubebuilder conventions

---

### Phase 2 — CI Pipeline & Automation (Week 1)

| # | Feature | Description |
|---|---------|-------------|
| 2.1 | **GitHub Actions CI** | CI workflow triggers on push/PR: lint (`golangci-lint`), unit test (`make test`), build (`make build`), container build (`make docker-build`). Branch protection rules require CI pass. |
| 2.2 | **Artifact Caching** | Cache Go modules and build artifacts in CI for faster builds. Cache container layer builds. |
| 2.3 | **Makefile Enhancements** | Add targets: `make lint`, `make fmt`, `make vet`, `make envtest`, `make kind-cluster`, `make deploy`, `make undeploy`. All CI steps runnable locally. |

**Verification Gate:**
- [ ] GitHub Actions CI workflow triggers on push/PR and passes
- [ ] `make test` runs (even if no tests yet) — CI pipeline green
- [ ] `make lint` runs golangci-lint with project config
- [ ] CI caching reduces subsequent build times

---

### Phase 3 — Contributing Guide, Governance & Structured Logging (Week 1)

| # | Feature | Description |
|---|---------|-------------|
| 3.1 | **Contributing Guide & Governance** | Ship `CONTRIBUTING.md` (development workflow, PR process, code style, Conventional Commits), `CODE_OF_CONDUCT.md`, `LICENSE` (Apache 2.0), `OWNERS`/`CODEOWNERS` for review routing. |
| 3.2 | **Structured Logging** | Use `zap` via controller-runtime with structured JSON log output. Support configurable log verbosity levels (`--zap-log-level`). Include reconciliation context (namespace, name, generation) in all log entries. |
| 3.3 | **README & Architecture Diagram** | Initial README with project description, architecture diagram (text-based), badges (CI, Go Report Card, license), and quickstart placeholder. |

**Verification Gate:**
- [ ] `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `OWNERS` present in repo root
- [ ] Structured JSON log output verified in operator startup logs
- [ ] README renders correctly on GitHub with architecture diagram visible
- [ ] Conventional Commits convention documented and enforced

---

### Phase 4 — LLMDeployment CRD Type Definitions (Week 2)

| # | Feature | Description |
|---|---------|-------------|
| 4.1 | **LLMDeployment CRD** | Define `LLMDeployment` CRD Go types under `api/v1alpha1/` with `spec` and `status` fields. API group: `modelplane.io/v1alpha1`. |
| 4.2 | **Spec Fields** | Define core spec fields: `model` (name, version, registry), `runtime` (ollama, vllm), `replicas`, `resources` (cpu, memory, gpu), `storage`, `serving` (port, timeout). |
| 4.3 | **Code Generation** | Run `make generate` (DeepCopy) and `make manifests` (CRD YAML). Verify generation is idempotent — no diff on re-run. |

**Verification Gate:**
- [ ] `make generate && make manifests` succeeds and is idempotent
- [ ] CRD YAML generated under `config/crd/bases/`
- [ ] Go types compile without errors
- [ ] `kubectl apply -f config/crd/` installs CRD on Kind cluster without errors

---

### Phase 5 — Status Subresource & Conditions (Week 2)

| # | Feature | Description |
|---|---------|-------------|
| 5.1 | **Status Subresource** | Implement `status` subresource on `LLMDeployment` following `metav1.Condition` convention. |
| 5.2 | **Condition Types** | Report conditions: `Ready`, `Progressing`, `Degraded`, `ModelLoaded`, `InferenceReady`. Each with `status`, `reason`, `message`, `lastTransitionTime`. |
| 5.3 | **Status Fields** | Track `observedGeneration`, `readyReplicas`, `currentModelVersion`, `lastReconcileTime`, `phase` (Pending, Running, Failed, Terminating). |

**Verification Gate:**
- [ ] `kubectl apply -f config/samples/` creates a sample CR successfully
- [ ] `kubectl get llmd -o yaml` shows `status` block (even if empty)
- [ ] CRD schema includes `status` subresource marker
- [ ] Status fields compile and generate correctly

---

### Phase 6 — Printer Columns, Short Names & Sample CRs (Week 2)

| # | Feature | Description |
|---|---------|-------------|
| 6.1 | **Printer Columns** | Define `+kubebuilder:printcolumn` markers so `kubectl get llmdeployments` shows columns: READY, MODEL, RUNTIME, REPLICAS, PHASE, AGE. |
| 6.2 | **Short Names & Categories** | Register short name `llmd`. Add `categories: [modelplane]` so `kubectl get modelplane` lists all ModelPlane CRDs. |
| 6.3 | **Sample Custom Resources** | Ship `config/samples/` with example CRs: minimal deployment, GPU deployment, multi-model, air-gapped. CRD schema validation rejects invalid fields. |

**Verification Gate:**
- [ ] `kubectl get llmd` returns empty table with correct column headers
- [ ] `kubectl get modelplane` lists all ModelPlane resources
- [ ] CRD schema validation rejects invalid fields (e.g., negative `replicas`)
- [ ] All sample CRs apply cleanly on Kind cluster

---

### Phase 7 — Core Reconciliation Loop (Week 3)

| # | Feature | Description |
|---|---------|-------------|
| 7.1 | **Controller Setup** | Register `LLMDeployment` controller with controller-runtime manager. Configure watches on `LLMDeployment` CRs. |
| 7.2 | **Reconcile Function** | Implement the main `Reconcile()` function: fetch CR → determine desired state → create/update Deployments, Services, ConfigMaps for Ollama inference pods. |
| 7.3 | **Server-Side Apply** | Use server-side apply (SSA) semantics for creating and updating child resources. Field manager: `modelplane`. |

**Verification Gate:**
- [ ] Create `LLMDeployment` CR → operator creates Deployment + Service within 30s
- [ ] `kubectl get deployment` shows child Deployment created by operator
- [ ] Operator logs show reconciliation cycle completing successfully
- [ ] `status.conditions` updated with `Progressing` after reconciliation starts

---

### Phase 8 — Owner References & Garbage Collection (Week 3)

| # | Feature | Description |
|---|---------|-------------|
| 8.1 | **Owner References** | Set `ownerReferences` on all child resources (Deployments, Services, ConfigMaps) pointing to the parent `LLMDeployment` CR. |
| 8.2 | **Cascade Deletion** | Ensure Kubernetes garbage collector cascades deletion automatically when parent CR is deleted. Verify no orphaned resources. |
| 8.3 | **Cross-Namespace Awareness** | Handle edge cases: operator namespace vs workload namespace. Ensure owner references work within same namespace. |

**Verification Gate:**
- [ ] `kubectl get deployment -o yaml` shows correct `ownerReferences` block
- [ ] Delete `LLMDeployment` CR → child Deployment and Service are garbage-collected
- [ ] No orphaned resources remain after CR deletion
- [ ] Owner reference UID matches parent CR UID

---

### Phase 9 — Event Recording & Idempotent Reconciliation (Week 3)

| # | Feature | Description |
|---|---------|-------------|
| 9.1 | **Event Recording** | Emit Kubernetes Events on all reconciliation actions — deployment created, deployment updated, errors encountered. Primary debugging mechanism for `kubectl describe llmd`. |
| 9.2 | **Idempotent Reconciliation** | Ensure the reconciler is safe to run repeatedly without side effects. Use patch semantics to avoid update conflicts. Handle `resourceVersion` mismatches gracefully with retry. |
| 9.3 | **envtest Unit Tests** | Write controller unit tests using envtest (real API server, no full cluster). Test create, update, delete lifecycle. Verify events emitted. |

**Verification Gate:**
- [ ] `kubectl describe llmd <name>` shows Events (e.g., "Created Deployment")
- [ ] Manually trigger reconcile twice → no errors, no duplicate resources
- [ ] `status.conditions` updated with `Ready` or `Progressing` after reconciliation
- [ ] envtest unit tests pass for reconciler logic
- [ ] `make test` reports >50% coverage on controller package

---

### Phase 10 — Finalizers & Cleanup (Week 4)

| # | Feature | Description |
|---|---------|-------------|
| 10.1 | **Finalizer Registration** | Add `modelplane.io/cleanup` finalizer to `LLMDeployment` CRs on creation. Prevent premature deletion before cleanup completes. |
| 10.2 | **Cleanup Logic** | Implement finalizer handler: clean up PVs, GPU reservations, TLS secrets, and any external resources before CR deletion completes. |
| 10.3 | **Finalizer Removal** | Remove finalizer after cleanup succeeds. Handle cleanup failures gracefully — retry with backoff, surface error in status conditions. |

**Verification Gate:**
- [ ] `kubectl get llmd <name> -o yaml` shows finalizer in `metadata.finalizers`
- [ ] Delete CR → finalizer runs cleanup → CR is fully removed (no stuck `Terminating`)
- [ ] envtest tests cover finalizer add/remove lifecycle
- [ ] Cleanup failure → CR stays in `Terminating` with error condition, retries

---

### Phase 11 — Requeue Strategy & Rate Limiting (Week 4)

| # | Feature | Description |
|---|---------|-------------|
| 11.1 | **Exponential Backoff** | Configure exponential backoff with jitter for failed reconciliations. Base interval: 1s, max interval: 5m. |
| 11.2 | **Rate Limiter Configuration** | Tune `MaxConcurrentReconciles` (default: 1), configure `RateLimiter` on controller to avoid API server overload. |
| 11.3 | **Requeue Semantics** | Define when to requeue immediately (transient error), requeue after delay (waiting for external state), or not requeue (terminal state/success). Document requeue strategy. |

**Verification Gate:**
- [ ] Simulate reconcile failure → observe exponential backoff in logs (not immediate rapid retry)
- [ ] Logs show increasing requeue intervals: ~1s, ~2s, ~4s, etc.
- [ ] Successful reconciliation does not trigger unnecessary requeues
- [ ] `MaxConcurrentReconciles` configurable via operator flag

---

### Phase 12 — Drift Detection & Self-Healing (Week 4)

| # | Feature | Description |
|---|---------|-------------|
| 12.1 | **Child Resource Watches** | Configure controller to watch all owned child resources (Deployments, Services, ConfigMaps) via `Owns()` predicates. |
| 12.2 | **Drift Detection** | If a child resource is modified externally (e.g., manual `kubectl edit`), detect the drift via watch events and trigger reconciliation. |
| 12.3 | **Self-Healing Reconciliation** | Reconcile drifted resources back to the desired state defined by the parent CR. Log drift detection events. |

**Verification Gate:**
- [ ] Manually edit child Deployment (e.g., change replicas) → operator detects drift and corrects within 30s
- [ ] Drift correction logged as a Kubernetes Event on the parent CR
- [ ] Manual edit to child Service → operator reconciles back to desired state
- [ ] Watch predicates filter out operator's own updates (no infinite loop)

---

### Phase 13 — Leader Election & High Availability (Week 5)

| # | Feature | Description |
|---|---------|-------------|
| 13.1 | **Leader Election** | Enable controller-runtime leader election (`--leader-elect=true`). Multiple operator replicas can run for HA without conflicting reconciliations. |
| 13.2 | **Lease Configuration** | Configure lease duration (15s), renew deadline (10s), and retry period (2s). Tunable via operator flags. |
| 13.3 | **Standby Behavior** | Non-leader replicas stay idle, watching for lease expiry. On leader failure, standby acquires lease and resumes reconciling. |

**Verification Gate:**
- [ ] Deploy 2 operator replicas → only one is active leader, the other is standby
- [ ] Kill leader pod → standby acquires lease and resumes reconciling within lease timeout
- [ ] Logs clearly indicate leader election state (acquired/lost/waiting)
- [ ] Leader election lease object visible: `kubectl get lease -n modelplane-system`

---

### Phase 14 — Graceful Shutdown & Signal Handling (Week 5)

| # | Feature | Description |
|---|---------|-------------|
| 14.1 | **SIGTERM/SIGINT Handling** | Handle termination signals to initiate graceful shutdown. Drain in-flight reconciliations before exit. |
| 14.2 | **Leader Lease Release** | Release leader election lease on shutdown so standby can acquire immediately (no waiting for lease timeout). |
| 14.3 | **Informer Cache Shutdown** | Close informer caches cleanly within the pod's `terminationGracePeriodSeconds` (default: 30s). Log shutdown progress. |

**Verification Gate:**
- [ ] Send SIGTERM to operator → in-flight reconciliation completes, leader lease released cleanly
- [ ] Standby acquires lease immediately after graceful shutdown (not after full timeout)
- [ ] Operator logs show orderly shutdown sequence: drain → lease release → cache close → exit
- [ ] No error logs during graceful shutdown

---

### Phase 15 — Health Probes, Resource Limits & Client-Go Tuning (Week 5)

| # | Feature | Description |
|---|---------|-------------|
| 15.1 | **Liveness & Readiness Probes** | Liveness: `/healthz` — verifies process alive. Readiness: `/readyz` — verifies leader election acquired, informer caches synced, webhooks serving. |
| 15.2 | **Resource Limits** | Set explicit resource requests and limits on operator manager container. Default: `requests: {cpu: 100m, memory: 128Mi}`, `limits: {cpu: 500m, memory: 512Mi}`. Configurable via Helm values. |
| 15.3 | **Client-Go QPS & Burst** | Tune client-go Kubernetes API client rate limits. Default: `QPS: 50, Burst: 100`. Expose as operator configuration flags. |

**Verification Gate:**
- [ ] `kubectl describe pod <operator>` shows liveness/readiness probes configured
- [ ] Operator pod has resource requests/limits in pod spec
- [ ] Logs show client-go QPS/Burst configuration at startup
- [ ] Readiness probe fails until informer caches are synced — verified in startup logs

---

### Phase 16 — Single CR Full-Stack Deploy (Ollama) (Week 6)

| # | Feature | Description |
|---|---------|-------------|
| 16.1 | **Ollama Runtime Integration** | A single `LLMDeployment` CR provisions the Ollama inference pod, Service, and ConfigMap — no extra steps. |
| 16.2 | **Model Pull on Startup** | Inference pod init container or entrypoint script pulls the specified model on first start. Support `spec.model.name` (e.g., `llama3:8b`). |
| 16.3 | **Inference Endpoint** | Expose Ollama API via ClusterIP Service. User does `kubectl apply` and gets a working inference endpoint at `<service>:8080`. |

**Verification Gate:**
- [ ] `kubectl apply -f llmdeployment.yaml` → Ollama pod running, model pulled, inference endpoint responding within 5 min
- [ ] `curl <service-ip>:8080/api/generate` returns a valid LLM response
- [ ] `kubectl get llmd` shows `Ready=True` after model is loaded
- [ ] Pod logs show model pull and loading progress

---

### Phase 17 — Inference Pod Health & Readiness Probes (Week 6)

| # | Feature | Description |
|---|---------|-------------|
| 17.1 | **Liveness Probe** | HTTP liveness check on Ollama API (`/api/tags` or `/`). Detects hung or crashed inference processes. |
| 17.2 | **Readiness Probe** | Readiness verifies model is fully loaded and accepting inference requests. Gates traffic until model loading completes. |
| 17.3 | **Startup Probe** | Startup probe with generous timeout for initial model pull (large models can take minutes). Prevents liveness probe from killing pods during first load. |

**Verification Gate:**
- [ ] Readiness probe gates traffic until model is fully loaded
- [ ] Kill inference process in pod → liveness probe detects, Kubernetes restarts container
- [ ] Large model pull → startup probe allows sufficient time without premature restart
- [ ] `kubectl describe pod` shows all three probes configured

---

### Phase 18 — Persistent Storage Strategy & Volume Management (Week 6)

| # | Feature | Description |
|---|---------|-------------|
| 18.1 | **PVC Per Inference Pod** | `ReadWriteOnce` PVC per inference pod for model cache. Dynamic provisioning with configurable `storageClassName` via CRD `spec.storage`. |
| 18.2 | **Reclaim Policy** | `Retain` for model data PVCs (avoid re-downloading on pod restart). `Delete` for ephemeral caches. Configurable via CR. |
| 18.3 | **Storage Size Configuration** | Default storage size based on model size estimates. Configurable via `spec.storage.size`. Validation prevents undersized PVCs. |

**Verification Gate:**
- [ ] PVC created with correct size, access mode, and storage class from CRD spec
- [ ] Kill inference pod → Kubernetes restarts it, model reloads from PVC cache (fast restart)
- [ ] `kubectl get pvc` shows PVC with correct owner reference
- [ ] Delete CR → PVC cleanup follows configured reclaim policy

---

### Phase 19 — Local Model Registry Deployment (Zot) (Week 7)

| # | Feature | Description |
|---|---------|-------------|
| 19.1 | **Zot Registry Deployment** | Deploy OCI-compatible Zot registry in-cluster for storing and distributing model artifacts. Managed by ModelPlane. |
| 19.2 | **Registry Storage** | PVC-backed storage for registry data. Configurable storage class and size. |
| 19.3 | **Registry Health Checks** | Liveness and readiness probes on registry pod. Operator monitors registry health in reconciliation loop. |

**Verification Gate:**
- [ ] Registry pod running and healthy in `modelplane-system` namespace
- [ ] Push an OCI artifact to registry via Skopeo/ORAS → succeeds
- [ ] Registry survives pod restart — data persisted on PVC
- [ ] `kubectl logs <registry-pod>` shows clean startup

---

### Phase 20 — ModelRegistry CRD (Week 7)

| # | Feature | Description |
|---|---------|-------------|
| 20.1 | **ModelRegistry CRD Types** | Define `ModelRegistry` CRD Go types with spec (type, image, storage, auth, tls, sync) and status (phase, endpoint, modelCount, conditions). API group: `modelplane.io/v1alpha1`. |
| 20.2 | **Printer Columns & Short Name** | Printer columns: READY, TYPE, ENDPOINT, MODELS, AGE. Short name: `mr`. Category: `modelplane`. |
| 20.3 | **ModelRegistry Controller** | Reconciliation loop for `ModelRegistry` CRs: create/update Zot deployment, Service, PVC, ConfigMap. Owner references and garbage collection. |

**Verification Gate:**
- [ ] `kubectl apply -f modelregistry.yaml` → Zot registry pod running and healthy
- [ ] `kubectl get mr` shows correct printer columns with `Ready=True`
- [ ] Push a model artifact to registry → `status.modelCount` increments
- [ ] Delete `ModelRegistry` CR → registry pod and PVC cleaned up via owner references

---

### Phase 21 — Registry Integration with Inference Runtime (Week 7)

| # | Feature | Description |
|---|---------|-------------|
| 21.1 | **Registry Reference in LLMDeployment** | Connect `LLMDeployment` reconciler to pull models from the local `ModelRegistry` via `spec.model.registry` reference. |
| 21.2 | **Local vs Remote Registry** | Support both local (in-cluster Zot) and remote (Docker Hub, GHCR, Quay) registry sources. |
| 21.3 | **Registry Authentication** | Support pull secrets for authenticated registries. Reference Kubernetes Secrets via `spec.model.imagePullSecret`. |

**Verification Gate:**
- [ ] Create `LLMDeployment` referencing local registry → model pulled from in-cluster registry (not internet)
- [ ] Create `LLMDeployment` with remote registry → model pulled from external source
- [ ] Authenticated registry pull with imagePullSecret → succeeds
- [ ] Missing registry reference → operator sets `Degraded` condition with clear message

---

### Phase 22 — Basic CLI (mpctl) — Core Commands (Week 8)

| # | Feature | Description |
|---|---------|-------------|
| 22.1 | **CLI Framework** | Initialize `mpctl` CLI using Cobra + Viper. Kubeconfig-aware, supports `--namespace`, `--context`, `--kubeconfig` flags. |
| 22.2 | **Core Commands** | Implement `mpctl create`, `mpctl get`, `mpctl describe`, `mpctl delete`. Each command operates on `LLMDeployment` CRs via the Kubernetes API. |
| 22.3 | **Logs Command** | `mpctl logs <name>` streams inference pod logs. Supports `--follow`, `--tail`, `--container` flags. |

**Verification Gate:**
- [ ] `mpctl create --model llama3:8b` → CR created, operator reconciles, inference running
- [ ] `mpctl get` → lists all LLMDeployments with status
- [ ] `mpctl describe <name>` → shows CR details, conditions, events
- [ ] `mpctl delete <name>` → CR deleted, resources cleaned up
- [ ] `mpctl logs <name>` → streams inference pod logs

---

### Phase 23 — Operator Configuration & Feature Gates (Week 8)

| # | Feature | Description |
|---|---------|-------------|
| 23.1 | **Operator ConfigMap** | Support operator-level configuration via ConfigMap: default runtime, log level, metrics port, health probe port, leader election namespace, concurrent reconciles, sync period, webhook port. |
| 23.2 | **CLI Flag Overrides** | All ConfigMap values overridable via CLI flags on the operator binary. Flag takes precedence over ConfigMap. |
| 23.3 | **Feature Gates** | Implement feature gate mechanism (`--feature-gates=WebUI=true,CanaryRollouts=false`). Support `Alpha`, `Beta`, `GA` maturity levels. Gate all non-GA features. |

**Verification Gate:**
- [ ] Operator reads configuration from ConfigMap at startup — log level change takes effect
- [ ] CLI flag `--zap-log-level=debug` overrides ConfigMap value
- [ ] `--feature-gates=WebUI=false` disables Web UI reconciliation — verified in logs
- [ ] Feature gate status logged at startup for all gates
- [ ] Document all configuration options in `docs/configuration.md`

---

### Phase 24 — Uninstall, Cleanup & Lifecycle Commands (Week 8)

| # | Feature | Description |
|---|---------|-------------|
| 24.1 | **Uninstall Command** | `mpctl uninstall --cleanup` removes all CRs, CRDs, operator deployment, RBAC, and namespace. Configurable cascade delete vs orphan policy. |
| 24.2 | **Status Command** | `mpctl status` shows operator health, leader election state, CRD versions, resource counts, and recent events. |
| 24.3 | **Version Command** | `mpctl version` shows CLI version, operator version (queried from running operator), API versions, and Go/K8s dependency versions. |

**Verification Gate:**
- [ ] `mpctl uninstall --cleanup` → all CRs and operator resources removed
- [ ] `mpctl uninstall` (without cleanup) → operator removed, CRs orphaned
- [ ] `mpctl status` → shows operator running, leader elected, CRD counts
- [ ] `mpctl version` → shows CLI and operator versions

---

### Phase 25 — CEL Validation Rules (Week 9)

| # | Feature | Description |
|---|---------|-------------|
| 25.1 | **Basic Field Validation** | Use Common Expression Language (CEL) `x-kubernetes-validations` for: `spec.replicas >= 0`, `spec.serving.port` in range 1–65535, enum checks on `spec.runtime` (ollama, vllm). |
| 25.2 | **Cross-Field Validation** | CEL rules for: `spec.autoscaling.minReplicas <= spec.autoscaling.maxReplicas`, GPU resource consistency, storage size > 0 when storage enabled. |
| 25.3 | **Immutable Fields** | Mark selected fields as immutable after creation (e.g., `spec.runtime` cannot change — requires delete/recreate). Use CEL `oldSelf` for transition rules. |

**Verification Gate:**
- [ ] Submit CR with `replicas: -1` → rejected by CEL validation with clear error message
- [ ] Submit CR with `minReplicas > maxReplicas` → rejected by CEL
- [ ] Submit CR with `spec.runtime: foo` → rejected by enum validation
- [ ] Attempt to change immutable field → rejected with clear error
- [ ] All validation errors include field path and human-readable message

---

### Phase 26 — Validating Admission Webhook (Week 9)

| # | Feature | Description |
|---|---------|-------------|
| 26.1 | **Webhook Server Setup** | Configure validating admission webhook with cert-manager TLS. Register webhook for `LLMDeployment` CREATE and UPDATE operations. |
| 26.2 | **Complex Cross-Field Validation** | Validate: GPU count vs model size compatibility, runtime-specific field requirements (vLLM requires GPU), model exists in referenced registry. |
| 26.3 | **Webhook Dry-Run Support** | Support `kubectl apply --dry-run=server` for validating CRs without creating them. Webhook handles dry-run requests correctly. |

**Verification Gate:**
- [ ] Submit CR with unsupported runtime → rejected by validating webhook with clear error
- [ ] Submit CR with vLLM runtime and no GPU → rejected with "vLLM requires GPU resources"
- [ ] Webhook TLS certificates provisioned via cert-manager — webhook pod starts clean
- [ ] `kubectl apply --dry-run=server -f cr.yaml` → validation runs without creating resource
- [ ] envtest tests cover all validation rules

---

### Phase 27 — Defaulting (Mutating) Webhook (Week 9)

| # | Feature | Description |
|---|---------|-------------|
| 27.1 | **Mutating Webhook Setup** | Configure mutating admission webhook. Register for `LLMDeployment` CREATE operations. |
| 27.2 | **Field Defaults** | Set sensible values for omitted fields: `spec.replicas: 1`, `spec.runtime: ollama`, `spec.serving.port: 8080`, `spec.serving.timeout: 120s`, `spec.storage.accessMode: ReadWriteOnce`. |
| 27.3 | **Label & Annotation Injection** | Auto-inject standard labels: `app.kubernetes.io/managed-by: modelplane`, `modelplane.io/version`, `modelplane.io/runtime`. |

**Verification Gate:**
- [ ] Submit CR with no `replicas` field → defaulting webhook sets `replicas: 1`
- [ ] Submit CR with no `runtime` field → defaulting webhook sets `runtime: ollama`
- [ ] Defaulted CR shows injected labels in `metadata.labels`
- [ ] `kubectl get llmd <name> -o yaml` shows all defaults applied
- [ ] envtest tests cover all defaulting rules

---

### Phase 28 — Pod Security Standards & SecurityContext (Week 10)

| # | Feature | Description |
|---|---------|-------------|
| 28.1 | **Restricted PSS** | Enforce `restricted` Pod Security Standard for all operator-managed pods. On OpenShift, define and bind appropriate SecurityContextConstraints (SCCs). |
| 28.2 | **SecurityContext Hardening** | Set explicit `securityContext` on every container: `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `seccompProfile: RuntimeDefault`, `capabilities.drop: [ALL]`. |
| 28.3 | **GPU Exception Handling** | Define minimal security exceptions where required (e.g., GPU device plugin access). Document all exceptions with justification. |

**Verification Gate:**
- [ ] All managed pods pass `kubectl label ns <ns> pod-security.kubernetes.io/enforce=restricted` — no violations
- [ ] `kubectl get pod <inference> -o jsonpath='{.spec.containers[0].securityContext}'` shows all hardening fields
- [ ] GPU pods run with minimal additional privileges — documented and justified
- [ ] OpenShift SCC binding tested on CRC

---

### Phase 29 — Dedicated Service Accounts & Least-Privilege RBAC (Week 10)

| # | Feature | Description |
|---|---------|-------------|
| 29.1 | **Per-Component Service Accounts** | Create separate ServiceAccounts for: operator manager, inference pods, model registry, preloader DaemonSet. |
| 29.2 | **Least-Privilege RBAC** | Bind minimal RBAC roles to each ServiceAccount. Operator SA: manage CRDs, Deployments, Services. Inference SA: read ConfigMaps, Secrets. Registry SA: manage PVCs. |
| 29.3 | **Token Automount Control** | Disable `automountServiceAccountToken` where not needed (inference pods don't need API access). |

**Verification Gate:**
- [ ] Each component has its own ServiceAccount — `kubectl get sa -n modelplane-system` shows 4+ SAs
- [ ] Inference pod SA cannot list nodes or access kube-system — RBAC test fails as expected
- [ ] Inference pod has `automountServiceAccountToken: false`
- [ ] `kubectl auth can-i --as=system:serviceaccount:modelplane-system:modelplane-inference --list` shows minimal permissions

---

### Phase 30 — Operator Metrics Endpoint Security (Week 10)

| # | Feature | Description |
|---|---------|-------------|
| 30.1 | **kube-rbac-proxy Sidecar** | Protect the operator's `/metrics` Prometheus endpoint using kube-rbac-proxy sidecar. Require ServiceAccount token authentication for metrics scraping. |
| 30.2 | **ServiceMonitor** | Ship `ServiceMonitor` CR with TLS configuration for Prometheus to scrape operator metrics securely. |
| 30.3 | **Metrics RBAC** | Create ClusterRole `modelplane-metrics-reader` for Prometheus SA to authenticate against kube-rbac-proxy. |

**Verification Gate:**
- [ ] `curl <operator-ip>:8443/metrics` without valid token → 401 Unauthorized
- [ ] ServiceMonitor configured and Prometheus scrapes metrics successfully with auth
- [ ] Metrics endpoint serves valid Prometheus exposition format
- [ ] `kubectl get servicemonitor -n modelplane-system` shows monitor configured

---

### Phase 31 — Certificate & Trust Management (cert-manager) (Week 11)

| # | Feature | Description |
|---|---------|-------------|
| 31.1 | **Internal PKI Bootstrap** | Use cert-manager to bootstrap internal PKI for TLS between operator, registry, and inference pods. Auto-issue certificates. |
| 31.2 | **Certificate Auto-Renewal** | Configure auto-renewal before certificate expiry. Monitor certificate status via cert-manager conditions. |
| 31.3 | **Custom CA Support** | Support custom CA for air-gapped environments where external CAs are unreachable. Inject CA bundle into pods via ConfigMap. |

**Verification Gate:**
- [ ] cert-manager issues TLS certificates for operator webhook, registry, and inter-pod communication
- [ ] Certificates auto-renew before expiry — verify with `kubectl get certificate`
- [ ] Custom CA injection tested in air-gapped Kind cluster
- [ ] Certificate expiry monitored — approaching expiry triggers warning event

---

### Phase 32 — Network Policies (Week 11)

| # | Feature | Description |
|---|---------|-------------|
| 32.1 | **Default Deny Ingress** | Ship default NetworkPolicies denying all ingress by default in the operator namespace. |
| 32.2 | **Allow Rules** | Allow: operator ↔ API server, operator → inference pods (metrics scrape), inference pods → registry, Gateway/Ingress → inference endpoints. |
| 32.3 | **Per-Namespace Tenant Isolation** | NetworkPolicies for tenant namespace isolation. Pods in namespace A cannot reach pods in namespace B. |

**Verification Gate:**
- [ ] `kubectl exec -it <inference-pod> -- curl <operator-metrics-ip>` → blocked by NetworkPolicy
- [ ] `kubectl exec -it <inference-pod> -- curl <registry-ip>:5000` → allowed by NetworkPolicy
- [ ] External traffic to inference endpoint only allowed via Gateway/Ingress — direct pod access blocked
- [ ] Cross-namespace traffic blocked between tenant namespaces

---

### Phase 33 — Secrets Management Strategy (Week 11)

| # | Feature | Description |
|---|---------|-------------|
| 33.1 | **Kubernetes Secrets (Default)** | Use Kubernetes Secrets as default secret storage. Operator creates and manages TLS, registry auth, and API key secrets. |
| 33.2 | **External Secrets Operator Integration** | Support external-secrets-operator (ESO) for HashiCorp Vault, AWS Secrets Manager, Azure Key Vault integration. |
| 33.3 | **Credential Rotation** | Document rotation strategy for all credentials. Support forced rotation via annotation trigger (`modelplane.io/rotate-secrets: "true"`). |

**Verification Gate:**
- [ ] Secrets created by operator are of correct type (Opaque, TLS, docker-registry)
- [ ] ESO `ExternalSecret` reference in CR → secret synced from Vault
- [ ] Secret rotation annotation triggers re-creation of affected secrets
- [ ] Rotation does not cause inference pod downtime (rolling restart)

---

### Phase 34 — Offline Model Bundling (OCI Artifacts) (Week 12)

| # | Feature | Description |
|---|---------|-------------|
| 34.1 | **Bundle CLI Command** | `mpctl bundle --model llama3:8b --output llama3-bundle.tar` packages model weights, tokenizer, and runtime config into a single OCI artifact. |
| 34.2 | **OCI Artifact Format** | Use OCI image spec for model bundles. Support multi-layer artifacts (model weights, tokenizer, config as separate layers). |
| 34.3 | **Bundle Import** | `mpctl bundle import --file llama3-bundle.tar --registry <registry>` loads a bundle into the in-cluster or air-gapped registry. |

**Verification Gate:**
- [ ] `mpctl bundle --model llama3:8b` produces valid OCI tarball
- [ ] Load bundle into air-gapped Kind cluster (no internet) → model available in local registry
- [ ] Bundle contains correct OCI manifest with expected layers
- [ ] `mpctl bundle import` succeeds against local Zot registry

---

### Phase 35 — Model Preloader DaemonSet (Week 12)

| # | Feature | Description |
|---|---------|-------------|
| 35.1 | **Preloader DaemonSet** | DaemonSet that pre-pulls and caches model artifacts on GPU nodes from the local registry. Managed by the operator based on `spec.offlineMode.preload: true`. |
| 35.2 | **Node Selector & Tolerations** | Preloader runs only on nodes with GPU labels. Configurable node selector and tolerations. |
| 35.3 | **Preloader Status** | Report preload progress in `LLMDeployment` status. Condition: `ModelPreloaded` with per-node cache status. |

**Verification Gate:**
- [ ] `spec.offlineMode.preload: true` → DaemonSet created on GPU-labeled nodes
- [ ] Preloader pre-pulls model to node cache → inference pod starts faster on second deploy
- [ ] `status.conditions` shows `ModelPreloaded=True` after preload completes
- [ ] Preloader only runs on nodes matching GPU label selector

---

### Phase 36 — Dependency Mirroring & Full Air-Gap Install (Week 13)

| # | Feature | Description |
|---|---------|-------------|
| 36.1 | **Air-Gap Bundle Script** | `hack/airgap-bundle.sh` produces a single tarball containing all operator + runtime container images and Helm charts. |
| 36.2 | **Air-Gap Install Procedure** | Documented procedure: transfer tarball → load images into air-gapped registry → `helm install` from local chart → deploy CRs. |
| 36.3 | **Zero-Internet Validation** | End-to-end test: create network-isolated Kind cluster (no internet) → install operator from bundle → deploy LLMDeployment → inference responding. |

**Verification Gate:**
- [ ] `hack/airgap-bundle.sh` produces tarball containing all operator + runtime images
- [ ] Full operator install from bundle in network-isolated Kind cluster — zero internet calls
- [ ] Create `LLMDeployment` in air-gapped cluster → inference running
- [ ] Air-gap install documented step-by-step in `docs/airgap-install.md`

---

### Phase 37 — Prometheus Metrics (Week 13)

| # | Feature | Description |
|---|---------|-------------|
| 37.1 | **Operator Metrics** | Expose custom Prometheus metrics: `modelplane_reconciliation_duration_seconds`, `modelplane_reconciliation_errors_total`, `modelplane_active_deployments`. Register in `internal/metrics/`. |
| 37.2 | **Inference Metrics** | Expose inference metrics: `modelplane_inference_requests_total`, `modelplane_inference_latency_seconds`, `modelplane_model_load_duration_seconds`. |
| 37.3 | **Infrastructure Metrics** | Expose resource metrics: `modelplane_gpu_memory_used_bytes`, `modelplane_storage_used_bytes`, `modelplane_registry_pull_duration_seconds`. |

**Verification Gate:**
- [ ] Prometheus scrapes operator metrics — `curl <metrics>/metrics` returns custom metrics
- [ ] All metric names follow Prometheus naming conventions (`_total`, `_seconds`, `_bytes`)
- [ ] Metrics include correct labels (namespace, name, model, runtime)
- [ ] `make test` includes metric registration tests

---

### Phase 38 — Grafana Dashboards & PrometheusRule Alerts (Week 14)

| # | Feature | Description |
|---|---------|-------------|
| 38.1 | **Grafana Dashboards** | Ship pre-built Grafana dashboards as ConfigMaps: Operator Health (reconciliation rate, errors, queue depth), Inference Performance (latency p50/p95/p99, throughput, GPU utilization), Model Registry (pull rate, storage usage). |
| 38.2 | **PrometheusRule Alerts** | Ship `PrometheusRule` CRs: `ModelPlaneOperatorDown`, `ReconciliationFailureRate`, `InferenceLatencyHigh`, `GPUMemoryExhausted`, `ModelLoadFailed`, `CertificateExpiringSoon`. |
| 38.3 | **Runbook URLs** | Include runbook URLs in all alert annotations pointing to troubleshooting docs. Validate alerts with `promtool`. |

**Verification Gate:**
- [ ] Grafana dashboard loads and shows live data (reconciliation rate, inference latency)
- [ ] Simulate high latency → `InferenceLatencyHigh` alert fires within evaluation interval
- [ ] Simulate reconciliation failure → `ReconciliationFailureRate` alert fires
- [ ] `promtool check rules` validates all PrometheusRule YAML
- [ ] Runbook URLs resolve to actual documentation pages

---

### Phase 39 — OpenTelemetry Tracing & Audit Logging (Week 14)

| # | Feature | Description |
|---|---------|-------------|
| 39.1 | **OpenTelemetry Tracing** | Instrument reconciliation loop and inference request path with OpenTelemetry spans. Support OTLP export to any OTel-compatible backend (Jaeger, Tempo). |
| 39.2 | **Trace Context Propagation** | Trace model pull → load → first inference as a single distributed trace. Propagate trace context via HTTP headers. |
| 39.3 | **Audit Logging** | Immutable audit trail for model deployments, access, and configuration changes. Log to stdout (structured JSON) and optionally to a dedicated audit log sink. |

**Verification Gate:**
- [ ] OTel traces appear in Jaeger/Tempo for a model deployment lifecycle
- [ ] Traces show full span tree: reconcile → create deployment → model pull → model load
- [ ] Audit log entries recorded for CR create/update/delete in structured JSON
- [ ] `OTEL_EXPORTER_OTLP_ENDPOINT` configurable via operator environment variable

---

### Phase 40 — HPA & Custom Metrics Autoscaling (Week 15)

| # | Feature | Description |
|---|---------|-------------|
| 40.1 | **HPA Integration** | Auto-create HPA for inference Deployments when `spec.autoscaling.enabled: true`. Scale based on CPU/memory or custom metrics. |
| 40.2 | **Custom Metrics (Prometheus Adapter / KEDA)** | Scale on request queue depth, latency percentiles, and GPU utilization via Prometheus adapter or KEDA ScaledObject. |
| 40.3 | **Autoscaling Configuration** | Configurable via CRD `spec.autoscaling`: minReplicas, maxReplicas, targetMetric, targetValue, scaleDown stabilization window. |

**Verification Gate:**
- [ ] Generate load → HPA scales inference replicas from 1 → 3 within 60s
- [ ] Load drops → HPA scales back to minReplicas within cooldown period
- [ ] Custom metric (request queue depth) drives scaling decision
- [ ] `kubectl get hpa` shows HPA with correct metrics and targets

---

### Phase 41 — PodDisruptionBudgets & Topology Spread Constraints (Week 15)

| # | Feature | Description |
|---|---------|-------------|
| 41.1 | **PodDisruptionBudgets** | Auto-create PDBs for inference Deployments. Default: `minAvailable: 1` or `maxUnavailable: 1` depending on replica count. Configurable via `spec.disruption`. |
| 41.2 | **Topology Spread Constraints** | Spread inference pods across failure domains (zones, nodes). Default: `topologyKey: kubernetes.io/hostname`, `maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule`. |
| 41.3 | **Node Affinity & Anti-Affinity** | Support `spec.affinity` for node affinity (GPU node targeting) and pod anti-affinity (spread across nodes). |

**Verification Gate:**
- [ ] `kubectl drain <node>` → PDB prevents evicting all inference pods simultaneously
- [ ] With 3 replicas across 2 nodes → pods spread per topology constraint
- [ ] `kubectl get pdb` shows PDB created with correct minAvailable
- [ ] Node affinity targets GPU-labeled nodes when GPU resources requested

---

### Phase 42 — Priority Classes & Resource Management (Week 15)

| # | Feature | Description |
|---|---------|-------------|
| 42.1 | **PriorityClasses** | Ship PriorityClasses: `modelplane-critical` (system-level), `modelplane-inference-high` (inference pods), `modelplane-preloader-low` (preloader DaemonSet). |
| 42.2 | **Resource Quota Awareness** | Operator checks namespace ResourceQuota before creating pods. Surface quota exceeded errors in status conditions. |
| 42.3 | **Resource Recommendations** | Document recommended resource requests/limits for common model sizes (7B, 13B, 70B). Provide sizing guide. |

**Verification Gate:**
- [ ] Under cluster memory pressure → preloader pods preempted before inference pods
- [ ] Inference pods preempted before operator pod (priority class ordering)
- [ ] `kubectl get priorityclass` shows all 3 priority classes
- [ ] Resource recommendations documented in `docs/sizing-guide.md`

---

### Phase 43 — InferenceEndpoint CRD (Week 16)

| # | Feature | Description |
|---|---------|-------------|
| 43.1 | **InferenceEndpoint CRD Types** | Define `InferenceEndpoint` CRD with spec (gatewayAPI, ingress, tls, routes, rateLimit, authentication) and status (phase, host, routeCount, conditions). API group: `modelplane.io/v1alpha1`. |
| 43.2 | **Printer Columns & Short Name** | Printer columns: READY, HOST, MODELS, AGE. Short name: `ie`. Category: `modelplane`. |
| 43.3 | **InferenceEndpoint Controller** | Reconciliation loop for `InferenceEndpoint` CRs: create/update Gateway API resources or Ingress objects. |

**Verification Gate:**
- [ ] `kubectl apply -f inferenceendpoint.yaml` → Gateway + HTTPRoutes created
- [ ] `kubectl get ie` shows READY=True, HOST, route count
- [ ] CRD schema validation and printer columns work correctly
- [ ] `kubectl get modelplane` now lists LLMDeployments, ModelRegistries, and InferenceEndpoints

---

### Phase 44 — Gateway API & Ingress Integration (Week 16)

| # | Feature | Description |
|---|---------|-------------|
| 44.1 | **Gateway API (Primary)** | Use Gateway API as primary traffic routing mechanism. Ship GatewayClass and Gateway manifests. Create HTTPRoutes from InferenceEndpoint spec. |
| 44.2 | **Ingress Fallback** | Fall back to Ingress for clusters without Gateway API CRDs. Auto-detect Gateway API availability and switch routing strategy. |
| 44.3 | **TLS Termination** | Support TLS termination at Gateway/Ingress level. Integrate with cert-manager for automatic certificate provisioning. |

**Verification Gate:**
- [ ] Gateway API cluster: HTTPRoute created, traffic routes to inference pods
- [ ] Non-Gateway cluster: `ingress.enabled: true` creates Ingress resource instead
- [ ] TLS termination working — `curl https://<host>` returns inference response
- [ ] Gateway API availability auto-detected at operator startup

---

### Phase 45 — Multi-Model Routing & Service Discovery (Week 17)

| # | Feature | Description |
|---|---------|-------------|
| 45.1 | **Path-Based Routing** | Route requests to different models by path: `/v1/llama3`, `/v1/mistral`, `/v1/codellama`. |
| 45.2 | **Header-Based Routing** | Route by header: `x-model: llama3-8b`, `x-model: mistral-7b`. Support weighted routing for A/B testing. |
| 45.3 | **Service Discovery** | ClusterIP services for internal inference traffic. Headless services for StatefulSet-based serving. Support ExternalDNS integration for external endpoint registration. |

**Verification Gate:**
- [ ] `curl <gateway>/v1/llama3` → routed to llama3 inference pods
- [ ] `curl -H "x-model: mistral-7b" <gateway>/v1/chat` → routed to mistral pods
- [ ] Internal service DNS: `<name>.<namespace>.svc.cluster.local` resolves correctly
- [ ] ExternalDNS creates DNS record for external-facing endpoints

---

### Phase 46 — RBAC & Namespace-Scoped Multi-Tenancy (Week 17)

| # | Feature | Description |
|---|---------|-------------|
| 46.1 | **ClusterRoles** | Ship ClusterRoles: `modelplane-admin` (full access), `modelplane-editor` (create/update/delete CRs), `modelplane-viewer` (read-only). |
| 46.2 | **Namespace Isolation** | Namespace-scoped tenancy — each team/tenant operates in their own namespace. Cross-namespace access denied by default. |
| 46.3 | **Per-Model RBAC** | Fine-grained RBAC policies allowing access to specific models within a namespace. Support RBAC for `mpctl` operations. |

**Verification Gate:**
- [ ] User with `modelplane-viewer` role can `kubectl get llmd` but cannot `kubectl delete llmd`
- [ ] User with `modelplane-editor` role can create/update LLMDeployments but not modify operator config
- [ ] Tenant in namespace A cannot see or modify LLMDeployments in namespace B
- [ ] `mpctl` respects RBAC — unauthorized operations fail with clear error

---

### Phase 47 — Storage Quotas & Service Mesh Compatibility (Week 18)

| # | Feature | Description |
|---|---------|-------------|
| 47.1 | **Storage Quotas** | Enforce per-namespace and per-model storage quotas via `ResourceQuota` integration. Prevent a single tenant from exhausting cluster storage. Expose `status.storageUsed` on CRDs. |
| 47.2 | **Service Mesh Compatibility** | Test compatibility with Istio and OpenShift Service Mesh. Support opt-in/opt-out sidecar injection annotations (`sidecar.istio.io/inject`). Handle GPU pod interference from sidecars. |
| 47.3 | **Resource Usage Reporting** | Aggregate resource usage per tenant/namespace. `mpctl report --namespace <ns>` shows GPU hours, storage, inference request counts. |

**Verification Gate:**
- [ ] Create models exceeding storage quota → CR rejected or status shows `Degraded` with quota message
- [ ] `status.storageUsed` accurately reports current PVC usage
- [ ] Inference pods with `sidecar.istio.io/inject: "false"` → no sidecar injected
- [ ] `mpctl report` shows resource usage per namespace

---

### Phase 48 — Model Versioning, Canary/Blue-Green Rollouts & CRD Evolution (Week 19)

| # | Feature | Description |
|---|---------|-------------|
| 48.1 | **Canary Rollouts** | Support canary deployments when updating model versions. Traffic split by percentage (e.g., 90/10 old/new). Automatic rollback on error-rate spike or latency threshold breach. |
| 48.2 | **Blue-Green Deployments** | Blue-green switching: old pods kept until new pods are Ready, then traffic switched atomically. Instant rollback by switching back. |
| 48.3 | **CRD Conversion Webhooks** | Implement conversion webhook infrastructure for `v1alpha1` → `v1beta1` → `v1` CRD evolution. Define API deprecation policy: `v1alpha1` supported for 2 releases after `v1beta1` GA. |

**Verification Gate:**
- [ ] Update model version → canary created with 10% traffic split
- [ ] Canary passes health checks → traffic shifted to 100% new version
- [ ] Canary fails → automatic rollback to previous version within 60s
- [ ] Blue-green: old pods held until new Ready, then switched
- [ ] Conversion webhook converts `v1alpha1` CR to `v1beta1` transparently

---

### Phase 49 — Helm Chart, OLM Bundle & Supply Chain Security (Week 20)

| # | Feature | Description |
|---|---------|-------------|
| 49.1 | **Helm Chart** | Production Helm chart (`charts/modelplane/`) with configurable values: operator image, replicas, resources, feature gates, log level, storage class, network policies toggle, priority classes. |
| 49.2 | **OLM Bundle & OperatorHub** | Generate OLM bundle: ClusterServiceVersion (CSV), CRDs, RBAC. Upgrade channels: `stable`, `fast`, `candidate`. Publish to OperatorHub. One-click install from OpenShift web console. Target Capability Level III. |
| 49.3 | **Supply Chain Security** | Container image scanning (Trivy). Go dependency audit (`govulncheck`). SBOM generation (SPDX/CycloneDX). SLSA Level 3 provenance attestations (cosign). Multi-arch builds (`linux/amd64`, `linux/arm64`). Strict image tagging — never `:latest`, always `:v1.0.0` + `@sha256:`. |

**Verification Gate:**
- [ ] `helm install modelplane charts/modelplane/ --namespace modelplane-system` → operator running
- [ ] `helm upgrade` → operator restarts with new configuration
- [ ] `operator-sdk bundle validate ./bundle` → passes all checks
- [ ] Install from OperatorHub on CRC/OpenShift → operator running within 2 min
- [ ] Trivy scan → zero critical/high CVEs; `govulncheck` → zero vulnerabilities
- [ ] `cosign verify <image>` → signature and SLSA provenance verified
- [ ] Multi-arch manifest includes both amd64 and arm64

---

### Phase 50 — E2E Testing, Documentation, Web UI & v1.0 Release (Week 21)

| # | Feature | Description |
|---|---------|-------------|
| 50.1 | **End-to-End Testing** | Comprehensive e2e test suite on Kind: CR lifecycle, air-gap install, autoscaling, canary rollout, multi-model routing, RBAC, network policies, PDBs. Operator upgrade test matrix (N-1 → N). Backup/DR test (Velero). Zero flakes over 3 consecutive runs. |
| 50.2 | **Documentation Site & Troubleshooting** | MkDocs Material docs site (GitHub Pages): user guide, API reference (auto-generated from CRDs), architecture diagrams, air-gap install guide, sizing guide, troubleshooting guide (≥10 failure scenarios), configuration reference. Changelog automation (`git-cliff`). API deprecation policy published. |
| 50.3 | **Web UI & OpenShift Console Plugin** | Lightweight React + PatternFly management console (opt-in via `spec.ui.enabled`). Deploy, scale, monitor, and roll back LLM models via browser. OpenShift console dynamic plugin via `ConsolePlugin` CR. |
| 50.4 | **v1.0 Release** | Semantic versioning. GoReleaser `v1.0.0` tag. Publish container images (`:v1.0.0` + `@sha256:`), Helm chart, OLM bundle. Demo video (2 min). Blog post. LinkedIn + CNCF Slack announcement. Submit to CNCF Landscape under "AI". |

**Verification Gate:**
- [ ] Full e2e suite passes on Kind: all features exercised, zero flakes over 3 runs
- [ ] Operator upgrade v0.9 → v1.0 → running LLMDeployments continue serving
- [ ] Docs site builds — all pages render, no broken links, API reference matches CRDs
- [ ] Troubleshooting guide covers ≥10 failure scenarios
- [ ] Web UI deploys with `spec.ui.enabled: true`, lists and manages all CRs
- [ ] OpenShift console plugin integrates as sidebar item
- [ ] `v1.0.0` tag created, GitHub Release published with changelog + binaries
- [ ] Demo video demonstrates full lifecycle in under 2 minutes
- [ ] README: architecture diagram, quickstart (< 5 min), CI badge green, release badge

---

## 3. Milestones & Timeline

| Milestone | Phases | Target | Deliverables |
|-----------|--------|--------|-------------|
| **M1 — Walking Skeleton** | 1–9 | Week 3 | Repo scaffolded, CI green, `LLMDeployment` CRD installed, core reconciler creates Deployments with owner references, events, and status conditions. envtest passing. |
| **M2 — Hardened Operator** | 10–15 | Week 5 | Finalizers, drift detection, exponential backoff. Leader election, graceful shutdown, health probes, resource limits. Two replicas run without conflict. |
| **M3 — Inference Serving** | 16–21 | Week 7 | Single CR deploys Ollama inference pod with PVC storage. Local Zot model registry operational. Model pulled from in-cluster registry. `curl` returns LLM response. |
| **M4 — Developer UX** | 22–27 | Week 9 | `mpctl` CLI operational. Operator configuration via ConfigMap. Feature gates. CEL validation + validating/defaulting webhooks on CRDs. |
| **M5 — Security Baseline** | 28–33 | Week 11 | Restricted PSS enforced. Per-component service accounts. Network policies. cert-manager TLS. Metrics endpoint secured. Secrets management. |
| **M6 — Air-Gap Ready** | 34–36 | Week 13 | Offline model bundling, preloader DaemonSet, dependency mirroring. Full install in air-gapped Kind cluster — zero internet calls. |
| **M7 — Observable** | 37–39 | Week 14 | Prometheus metrics, Grafana dashboards, PrometheusRule alerts with runbooks, OTel tracing, audit logging. |
| **M8 — Scalable & Reliable** | 40–42 | Week 15 | HPA autoscaling on custom metrics, PDBs, topology spread constraints, priority classes. Inference survives node drain. |
| **M9 — Multi-Model & Routing** | 43–45 | Week 17 | `InferenceEndpoint` CRD, Gateway API + Ingress fallback, multi-model path/header routing, service discovery. |
| **M10 — Multi-Tenant** | 46–47 | Week 18 | RBAC multi-tenancy with ClusterRoles, namespace isolation, storage quotas, service mesh compatibility. |
| **M11 — Rollout Strategies** | 48 | Week 19 | Canary and blue-green model rollouts with auto-rollback. CRD conversion webhooks for API evolution. |
| **M12 — Packaged & Secured** | 49 | Week 20 | Helm chart, OLM bundle, OperatorHub listing. Multi-arch images, SLSA provenance, SBOM, image signing. Supply chain secured. |
| **M13 — v1.0 GA** | 50 | Week 21 | Full e2e test suite. Docs site live. Troubleshooting guide. Web UI + OpenShift console plugin. v1.0.0 tagged and released. Demo video. Blog post. LinkedIn + CNCF Slack announcement. Submit to CNCF Landscape under "AI". |
