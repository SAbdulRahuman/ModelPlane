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

### Phase 1 — Foundation (Weeks 1–4)
| # | Feature | Description |
|---|---------|-------------|
| 1.1 | **Project Scaffolding** | Initialize Go module, Kubebuilder/Operator SDK project, CI pipeline, container build. |
| 1.2 | **Custom Resource Definitions (CRDs)** | Define `LLMDeployment`, `ModelRegistry`, and `InferenceEndpoint` CRDs with validation webhooks. |
| 1.3 | **Operator Controller — Core Reconciler** | Implement the reconciliation loop: watch CRs → create/update Deployments, Services, ConfigMaps. |
| 1.4 | **Single CR Full-Stack Deploy** | A single `LLMDeployment` CR provisions the model registry, inference runtime, service, and autoscaler — no extra steps. |
| 1.5 | **Local Model Registry** | OCI-compatible local registry for storing and distributing model artifacts within the cluster. |
| 1.6 | **Basic CLI (`llmdctl`)** | CLI tool for creating, listing, and deleting LLM deployments. |

### Phase 2 — Air-Gapped & Offline (Weeks 5–8)
| # | Feature | Description |
|---|---------|-------------|
| 2.1 | **Offline Model Bundling** | Tooling to package model weights, tokenizer, and runtime into a single OCI artifact for air-gapped transfer. |
| 2.2 | **Model Preloader DaemonSet** | DaemonSet that pre-pulls and caches model artifacts on GPU nodes from the local registry. |
| 2.3 | **Dependency Mirroring** | Helm chart / manifest generation that bundles all container images and charts for offline install. |
| 2.4 | **Certificate & Trust Management** | Internal PKI bootstrap for TLS between operator, registry, and inference pods in isolated networks. |
| 2.5 | **Health & Readiness Probes** | Custom health checks for model loading state, GPU memory, and inference readiness. |

### Phase 3 — Enterprise Features (Weeks 9–14)
| # | Feature | Description |
|---|---------|-------------|
| 3.1 | **Autoscaling (HPA + Custom Metrics)** | Scale inference replicas based on request queue depth, latency percentiles, and GPU utilization. |
| 3.2 | **Multi-Model Routing & Gateway** | Ingress/Gateway API integration to route requests to different models by path, header, or tenant. |
| 3.3 | **Model Versioning & Canary Rollouts** | Support blue-green and canary deployments when updating model versions. |
| 3.4 | **RBAC & Multi-Tenancy** | Namespace-scoped tenancy, per-model RBAC policies, and quota enforcement. |
| 3.5 | **Observability Stack** | Prometheus metrics, Grafana dashboards, OpenTelemetry tracing for inference latency and throughput. |
| 3.6 | **Audit Logging** | Immutable audit trail for model deployments, access, and configuration changes. |
| 3.7 | **Operator Web UI (Optional)** | Lightweight management console for deploying, scaling, monitoring, and rolling back LLM models via browser. Opt-in via `spec.ui.enabled`. Works standalone on Kubernetes and as an OpenShift console dynamic plugin. Every UI action is CRD-driven — the UI is a frontend to the Kubernetes API, not a bypass. |

### Phase 4 — Hardening & Release (Weeks 15–18)
| # | Feature | Description |
|---|---------|-------------|
| 4.1 | **End-to-End Testing** | Integration test suite running on Kind/k3s with GPU simulation. |
| 4.2 | **Security Scanning & SBOM** | Container image scanning, Go dependency audit, and Software Bill of Materials generation. |
| 4.3 | **Documentation Site** | User guide, API reference (auto-generated from CRDs), architecture diagrams, air-gap install guide. |
| 4.4 | **Helm Chart & OLM Bundle** | Production Helm chart and Operator Lifecycle Manager bundle for OpenShift/OKD. |
| 4.5 | **OpenShift OperatorHub One-Click Install** | Publish operator to OperatorHub catalog; users install with a single click from the OpenShift web console. Includes CSV, icon, description, and install modes (OwnNamespace, AllNamespaces). |
| 4.6 | **v1.0 Release** | Semantic versioning, changelog, GitHub release automation. |

---

## 3. Architecture Overview

```text
┌──────────────────────────────────────────────────────────┐
│             Kubernetes / OpenShift Cluster                │
│                                                          │
│  ┌──────────────┐    ┌────────────────────────────────┐  │
│  │  llmd-operator│───▶│  LLMDeployment Controller      │  │
│  │  (manager)    │    │  ModelRegistry Controller       │  │
│  └──────┬───────┘    │  InferenceEndpoint Controller   │  │
│         │            └────────────────────────────────┘  │
│         │                                                │
│         ▼                                                │
│  ┌──────────────┐    ┌──────────────┐                    │
│  │ Model Registry│◀──│ Model Preloader│ (DaemonSet)      │
│  │ (OCI / local) │    │ (GPU nodes)   │                  │
│  └──────────────┘    └──────────────┘                    │
│         │                                                │
│         ▼                                                │
│  ┌──────────────────────────────────────┐                │
│  │  Inference Pods (Ollama)              │                │
│  │  ┌────────┐ ┌────────┐ ┌────────┐   │                │
│  │  │ Model A│ │ Model B│ │ Model C│   │                │
│  │  └────────┘ └────────┘ └────────┘   │                │
│  └──────────────────────────────────────┘                │
│         ▲                                                │
│  ┌──────┴───────┐                                        │
│  │ Gateway /     │◀── External Traffic                   │
│  │ Ingress       │                                       │
│  └──────────────┘                                        │
└──────────────────────────────────────────────────────────┘
```

---

## 4. Technology Stack

| Layer | Technology |
|-------|-----------|
| Language | Go 1.22+ |
| Operator Framework | Kubebuilder v4 / controller-runtime |
| Inference Runtime (v1) | Ollama (CPU + GPU) |
| Inference Runtimes (v1.1+) | vLLM, llama.cpp, Triton Inference Server |
| Model Format | GGUF (v1), SafeTensors, ONNX (v1.1+) |
| Container Registry | Distribution (CNCF) / Zot (air-gap) |
| Target Platforms | Kubernetes 1.28+, OpenShift 4.14+ |
| Packaging | Helm 3, Kustomize, OLM (OperatorHub) |
| CI/CD | GitHub Actions, Tekton (air-gap) |
| Observability | Prometheus, Grafana, OpenTelemetry |
| Testing | Ginkgo, Gomega, Kind, chainsaw |
| CLI | Cobra + Viper (`llmdctl`) |
| Web UI | React / Next.js, PatternFly (OpenShift-native), proxied via Kubernetes API |
| Docs | MkDocs Material |

---

## 5. CRD Design (Draft)

```yaml
apiVersion: llmd.io/v1alpha1
kind: LLMDeployment
metadata:
  name: llama3-8b
  namespace: ai-team
spec:
  model:
    registry: local-registry          # or "remote"
    name: llama3:8b                   # Ollama model tag
    format: gguf
    version: "1.0.0"
  runtime: ollama                     # v1: ollama only | v1.1+: vllm, llama.cpp, triton
  replicas: 2
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 8
    targetQueueDepth: 10
  resources:
    gpu:
      type: nvidia.com/gpu
      count: 4
      memory: 80Gi
  serving:
    port: 8080
    maxConcurrency: 64
    timeout: 120s
  offlineMode:
    enabled: true
    preload: true
    cachePath: /models
  ui:
    enabled: true                     # opt-in web management console
    route: true                       # create OpenShift Route / Ingress automatically
```

---

## 6. Repository Structure (Planned)

```
llmd/
├── api/
│   └── v1alpha1/           # CRD Go types & deepcopy
├── cmd/
│   ├── manager/            # Operator entrypoint
│   └── llmdctl/            # CLI tool
├── internal/
│   ├── controller/         # Reconcilers
│   ├── registry/           # Model registry client
│   ├── runtime/            # Ollama adapter (v1); pluggable interface for v1.1+
│   ├── preloader/          # Model preload logic
│   └── webhook/            # Admission webhooks
├── ui/                         # Web UI source
│   ├── src/                    #   React / Next.js app
│   ├── openshift-plugin/       #   OpenShift console dynamic plugin
│   ├── Dockerfile              #   UI container build
│   └── package.json
├── config/
│   ├── crd/                # Generated CRD manifests
│   ├── rbac/               # RBAC manifests
│   ├── manager/            # Operator deployment
│   └── samples/            # Example CRs
├── bundle/                     # OLM operator bundle (CSV, CRDs, metadata)
│   ├── manifests/              #   ClusterServiceVersion + CRDs
│   └── metadata/               #   annotations.yaml, dependencies
├── charts/
│   └── llmd/                   # Helm chart
├── hack/
│   ├── airgap-bundle.sh    # Offline packaging script
│   └── tools.go            # Build tool deps
├── test/
│   └── e2e/                # End-to-end tests
├── docs/                   # MkDocs site source
├── Dockerfile
├── Makefile
├── PROJECT
├── go.mod
└── README.md
```

---

## 7. Milestones & Timeline

| Milestone | Target Date | Deliverables |
|-----------|------------|-------------|
| **M1 — Bootstrap** | Week 2 | Repo scaffolded, CRDs defined, CI green, dev environment docs. |
| **M2 — Core Operator** | Week 4 | Reconciler deploys inference pods, local registry operational, basic CLI. |
| **M3 — Air-Gap Ready** | Week 8 | Offline bundle tooling, preloader, internal TLS, tested in isolated Kind cluster. |
| **M4 — Enterprise MVP** | Week 12 | Autoscaling, multi-model routing, RBAC, Prometheus dashboards, operator web UI. |
| **M5 — Canary & Versioning** | Week 14 | Model rollout strategies, audit logging. |
| **M6 — v1.0 GA** | Week 18 | Helm chart, OLM bundle, OpenShift OperatorHub listing, docs site, security scan, release automation. |

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| GPU scheduling complexity across node pools | High | Leverage NVIDIA GPU Operator; abstract via CRD `resources.gpu` spec. |
| Large model artifacts (100+ GB) slow to distribute | High | Pre-pull DaemonSet with P2P distribution (Dragonfly/Spegel). |
| CRD API instability during development | Medium | Version as `v1alpha1`; use conversion webhooks for future versions. |
| Air-gapped dependency drift | Medium | Pin all image digests; generate SBOM; automated mirror sync tooling. |
| Multi-tenant GPU contention | Medium | Enforce ResourceQuotas and PriorityClasses per namespace. |

---

## 9. Success Criteria

- [ ] Deploy an LLM from a single `kubectl apply -f llmdeployment.yaml` in < 5 min (warm cache).
- [ ] One-click install from OpenShift OperatorHub — operator running in < 2 min.
- [ ] Single CR (`LLMDeployment`) provisions the entire inference stack end-to-end with zero manual steps.
- [ ] Full install and model serving in an air-gapped cluster with zero internet calls.
- [ ] Works identically on vanilla Kubernetes and OpenShift with no platform-specific configuration.
- [ ] Autoscale from 1 → N replicas based on inference queue depth within 60s.
- [ ] Canary rollout a new model version with automatic rollback on error-rate spike.
- [ ] Deploy, scale, and rollback a model entirely from the web UI with zero CLI usage.
- [ ] Pass CIS Kubernetes Benchmark and container image vulnerability scan with zero critical findings.

---

## 10. Open Questions

1. Should we support non-NVIDIA GPUs (AMD ROCm, Intel Gaudi) in v1, or defer to v1.1? 
Answer: defer to v1.1 to focus on NVIDIA ecosystem first, but design CRD with extensibility for other GPU types in mind.

2. Preferred inference runtime default: vLLM vs llama.cpp vs Ollama vs pluggable adapter?
Answer: **Ollama is the sole runtime for v1.** CPU-friendly, easy to demo on a laptop, no GPU required. The runtime adapter interface is designed for extensibility — vLLM, llama.cpp, and Triton will be added in v1.1+.

3. Model registry: build custom, or extend Zot / Distribution with model-aware metadata?
Answer: Extend Zot with a custom controller to manage model metadata and lifecycle, rather than building a registry from scratch. This leverages existing OCI distribution capabilities while adding LLM-specific features.

4. Minimum supported Kubernetes version: 1.28+ or 1.30+?
Answer: Target Kubernetes 1.28+ for v1.0 to maximize compatibility, but ensure code is forward-compatible with 1.30+ features for future releases.

5. OpenShift minimum version: 4.14+ or 4.16+?
Answer: Target OpenShift 4.14+ for v1.0 to align with Kubernetes 1.28+ support, but validate on 4.16+ during testing to ensure compatibility with newer platform features.

6. Should the OperatorHub listing target community-operators or certified-operators catalog?
Answer: Start with community-operators for faster iteration and feedback, with a roadmap to pursue certification for the certified-operators catalog in future releases.

7. Web UI: full standalone app or OpenShift console plugin only?
Answer: Build as a standalone React app with PatternFly, then wrap it as an OpenShift console dynamic plugin. This gives full functionality on vanilla Kubernetes while integrating natively into the OpenShift console for OpenShift users.

---

## 11. v1.1+ Roadmap (Post-Release)

Features deferred from v1 to keep scope focused:

| # | Feature | Description |
|---|---------|-------------|
| 11.1 | **vLLM Runtime Adapter** | GPU-accelerated inference with vLLM for enterprise-scale workloads. |
| 11.2 | **llama.cpp Runtime Adapter** | Lightweight CPU/edge inference with llama.cpp and GGML models. |
| 11.3 | **Triton Inference Server Adapter** | NVIDIA Triton for multi-framework model serving (ONNX, TensorRT, PyTorch). |
| 11.4 | **SafeTensors & ONNX Model Formats** | Extend model registry to support SafeTensors and ONNX beyond GGUF. |
| 11.5 | **Non-NVIDIA GPU Support** | AMD ROCm, Intel Gaudi accelerator support via CRD `resources.gpu.type` extensibility. |
| 11.6 | **Operator Web UI** | Lightweight management console (React + PatternFly) with OpenShift console dynamic plugin. |
| 11.7 | **Model Versioning & Canary Rollouts** | Blue-green and canary model deployments with automatic rollback. |
| 11.8 | **Advanced Multi-Tenancy** | Cross-namespace model sharing, fine-grained quota policies, tenant isolation. |

