# LLMD on Kubernetes — Project Plan

**Project Title:** LLMD on Kubernetes  
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

### Phase 1 — Project Bootstrap & CI (Week 1)

| # | Feature | Description |
|---|---------|-------------|
| 1.1 | **Project Scaffolding** | Initialize Go module, Kubebuilder/Operator SDK project, CI pipeline (GitHub Actions), container build (Dockerfile + Podman). Configure `.golangci.yaml`, `Makefile` with standard targets (`generate`, `manifests`, `test`, `build`, `docker-build`). |
| 1.2 | **Contributing Guide & Governance** | Ship `CONTRIBUTING.md` (development workflow, PR process, code style, Conventional Commits), `CODE_OF_CONDUCT.md`, `LICENSE` (Apache 2.0), `OWNERS`/`CODEOWNERS` for review routing. Define release governance. |
| 1.3 | **Structured Logging** | Use `zap` via controller-runtime with structured JSON log output. Support configurable log verbosity levels (`--zap-log-level`). Include reconciliation context (namespace, name, generation) in all log entries. |

**Verification Gate:**
- [ ] `make build` compiles without errors
- [ ] `make test` runs (even if no tests yet) — CI pipeline green
- [ ] `make docker-build` produces a valid container image
- [ ] `golangci-lint run` passes with zero issues
- [ ] `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `OWNERS` present in repo root
- [ ] GitHub Actions CI workflow triggers on push/PR and passes

---

### Phase 2 — CRD Definitions & Status (Week 2)

| # | Feature | Description |
|---|---------|-------------|
| 2.1 | **LLMDeployment CRD** | Define `LLMDeployment` CRD Go types with `spec` and `status` fields. Include `metav1.Condition` array in status. Run `make generate` and `make manifests` to produce DeepCopy and CRD YAML. |
| 2.2 | **Status Subresource & Conditions** | Implement `status` subresource on `LLMDeployment` following `metav1.Condition` convention. Report conditions: `Ready`, `Progressing`, `Degraded`, `ModelLoaded`, `InferenceReady`. Track `observedGeneration`, `readyReplicas`, `currentModelVersion`, `lastReconcileTime`. |
| 2.3 | **Printer Columns & Short Names** | Define `+kubebuilder:printcolumn` markers so `kubectl get llmdeployments` shows columns (READY, MODEL, RUNTIME, REPLICAS, PHASE, AGE). Register short name `llmd`. |

**Verification Gate:**
- [ ] `kubectl apply -f config/crd/` installs CRD on Kind cluster without errors
- [ ] `kubectl get llmd` returns empty table with correct column headers
- [ ] `kubectl apply -f config/samples/` creates a sample CR successfully
- [ ] `kubectl get llmd -o yaml` shows `status` block (even if empty)
- [ ] CRD schema validation rejects invalid fields (e.g., negative `replicas`)
- [ ] `make generate && make manifests` is idempotent — no diff on re-run

---

### Phase 3 — Core Reconciler (Weeks 2–3)

| # | Feature | Description |
|---|---------|-------------|
| 3.1 | **Operator Controller — Core Reconciler** | Implement the reconciliation loop: watch `LLMDeployment` CRs → create/update Deployments, Services, ConfigMaps for Ollama inference pods. Use server-side apply semantics. |
| 3.2 | **Owner References & Garbage Collection** | Set `ownerReferences` on all child resources (Deployments, Services, ConfigMaps) pointing to the parent `LLMDeployment` CR. Ensures Kubernetes garbage collector cascades deletion automatically. |
| 3.3 | **Event Recording** | Emit Kubernetes Events on all reconciliation actions — deployment created, deployment updated, errors encountered. Primary debugging mechanism for `kubectl describe llmd`. |
| 3.4 | **Idempotent Reconciliation** | Ensure the reconciler is safe to run repeatedly without side effects. Use patch semantics to avoid update conflicts. Handle `resourceVersion` mismatches gracefully with retry. |

**Verification Gate:**
- [ ] Create `LLMDeployment` CR → operator creates Deployment + Service within 30s
- [ ] `kubectl describe llmd <name>` shows Events (e.g., "Created Deployment")
- [ ] `kubectl get deployment` shows child Deployment with correct ownerReference
- [ ] Delete `LLMDeployment` CR → child Deployment and Service are garbage-collected
- [ ] Manually trigger reconcile twice → no errors, no duplicate resources
- [ ] `status.conditions` updated with `Ready` or `Progressing` after reconciliation
- [ ] envtest unit tests pass for reconciler logic

---

### Phase 4 — Reconciler Hardening (Week 3)

| # | Feature | Description |
|---|---------|-------------|
| 4.1 | **Finalizers** | Implement finalizers on `LLMDeployment` to ensure clean teardown of owned resources (PVs, GPU reservations, TLS secrets) before CR deletion completes. Finalizer: `llmd.io/cleanup`. |
| 4.2 | **Requeue Strategy & Rate Limiting** | Configure exponential backoff with jitter for failed reconciliations. Tune `MaxConcurrentReconciles`, `RateLimiter`, and base/max requeue intervals to avoid API server overload. |
| 4.3 | **Drift Detection & Self-Healing** | Watch all owned child resources (Deployments, Services, ConfigMaps). If a child is modified externally (e.g., manual edit), detect the drift and reconcile back to desired state. |

**Verification Gate:**
- [ ] Delete CR → finalizer runs cleanup → CR is fully removed (no stuck `Terminating`)
- [ ] Manually edit child Deployment (e.g., change replicas) → operator detects drift and corrects within 30s
- [ ] Simulate reconcile failure → observe exponential backoff in logs (not immediate rapid retry)
- [ ] `kubectl get llmd <name> -o yaml` shows finalizer in `metadata.finalizers`
- [ ] envtest tests cover finalizer add/remove and drift correction

---

### Phase 5 — Operator Reliability (Week 4)

| # | Feature | Description |
|---|---------|-------------|
| 5.1 | **Leader Election** | Enable controller-runtime leader election (`--leader-elect=true`) so multiple operator replicas can run for HA without conflicting reconciliations. Configure lease duration, renew deadline, and retry period. |
| 5.2 | **Graceful Shutdown** | Handle SIGTERM/SIGINT signals to drain in-flight reconciliations, release leader election leases, and close informer caches cleanly within the pod's `terminationGracePeriodSeconds`. |
| 5.3 | **Operator Liveness & Readiness Probes** | Configure health probes on the operator manager pod. Liveness: `/healthz` — verifies process alive. Readiness: `/readyz` — verifies leader election acquired, informer caches synced, webhooks serving. |
| 5.4 | **Resource Limits for Operator Pod** | Set explicit resource requests and limits on the operator manager container. Default: `requests: {cpu: 100m, memory: 128Mi}`, `limits: {cpu: 500m, memory: 512Mi}`. Configurable via Helm values. |
| 5.5 | **Client-Go QPS & Rate Limiting** | Tune client-go Kubernetes API client rate limits (`QPS`, `Burst`). Default: `QPS: 50, Burst: 100`. Expose as operator configuration flags. |

**Verification Gate:**
- [ ] Deploy 2 operator replicas → only one is active leader, the other is standby
- [ ] Kill leader pod → standby acquires lease and resumes reconciling within lease timeout
- [ ] Send SIGTERM to operator → in-flight reconciliation completes, leader lease released cleanly
- [ ] `kubectl describe pod <operator>` shows liveness/readiness probes configured
- [ ] Operator pod has resource requests/limits in pod spec
- [ ] Logs show client-go QPS/Burst configuration at startup

---

### Phase 6 — Inference Runtime & Model Serving (Weeks 4–5)

| # | Feature | Description |
|---|---------|-------------|
| 6.1 | **Single CR Full-Stack Deploy** | A single `LLMDeployment` CR provisions the inference runtime (Ollama pod), Service, and ConfigMap — no extra steps. User does `kubectl apply` and gets a working inference endpoint. |
| 6.2 | **Health & Readiness Probes (Inference Pods)** | Custom health checks for model loading state, GPU memory, and inference readiness on Ollama pods. Liveness: HTTP check on Ollama API. Readiness: verify model is loaded and accepting requests. |
| 6.3 | **Persistent Storage Strategy** | Define volume strategy for model cache: `ReadWriteOnce` PVCs per inference pod (default). Dynamic provisioning with configurable `storageClassName` via CRD `spec.storage`. Reclaim policy: `Retain` for model data, `Delete` for ephemeral caches. |

**Verification Gate:**
- [ ] `kubectl apply -f llmdeployment.yaml` → Ollama pod running, model pulled, inference endpoint responding within 5 min (warm cache)
- [ ] `curl <service-ip>:8080/api/generate` returns a valid LLM response
- [ ] Kill inference pod → Kubernetes restarts it, model reloads from PVC cache
- [ ] `kubectl get llmd` shows `Ready=True` after model is loaded
- [ ] PVC created with correct size and access mode from CRD spec
- [ ] Readiness probe gates traffic until model is fully loaded

---

### Phase 7 — Local Model Registry (Week 5)

| # | Feature | Description |
|---|---------|-------------|
| 7.1 | **Local Model Registry** | Deploy OCI-compatible local registry (Zot) for storing and distributing model artifacts within the cluster. Managed via `ModelRegistry` CRD. |
| 7.2 | **ModelRegistry CRD** | Define `ModelRegistry` CRD Go types with spec (type, image, storage, auth, tls, sync) and status (phase, endpoint, modelCount, conditions). Printer columns: READY, TYPE, ENDPOINT, MODELS, AGE. Short name: `mr`. |
| 7.3 | **Registry Integration with Inference** | Connect `LLMDeployment` reconciler to pull models from the local `ModelRegistry` (via `spec.model.registry` reference). Support both local and remote registry types. |

**Verification Gate:**
- [ ] `kubectl apply -f modelregistry.yaml` → Zot registry pod running and healthy
- [ ] `kubectl get mr` shows correct printer columns with `Ready=True`
- [ ] Push a model artifact to registry via Skopeo/ORAS → `status.modelCount` increments
- [ ] Create `LLMDeployment` referencing local registry → model pulled from in-cluster registry (not internet)
- [ ] Delete `ModelRegistry` CR → registry pod and PVC cleaned up via owner references

---

### Phase 8 — CLI & Operator Configuration (Week 6)

| # | Feature | Description |
|---|---------|-------------|
| 8.1 | **Basic CLI (`llmdctl`)** | CLI tool (Cobra + Viper) for creating, listing, inspecting, and deleting LLM deployments. Commands: `llmdctl create`, `llmdctl get`, `llmdctl describe`, `llmdctl delete`, `llmdctl logs`. |
| 8.2 | **Uninstall & Cleanup Strategy** | Ship `llmdctl uninstall --cleanup` command. Define operator uninstall behavior: configurable cascade delete vs orphan policy for managed CRs. Document manual recovery procedures. |
| 8.3 | **Operator Configuration** | Support operator-level configuration via ConfigMap and CLI flags: default runtime, log level, metrics port, health probe port, leader election namespace, concurrent reconciles, sync period, webhook port. Document all options. |
| 8.4 | **Feature Gates** | Implement feature gate mechanism (`--feature-gates=WebUI=true,CanaryRollouts=false`) to enable/disable experimental features without code changes. Gate all non-GA features. Support `Alpha`, `Beta`, `GA` maturity levels. |

**Verification Gate:**
- [ ] `llmdctl create --model llama3:8b` → CR created, operator reconciles, inference running
- [ ] `llmdctl get` → lists all LLMDeployments with status
- [ ] `llmdctl delete <name>` → CR deleted, resources cleaned up
- [ ] `llmdctl uninstall --cleanup` → all CRs and operator resources removed
- [ ] Operator reads configuration from ConfigMap at startup — log level change takes effect
- [ ] `--feature-gates=WebUI=false` disables Web UI reconciliation — verified in logs

---

### Phase 9 — CRD Validation & Defaults (Week 7)

| # | Feature | Description |
|---|---------|-------------|
| 9.1 | **CRD Validation (CEL Rules)** | Use Common Expression Language (CEL) `x-kubernetes-validations` for field validation: `spec.replicas >= 0`, `spec.autoscaling.minReplicas <= maxReplicas`, `spec.serving.port` in range 1–65535, enum checks on `spec.runtime`. |
| 9.2 | **Validating Webhook** | Implement validating admission webhook for complex cross-field validation: GPU count vs model size compatibility, runtime-specific field requirements, model exists in referenced registry. |
| 9.3 | **Defaulting (Mutating) Webhook** | Implement defaulting webhook to set sensible values for omitted fields: `spec.replicas: 1`, `spec.runtime: ollama`, `spec.serving.port: 8080`, `spec.serving.timeout: 120s`, `spec.storage.accessMode: ReadWriteOnce`. |

**Verification Gate:**
- [ ] Submit CR with `replicas: -1` → rejected by CEL validation with clear error message
- [ ] Submit CR with `minReplicas > maxReplicas` → rejected by CEL
- [ ] Submit CR with unsupported `runtime: foo` → rejected by validating webhook
- [ ] Submit CR with no `replicas` field → defaulting webhook sets `replicas: 1`
- [ ] Submit CR with no `runtime` field → defaulting webhook sets `runtime: ollama`
- [ ] Webhook TLS certificates provisioned via cert-manager — webhook pod starts clean
- [ ] envtest tests cover all validation and defaulting rules

---

### Phase 10 — Security Hardening (Weeks 7–8)

| # | Feature | Description |
|---|---------|-------------|
| 10.1 | **Pod Security Standards (PSS)** | Enforce `restricted` Pod Security Standard for all operator-managed pods. On OpenShift, define and bind appropriate SecurityContextConstraints (SCCs). All pods run as non-root with read-only root filesystem, `seccompProfile: RuntimeDefault`, and `capabilities.drop: [ALL]`. |
| 10.2 | **SecurityContext Hardening** | Set explicit `securityContext` on every container: `runAsNonRoot: true`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `seccompProfile: RuntimeDefault`, drop all capabilities. Define exceptions only where required (e.g., GPU device plugin). |
| 10.3 | **Dedicated Service Accounts** | Create separate ServiceAccounts for each component — operator manager, inference pods, model registry, preloader DaemonSet. Bind least-privilege RBAC roles to each. Disable automount of SA tokens where not needed. |
| 10.4 | **Operator Metrics Endpoint Security** | Protect the operator's `/metrics` Prometheus endpoint using kube-rbac-proxy sidecar. Require ServiceAccount token authentication for metrics scraping. Ship ServiceMonitor with TLS configuration. |

**Verification Gate:**
- [ ] All managed pods pass `kubectl label ns <ns> pod-security.kubernetes.io/enforce=restricted` — no violations
- [ ] `kubectl get pod <inference> -o jsonpath='{.spec.containers[0].securityContext}'` shows all hardening fields
- [ ] Each component has its own ServiceAccount — `kubectl get sa` shows 4+ SAs
- [ ] Inference pod SA cannot list nodes or access kube-system — RBAC test fails as expected
- [ ] `curl <operator-ip>:8443/metrics` without valid token → 401 Unauthorized
- [ ] ServiceMonitor configured and Prometheus scrapes metrics successfully with auth

---

### Phase 11 — Network & Certificate Security (Week 8)

| # | Feature | Description |
|---|---------|-------------|
| 11.1 | **Certificate & Trust Management** | Internal PKI bootstrap for TLS between operator, registry, and inference pods using cert-manager. Auto-issue and auto-renew certificates. Support custom CA for air-gapped environments. |
| 11.2 | **Network Policies** | Ship default NetworkPolicies restricting traffic: operator ↔ API server, operator ↔ inference pods (metrics scrape), inference pods ↔ registry, deny all ingress by default except Gateway/Ingress traffic to inference endpoints. Per-namespace tenant isolation. |
| 11.3 | **Secrets Management Strategy** | Support Kubernetes Secrets (default), external-secrets-operator (ESO) integration for HashiCorp Vault / AWS Secrets Manager / Azure Key Vault, and cert-manager for automated TLS certificate lifecycle. Document rotation strategy for all credentials. |

**Verification Gate:**
- [ ] cert-manager issues TLS certificates for operator webhook, registry, and inter-pod communication
- [ ] Certificates auto-renew before expiry — verify with `kubectl get certificate`
- [ ] `kubectl exec -it <inference-pod> -- curl <operator-metrics-ip>` → blocked by NetworkPolicy
- [ ] `kubectl exec -it <inference-pod> -- curl <registry-ip>:5000` → allowed by NetworkPolicy
- [ ] External traffic to inference endpoint only allowed via Gateway/Ingress — direct pod access blocked
- [ ] Secrets created by operator are of correct type (Opaque, TLS, docker-registry as appropriate)

---

### Phase 12 — Air-Gap & Offline Support (Weeks 9–10)

| # | Feature | Description |
|---|---------|-------------|
| 12.1 | **Offline Model Bundling** | Tooling to package model weights, tokenizer, and runtime into a single OCI artifact for air-gapped transfer. CLI: `llmdctl bundle --model llama3:8b --output llama3-bundle.tar`. |
| 12.2 | **Model Preloader DaemonSet** | DaemonSet that pre-pulls and caches model artifacts on GPU nodes from the local registry. Managed by the operator based on `spec.offlineMode.preload: true`. |
| 12.3 | **Dependency Mirroring** | Helm chart / manifest generation that bundles all container images and charts for offline install. Script: `hack/airgap-bundle.sh` produces a single tarball with all dependencies. |

**Verification Gate:**
- [ ] `llmdctl bundle --model llama3:8b` produces valid OCI tarball
- [ ] Load bundle into air-gapped Kind cluster (no internet) → model available in local registry
- [ ] Create `LLMDeployment` in air-gapped cluster → inference running with zero internet calls
- [ ] Preloader DaemonSet pre-pulls model to node cache → inference pod starts faster on second deploy
- [ ] `hack/airgap-bundle.sh` produces tarball containing all operator + runtime images
- [ ] Full operator install from bundle in network-isolated environment — end to end

---

### Phase 13 — Observability & Alerting (Weeks 10–11)

| # | Feature | Description |
|---|---------|-------------|
| 13.1 | **Prometheus Metrics** | Expose custom Prometheus metrics from operator and inference pods: `llmd_reconciliation_duration_seconds`, `llmd_inference_requests_total`, `llmd_inference_latency_seconds`, `llmd_model_load_duration_seconds`, `llmd_gpu_memory_used_bytes`. Register in `internal/metrics/`. |
| 13.2 | **Grafana Dashboards** | Ship pre-built Grafana dashboards as ConfigMaps: Operator Health (reconciliation rate, errors, queue depth), Inference Performance (latency p50/p95/p99, throughput, GPU utilization), Model Registry (pull rate, storage usage). |
| 13.3 | **OpenTelemetry Tracing** | Instrument reconciliation loop and inference request path with OpenTelemetry spans. Support OTLP export to any OTel-compatible backend. Trace model pull → load → first inference. |
| 13.4 | **Runbooks & PrometheusRule Alerts** | Ship `PrometheusRule` CRs: `LLMDOperatorDown`, `ReconciliationFailureRate`, `InferenceLatencyHigh`, `GPUMemoryExhausted`, `ModelLoadFailed`, `CertificateExpiringSoon`. Include runbook URLs in alert annotations. |
| 13.5 | **Audit Logging** | Immutable audit trail for model deployments, access, and configuration changes. Log to stdout (structured JSON) and optionally to a dedicated audit log sink. |

**Verification Gate:**
- [ ] Prometheus scrapes operator metrics — `curl <metrics>/metrics` returns custom metrics
- [ ] Grafana dashboard loads and shows live data (reconciliation rate, inference latency)
- [ ] OTel traces appear in Jaeger/Tempo for a model deployment lifecycle
- [ ] Simulate high latency → `InferenceLatencyHigh` alert fires within evaluation interval
- [ ] Simulate reconciliation failure → `ReconciliationFailureRate` alert fires
- [ ] Audit log entries recorded for CR create/update/delete in structured JSON

---

### Phase 14 — Autoscaling & Pod Reliability (Week 11)

| # | Feature | Description |
|---|---------|-------------|
| 14.1 | **Autoscaling (HPA + Custom Metrics)** | Scale inference replicas based on request queue depth, latency percentiles, and GPU utilization. Register custom metrics via Prometheus adapter or KEDA. Configurable via CRD `spec.autoscaling`. |
| 14.2 | **PodDisruptionBudgets (PDBs)** | Automatically create PDBs for inference Deployments. Default: `minAvailable: 1` or `maxUnavailable: 1` depending on replica count. Configurable via CRD `spec.disruption`. |
| 14.3 | **Topology Spread Constraints** | Spread inference pods across failure domains (zones, nodes). Configurable via CRD `spec.topologySpread`. Default: `topologyKey: kubernetes.io/hostname`, `maxSkew: 1`, `whenUnsatisfiable: DoNotSchedule`. |
| 14.4 | **Priority Classes** | Ship PriorityClasses: `llmd-operator-critical` (system-level), `llmd-inference-high` (inference pods), `llmd-preloader-low` (preloader DaemonSet). Ensures inference survives cluster pressure. |

**Verification Gate:**
- [ ] Generate load → HPA scales inference replicas from 1 → 3 within 60s
- [ ] Load drops → HPA scales back to minReplicas within cooldown period
- [ ] `kubectl drain <node>` → PDB prevents evicting all inference pods simultaneously
- [ ] With 3 replicas across 2 nodes → pods spread per topology constraint (not all on one node)
- [ ] Under cluster memory pressure → preloader pods preempted before inference pods (priority class)
- [ ] `kubectl get pdb` shows PDB created with correct minAvailable

---

### Phase 15 — Networking & Traffic Routing (Week 12)

| # | Feature | Description |
|---|---------|-------------|
| 15.1 | **InferenceEndpoint CRD** | Define `InferenceEndpoint` CRD with spec (gatewayAPI, ingress, tls, routes, rateLimit, authentication) and status (phase, host, routeCount, conditions). Printer columns: READY, HOST, MODELS, AGE. Short name: `ie`. |
| 15.2 | **Gateway API (Primary) + Ingress Fallback** | Use Gateway API as the primary traffic routing mechanism. Support HTTPRoute for model routing by path/header/tenant. Fall back to Ingress for clusters without Gateway API. Ship GatewayClass and Gateway manifests. |
| 15.3 | **Multi-Model Routing** | Route requests to different models by path (`/v1/llama3`, `/v1/mistral`), header (`x-model: llama3-8b`), or tenant (namespace). Reconcile HTTPRoute/Ingress rules from `InferenceEndpoint` CR. |
| 15.4 | **DNS & Service Discovery** | ClusterIP services for internal inference traffic, headless services for StatefulSet-based serving. Support ExternalDNS integration for external endpoint registration. Document client connection patterns. |

**Verification Gate:**
- [ ] `kubectl apply -f inferenceendpoint.yaml` → Gateway + HTTPRoutes created
- [ ] `curl <gateway>/v1/llama3` → routed to llama3 inference pods
- [ ] `curl -H "x-model: mistral-7b" <gateway>/v1/chat` → routed to mistral pods
- [ ] `kubectl get ie` shows READY=True, HOST, route count
- [ ] On cluster without Gateway API, `ingress.enabled: true` creates Ingress resource instead
- [ ] Internal service DNS resolution: `<name>.<namespace>.svc.cluster.local` resolves correctly

---

### Phase 16 — Multi-Tenancy & Storage Quotas (Weeks 12–13)

| # | Feature | Description |
|---|---------|-------------|
| 16.1 | **RBAC & Multi-Tenancy** | Namespace-scoped tenancy, per-model RBAC policies, and quota enforcement. Ship ClusterRoles (`llmd-admin`, `llmd-editor`, `llmd-viewer`) for binding to users/groups per namespace. |
| 16.2 | **Storage Quotas** | Enforce per-namespace and per-model storage quotas via `ResourceQuota` integration. Prevent a single tenant from exhausting cluster storage. Expose `status.storageUsed` on CRDs. |
| 16.3 | **Service Mesh Compatibility** | Document and test compatibility with Istio and OpenShift Service Mesh. Support opt-in/opt-out sidecar injection annotations (`sidecar.istio.io/inject`). Handle GPU pod interference from sidecars. |

**Verification Gate:**
- [ ] User with `llmd-viewer` role can `kubectl get llmd` but cannot `kubectl delete llmd`
- [ ] User with `llmd-editor` role can create/update LLMDeployments but not modify operator config
- [ ] Tenant in namespace A cannot see or modify LLMDeployments in namespace B
- [ ] Create models exceeding storage quota → CR rejected or status shows `Degraded` with quota message
- [ ] `status.storageUsed` accurately reports current PVC usage
- [ ] Inference pods with `sidecar.istio.io/inject: "false"` annotation → no sidecar injected

---

### Phase 17 — Model Versioning & Rollout Strategies (Weeks 13–14)

| # | Feature | Description |
|---|---------|-------------|
| 17.1 | **Model Versioning & Canary Rollouts** | Support blue-green and canary deployments when updating model versions. Traffic split by percentage (e.g., 90/10 old/new). Automatic rollback on error-rate spike or latency threshold breach. |
| 17.2 | **CRD Evolution Plan (Conversion Webhooks)** | Implement conversion webhook infrastructure for `v1alpha1` → `v1beta1` → `v1` CRD evolution. Define API deprecation policy: `v1alpha1` supported for 2 releases after `v1beta1` GA. |
| 17.3 | **ModelRegistry & InferenceEndpoint CRD Finalization** | Finalize full CRD specifications for `ModelRegistry` (auth, sync, TLS) and `InferenceEndpoint` (rate limiting, authentication). Add CEL validation, status subresources, and printer columns to both. |

**Verification Gate:**
- [ ] Update model version in CR → canary deployment created with 10% traffic split
- [ ] Canary passes health checks → traffic gradually shifted to 100% new version
- [ ] Canary fails health checks → automatic rollback to previous version within 60s
- [ ] Blue-green: update `spec.model.version` → old pods kept until new pods are Ready, then switched
- [ ] Conversion webhook converts `v1alpha1` CR to `v1beta1` transparently
- [ ] All 3 CRDs have complete CEL validation, status conditions, and printer columns

---

### Phase 18 — Helm Chart & OLM Packaging (Weeks 14–15)

| # | Feature | Description |
|---|---------|-------------|
| 18.1 | **Helm Chart** | Production Helm chart with configurable values: operator image, replicas, resources, feature gates, log level, storage class, network policies toggle, priority classes. Includes all config/ manifests as templates. |
| 18.2 | **OLM Bundle** | Generate Operator Lifecycle Manager bundle: ClusterServiceVersion (CSV), CRDs, RBAC, metadata/annotations. Configure install modes (OwnNamespace, AllNamespaces). |
| 18.3 | **OLM Release Channels** | Define upgrade channels: `stable` (GA, manual approval default), `fast` (latest, auto-approval option), `candidate` (pre-release/RC). Configure `replaces`, `skips`, `skipRange` in CSV. |
| 18.4 | **OpenShift OperatorHub One-Click Install** | Publish operator to OperatorHub catalog. Includes CSV with icon, description, maturity level, install modes. Users install with a single click from OpenShift web console. |
| 18.5 | **Operator Capability Level Targeting** | Target OLM Capability Level III (Full Lifecycle): Basic Install, Seamless Upgrades, Full Lifecycle. Map each feature to a capability level. Document Level IV–V targets for v1.1+. |

**Verification Gate:**
- [ ] `helm install llmd charts/llmd/ --namespace llmd-system` → operator running, CRDs installed
- [ ] `helm upgrade llmd charts/llmd/ --set operator.logLevel=debug` → operator restarts with new log level
- [ ] `helm uninstall llmd` → clean removal of all operator resources
- [ ] `operator-sdk bundle validate ./bundle` → passes all checks
- [ ] `operator-sdk scorecard ./bundle` → passes OLM best practices
- [ ] Install from OperatorHub catalog on CRC/OpenShift → operator running within 2 min
- [ ] CSV shows Capability Level III badge

---

### Phase 19 — Container Security & Supply Chain (Week 15)

| # | Feature | Description |
|---|---------|-------------|
| 19.1 | **Security Scanning & SBOM** | Container image scanning (Trivy) in CI. Go dependency audit (`govulncheck`). Generate Software Bill of Materials (SBOM) in SPDX/CycloneDX format with every build. |
| 19.2 | **SLSA Provenance Attestation** | Generate SLSA Level 3 build provenance attestations using GitHub Actions OIDC and cosign/SLSA verifier. Attach attestations to container images. |
| 19.3 | **Multi-Architecture Container Builds** | Build and publish `linux/amd64` and `linux/arm64` multi-arch container images using Podman manifest lists or `docker buildx`. Test on both architectures in CI. |
| 19.4 | **Container Image Tagging Strategy** | Enforce strict tagging: never `:latest` in production manifests. Tag as `:v1.0.0` (semver) and `@sha256:...` (digest). Pin all image references in Helm chart and OLM bundle by digest. |

**Verification Gate:**
- [ ] Trivy scan of operator image → zero critical/high CVEs
- [ ] `govulncheck ./...` → zero known vulnerabilities in Go dependencies
- [ ] SBOM generated and attached to container image as attestation
- [ ] `cosign verify <image>` → signature and SLSA provenance verified
- [ ] `docker manifest inspect <image>` → shows both amd64 and arm64 manifests
- [ ] All image references in Helm chart and OLM bundle use `@sha256:` digest

---

### Phase 20 — Upgrade Testing & Resilience (Week 16)

| # | Feature | Description |
|---|---------|-------------|
| 20.1 | **Operator Upgrade & Rollback Testing** | Automated test matrix: N-1 → N (standard upgrade), N → N+1 (forward compatibility). Test that running LLM workloads survive operator upgrades without downtime. Document rollback procedures. |
| 20.2 | **End-to-End Testing (Full Suite)** | Comprehensive integration test suite on Kind/k3s covering all features: CR lifecycle, air-gap install, autoscaling, canary rollout, multi-model routing, RBAC, network policies, PDBs. Run in CI on every PR. |
| 20.3 | **Backup & Disaster Recovery** | Document backup strategy using Velero or OADP for CRs, model registry data, and PVCs. Define RPO/RTO targets. Test full cluster restore with operator and workloads. |

**Verification Gate:**
- [ ] Upgrade operator from v0.9 → v1.0 → running LLMDeployments continue serving without restart
- [ ] OLM upgrade via `stable` channel → CSV transitions cleanly from old to new version
- [ ] Documented rollback: uninstall new CSV, reinstall old CSV → operator recovers
- [ ] Full e2e suite passes on Kind: all features exercised, zero flakes over 3 consecutive runs
- [ ] Velero backup of namespace → delete namespace → Velero restore → all CRs and workloads recovered
- [ ] DR runbook tested: cluster rebuild → operator install → restore from backup → inference serving

---

### Phase 21 — Documentation & Troubleshooting (Weeks 16–17)

| # | Feature | Description |
|---|---------|-------------|
| 21.1 | **Documentation Site** | User guide, API reference (auto-generated from CRDs), architecture diagrams, air-gap install guide. Published via MkDocs Material to GitHub Pages. |
| 21.2 | **Troubleshooting Guide** | Comprehensive guide covering top failure modes: model pull timeout, GPU not detected, webhook cert expired, leader election lost, reconciliation stuck, OOM on inference pod, air-gap registry unreachable. Include diagnostic commands and log patterns. |
| 21.3 | **Changelog Automation** | Adopt Conventional Commits. Automate changelog with `git-cliff` or `release-drafter`. Generate per-release changelogs in GitHub Releases. Include breaking changes, deprecations, migration notes. |
| 21.4 | **API Deprecation Policy** | Document and publish deprecation policy: `v1alpha1` supported for 2 releases after `v1beta1` GA. Announce deprecations in changelogs and operator logs at startup. |

**Verification Gate:**
- [ ] Docs site builds and deploys to GitHub Pages — all pages render without broken links
- [ ] API reference auto-generated from CRD Go types — matches current CRD spec
- [ ] Troubleshooting guide covers ≥10 failure scenarios with step-by-step resolution
- [ ] `git-cliff` generates valid changelog from commit history
- [ ] Deprecation warnings appear in operator logs when `v1alpha1` CRs are created (after `v1beta1` exists)

---

### Phase 22 — Web UI & Console Plugin (Week 17)

| # | Feature | Description |
|---|---------|-------------|
| 22.1 | **Operator Web UI (Standalone)** | Lightweight React + PatternFly management console for deploying, scaling, monitoring, and rolling back LLM models via browser. Opt-in via `spec.ui.enabled`. CRD-driven — UI is a frontend to the Kubernetes API. Proxied via kube-apiserver. |
| 22.2 | **OpenShift Console Dynamic Plugin** | Wrap standalone Web UI as an OpenShift console dynamic plugin. Integrates natively into the OpenShift web console. Registered via `ConsolePlugin` CR. |

**Verification Gate:**
- [ ] `spec.ui.enabled: true` → UI pod deployed, accessible via Service/Route
- [ ] UI lists LLMDeployments, ModelRegistries, and InferenceEndpoints
- [ ] Create new LLMDeployment from UI → CR created, operator reconciles, inference running
- [ ] Scale replicas from UI → CR updated, operator scales pods
- [ ] On OpenShift with console plugin → UI appears as sidebar item in OpenShift console
- [ ] `spec.ui.enabled: false` → no UI resources deployed (feature gate respected)

---

### Phase 23 — v1.0 Release (Week 18)

| # | Feature | Description |
|---|---------|-------------|
| 23.1 | **v1.0 Release** | Semantic versioning, final changelog, GitHub release automation via GoReleaser. Tag `v1.0.0`, publish container images, Helm chart, OLM bundle to OperatorHub catalog. |
| 23.2 | **Demo Video & README** | Record 2-minute demo video showing `kubectl apply` → model running → inference response. Update README with architecture diagram, quickstart, badges (CI, Go Report Card, release). |
| 23.3 | **Release Announcement** | Post on LinkedIn, CNCF Slack (#kubernetes-operators), publish blog post. Submit to CNCF Landscape under "AI" category. |

**Verification Gate:**
- [ ] `v1.0.0` tag created, GitHub Release published with changelog and binaries
- [ ] Container images published with `:v1.0.0` tag and `@sha256:` digest
- [ ] Helm chart version `1.0.0` installable from chart repository
- [ ] OLM bundle available in OperatorHub catalog — one-click install works
- [ ] Demo video demonstrates full lifecycle in under 2 minutes
- [ ] README has: architecture diagram, quickstart (< 5 min), CI badge green, release badge

---

## 8. Milestones & Timeline

| Milestone | Phases | Target | Deliverables |
|-----------|--------|--------|-------------|
| **M1 — Walking Skeleton** | 1–3 | Week 3 | Repo scaffolded, CI green, `LLMDeployment` CRD installed, core reconciler creates Deployments with owner references, events, and status conditions. |
| **M2 — Hardened Operator** | 4–5 | Week 4 | Finalizers, drift detection, exponential backoff. Leader election, graceful shutdown, operator probes, resource limits. Two replicas run without conflict. |
| **M3 — Inference Serving** | 6–7 | Week 5 | Single CR deploys Ollama inference pod with PVC storage. Local model registry (Zot) operational. Model pulled from in-cluster registry. `curl` returns LLM response. |
| **M4 — Developer UX** | 8–9 | Week 7 | `llmdctl` CLI operational. Operator configuration via ConfigMap. Feature gates. CEL validation + defaulting webhook on CRDs. |
| **M5 — Security Baseline** | 10–11 | Week 8 | Restricted PSS enforced. Per-component service accounts. Network policies. cert-manager TLS. Metrics endpoint secured. |
| **M6 — Air-Gap Ready** | 12 | Week 10 | Offline model bundling, preloader DaemonSet, dependency mirroring. Full install in air-gapped Kind cluster — zero internet calls. |
| **M7 — Observable** | 13 | Week 11 | Prometheus metrics, Grafana dashboards, OTel tracing, PrometheusRule alerts with runbooks, audit logging. |
| **M8 — Scalable & Reliable** | 14 | Week 11 | HPA autoscaling, PDBs, topology spread constraints, priority classes. Inference survives node drain. |
| **M9 — Multi-Model** | 15–16 | Week 13 | `InferenceEndpoint` CRD, Gateway API routing, multi-model path/header routing. RBAC multi-tenancy, storage quotas. |
| **M10 — Rollout Strategies** | 17 | Week 14 | Canary and blue-green model deployments. CRD conversion webhooks. All 3 CRDs finalized. |
| **M11 — Packaged** | 18–19 | Week 15 | Helm chart, OLM bundle, OperatorHub listing. Multi-arch images, SLSA provenance, SBOM, image signing. |
| **M12 — Battle-Tested** | 20–21 | Week 17 | Full e2e test suite. Operator upgrade test matrix. Backup/DR documented. Docs site live. Troubleshooting guide. Changelog automation. |
| **M13 — v1.0 GA** | 22–23 | Week 18 | Web UI + OpenShift console plugin. v1.0.0 tagged and released. Demo video. Blog post. OperatorHub one-click install verified. |

