# rrf-fusion.java — Reciprocal Rank Fusion

Reciprocal Rank Fusion (RRF) is the rank-based fusion behind the hybrid search (BM25 + KNN).
Its key property: **it only needs the rank positions, not the raw scores** — so two engines with
incomparable score scales (BM25 vs cosine similarity) can be fused without any normalization.

```
RRF(d) = Σ 1 / (k + rank_i(d))
```

- `k` (rank constant) smooths the marginal benefit of a high rank. Here `k = 60`:
  a document ranked 1st scores 1/61, ranked 10th scores 1/70 — differences are mild, so a
  document that appears (weakly) in **both** lists can beat a document ranked highly in only one.
- No per-engine tuning, no score calibration.

This file is a dependency-free, runnable sketch of the algorithm (the production integration uses
the native `retriever.rrf` inside Elasticsearch).

```java
import java.util.*;

/** Reciprocal Rank Fusion — merge multiple ranked lists without score normalization. */
public final class RrfFusion {

    /** Smoothing constant: higher k dilutes rank differences. 60 is the community default. */
    static final double K = 60.0;

    /**
     * Fuse ranked lists of document ids into a single ranked result.
     *
     * @param rankedLists one list per retriever, ordered best-first (id only)
     * @param topK        how many results to keep
     * @return linked map of docId -> fused score, best first
     */
    public static LinkedHashMap<String, Double> fuse(List<List<String>> rankedLists, int topK) {
        Map<String, Double> scores = new HashMap<>();
        for (List<String> list : rankedLists) {
            for (int i = 0; i < list.size(); i++) {
                scores.merge(list.get(i), 1.0 / (K + i + 1), Double::sum);
            }
        }
        // sort by fused score desc, keep insertion order for stable top-K
        LinkedHashMap<String, Double> out = new LinkedHashMap<>();
        scores.entrySet().stream()
                .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
                .limit(topK)
                .forEach(e -> out.put(e.getKey(), e.getValue()));
        return out;
    }

    /** Tiny self-test: dual weak hits out-rank a single strong hit. */
    public static void main(String[] args) {
        List<List<String>> lists = List.of(
                List.of("bm25-only-high", "shared-a", "shared-b", "bm25-weak"),
                List.of("knn-strong", "shared-b", "shared-a", "knn-weak"));
        fuse(lists, 6).forEach((id, score) ->
                System.out.printf("%-14s %.4f%n", id, score));
        // expect "shared-a"/"shared-b" (present in both lists) to out-rank
        // "bm25-only-high" (rank 1 in one list only) — that is RRF's whole point.
    }
}
```

Run: `java rrf-fusion.java` (Java 11+, single-file source launcher).
