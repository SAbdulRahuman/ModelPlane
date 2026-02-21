# LLMD on Kubernetes — Developer Tools Installation Plan

**Purpose:** Complete list of tools, CLIs, and dependencies required to develop, build, test, and release the LLMD Kubernetes operator.  
**Target OS:** Ubuntu 22.04+ / Debian 12+ (primary) · Fedora/RHEL (secondary) · macOS (tertiary)  
**Last Updated:** 2026-02-21

---

## 1. Language & Build Tools

| Tool | Version | Purpose | Install (Ubuntu) | Install (Fedora) |
|------|---------|---------|-------------------|-------------------|
| **Go** | 1.22+ | Primary language for operator, CLI, and tests | See [go.dev/dl](https://go.dev/dl/) — `sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.*.linux-amd64.tar.gz` | `sudo dnf install golang` |
| **Make** | 4.x+ | Build automation (`make build`, `make test`, `make manifests`) | `sudo apt install make` | `sudo dnf install make` |
| **Git** | 2.40+ | Version control, Conventional Commits | `sudo apt install git` | `sudo dnf install git` |
| **curl** | latest | Downloading binaries and scripts | `sudo apt install curl` | `sudo dnf install curl` |
| **jq** | latest | JSON parsing in scripts and CI | `sudo apt install jq` | `sudo dnf install jq` |

> **Ubuntu Note:** The `golang` package in Ubuntu apt repos is often outdated. Install Go from [go.dev/dl](https://go.dev/dl/) to get 1.22+. Add `export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin` to your `~/.bashrc`.

---

## 2. Kubernetes Operator Framework

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **Kubebuilder** | v4.x | CRD scaffolding, controller generation, webhook setup | `curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)" && chmod +x kubebuilder && sudo mv kubebuilder /usr/local/bin/` |
| **Operator SDK** | v1.37+ | OLM bundle generation, scorecard testing, CSV creation | [GitHub releases](https://github.com/operator-framework/operator-sdk/releases) — see install script below |
| **controller-gen** | latest | CRD manifest and DeepCopy generation (`make generate`, `make manifests`) | `go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest` |
| **kustomize** | v5.x+ | Manifest overlay management (used by Kubebuilder internally) | `go install sigs.k8s.io/kustomize/kustomize/v5@latest` |
| **setup-envtest** | latest | Downloads envtest binaries (etcd, kube-apiserver) for unit tests | `go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest` |

---

## 3. Kubernetes CLIs

| Tool | Version | Purpose | Install (Ubuntu) | Install (Fedora) |
|------|---------|---------|-------------------|-------------------|
| **kubectl** | 1.28+ | Cluster interaction, CR management, debugging | See [kubernetes.io/docs](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) — snap: `sudo snap install kubectl --classic` | `sudo dnf install kubernetes-client` |
| **oc** | 4.14+ | OpenShift-specific operations (routes, SCCs, OperatorHub) | [mirror.openshift.com](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/) — download and extract tarball |
| **helm** | v3.14+ | Chart packaging, templating, install/upgrade/rollback | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` or `sudo snap install helm --classic` |
| **opm** | latest | OLM catalog/index image management | [GitHub releases](https://github.com/operator-framework/operator-registry/releases) |

---

## 4. Local Kubernetes Clusters

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **Kind** | v0.22+ | Primary local cluster for development and CI testing | `go install sigs.k8s.io/kind@latest` |
| **k3s / k3d** | latest | Lightweight alternative local cluster | `curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh \| bash` |
| **CRC (CodeReady Containers)** | 2.x | Local single-node OpenShift for OperatorHub testing | [console.redhat.com/openshift/create/local](https://console.redhat.com/openshift/create/local) |
| **minikube** | latest | Alternative local cluster (optional) | `curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube` |

> **Recommendation:** Use **Kind** as the primary dev cluster. Use **CRC** only when testing OpenShift-specific features (SCCs, Routes, OperatorHub).

---

## 5. Container Tools

| Tool | Version | Purpose | Install (Ubuntu) | Install (Fedora) |
|------|---------|---------|-------------------|-------------------|
| **Podman** | 4.x+ | Daemonless container build and run (replaces Docker) | `sudo apt install podman` | `sudo dnf install podman` |
| **Buildah** | 1.33+ | OCI image building (standalone or via Podman) | `sudo apt install buildah` | `sudo dnf install buildah` |
| **Skopeo** | 1.14+ | Image inspection, copying between registries, air-gap transfer | `sudo apt install skopeo` | `sudo dnf install skopeo` |
| **Docker** | 24+ | Alternative container runtime (optional, for Docker-based CI) | [docs.docker.com/engine/install/ubuntu](https://docs.docker.com/engine/install/ubuntu/) |

> **Note:** On Ubuntu 22.04+, Podman, Buildah, and Skopeo are available in the default `apt` repos. Podman is preferred for Red Hat/OpenShift ecosystem alignment, but Docker works fine too.

---

## 6. Testing Frameworks & Tools

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **envtest** | latest | Unit testing controllers against real API server (no full cluster) | Included via `sigs.k8s.io/controller-runtime/pkg/envtest` Go module |
| **Ginkgo** | v2.x | BDD-style test framework for Go (operator e2e tests) | `go install github.com/onsi/ginkgo/v2/ginkgo@latest` |
| **Gomega** | latest | Matcher library for Ginkgo assertions | Go module dep: `github.com/onsi/gomega` |
| **chainsaw** | latest | Declarative YAML-based Kubernetes e2e testing | [kyverno.github.io/chainsaw](https://kyverno.github.io/chainsaw/) |

---

## 7. Code Quality & Linting

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **golangci-lint** | v1.57+ | Go linter aggregator (configured via `.golangci.yaml`) | `go install github.com/golangci-lint/cmd/golangci-lint@latest` |
| **govulncheck** | latest | Go dependency vulnerability scanning | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| **gofumpt** | latest | Stricter Go formatting (superset of `gofmt`) | `go install mvdan.cc/gofumpt@latest` |
| **goimports** | latest | Auto-manage Go import statements | `go install golang.org/x/tools/cmd/goimports@latest` |

---

## 8. Security & Supply Chain

| Tool | Version | Purpose | Install (Ubuntu) |
|------|---------|---------|------------------|
| **Trivy** | latest | Container image vulnerability scanning | `sudo apt install wget apt-transport-https gnupg lsb-release && wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \| gpg --dearmor \| sudo tee /usr/share/keyrings/trivy.gpg > /dev/null && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \| sudo tee /etc/apt/sources.list.d/trivy.list && sudo apt update && sudo apt install trivy` |
| **cosign** | latest | Container image signing and SLSA provenance verification | `go install github.com/sigstore/cosign/v2/cmd/cosign@latest` |
| **syft** | latest | SBOM generation (SPDX/CycloneDX format) | `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh \| sh -s -- -b /usr/local/bin` |
| **ORAS** | latest | OCI artifact push/pull (model registry interaction) | [oras.land/docs/installation](https://oras.land/docs/installation) |

---

## 9. Observability Tools (In-Cluster)

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| **Prometheus** | latest | Metrics collection and alerting | `helm install prometheus prometheus-community/kube-prometheus-stack` |
| **Grafana** | latest | Dashboard visualization for operator and inference metrics | Bundled with kube-prometheus-stack |
| **Jaeger** | latest | Distributed tracing backend (OpenTelemetry traces) | `helm install jaeger jaegertracing/jaeger` |
| **promtool** | latest | Validate PrometheusRule YAML and unit-test alerting rules | `go install github.com/prometheus/prometheus/cmd/promtool@latest` |

> These are deployed **in-cluster** via Helm for local development. Not installed on the host (except `promtool`).

---

## 10. Documentation & Release

| Tool | Version | Purpose | Install (Ubuntu) |
|------|---------|---------|------------------|
| **Python 3 + pip** | 3.10+ | Required for MkDocs | `sudo apt install python3 python3-pip python3-venv` |
| **MkDocs Material** | latest | Documentation site generator (GitHub Pages) | `pip install mkdocs-material` |
| **git-cliff** | latest | Changelog generation from Conventional Commits | `cargo install git-cliff` or download from [GitHub releases](https://github.com/orhun/git-cliff/releases) |
| **GoReleaser** | latest | Go binary and container release automation | `go install github.com/goreleaser/goreleaser@latest` |
| **Rust / Cargo** | latest | Required only for `git-cliff` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |

---

## 11. CLI Frameworks (Go Module Dependencies)

These are Go modules added via `go get` — **not** host-installed tools:

| Module | Purpose |
|--------|---------|
| `github.com/spf13/cobra` | CLI framework for `llmdctl` |
| `github.com/spf13/viper` | Configuration management for `llmdctl` |
| `sigs.k8s.io/controller-runtime` | Core operator framework (manager, reconciler, client, envtest) |
| `k8s.io/client-go` | Kubernetes API client |
| `k8s.io/apimachinery` | API types, conditions, scheme registration |
| `k8s.io/api` | Core Kubernetes API types |
| `go.uber.org/zap` | Structured logging (via controller-runtime) |
| `go.opentelemetry.io/otel` | OpenTelemetry tracing instrumentation |
| `github.com/prometheus/client_golang` | Prometheus metrics registration |
| `github.com/cert-manager/cert-manager` | Certificate CRD types (for webhook TLS) |

---

## 12. IDE & Editor Setup

| Tool | Purpose | Install |
|------|---------|---------|
| **VS Code** | Primary IDE | `sudo snap install code --classic` or [code.visualstudio.com](https://code.visualstudio.com/) |
| **Go extension** (VS Code) | Go language support, debugging, testing | Extension: `golang.go` |
| **YAML extension** (VS Code) | Kubernetes manifest editing with schema validation | Extension: `redhat.vscode-yaml` |
| **Kubernetes extension** (VS Code) | Cluster explorer, resource viewing | Extension: `ms-kubernetes-tools.vscode-kubernetes-tools` |

---

## 13. Quick Install Script — Ubuntu

```bash
#!/usr/bin/env bash
# LLMD Development Environment Bootstrap — Ubuntu 22.04+ / Debian 12+
# Run: chmod +x install-dev-tools.sh && ./install-dev-tools.sh

set -euo pipefail

ARCH=$(dpkg --print-architecture)  # amd64 or arm64
GO_VERSION="1.22.5"

echo "=== [1/10] System packages ==="
sudo apt update
sudo apt install -y build-essential make git curl wget jq unzip \
                    podman buildah skopeo \
                    python3 python3-pip python3-venv \
                    apt-transport-https gnupg lsb-release ca-certificates

echo "=== [2/10] Go ${GO_VERSION} ==="
if ! go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
  wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${ARCH}.tar.gz"
  rm "go${GO_VERSION}.linux-${ARCH}.tar.gz"
fi
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
grep -qxF 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' ~/.bashrc || \
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc

echo "=== [3/10] Go tools ==="
go install sigs.k8s.io/controller-tools/cmd/controller-gen@latest
go install sigs.k8s.io/kustomize/kustomize/v5@latest
go install sigs.k8s.io/kind@latest
go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest
go install github.com/onsi/ginkgo/v2/ginkgo@latest
go install github.com/golangci-lint/cmd/golangci-lint@latest
go install golang.org/x/vuln/cmd/govulncheck@latest
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/goreleaser/goreleaser@latest
go install github.com/sigstore/cosign/v2/cmd/cosign@latest
go install github.com/prometheus/prometheus/cmd/promtool@latest

echo "=== [4/10] Kubebuilder ==="
if ! kubebuilder version &>/dev/null; then
  curl -L -o kubebuilder "https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)"
  chmod +x kubebuilder && sudo mv kubebuilder /usr/local/bin/
fi

echo "=== [5/10] Operator SDK ==="
if ! operator-sdk version &>/dev/null; then
  OPERATOR_SDK_VERSION=$(curl -s https://api.github.com/repos/operator-framework/operator-sdk/releases/latest | jq -r '.tag_name')
  curl -LO "https://github.com/operator-framework/operator-sdk/releases/download/${OPERATOR_SDK_VERSION}/operator-sdk_linux_${ARCH}"
  chmod +x "operator-sdk_linux_${ARCH}"
  sudo mv "operator-sdk_linux_${ARCH}" /usr/local/bin/operator-sdk
fi

echo "=== [6/10] kubectl ==="
if ! kubectl version --client &>/dev/null; then
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
  chmod +x kubectl && sudo mv kubectl /usr/local/bin/
fi

echo "=== [7/10] Helm ==="
if ! helm version &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "=== [8/10] Trivy ==="
if ! trivy version &>/dev/null; then
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
    gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
    sudo tee /etc/apt/sources.list.d/trivy
fi