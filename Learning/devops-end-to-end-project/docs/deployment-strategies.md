# Kubernetes Deployment Strategies

## Overview

| Strategy | Downtime | Rollback speed | Infra cost | Blast radius on bug |
|---|---|---|---|---|
| Rolling Update | None | Fast (auto) | Normal | Full |
| Recreate | Full | Slow (manual restart) | Normal | Full |
| Blue-Green | None | Instant (switch back) | Double during overlap | Full |
| Canary | None | Fast (shift traffic back) | Normal + slight overhead | Smallest |

---

## Rolling Update (our default, in deployment.yaml)

Pods are replaced gradually — old and new versions briefly coexist.

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

With 3 replicas: `maxUnavailable: 1` guarantees at least 2 Pods serve traffic
at all times. `maxSurge: 1` allows 1 extra Pod temporarily so capacity never
drops. A new Pod must pass its readiness probe before an old Pod is removed.

**When to use:** default choice for stateless apps. Native to Kubernetes,
zero extra tooling, zero downtime.

**Limitation:** old and new versions run simultaneously for a few seconds —
requires the app to tolerate both versions being live at once (e.g. a
backwards-compatible API, not a breaking schema change).

---

## Recreate

All old Pods are terminated before any new Pod starts.

```yaml
strategy:
  type: Recreate
```

**When to use:** only when old and new versions genuinely cannot run side
by side — typically a breaking database migration, or a singleton workload
that can't have two instances active at once.

**Tradeoff:** guaranteed downtime for the entire swap. Simplest strategy,
but the only one that sacrifices availability by design.

---

## Blue-Green

Two full, independent environments exist simultaneously — "blue" (current
live version) and "green" (new version). Traffic is switched from blue to
green all at once, via a load balancer, DNS change, or Ingress update.

```
Before:  Ingress → blue-service  (100% traffic)
Switch:  Ingress → green-service (100% traffic, instant)
Rollback: Ingress → blue-service (instant, blue never torn down yet)
```

**When to use:** when you need the fastest possible rollback and can afford
to run double infrastructure temporarily. Common for high-stakes releases
where "revert instantly" matters more than infrastructure efficiency.

**Tradeoff:** doubles infrastructure cost during the overlap window. Not
natively a Kubernetes primitive — implemented via two Deployments/Services
plus a manual or scripted traffic switch (often via Ingress or a Service
selector change).

---

## Canary

A small percentage of real traffic is routed to the new version first,
then gradually increased while monitoring error rates and latency.

```
Stage 1:  95% → v1,  5% → v2   (watch metrics)
Stage 2:  70% → v1, 30% → v2   (watch metrics)
Stage 3:   0% → v1, 100% → v2  (fully rolled out)
```

**When to use:** highest-risk releases, or whenever you want real production
traffic to validate a change before full exposure — without risking every
user.

**Tradeoff:** needs traffic-splitting infrastructure beyond plain
Kubernetes — a service mesh (Istio, Linkerd) or an Ingress controller
with weighted routing support (e.g. nginx canary annotations). Plain
`kubectl` and a Deployment alone can't do percentage-based splitting.

---

## Which Is Safest? Which Reduces Downtime Most?

**Zero downtime:** Rolling Update, Blue-Green, and Canary all achieve this.
Recreate is the only strategy with guaranteed downtime.

**Safest overall: Canary.** Not because it prevents downtime — because it
limits *exposure*. If a bad release ships, only a small percentage of users
ever see it before metrics catch the problem and traffic shifts back. Rolling
Update and Blue-Green both go from 0% to 100% new-version exposure without a
gradual confidence-building step — a bug hits everyone as soon as the swap
completes.

**Fastest rollback: Blue-Green.** The old environment is still running and
fully warmed up — rollback is just flipping the switch back, no waiting for
Pods to restart.

**Default recommendation:** Rolling Update for most day-to-day deploys — it's
free (native to Kubernetes), safe enough for typical changes, and requires no
extra infrastructure. Reach for Canary when a release is genuinely risky, and
Blue-Green when instant rollback matters more than infrastructure cost.

---

## Key Takeaways

1. Rolling Update is the Kubernetes-native default — zero downtime via
   `maxUnavailable`/`maxSurge`, no extra tooling required.
2. Recreate is the only strategy with planned downtime — use only when
   versions can't coexist.
3. Blue-Green trades infrastructure cost for instant rollback.
4. Canary trades setup complexity (service mesh or weighted Ingress) for the
   smallest blast radius on a bad release.
5. "Safest" and "zero downtime" are different questions — Canary is the
   safest against bad code, not because it avoids downtime, but because it
   limits how many users are affected before you notice and revert.