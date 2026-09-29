# ADR-003: Event-driven parsing pipeline with RabbitMQ

- **Status**: Accepted
- **Date**: 2026-09
- **Scope**: how uploaded documents become searchable chunks

## Context

Document ingestion is a multi-stage pipeline: `upload → parse → enrich → review → vectorize → index → (approval gate) → searchable`. Requirements:

1. A burst of uploads must not block the request path (bulk uploads, big PDFs).
2. Any stage may fail transiently and must be retryable without data loss.
3. Workers must be idempotent (at-least-once delivery is the norm, duplicates are the design premise).
4. A developer must be able to run the whole system locally *without* RabbitMQ.

## Decision

Drive the pipeline with **RabbitMQ**: one queue per stage (`parse`, `enrich`, `review`, `vector`) plus per-queue `.dlq` dead-letter queues, with:

- **Manual ack** — a message is acked only after the stage commits its DB state; failures nack → retry → DLQ after limit.
- **Idempotent workers** — a file state machine + unique constraints make re-processing a message a no-op (state machine gates which transitions are allowed).
- **Transport switch** — `KB_JOB_TRANSPORT=local|rabbit`: in dev, events are delivered through an in-process channel so no middleware is needed; in production the same code path publishes to RabbitMQ.
- **After-commit publishing** — events are published only after the DB transaction commits (`TransactionSynchronization.afterCommit`), so a consumer never observes uncommitted rows.

## Consequences

**Positive**

- Natural backpressure / surge absorption: upload bursts buffer in queues while workers consume at their own rate.
- Failure isolation and observability: per-queue depth gauges (`kb_mq_queue_depth`, 6 queues incl. DLQs) with threshold alerts.
- The local channel keeps the dev loop zero-dependency; the same event model is used in both modes.
- Reconciliation job (PG/ES/MinIO, daily 03:00 + manual) provides the final-consistency backstop when any async write is lost.

**Negative / trade-offs**

- Eventual consistency by design: PG metadata and ES search index may disagree for a short window; the reconciliation job converges and alerts.
- No strict ordering guarantee (RabbitMQ); deliberately not needed — each stage is independently idempotent.

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Synchronous call chain** | A slow/failed parser blocks the upload response; no retry, no backlog visibility, no surge absorption. |
| **Kafka** | Overkill for short pipelines with exact routing; RabbitMQ's broker-side routing + DLQ semantics fit the stage model better and are simpler to operate. |
| **In-process threads only** | Works single-node, but no persistence/retry/DLQ, and production would need the same semantics re-implemented — hence the transport abstraction instead. |

**Lesson recorded (real incident)**: an early version dispatched events *inside* the DB transaction — a fast consumer read uncommitted rows and skipped them as "already processed" (idempotent skip), stalling the pipeline. Fix: publish after commit, aligning the local channel with RabbitMQ semantics.
