#!/bin/bash

# This shell script deploys a Kubernetes or OpenShift cluster with an
# KGateway-based Gateway API implementation fully configured. It deploys the
# vllm simulator, which it exposes with a Gateway -> HTTPRoute -> InferencePool.
# The Gateway is configured with the a filter for the ext_proc endpoint picker.

set -eux

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set a default VLLM_SIM_IMAGE if not provided
: "${VLLM_SIM_IMAGE:=quay.io/vllm-d/vllm-sim}"

# Set a default VLLM_SIM_TAG if not provided
: "${VLLM_SIM_TAG:=0.0.2}"

# Set a default EPP_IMAGE if not provided
: "${EPP_IMAGE:=us-central1-docker.pkg.dev/k8s-staging-images/gateway-api-inference-extension/epp}"

# Set a default EPP_TAG if not provided
: "${EPP_TAG:=main}"

# ------------------------------------------------------------------------------
# Deployment
# ------------------------------------------------------------------------------

kubectl create namespace ${NAMESPACE} 2>/dev/null || true

# Hack to deal with KGateways broken OpenShift support
export PROXY_UID=$(kubectl get namespace ${NAMESPACE} -o json | jq -e -r '.metadata.annotations["openshift.io/sa.scc.uid-range"]' | perl -F'/' -lane 'print $F[0]+1'); 

set -o pipefail

echo "INFO: Deploying Development Environment in namespace ${NAMESPACE}"

kustomize build deploy/environments/dev/kubernetes-kgateway | envsubst | kubectl -n ${NAMESPACE} apply -f -

echo "INFO: Waiting for resources in namespace ${NAMESPACE} to become ready"

kubectl -n ${NAMESPACE} wait deployment/endpoint-picker --for=condition=Available --timeout=60s
kubectl -n ${NAMESPACE} wait deployment/vllm-sim --for=condition=Available --timeout=60s
kubectl -n ${NAMESPACE} wait gateway/inference-gateway --for=condition=Programmed --timeout=60s
kubectl -n ${NAMESPACE} wait deployment/inference-gateway --for=condition=Available --timeout=60s

