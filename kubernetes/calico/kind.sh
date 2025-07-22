#!/bin/bash

set -euo pipefail

parent=${1:?Must provide parent org as first argument}
version="${2:-v3.30.2}"
helm="${HELM:-false}"

# Check we have the required tools installed to run the script
cmds="
  chainctl
  crane
  curl
  docker
  jq
  kind
  kubectl
"
missing_cmds=""
for cmd in ${cmds}; do
  if ! command -v "${cmd}" &> /dev/null; then
    missing_cmds+="${cmd} "
  fi
done
if [[ -n "${missing_cmds}" ]]; then
  echo "Missing required commands: ${missing_cmds}" >&2
  exit 1
fi

# Delete existing cluster
if kind get clusters 2>/dev/null | grep -Eq '^calico$'; then
  kind delete cluster --name calico
fi

# Create the cluster
kind create cluster --name calico --config kind.yaml

# We'll write temporary artifacts to this location
tmp_dir=$(mktemp -d)
trap "rm -rf ${tmp_dir}" EXIT

# Add docker config to the kind node so it can pull images from cgr.dev
echo "Adding docker config to kind node..." >&2
mkdir -p "${tmp_dir}/docker"
export DOCKER_CONFIG="${tmp_dir}/docker"
crane auth login -u _token -p $(chainctl auth token --audience=cgr.dev) cgr.dev
docker cp "${DOCKER_CONFIG}/config.json" calico-control-plane:/var/lib/kubelet/config.json
docker exec calico-control-plane systemctl restart kubelet.service
docker cp "${DOCKER_CONFIG}/config.json" calico-worker:/var/lib/kubelet/config.json
docker exec calico-worker systemctl restart kubelet.service

# Install Calico with helm, or with the raw manifests
if [ "${helm}" = "true" ]; then
  export ORGANIZATION="${parent}"
  envsubst < values.yaml > "${tmp_dir}/values.yaml"
  helm repo add projectcalico https://docs.tigera.io/calico/charts
  helm install calico projectcalico/tigera-operator --create-namespace --version "${version}" --namespace tigera-operator -f "${tmp_dir}/values.yaml"
else
  # Apply the tigera operator manifests
  kubectl create -f - < <(curl -sSf "https://raw.githubusercontent.com/projectcalico/calico/${version}/manifests/tigera-operator.yaml" | sed "s|quay.io/tigera/operator|cgr.dev/${parent}/tigera-operator|g")
  if ! kubectl get crd installations.operator.tigera.io &>/dev/null; then
    kubectl create -f "https://raw.githubusercontent.com/projectcalico/calico/${version}/manifests/operator-crds.yaml"
  fi

  # Create the installation
  cat <<EOF | kubectl apply -f -
  apiVersion: operator.tigera.io/v1
  kind: Installation
  metadata:
    name: default
  spec:
    variant: Calico
    registry: cgr.dev
    imagePath: ${parent}
    imagePrefix: calico-
EOF
fi

# Wait for the tigera-operator
kubectl rollout status deployment tigera-operator -n tigera-operator --timeout 3m


# Wait for everything to become ready
kubectl wait --for condition=ready installation.operator.tigera.io/default --timeout=5m
kubectl rollout status daemonset calico-node -n calico-system --timeout 5m
kubectl rollout status deployment calico-kube-controllers -n calico-system --timeout 5m
kubectl rollout status deployment calico-typha -n calico-system --timeout 5m
kubectl rollout status daemonset csi-node-driver -n calico-system --timeout 5m
