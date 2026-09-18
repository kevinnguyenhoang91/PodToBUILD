# Solution Evaluation

**Agent:** sub-solution-evaluator · **Phase:** 4

Trade-off analysis of the two live architectural options (A1/A3/A4 eliminated in Phase 0).

| Criterion | Weight | A5 — Repair in place | A2 — Upgrade Bazel |
|---|---|---|---|
| Restores the build now | 30% | 10 — validated end-to-end | 3 — days of migration first |
| Risk of regression | 25% | 9 — one flag, same source, contained writes | 4 — touches every rule, dep and example |
| Effort | 15% | 9 — hours | 3 — multi-day |
| Long-term correctness | 15% | 5 — a workaround by design | 10 — removes the cause |
| Reversibility | 10% | 10 — delete a script and two Makefile lines | 4 — wide-reaching |
| Maintenance burden | 5% | 6 — one script, self-disabling | 8 — none once done |
| **Weighted** | | **8.55** | **4.75** |

**Conclusion:** A5 now (ADR-001), A2 later (ADR-002). These are complementary, not competing:
A5 explicitly self-retires when A2 lands, and A5's green build is what makes A2 safely testable.

**Interface between them:** the `LC_UUID` probe. When A2 completes, the probe reports both
binaries healthy and the script becomes inert — an executable, self-verifying removal trigger
rather than a calendar reminder.
