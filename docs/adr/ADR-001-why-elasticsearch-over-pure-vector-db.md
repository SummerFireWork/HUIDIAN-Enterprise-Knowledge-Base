# ADR-001: Why Elasticsearch instead of a pure vector database

- **Status**: Accepted
- **Date**: 2026-09
- **Scope**: retrieval engine selection for a vertical-domain enterprise knowledge base

## Context

The product needs search that behaves the way engineers expect:

1. **Keyword precision** — exact terms ("anchorage", "bridge type", "standard clause") must hit; Chinese requires a domain-aware tokenizer (IK with custom dictionary).
2. **Semantic recall** — paraphrased or conceptual queries should still find relevant chunks (embedding-based KNN).
3. **Structured retrieval features** — facets (aggregation), snippet highlighting, deep pagination, and server-side filtering must all work on the same result set.
4. **Operational simplicity** — a 2-person team pilots a 50-user site; every extra engine is an extra system to operate.

## Decision

Use **Elasticsearch 8.17** as the single retrieval engine, combining:

- BM25 retrieval on IK-analyzed text fields (with title/heading boosts);
- KNN retrieval on a `dense_vector` field (HNSW, `k=100`, `num_candidates=500`);
- **RRF fusion** via ES `retriever.rrf` — both paths run inside one request, no client-side merging;
- post-filter facets, highlighting, and `search_after` deep pagination on the same request.

The query builder injects ACL filters into **each retriever's filter** so permission filtering happens before recall (no TOCTOU).

## Consequences

**Positive**

- One engine, one cluster, one client library (`elasticsearch-java`), one monitoring surface.
- RRF inside ES removes cross-engine score-normalization and result-merging code from the application.
- Measured: 100k chunks, BM25 P95 = 142 ms → RRF hybrid P95 = 156 ms (+9.9% for semantic recall) — the fusion cost is a single in-engine step.
- IK tokenizer + custom domain dictionary gives controllable Chinese term matching (and the classic text-vs-keyword aggregation lesson was learned and documented).

**Negative / trade-offs**

- Hybrid retrieval depends on the embedding field; if vectorization fails, the system degrades to pure BM25 (marked `degraded=true`) — availability preserved, recall reduced.
- ES is heavier to operate than a pure vector DB (cluster config, snapshot/backup, reindex for mapping changes).

## Alternatives considered

| Option | Why rejected |
|---|---|
| **Milvus / Qdrant** (pure vector DB) | Excellent ANN, but keyword search and Chinese tokenization are weak or external; we would need a second engine for BM25 and cross-engine fusion — more operations, more code. |
| **PostgreSQL pgvector** | Good enough for small corpora, but Chinese full-text is weak, and the required feature set (facets, highlight, deep pagination, HNSW scale) would push Postgres beyond its comfort zone. |
| **Two engines (ES + vector DB)** | Maximum per-engine performance, but doubles operations, adds cross-engine consistency and fusion complexity — not justified for this scale. |
