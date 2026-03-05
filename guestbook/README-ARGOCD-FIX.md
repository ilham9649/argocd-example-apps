# ArgoCD Gateway Fix Summary

## Problem
ArgoCD web UI was not accessible through GKE Gateway API due to HTTP→HTTPS redirect causing health check failures.

## Root Cause
ArgoCD server redirects all HTTP traffic (port 80) to HTTPS (port 443). GKE Gateway health checks to port 80 don't follow redirects, causing:
- Gateway reports "no healthy upstream"
- 503 Service Unavailable errors

## Solution Applied
Disabled HTTP→HTTPS redirect by setting `ARGOCD_SERVER_INSECURE=true` in ConfigMap.

## Files Modified
- `argocd-configmap.yaml` - ConfigMap with `server.insecure: "true"`

## Gateway Configuration
- **IP**: 35.190.12.248
- **Domain**: argocd.sulaksono.id
- **Status**: Programmed and Healthy
- **Listener**: HTTP port 80
- **HTTPRoute**: Routes to argocd-server port 443 (HTTPS)

## Access ArgoCD
```bash
# HTTP access (works with HTTP→HTTPS redirect disabled)
curl http://argocd.sulaksono.id

# HTTPS access (currently using self-signed cert, needs Let's Encrypt)
curl -k https://argocd.sulaksono.id
```

## Next Steps (Optional: HTTPS with Let's Encrypt)
If you want full HTTPS with Let's Encrypt certificates:

1. Cert-manager is already installed
2. Certificate resource is ready (`kubectl get certificate argocd-cert -n argocd`)
3. Let's Encrypt will use HTTP-01 challenge and create `.well-known/acme-challenge/` path
4. Once certificate is Ready, add HTTPS listener to Gateway with TLS certificate

## Current Status
✅ Gateway: Programmed and Healthy
✅ HTTP access: Working (200 OK)
⚠️ HTTPS access: Using self-signed cert
✅ DNS: Resolves to 35.190.12.248

## Verification
```bash
# Test Gateway
kubectl get gateway argocd-gateway -n argocd

# Test HTTP
curl -I http://argocd.sulaksono.id

# Check ArgoCD pods
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
```