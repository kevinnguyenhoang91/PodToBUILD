# Business Case

**Agent:** sub-opportunity-analyzer · **Phase:** 0

## Value

| Dimension | Assessment |
|---|---|
| **Cost of inaction** | Total. The project is unbuildable on current Xcode; development, testing and releases stop. Every contributor who upgrades Xcode is locked out permanently. |
| **Cost of fix** | Low. Root cause is known and proven; the remedy is a small, self-contained, idempotent shell script plus a Makefile hook. No source changes to PodToBUILD itself, no dependency upgrades. |
| **Risk of fix** | Low–Medium. The script rewrites files inside Bazel's output base (`external/local_config_cc/`), not the repo or the system. It is guarded by an `LC_UUID`-present check, so it is a no-op on healthy hosts, and on non-Darwin hosts it exits immediately. |
| **Correctness upside** | Restores duplicate-symbol detection (`libtool_check_unique`), which is currently silently disabled on *every* archive link — a real, latent correctness gap independent of the build failure. |
| **Strategic** | Buys time. It unblocks work now without forcing the much larger Bazel 7/8 + rules_apple + Bzlmod migration, which can then be scheduled deliberately rather than under duress. |

## ROI
Effort: hours. Benefit: unblocks the entire project indefinitely on current and future macOS.
The fix is self-retiring — once the repo moves to a Bazel release that dropped `-Wl,-no_uuid`,
the guard makes the script a no-op and it can be deleted.

## Recommendation
**Proceed.** Highest-value, lowest-risk work available on this repo.
