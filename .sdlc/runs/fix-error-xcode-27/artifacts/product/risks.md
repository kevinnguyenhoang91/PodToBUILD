# Risk Analysis

**Agent:** sub-risk-analyzer · **Phase:** 2

| ID | Risk | L | I | Score | Mitigation | Status |
|---|---|---|---|---|---|---|
| RK-1 | Repair writes into Bazel's output base — an unofficial seam Bazel may reorganize. | M | M | 6 | Resolve every path via `bazel info` (never hard-coded); verify each expected file exists before writing; fail loudly with the expected path if not (AC-7). Confined to `external/local_config_cc/`. | Mitigated |
| RK-2 | `bazel clean --expunge` discards the repair, reintroducing the failure. | H | M | 9 | Hook the repair into `make build`/`make release` so it always precedes the real build; make it idempotent so the extra run is free (AC-5). | Mitigated |
| RK-3 | Re-linking with different flags changes `wrapped_clang` behavior. | L | H | 5 | Compile the **same source** Bazel ships, with Bazel's **exact** command line, removing exactly one flag (`-Wl,-no_uuid`) that affects only the presence of a build-ID load command — not codegen. `-Wl,-no_adhoc_codesign` and the explicit `codesign` step are retained verbatim. | Mitigated |
| RK-4 | Dropping `-no_uuid` breaks build reproducibility (its original purpose): `LC_UUID` is content-derived, so identical inputs still yield identical UUIDs, but toolchain-path differences could vary it. | M | L | 3 | Accepted. The binary is a local build driver, never shipped in `PodToBUILD.zip`; it does not enter any output artifact. Documented in ADR-001. | Accepted |
| RK-5 | Bazel's embedded source layout (`embedded_tools/tools/osx/crosstool/wrapped_clang.cc`) changes in a future Bazel. | L | M | 3 | Existence-checked at runtime with a clear error (AC-7); the script is pinned in intent to Bazel 6.x and self-disables once the host Bazel emits healthy binaries. | Mitigated |
| RK-6 | Codesign identity mismatch across the two architectures breaks the universal binary. | L | H | 5 | Reuse Bazel's own `codesign --identifier <name> --force --sign -` invocation verbatim (the `--identifier` is required for cross-arch reproducibility). Verified by successful multi-arch load. | Mitigated |
| RK-7 | Fix masks the real need to upgrade Bazel; repo drifts further behind. | M | M | 6 | ADR-002 records the deferral explicitly with a retirement trigger; the script's self-disabling guard makes removal trivial and detectable. | Mitigated |
| RK-8 | Repair triggers a Bazel analysis pass (FR-7) that is slow or has side effects. | L | L | 2 | Use `--nobuild` (loading + analysis only, no actions). Only invoked when `local_config_cc` is absent. | Mitigated |
| RK-9 | Concurrent `make build` invocations race on rewriting the same binary. | L | M | 3 | Write to a temp file in the same directory and `mv` atomically into place. | Mitigated |

**Residual risk: LOW.** No Critical or High residual items.
