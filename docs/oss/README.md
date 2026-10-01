# OSS Assets Index & Screenshot Replacement Checklist

> Serves open-source / resume / portfolio preparation: all auto-generated figures and screenshot placeholders live here.
> **Rule: before releasing, go through every image referenced from the README (`docs/oss/assets/`) and replace the placeholders one by one.**

## 1. Asset Inventory

| File | Purpose | Status |
|---|---|---|
| `assets/architecture.svg` | System architecture (README "System Architecture" section) | ✅ generated (1600×1160, dark brand theme) |
| `assets/quickstart.svg` | Quick-start flow (README "Quick Start" section) | ✅ generated (1600×640) |
| `assets/eval-benchmark.svg` | Benchmark & performance figure (README "Benchmark" section) | ✅ generated (real measured numbers) |
| `assets/screenshot-placeholder.svg` | Generic screenshot placeholder (README preview & highlights) | ✅ generated (1280×720) |
| `assets/demo-video.mp4` | Demo walkthrough video (README "Online Demo" section) | ⬜ placeholder — record & drop here (see §5) |

## 2. Screenshot Replacement Checklist (execute before release)

Each item below is a placeholder in the README that **must** be replaced. Method: capture the real UI → save PNG/JPG (1280×720 or 16:9 recommended) → put into `docs/oss/assets/screenshots/` → update the corresponding `<img>` reference in the README.

| # | README location | What to capture | Status |
|---|---|---|---|
| 1 | Top hero | System home / workspace (with global search bar) | ☐ replace |
| 2 | Highlights · Search | Search results page: three-column layout + highlight + facets + similar cases | ☐ replace |
| 3 | Highlights · Knowledge bases | KB page: three-tier tree + file list + upload wizard (classification tabs) | ☐ replace |
| 4 | Highlights · Parse result | File detail drawer: parse-result stats (pages/tables/images/blocks) + original-text anchor | ☐ replace |
| 5 | Highlights · RAG Q&A | Q&A page: SSE streaming answer + citation cards | ☐ replace |
| 6 | Highlights · Dashboard | Stats dashboard: metric cards + ECharts + map | ☐ replace |
| 7 | Highlights · Members | KB members tab: member list + roles + pending approvals | ☐ replace |
| 8 | Benchmark | Real benchmark run output (replace/extend `eval-benchmark.svg` if re-measured) | ☐ optional |
| 9 | Quick start | (optional) docker compose health check all-green screenshot | ☐ optional |

> For #8: rerun the load scripts under `backend/docker/smoke-*.py` and update `eval-benchmark.svg` with fresh P50/P90/P95/P99 numbers if the environment has changed.

## 5. Demo Video Checklist (README "Online Demo")

| Item | Where it goes | Status |
|---|---|---|
| Record a 15–30 s walkthrough: search → facets → deep pagination → SSE Q&A with citations | `assets/demo-video.mp4` (16:9, ≤ 10 MB recommended) | ⬜ todo |
| Place the demo URL (published link) into the README "Online Demo" section | `README.md` · `Online Demo` | ⬜ todo (deployment later) |
| Sanity rule | demo data is **synthetic/public samples only** — never record or publish organization documents | ✅ rule fixed |

> The current public-branch README lives at `docs/oss/README.public.md` (source for the `public` git branch).
> Keep it in sync when editing `README.md`'s public-facing sections.

## 3. How to Swap a Placeholder

```markdown
<!-- before -->
<img src="docs/oss/assets/screenshot-placeholder.svg" alt="System home screenshot" width="800">

<!-- after -->
<img src="docs/oss/assets/screenshots/home.png" alt="System home screenshot" width="800">
```

## 4. Verified Numbers You Can Reuse (README / interview talking points)

- App-side search latency **P50=162 / P90=211 / P95=226 / P99=263 ms**（target ≤ 300 ms）, RPS=121.5（20 concurrent × 500 searches, local benchmark）
- ES plain search P95=142 ms; BM25+KNN+RRF hybrid P95=156 ms（+9.9% for semantic recall）
- 100k synthetic chunks ingested in **17.7 s**
- Demo KB Recall@5 = 50%（50 real questions baseline, DoD target ≥85%, regression ongoing）
- Three-way reconciliation（PG/ES/MinIO）20/20/20 consistent
- Unit tests: 141 all green（`mvn -B test`, 2026-09-28 verified）; backend milestones M0–M13 all delivered
