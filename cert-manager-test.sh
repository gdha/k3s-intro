#!/bin/bash

# read - https://github.com/rancher/k3s/issues/117
# and also - https://cert-manager.io/docs/installation/kubernetes/
######

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Create service account and RBAC resources for tiller
kubectl apply -f https://raw.githubusercontent.com/gdha/k3s-intro/master/deploy/manifests/tiller-serviceaccount-rbac.yaml

# It may take a while before the tiller pod is available, therefore, sleep a bit
echo "Wait 5 seconds so that \"tiller\" pod may become available..."
sleep 5

# Initialize tiller
# helm init --service-account tiller --wait --upgrade
# See issue at https://github.com/helm/helm/issues/6374
helm init --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -

# helm init --service-account tiller --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | sed 's@  replicas: 1@  replicas: 1\n  selector: {"matchLabels": {"app": "helm", "name": "tiller"}}@' | kubectl apply -f -

# Install the CustomResourceDefinition resources separately
kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml

# Create the namespace for cert-manager
kubectl create namespace cert-manager

# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
# failed to renew lease kube-system/cert-manager-cainjector-leader-election-core: failed to tryAcquireOrRenew context deadline exceeded => add '--set rbac.create=true' (https://github.com/jetstack/cert-manager/issues/1068)
helm install \
  --name cert-manager \
  --namespace cert-manager \
  --set rbac.create=true \
  --version v0.12.0 \
  jetstack/cert-manager

# Wait for the pods to be ready here...
kubectl -n cert-manager rollout status deployment/cert-manager
kubectl -n cert-manager rollout status deployment/cert-manager-cainjector
kubectl -n cert-manager rollout status deployment/cert-manager-webhook

# Create certificates, Issuer and ClusterIssuer to test deployment
kubectl apply -f https://raw.githubusercontent.com/gdha/k3s-intro/master/deploy/manifests/test-cert-manager-resources.yaml

# Check that certs are issued
kubectl describe certificate -n cert-manager-test
