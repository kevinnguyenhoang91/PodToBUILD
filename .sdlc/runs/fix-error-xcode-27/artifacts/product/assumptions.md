# Assumptions

**Agent:** sub-assumption-extractor · **Phase:** 2

| ID | Assumption | Basis | If wrong |
|---|---|---|---|
| AS-1 | The repo intends to stay on Bazel 6.3.2 for now. | `.bazelversion`, committed `tools/bazel` 6.3.2, `Makefile: TESTED_BAZEL_VERSION=6.3.2`, rules_apple pinned to 1.1.3. | ADR-002's migration becomes the fix instead; this repair becomes unnecessary (and self-disables). |
| AS-2 | `LC_UUID` absence is the *only* Xcode-27 blocker for this build. | Verified: after repairing `wrapped_clang`, the build reached `Build completed successfully, 44 total actions`. | Further failures surface in Phase 7; scope would expand. |
| AS-3 | Removing `-Wl,-no_uuid` does not alter `wrapped_clang`'s runtime behavior. | The flag only suppresses emission of the `LC_UUID` load command; it does not affect code generation or linked content. | Behavioral drift would show up as compile/link failures in Phase 7 regression runs. |
| AS-4 | `libtool_check_unique`'s abort is currently non-fatal. | Observed: `external/local_config_cc/libtool` line 52 logs `Abort trap: 6` and the build still succeeds — i.e. the check is skipped, not enforced. | If it were fatal, severity rises but the fix is identical. |
| AS-5 | Developers and CI invoke the build through the `Makefile`. | `Makefile` is the documented entry point (`make build`, `make release`, `make unit-test`, `make ci`). | Direct `tools/bazel build` users bypass the hook — mitigated by documenting the script and making it runnable standalone. |
| AS-6 | `xcrun`, `clang`, `otool`, `codesign` are available. | All are required by the Bazel Apple toolchain already; the build cannot work without them. | Script fails loudly (AC-7). |
| AS-7 | The 10 `Examples/*` sub-builds use their own Bazel output bases. | Each `Examples/*/Makefile` runs Bazel in its own workspace directory. | Each example needs the repair too — addressed in Phase 5 design as a documented, reusable standalone invocation. |
