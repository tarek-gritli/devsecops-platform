# Demo: Guardrail Policies Blocked at Admission

The three Milestone 7 guardrails — non-root, resource requests/limits, registry allow-list — all in `failureAction: Enforce`, scoped to `demo-app-dev`/`demo-app-prod`. Two test pods isolate all three violations between them.

## Test 1: no `securityContext`, no `resources` — trips two guardrails at once

```
$ kubectl run guardrail-demo-1 --image=ghcr.io/tarek-gritli/guardrail-test:latest -n demo-app-dev
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/demo-app-dev/guardrail-demo-1 was blocked due to the following policies

require-non-root-demo-app:
  run-as-non-root: |-
    validation error: Running as root is not allowed. Either spec.securityContext.runAsNonRoot must be true, or container-level runAsNonRoot fields must be set to true.
    . rule run-as-non-root[0] failed at path /spec/securityContext/runAsNonRoot/ rule run-as-non-root[1] failed at path /spec/containers/0/securityContext/
require-resource-limits-demo-app:
  validate-resources: 'validation error: CPU and memory resource requests and memory limits are required for containers. rule validate-resources failed at path /spec/containers/0/resources/limits/'

$ kubectl get pods -n demo-app-dev | grep guardrail-demo-1
(no output above = nothing was created)
```

Correct registry (`ghcr.io/tarek-gritli/guardrail-test`), so `restrict-registries-demo-app` doesn't fire — only the two guardrails it actually violates.

## Test 2: compliant except for registry — isolates the third guardrail cleanly

```
$ kubectl run guardrail-demo-2 --image=busybox:1.36 -n demo-app-dev \
    --overrides='{"spec":{"securityContext":{"runAsNonRoot":true},"containers":[{"name":"guardrail-demo-2","image":"busybox:1.36","command":["sleep","3600"],"securityContext":{"runAsNonRoot":true},"resources":{"requests":{"cpu":"50m","memory":"64Mi"},"limits":{"memory":"128Mi"}}}]}}'
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/demo-app-dev/guardrail-demo-2 was blocked due to the following policies

restrict-registries-demo-app:
  validate-registries: 'validation error: Images must come from ghcr.io/tarek-gritli/*. rule validate-registries failed at path /spec/containers/0/image/'

$ kubectl get pods -n demo-app-dev | grep guardrail-demo-2
(no output above = nothing was created)
```

Explicitly compliant `securityContext`/`resources` here — only `restrict-registries-demo-app` fires, confirming the other two guardrails correctly pass a pod that satisfies them, rather than blocking indiscriminately.

## Contrast: `demo-app` itself, unaffected

All three guardrails plus Milestone 6's signature policy are active simultaneously in this namespace — the real `demo-app` Deployment keeps running throughout both tests above, since it satisfies every one of them (non-root since Milestone 7's `Deployment` fix, resource limits since Milestone 2, correct signed registry path since Milestone 5).
