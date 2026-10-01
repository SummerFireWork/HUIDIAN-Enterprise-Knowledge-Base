# OSS Assets Index

> Open-source / resume / portfolio assets for the public branch. All figures are generated and the UI screenshots
> were captured from the real one-click demo stack (2026-10-01), so nothing in the README is a placeholder.

## 1. Asset Inventory

| File                     | Purpose                                                     | Status                                         |
| ------------------------ | ----------------------------------------------------------- | ---------------------------------------------- |
| `assets/architecture.svg`| System architecture (README "System Architecture" section)  | ✅ generated (1600×1160, dark brand theme)      |
| `assets/quickstart.svg`  | One-click demo flow (README "One-Click Local Demo")         | ✅ generated (1600×640)                        |
| `assets/eval-benchmark.svg` | Benchmark & performance figure (README "Benchmark" section) | ✅ generated (real measured numbers)           |
| `assets/ui-home.png`     | Workbench home screenshot (README "Screenshot Preview")     | ✅ captured (1280×720 demo stack)              |
| `assets/ui-search.png`   | Hybrid search result: facets + highlight (README preview)   | ✅ captured (demo stack)                       |
| `assets/ui-qa.png`       | RAG Q&A with citation cards (README preview)                | ✅ captured (demo stack)                       |
| `assets/ui-perms.png`    | Permission matrix (README preview)                          | ✅ captured (demo stack)                       |
| `assets/demo-video.mp4`  | Demo walkthrough video (README "Demo Walkthrough")          | ✅ recorded (37 MB, 1280×720)                  |

> To re-capture screenshots after UI changes: run the demo stack (`docker compose up -d`), log in with
> `admin/admin123`, and save the pages you need as PNG/JPG (16:9 recommended) into `assets/ui-*.png`,
> then update the `<img>` references in the README.

## 2. Verified Numbers You Can Reuse (README / interview talking points)

- App-side search latency **P50=162 / P90=211 / P95=226 / P99=263 ms**（target ≤ 300 ms）, RPS=121.5（20 concurrent × 500 searches, local benchmark）
- ES plain search P95=142 ms; BM25+KNN+RRF hybrid P95=156 ms（+9.9% for semantic recall）
- 100k synthetic chunks ingested in **17.7 s**
- Demo KB Recall@5 = 50%（50 real questions baseline, DoD target ≥85%, regression ongoing）
- Three-way reconciliation（PG/ES/MinIO）20/20/20 consistent
- Unit tests: 141 all green（`mvn -B test`, 2026-09-28 verified）; backend milestones M0–M13 all delivered

## 3. Demo Video & Demo Data Rules

| Item        | Where it goes                               | Status                                     |
| ----------- | ------------------------------------------- | ------------------------------------------ |
| Demo video  | `assets/demo-video.mp4` (README "Demo Walkthrough") | ✅ done (2026-10-01, 37 MB)          |
| Sanity rule | demo data is **synthetic/public samples only** — never record or publish organization documents | ✅ rule fixed |

> The public-branch README source lives at `docs/oss/README.public.md` (kept in sync with the rendered
> `README.md` on the `public` branch).
