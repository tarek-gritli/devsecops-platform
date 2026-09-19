# Demo: Unsigned Image Blocked at Admission

The project's headline demo. Kyverno's `verifyImages` `ClusterPolicy` (`policies/verify-images.yaml`, `failureAction: Enforce`) checks every `ghcr.io/tarek-gritli/demo-app*` image against a Cosign keyless signature matching this repo's own GitHub Actions workflow. An image that was never signed by that pipeline gets rejected before Kubernetes ever creates the pod — not detected after the fact, refused at admission.

## Setup: a genuinely unsigned image, same registry path

```bash
docker pull busybox:1.36
docker tag busybox:1.36 ghcr.io/tarek-gritli/demo-app:unsigned-test
docker push ghcr.io/tarek-gritli/demo-app:unsigned-test
```

Pushed under the exact path the policy protects (`ghcr.io/tarek-gritli/demo-app*`) — an unsigned image somewhere else wouldn't even be checked, which would make for a meaningless demo.

## The block

```
$ kubectl run unsigned-test-demo --image=ghcr.io/tarek-gritli/demo-app:unsigned-test -n demo-app-dev
Error from server: admission webhook "mutate.kyverno.svc-fail" denied the request:

resource Pod/demo-app-dev/unsigned-test-demo was blocked due to the following policies

verify-demo-app-signature:
  verify-demo-app-cosign-signature: 'failed to verify image ghcr.io/tarek-gritli/demo-app:unsigned-test: .attestors[0].entries[0].keyless: no signatures found'

$ kubectl get pods -n demo-app-dev | grep unsigned-test-demo
(no output above = nothing was created)
```

The pod object was never admitted — it doesn't exist in any state (not even `Pending`/`Failed`), because it was rejected before creation.

## Contrast: the legitimate, signed image running fine, at the same moment

```
$ kubectl get pods -n demo-app-dev -l app=demo-app -o jsonpath='{.items[0].spec.containers[0].image}'
ghcr.io/tarek-gritli/demo-app@sha256:463acf53d0c9bc4c48409912e9eb65b86e8e2916906f4a153503b669948c7fcc

$ curl --cacert bootstrap/local-ca.crt https://demo-app.local:8443/health
{"status":"ok"}
```

Same policy, same registry path, same namespace — the only difference is whether the image was actually produced and signed by this repo's own CI pipeline. That's the entire trust boundary the policy enforces.
