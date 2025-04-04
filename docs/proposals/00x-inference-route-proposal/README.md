# Inference Route Proposal

Authors: @shaneutt

## Proposal Status

 ***Draft***

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

Currently the API, and by extension, the underlying mechanisms are non-obvious.
 The InferencePool as the backendRef that the HTTPRoute refers to is also surprising.
This proposal seeks to bring the GIE API more in line with the way that Gateway & Networking operates.

## Goals

- Improve heuristics of the API & product surface

## Proposal

**WIP**

We propose a new API resource to define rules that influence scheduling decisions or override them. 

The working name for this resource is `InferenceRoute`

Key points:

* The `InferenceRoute` provides composable lists of routing rules, this maybe
  include things like model names.
* The `InferenceRoute` now serves as the target for `HTTPRoute` `BackendRefs`
  instead of the `InferencePool`, providing clearer control and insights into
  the scheduler's decision-making process, given the applicable pool.

```yaml
TODO: InferenceRoute
```

TODO: explain more of the advantages of this approach.

## Alternatives Considered

### Extending InferencePool with new rules

We decided not to extend `InferencePool` to keep its API simple. There are two
distinct roles involved:

- The admin, who defines explicit **Routing Rules** for scheduling
- The model serving provider, who supplies **Metrics Rules** to refine
  scheduling.

Since both roles focus on the `InferencePool` as a common point (e.g.,
`Endpoints`), it should only include attributes that are mutually applicable to
both. 

