# ArgoCD Gateway with Let's Encrypt TLS

This configuration enables ArgoCD access through GKE Gateway API with automatic Let's Encrypt SSL certificates.

## Prerequisites

1. **Domain Name**: `argocd.sulaksono.id`
2. **DNS Record**: A record pointing to Gateway IP (will be created after Gateway provisioning)
3. **GCP Project**: `project-61148914-d23a-4c51-8b6` (for DNS01 challenge)

## Deployment Order

```bash
# 1. Create cert-manager namespace and install cert-manager
kubectl create namespace cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml

# 2. Install cert-manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.crds.yaml

# 3. Deploy Gateway and HTTPRoute (creates Gateway IP)
kubectl apply -f argocd-gateway-tls.yaml
kubectl apply -f argocd-httproute-http.yaml

# 4. Get Gateway IP for DNS
kubectl get gateway argocd-gateway -n argocd

# 5. Create DNS record for argocd.sulaksono.id pointing to Gateway IP

# 6. Deploy Certificate resources
kubectl apply -f cert-manager-issuer.yaml
kubectl apply -f certificate.yaml

# 7. Wait for certificate to be issued (HTTP-01 challenge)
kubectl get certificate argocd-cert -n argocd -w
```

## Files

- **cert-manager-namespace.yaml** - Namespace for cert-manager
- **cert-manager-issuer.yaml** - Let's Encrypt ClusterIssuer (DNS01 challenge)
- **certificate.yaml** - Certificate resource for argocd.sulaksono.id
- **argocd-gateway-tls.yaml** - Gateway with HTTP and HTTPS listeners
- **argocd-httproute-http.yaml** - HTTPRoute for HTTP (redirects to HTTPS)
- **argocd-httproute-https.yaml** - HTTPRoute for HTTPS with TLS

## Architecture

```
Internet → Gateway (35.190.12.248)
            ├─ HTTP:80 → HTTPRoute (HTTP) → HTTP 307 → HTTPS
            └─ HTTPS:443 → HTTPRoute (HTTPS) → argocd-server:443
                                              └─ TLS: argocd-cert secret
```

## Verification

```bash
# Check certificate status
kubectl get certificate argocd-cert -n argocd

# Check Gateway status
kubectl get gateway argocd-gateway -n argocd

# Access ArgoCD
# HTTP redirects to HTTPS
curl -L http://argocd.sulaksono.id

# HTTPS with Let's Encrypt certificate
curl -k https://argocd.sulaksono.id
```

## Notes

- Let's Encrypt uses HTTP-01 challenge by default
- Domain must be publicly accessible before certificate issuance
- Gateway IP takes 2-5 minutes to provision
- Certificate issuance takes 1-3 minutes
- Certificate validity: 90 days, auto-renews 30 days before expiry