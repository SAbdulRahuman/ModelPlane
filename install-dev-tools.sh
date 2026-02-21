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