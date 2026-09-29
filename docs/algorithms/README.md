# Algorithm Notebook

Small, dependency-free implementations of the core retrieval algorithms behind HUIDIAN's hybrid search.

These files are **standalone sketches** (no project dependencies, no business data) — they exist to make the
engineering decisions easy to read, verify and reuse.

| File | What it shows | Why it matters |
|---|---|---|
| [`rrf-fusion.java`](rrf-fusion.java) | Reciprocal Rank Fusion — merge BM25 + KNN rank lists without score normalization (`k=60`) | The heart of hybrid retrieval: rank-only fusion is robust across incomparable score scales and needs no per-engine tuning |

Run instructions are embedded in each file header. No build system required (`java rrf-fusion.java`).

> Note: in production this algorithm is executed natively inside Elasticsearch via `retriever.rrf`
> (single-request fusion, measured P95 142 ms → 156 ms at 100k chunks); the snippet here is the
> educational/reference implementation.
