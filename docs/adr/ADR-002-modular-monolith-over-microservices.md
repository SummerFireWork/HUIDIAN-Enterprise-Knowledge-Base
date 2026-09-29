# ADR-002: Modular monolith over microservices

- **Status**: Accepted
- **Date**: 2026-09
- **Scope**: application topology for the knowledge-base backend

## Context

- Team: 2 backend engineers; pilot: ~50 users in one branch office.
- Business domains are clearly separable: knowledge/classification, parsing, search, vectorization, Q&A, permissions, statistics, ops.
- The product must be *deployable and debuggable by a small team* while remaining evolvable (the roadmap includes a multi-tenant SaaS offering).

## Decision

Build a **modular monolith**: a single deployable (Spring Boot fat jar) with domain boundaries enforced by **Maven modules** (`kb-web`, `kb-file`, `kb-parser`, `kb-search`, `kb-vector`, `kb-job`, `kb-qa`, `kb-storage`, `kb-auth`, `kb-common`, `kb-eval`, `kb-bootstrap`), where cross-module communication goes through interfaces and events rather than raw implementation classes.

## Consequences

**Positive**

- One process, one local transaction — business operations (file state machine + metadata + ACL update) stay ACID without distributed-transaction machinery.
- Deploy / debug / profile is trivial (single JVM); onboarding a new engineer is fast.
- Module boundaries are real (Maven + package visibility), so the "monolith" does not degenerate into a ball of mud.
- Measured outcome: 141 unit tests, 13-module build green, P95 226 ms on one JVM.

**Negative / trade-offs**

- No independent scaling of individual domains; a hot domain (search) shares the process with others. Mitigated by async off-loading of non-critical paths (audit executor) and by keeping search stateless.
- All code changes require a full build/test cycle; deploy frequency is deliberately low.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Microservices (per domain)** | The three microservice benefits (independent deploy frequency, independent scaling, fault isolation) are not real demands at this scale; the costs (distributed transactions, service discovery, tracing, multi-env operations) are pure overhead for a 2-person team. |
| **Single flat module** | No domain boundary enforcement; the codebase would drift toward a monolith-without-modules — exactly what we wanted to avoid. |
| **Modular monolith now → microservices later** | Chosen: the module boundaries ARE the future service boundaries. Splitting later means extracting modules, not rewriting. |

**Evolution hook (P4+)**: multi-tenant SaaS, Q&A is already stateless; search/vector are infra-backed and can be extracted along `kb-search` / `kb-vector` boundaries.
