#!/bin/bash

set -e

NAMESPACE="argocd"
DOMAIN="argocd.sulaksono.id"
PROJECT_ID="project-61148914-d23a-4c51-8b6"

echo "=== Step 1: Create cert-manager namespace ==="
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=== Step 2: Install cert-manager CRDs ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml

echo ""
echo "=== Step 3: Install cert-manager ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml --namespace cert-manager

echo ""
echo "=== Step 4: Create Gateway (provisioning IP) ==="
kubectl apply -f argocd-gateway-tls.yaml --namespace $NAMESPACE

echo ""
echo "=== Step 5: Create HTTPRoutes ==="
kubectl apply -f argocd-httproute-http.yaml --namespace $NAMESPACE

echo ""
echo "=== Step 6: Wait for Gateway to get IP address ==="
echo "This may take 2-5 minutes..."
kubectl wait --for=condition=Programmed --timeout=300s gateway/argocd-gateway -n $NAMESPACE

echo ""
GATEWAY_IP=$(kubectl get gateway argocd-gateway -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}')
echo "Gateway IP: $GATEWAY_IP"
echo ""
echo "=== Step 7: Configure DNS ==="
echo "Create A record: $DOMAIN → $GATEWAY_IP"
echo ""
read -p "Press Enter once DNS is configured..."

echo ""
echo "=== Step 8: Deploy Certificate resources ==="
kubectl apply -f cert-manager-issuer.yaml --namespace $NAMESPACE
kubectl apply -f certificate.yaml --namespace $NAMESPACE

echo ""
echo "=== Step 9: Wait for certificate to be issued ==="
echo "This may take 1-3 minutes (HTTP-01 challenge)..."
kubectl wait --for=condition=Ready --timeout=300s certificate/argocd-cert -n $NAMESPACE

echo ""
echo "=== Certificate Issued Successfully ==="
kubectl get certificate argocd-cert -n $NAMESPACE

echo ""
echo "=== Access ArgoCD ==="
echo "HTTP: http://$DOMAIN (will redirect to HTTPS)"
echo "HTTPS: https://$DOMAIN (with Let's Encrypt certificate)"