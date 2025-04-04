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

Currently, the Gateway API Inference Extension (GIE) uses an `InferencePool` to serve 2 primary functions:
- An inference-specific gateway for routing between `InferenceModels` based on specific properties
  - Currently this is just the `model` body param; a required param as defined by the [OpenAI API spec](https://platform.openai.com/docs/api-reference/chat/create#chat-create-model)
- A specialized [Service] for selecting inference endpoints, based on the state of the compute pool + request attributes.
  - This will be referred to as the `scheduler`


This proposal focuses on extending the inference-specific gateway tooling, we foresee the need for additional routing rules that extend beyond `model` (such as RAG/system prompts per `InferenceModel`), these rules should be declarative, composable, and chainable,
making it easier for users to express their intent and clarifying the process
for developers adding new features.

Additionally we see a potential need for rules that bypass the scheduler entirely (e.g., a semantic cache). It has been discussed to have multiple ext-proc extensions in the request path, which is a valid option. But could lead to heavy overhead as the body must be parsed for each inference-focused extension in the chain. And as context length continues to trend longer, this cost may be exacerbated. Keeping additional routing rules as callouts within the InferencePool implementation allows for a single body parse, and to parallelize any pre-scheduler callouts. 
 > Example: A callout to validate if the prompt is on [topic](https://huggingface.co/nvidia/llama-3.1-nemoguard-8b-topic-control) and a callout for [content safety](https://huggingface.co/nvidia/llama-3.1-nemoguard-8b-content-safety) could happen in parallel for a single `InferenceModel`.

[Service]:https://kubernetes.io/docs/concepts/services-networking/service/

## Goals

- Make configuring routing rules for inference requests more explicit--and
  declarative--for consumption by the scheduler.
- Provide chains of routing rules, where sets of rules can be conditional upon
  a topical rule.
- Improve development & testing of new routing APIs.

## Non-goals

- Developing a "Declarative Metrics API" (see [#declarative-metrics-rules])

## Proposal

**WIP**

We propose extending the `InferenceModel` resource, adding an additional field 
to the `InferenceModel` spec. The working name of this field will be `Rules`.

Key points:

* `Rules` is a loose term, as it could include pre-scheduler filtration, such as content filtering, or prompt enrichment, such as RAG or system prompt injection.
* `Rules` provides composable lists of routing rules, `ModelName` could be considered a special-cased rule. But since it is _the_ unique identifier of an inferenceModel, it will remain separate.
* Routing rules can be defined at the top level or sequential, enabling conditional dependencies or parallel resolution.


As a part of this proposal, the core EPP logic will be refactored to have 2 layers:
- An easily extensible pre-scheduler Rule execution layer
- A scheduler layer (as directed by the [Scheduler Subsystem Proposal])

The Rule execution layer will ingest configuration as defined by the `Rules` field. And allow intermixing of pre-defined rules, and user generated rules.
One option for user extension would be to define a plugin interface and allow a user to define that way. However even the builtin [plugin package](https://pkg.go.dev/plugin#section-documentation) suggests against that. Instead, simply user could simply extend the implementation. Allowing for custom built and defined rules would require a very simply mapping API

Looking something like:

```yaml
kind: InferenceModel
...
spec:
  rules:
  - name: content-safety
  - name: prompt-injection
    after: content-safety
  - name: topical-validation
    after: content-safety
```
Similar to the [HTTPRouteFilter](https://gateway-api.sigs.k8s.io/reference/spec/#httproutefilter), the RuleType is a simple string, and the `after` field is optional, that allows rules to be executed conditionally.

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

