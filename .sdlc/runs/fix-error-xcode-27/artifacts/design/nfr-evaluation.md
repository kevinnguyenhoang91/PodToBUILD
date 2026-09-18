# NFR Evaluation

**Agent:** sub-nfr-evaluator · **Phase:** 5

| NFR | Target | Design satisfies it by | Verified in |
|---|---|---|---|
| NFR-1 Idempotent | 2nd run makes no writes | `has_lc_uuid` gate precedes every write path | AC-5 |
| NFR-2 No-op cost | No recompile on healthy host | Two `otool` probes + two `bazel info` calls (~sub-second); compile only on a 0 count | AC-5 |
| NFR-3 Scoped writes | Nothing outside the output base | Only `$CC_DIR/*` and temp files in `$CC_DIR`; `embedded_tools` read-only | AC-9 |
| NFR-4 Portable no-op | Exit 0 on non-Darwin | `uname -s` guard is the first statement after arg parsing | AC-8 |
| NFR-5 No new deps | Only existing tools | `sh`, `uname`, `otool`, `xcrun`, `clang`, `codesign`, `mv` — all already required by an Apple Bazel build | tech-stack.md |
| NFR-6 No committed binaries | Repo adds source only | One `.sh` + `Makefile` edits; binaries are produced at run time into the output base | AC-9 |
| NFR-7 Self-retiring | Inert after Bazel upgrade | `LC_UUID` probe is the enable condition; `--check` exits 0 when obsolete, giving an executable retirement test | ADR-001 |
| NFR-8 Observable | Reports per-binary outcome | Per-target status lines + a summary count; `--verbose` echoes exact commands | interface-contract.md |

## Performance
Healthy host: 2× `bazel info` + 2× `otool` ≈ well under a second, dominated by Bazel's own
startup, which the build pays anyway. Defective host: 2 universal-binary clang compiles of a
single `.cc` each — measured at a few seconds total, once per output base.

## Security
- No network access, no credential handling, no privilege escalation.
- Compiles **only** Bazel's own embedded sources from `$(bazel info install_base)`; no
  downloaded, generated, or user-supplied source enters the compile.
- Ad-hoc signature (`--sign -`) exactly as Bazel does — no identity or keychain access.
- Full detail in Phase 8.

## Reliability
Single failure mode of consequence is a partially-written binary, eliminated by
temp-file + verify + atomic `mv` (RK-9). A trap removes the temp file on any exit path.

**Gate 5 — Design Completeness: PASS.** Every FR and NFR has a concrete design mechanism and a
named verification.
