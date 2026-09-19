# DevSecOps/SRE/Cloud-Native Portfolio Platform

A local-first platform demonstrating GitOps, supply-chain security, policy enforcement, and SRE-style observability — built around a deliberately trivial demo app, because the platform *around* it is the point.

See [docs/architecture.md](docs/architecture.md) for the full system diagram.

## What's here

- **GitOps**: Argo CD app-of-apps — `root` watches `/infrastructure` and `/policies`, so every component here syncs automatically, no manual `kubectl apply`.
- **Observability**: kube-prometheus-stack, a RED dashboard, and a multi-window multi-burn-rate SLO alert that's been proven to actually fire.
- **SSO**: Argo CD logs in via Keycloak's native OIDC — no bundled Dex, no client secret (PKCE instead).
- **Supply chain**: every `demo-app` image is Trivy/Gitleaks-scanned, built, pushed to GHCR, Cosign-signed (keyless, via GitHub's own OIDC identity), and SBOM-attested — fully automated by CI.
- **Policy enforcement**: Kyverno checks that signature at admission — deploy an unsigned image under this repo's path and Kubernetes itself refuses to create the pod. Three more guardrails (non-root, resource limits, registry allow-list) enforce the same way.
- **Secrets**: SOPS+age, decrypted inline by Argo CD's own `repo-server` — no manual decrypt step breaking the GitOps model.

## Demos

Screenshots/recordings of the negative controls (SLO alert firing, unsigned image blocked, each guardrail blocked) are in [docs/demos/](docs/demos/).

## Trade-offs

### Kyverno vs. OPA/Gatekeeper

Kyverno policies are plain Kubernetes YAML — no new language to learn, and `verifyImages` ships Cosign/Sigstore signature verification as a first-class, built-in feature. Gatekeeper uses Rego (OPA's own policy language), which is more expressive for genuinely complex logic and has a longer enterprise track record, but signature verification isn't built in — you'd hand-write a Rego constraint template for it. This project's headline demo *is* Cosign verification; Kyverno making that a YAML field instead of custom Rego was the deciding factor.

### Traefik vs. nginx-ingress

nginx-ingress is being retired (EOL announced for March 2026) — not a reason to start anything new on it. Traefik ships with k3d/k3s by default, so there was no separate install step. Its `IngressRoute` CRD is considerably richer than the standard `Ingress` resource (real match expressions, native `Middleware` chaining, weighted traffic splitting) but isn't portable to other ingress controllers the way plain `Ingress` is — a real trade-off, accepted here because portability across controllers was never a goal for a single-cluster local demo.

### Monorepo vs. multi-repo

Everything — Terraform, GitOps manifests, app code, CI, and policies — lives in one repository. For a solo portfolio project, that means one clone gets you the whole system, and there's no cross-repo version-pinning to manage. Multi-repo earns its keep at team scale, with independent release cadences and access-control boundaries between infra and app teams — neither of which applies here.