# Demo: SLO Burn-Rate Alert Firing

Negative control for Milestone 3 — proves the multi-window multi-burn-rate `PrometheusRule` (`policies/... ` → `apps/demo-app/k8s/base/slo-alerts.yaml`, alert `DemoAppErrorBudgetBurnFast`) actually fires under real error traffic, and recovers once traffic stops.

## Setup

```bash
kubectl port-forward -n demo-app-dev svc/demo-app 8000:80 &
while true; do curl -s -o /dev/null localhost:8000/fail; sleep 0.1; done &
```

Sustained traffic against `demo-app`'s `/fail` endpoint (added specifically for this demo — `/health` always returns 200 and can't be driven into failure).

## Transition: `inactive` → `pending` → `firing`

Polled `kubectl port-forward`ed Prometheus (`/api/v1/rules` and `/api/v1/query`) every 30 seconds:

```
20:08:52 state=inactive 5m_error_ratio=0.582
20:09:22 state=pending  5m_error_ratio=0.801
20:09:52 state=pending  5m_error_ratio=0.870
20:10:23 state=pending  5m_error_ratio=0.903
20:10:53 state=pending  5m_error_ratio=0.923
20:11:23 state=firing
```

Confirmed via `/api/v1/alerts`:
```
firing since 2026-09-19T19:09:20.131312559Z
```

The alert requires the error ratio to exceed a 14.4× burn rate (against a 99% availability SLO) across **both** the 5-minute and 1-hour windows simultaneously, sustained for 2 minutes (`for: 2m`) before actually firing — the `pending` phase above is that 2-minute countdown, not the alert being slow.

## Recovery: traffic stopped, `firing` → `inactive`

```
20:11:54 state=firing  5m_error_ratio=0.942
20:12:24 state=firing  5m_error_ratio=0.942
20:12:54 state=firing  5m_error_ratio=0.941
20:13:24 state=firing  5m_error_ratio=0.941
20:13:54 state=firing  5m_error_ratio=0.935
20:14:24 state=firing  5m_error_ratio=0.921
20:14:54 state=firing  5m_error_ratio=0.900
20:15:24 state=firing  5m_error_ratio=0.862
20:15:54 state=firing  5m_error_ratio=0.777
20:16:25 state=firing  5m_error_ratio=0.387
20:16:55 state=inactive 5m_error_ratio=0
```