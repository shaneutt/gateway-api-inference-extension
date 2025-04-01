# Declarative Routing Rules

Authors: @kfswain, @shaneutt

## Proposal Status

 ***Draft***

> **Note**: This proposal is meant to compliment the [Scheduler Subsystem
> Proposal].

[Scheduler Subsystem Proposal]:https://github.com/kubernetes-sigs/gateway-api-inference-extension/pull/603

## Table of Contents

<!-- toc -->

-   [Summary](#summary)
-   [Motivation](#motivation)
-   [Goals](#goals)
-   [Non-Goals](#non-goals)
-   [Proposal](#proposal)

<!-- /toc -->

## Summary

This proposal outlines the method to configure inference routing rules.

## Motivation

Currently, the Gateway API Inference Extension (GIE) uses an `InferencePool` as
effectively a specialized [Service] for selecting inference endpoints, and an
`InferenceModel` to advertise available models in the `InferencePool` for the
scheduler to make decisions on.

In the future, we foresee the need for additional routing rules that extend
beyond model, and possibly rules that bypass the scheduler entirely (e.g., a
semantic cache). These rules should be declarative, composable, and chainable,
making it easier for users to express their intent and clarifying the process
for developers adding new features.

[Service]:https://kubernetes.io/docs/concepts/services-networking/service/

## Goals

- Make configuring routing rules for inference requests more explicit--and
  declarative--for consumption by the scheduler.
- Provide chains of routing rules, where sets of rules can be conditional upon
  a topical rule.
- Make it a little bit easier to develop and test new routing APIs and scheduler
  implementations.

## Non-goals

- Developing a "Declarative Metrics API" (see [#declarative-metrics-rules])

## Proposal

**WIP**

We propose a new API resource named `InferenceRoute` to define rules that
influence scheduling decisions or override them.

Key points:

* The `InferenceRoute` provides composable lists of routing rules, this maybe
  include things like model names.
* Routing rules can be defined at the top level or chained, enabling conditional
  dependencies.
* Each routing rule target matches an `InferencePool`, which can be shared
  across rules or distinct based on expected support for specific conditions.
* The `InferenceRoute` now serves as the target for `HTTPRoute` `BackendRefs`
  instead of the `InferencePool`, providing clearer control and insights into
  the scheduler's decision-making process, given the applicable pool.

```yaml
TODO: InferenceRoute
```

TODO: explain more of the advantages of this approach.

## Alternatives Considered

### Declarative Metrics Rules

The `InferencePool` gathers `Endpoints` from which the scheduler selects. Two
sources influence this selection:

- **Routing Rules:** These API resources, defined by the inference provider, let
  users specify how requests should be routed. Examples include model routing
  as well as enhancements like RAG or bypass mechanisms such as Semantic Cache.
  This proposal focuses on these user-defined routing rules.

- **Metrics Rules:** Model serving platforms supply metrics about running AI/ML
  workloads—such as prefix cache, LoRA Affinity, and Model Service Queue Depth
  —that can refine the scheduler's selections. These metrics help optimize
  performance and reduce inference costs by enabling dynamic scheduling
  adjustments during runtime.

While we see the need for declarative APIs for managing metrics, this proposal
outlines only their definition, with a detailed proposal deferred to a future
iteration to maintain focus.

### Extending InferencePool with new rules

We decided not to extend `InferencePool` to keep its API simple. There are two
distinct roles involved:

- The admin, who defines explicit **Routing Rules** for scheduling
- The model serving provider, who supplies **Metrics Rules** to refine
  scheduling.

Since both roles focus on the `InferencePool` as a common point (e.g.,
`Endpoints`), it should only include attributes that are mutually applicable to
both.
