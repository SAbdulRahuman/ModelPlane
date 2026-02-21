# LLMD on Kubernetes — Recommendations & Reference Guide

**Purpose:** Quick-reference guide during active development. Captures strategic recommendations, scope decisions, and career alignment guidance.  
**Last Updated:** 2026-02-21

---

## 1. Scope Discipline — Ship Working Code, Not a Plan

> A working operator with 5 features beats a plan with 25 features every time.  
> Your README.md and `kubectl apply` output is what gets you hired.

### Revised Phases for Solo Developer

| Phase | Weeks | Deliverables |
|-------|-------|-------------|
| **v0.1 — Walking Skeleton** | 1–3 | Kubebuilder scaffold, `LLMDeployment` CRD, reconciler creates a Pod running Ollama, basic `llmdctl`, CI green. |
| **v0.2 — Actually Useful** | 4–6 | Local model registry, model preloading, health probes, single CR deploys everything. |
| **v0.3 — Air-Gap** | 7–10 | Offline bundling, internal TLS, tested in isolated Kind cluster. |
| **v0.4 — Enterprise Polish** | 11–14 | Helm chart, OLM bundle, Prometheus metrics, basic autoscaling. |
| **v1.0 — Release** | 15–16 | Docs, demo video, security scan, GitHub release, blog post. |
| **v1.1+ — Stretch** | Post-release | Web UI, vLLM runtime, canary rollouts, multi-tenancy. |

---

## 2. Runtime Priority — Start with Ollama

| Runtime | Priority | Rationale |
|---------|----------|-----------|
| **Ollama** | **First** | Simple to run, CPU-friendly, easy to demo on a laptop, no GPU required for reviewers to test. |
| **vLLM** | Second | Requires GPU, harder to demo, but shows enterprise GPU orchestration skills. |
| llama.cpp | Third | Edge/embedded use cases, defer to v1.1+. |
| Triton | Fourth | Heavy enterprise runtime, defer to v1.1+. |

**Key principle:** A recruiter or engineering manager who clones your repo should be able to run it on **minikube/Kind in 5 minutes**. That means Ollama first.

---

## 3. What Recruiters & Hiring Managers Actually Look At

### ✅ Do These — High Impact

- [ ] Working operator that installs with `helm install` or OperatorHub
- [ ] Clean Go code with tests (>70% coverage)
- [ ] A 2-minute demo video / GIF in the README
- [ ] Real CRDs that apply cleanly on a Kind cluster
- [ ] GitHub Actions CI that's green
- [ ] Architecture diagram in the README (not buried in docs)

### ❌ Avoid These — Low or Negative Impact

- A 500-line plan.md with no working code
- "Coming soon" features listed everywhere
- Empty directories in the repo
- Broken CI / red badges
- Overly complex setup instructions

---

## 4. Kubestronaut Certification Order

Study each cert **in parallel** with the project feature that maps to it.

### Core Kubestronaut (5 certs)

| Order | Cert | Project Feature Alignment |
|-------|------|---------------------------|
| 1 | **KCNA** (Kubernetes and Cloud Native Associate) | Easiest, builds foundation. Study while scaffolding the project. |
| 2 | **CKAD** (Certified Kubernetes Application Developer) | Learn naturally while building the operator — pods, deployments, services, CRDs. |
| 3 | **CKA** (Certified Kubernetes Administrator) | Cluster admin skills from testing, deploying, node management. |
| 4 | **CKS** (Certified Kubernetes Security Specialist) | Security, TLS, RBAC, network policies from Phase 2–3. |
| 5 | **KCSA** (Kubernetes and Cloud Native Security Associate) | Security architecture, overlaps heavily with CKS study material. |

### Golden Kubestronaut (additional certs)

| Order | Cert | Project Feature Alignment |
|-------|------|---------------------------|
| 6 | **PCA** (Prometheus Certified Associate) | From your observability stack — metrics, alerting, dashboards. |
| 7 | **KCNA** → **CKNA** (Cilium/Networking) | From Gateway API / Ingress / Service mesh work. |
| 8 | **CHSA** (Certified Helm Specialist Associate) | From your Helm chart packaging and OLM bundle. |

---

## 5. Demo & Visibility Strategy

Shipping code is only half the battle. Visibility drives career impact.

### Before v0.1 Ships

- [ ] Set up GitHub repo with proper README structure (badges, quickstart, architecture)
- [ ] Add GitHub Topics: `kubernetes-operator`, `llm`, `airgap`, `openshift`, `golang`, `cncf`
- [ ] Configure GitHub Actions CI pipeline

### When v0.1 Ships (Week 3)

- [ ] Record a 2-minute demo video / GIF showing `kubectl apply` → model running
- [ ] Post on LinkedIn with demo video
- [ ] Share in CNCF Slack #kubernetes-operators channel

### When v0.3 Ships (Week 10) — Air-Gap Ready

- [ ] Write blog post: "Building a Kubernetes Operator for Offline LLM Deployment"
- [ ] Submit lightning talk to KubeCon / local CNCF meetup
- [ ] Post update on LinkedIn showing air-gap demo

### When v1.0 Ships (Week 16)

- [ ] Submit to CNCF Landscape under "AI" category
- [ ] Publish full documentation site
- [ ] Write blog post: "From Zero to Kubestronaut: Building an LLM Operator"
- [ ] Update resume with specific, measurable outcomes

---

## 6. Resume Bullet Points Template

Use these as a template once features are shipped. Fill in real metrics.

```
• Designed and built LLMD, an open-source Kubernetes operator (Go, Kubebuilder)
  enabling enterprise LLM deployment with offline/air-gapped support

• Implemented CRD-driven reconciliation loop managing full lifecycle of LLM
  inference workloads — single CR provisions registry, runtime, autoscaler

• Built offline model bundling tooling packaging 70B+ parameter models as
  OCI artifacts for air-gapped Kubernetes/OpenShift clusters

• Published Helm chart and OLM bundle with one-click install from
  OpenShift OperatorHub; adopted by N users/organizations

• Achieved >70% test coverage with e2e test suite running on Kind;
  zero critical findings in container image security scans
```

---

## 7. Architecture — Keep This in README

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
│  │  Inference Pods (Ollama / vLLM)      │                │
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

## 8. Key Technical Decisions (Quick Reference)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Language** | Go | Kubebuilder/controller-runtime require it; industry standard for operators. |
| **First runtime** | Ollama | CPU-friendly, easy demo, no GPU dependency for first impressions. |
| **CRD API version** | `v1alpha1` | Signal that API is evolving; use conversion webhooks later. |
| **Model registry** | Extend Zot | Don't reinvent OCI distribution; add model-aware metadata on top. |
| **GPU support** | NVIDIA first | 90%+ market share; design CRD for extensibility (AMD/Intel later). |
| **K8s minimum** | 1.28+ | Maximize compatibility; forward-compatible with 1.30+. |
| **OpenShift minimum** | 4.14+ | Aligns with K8s 1.28+. |
| **OperatorHub catalog** | community-operators first | Faster iteration; pursue certified-operators later. |
| **Web UI** | Defer to v1.1+ | High effort, low initial impact. Focus on operator + CLI first. |
| **Testing** | Kind + Ginkgo | Free, fast, runs in CI. No GPU simulation needed for Ollama. |

---

## 9. Weekly Checklist During Development

Use this every week to stay on track:

- [ ] Is CI green?
- [ ] Did I commit and push working code this week?
- [ ] Can someone clone the repo and run it in < 5 min?
- [ ] Did I write/update tests for new features?
- [ ] Did I update the README if the quickstart changed?
- [ ] Am I studying for the next Kubestronaut cert?
- [ ] Am I building the feature that maps to my current cert study?

---

## 10. Scorecard — Track Your Progress

| Criteria | Target | Current |
|----------|--------|---------|
| Working CRD + reconciler | v0.1 | ☐ |
| Single CR deploys Ollama model | v0.2 | ☐ |
| Air-gap install tested | v0.3 | ☐ |
| Helm chart + OLM bundle | v0.4 | ☐ |
| Demo video in README | v0.1 | ☐ |
| Test coverage > 70% | v1.0 | ☐ |
| Blog post published | v0.3 | ☐ |
| KCNA passed | — | ☐ |
| CKAD passed | — | ☐ |
| CKA passed | — | ☐ |
| CKS passed | — | ☐ |
| KCSA passed | — | ☐ |
| Kubestronaut achieved | — | ☐ |
| PCA passed | — | ☐ |
| Golden Kubestronaut achieved | — | ☐ |
