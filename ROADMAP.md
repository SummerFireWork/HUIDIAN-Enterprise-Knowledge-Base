# ROADMAP · HUIDIAN Enterprise Knowledge Base

> Last updated: 2026-09-29

## Current Status

**HUIDIAN 2.0** is feature-complete as an enterprise knowledge base:

- Hybrid search (BM25 + KNN + RRF), standards-aware parsing pipeline, three-tier knowledge governance,
  streaming RAG Q&A with citations, full ops tooling — **141 unit tests green, P95 226 ms at 100k chunks**.

This public repository deliberately carries **presentation assets only** (README, architecture diagrams,
ADRs, algorithm notebooks, benchmark summaries). The core implementation is kept private as a professional
IP-boundary decision — the system was architected and engineered for a real organization's pilot, so its
codebase, data and internal design documents are not part of this repository.

## Try it now

**No server, no source code needed**: the repo ships a prebuilt artifact (`release/huidian-kb.jar`,
backend + frontend in one jar) and a one-command docker compose up -d demo environment.
See README → *One-Click Local Demo*. Demo documents are synthetic samples; no organization data is involved.

## Why it matters

The public repo is the *front door*: it proves the architecture decisions, the measured results and the
engineering discipline. The roadmap below is the honest statement of where the project is going.

## Roadmap

### P2 — Retrieval quality (next)

- Integrate **BGE-Reranker** as a third retrieval stage (BM25 + KNN + RRF → rerank top-100).
- Publish a **public evaluation set** (query × expected chunks, cross-domain) so recall/NDCG regressions are measurable by anyone.
- Target: Recall@5 baseline 50% (demo set) → **≥ 85%** on the published set.

### P3 — Knowledge-graph enhancement

- **Entity extraction & disambiguation** over parsed standards (terminology graph, alias resolution).
- **Multi-hop Q&A** backed by the graph (not just retrieval), with citation traceability preserved.
- This is the feature that most changes the product's ceiling — and it is also the point where a **full open-source release** becomes genuinely valuable.

### P4 — Multi-tenancy & SaaS hooks

- Tenant isolation, per-tenant ACL policy, usage metering (module boundaries already reserved in ADR-002).

### P5 — Full open-source release

- **When?** After the P3 knowledge-graph upgrade lands (the point of "significantly different" from the
  organization-pilot codebase), the project will be fully open-sourced:
  - core backend + frontend source under Apache-2.0;
  - reproducible setup with **public / synthetic datasets only** (no organization data, ever);
  - the public evaluation set and benchmark harness shipped with the repo.

## Contributions before the full release

- **Issues & Discussions**: very welcome now — architecture opinions, benchmark questions, feature requests.
- **Code contributions**: accepted after the P5 full release (code is intentionally not published before then).

## Maintenance notes

- The `public` branch is the open-source surface; the full source lives on the private `main` branch of this
  repository's upstream history and is **not** pushed to GitHub until P5.
- Benchmark numbers in the README are from the local reference environment (see Benchmark section); they are
  updated whenever the harness is re-run.
