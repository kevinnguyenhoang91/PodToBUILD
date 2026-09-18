# Go / No-Go Decision — Gate 0

**Agent:** stage-problem-discovery · **Phase:** 0 · **Date:** 2026-09-18

## Decision: ✅ **GO**

## Rationale

| Gate 0 criterion | Status | Evidence |
|---|---|---|
| Problem is real and reproducible | ✅ | Reproduced on this host; full failure output captured. |
| Root cause identified, not guessed | ✅ | Traced to `osx_cc_configure.bzl:109` `-Wl,-no_uuid`; confirmed by `otool -l` showing 0 `LC_UUID`. |
| Problem is severe enough to act | ✅ | Total build stoppage — blocker for all contributors, CI, and releases. |
| ≥3 alternatives evaluated, incl. don't-build | ✅ | 5 evaluated (A1–A5) in `solution-alternatives.md`. |
| Selected solution is feasible | ✅ | Empirically validated end-to-end: `FAILED` → `Build completed successfully, 44 total actions`. |
| Success criteria are measurable | ✅ | SC-1…SC-6 in `problem-statement.md`. |
| Business case positive | ✅ | Hours of effort to remove an indefinite total blocker. |

## Scope Approved
Implement **A5** — a guarded, idempotent re-link of Bazel's `wrapped_clang`,
`wrapped_clang_pp` and `libtool_check_unique` with `LC_UUID` restored, invoked automatically
from the build entry point.

## Explicitly Deferred
**A2 — Bazel 7/8 + rules_apple/Bzlmod migration.** Correct long-term fix; too large and too
risky to bundle with an urgent unblock. Recorded as ADR-002 with a retirement trigger for A5.

## Risks Accepted
- **R1** — Fix operates inside Bazel's output base (unofficial seam). Mitigated: read-only
  detection first, writes confined to `external/local_config_cc/`, no repo or system mutation.
- **R2** — Must re-apply after `bazel clean --expunge`. Mitigated: hooked into `make build` /
  `make release` so it always runs before the build.
- **R3** — Bazel's embedded source paths could change in a future Bazel. Mitigated: script
  resolves them via `bazel info install_base` and fails loudly with a clear message if absent.

**Proceed to Phase 1: Bootstrap.**
