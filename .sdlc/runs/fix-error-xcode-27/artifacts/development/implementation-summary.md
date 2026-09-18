# Implementation Summary — Phase 6

**Agent:** stage-development

## Files changed

| File | Change | Tasks |
|---|---|---|
| `tools/fix_toolchain_uuid.sh` | **new**, +250 lines, executable | T-101…T-108 |
| `tools/test_fix_toolchain_uuid.sh` | **new**, +110 lines, executable | T-301 |
| `Makefile` | `fix-toolchain` target; `build`, `release`, `unit-test` now depend on it | T-201, T-202 |
| `README.md` | "Building on macOS 27 / Xcode 27" section incl. removal trigger and the known test issue | T-303 |

No changes to `Sources/`, `BUILD`, `WORKSPACE`, `third_party/`, or any dependency. No binaries committed.

## `sub-repo-analyzer` findings that shaped the implementation

1. `tools/bazel` is a **committed Mach-O universal binary**, not a wrapper script — confirmed with
   `file`. This ruled out the "wrap the bazel invocation" approach and made a `Makefile`
   prerequisite the right seam.
2. `.bazelrc` sets `--spawn_strategy=local` and `--experimental_strict_action_env`; the repair
   runs outside Bazel's action graph so neither affects it.
3. The repo already ships shell tooling (`MakeGoldMaster.sh`, `IntegrationTests/RunTests.sh`),
   so a shell script matches existing convention.
4. `_compile_cc_file` is called exactly twice in `osx_cc_configure.bzl` (lines 219, 228) —
   bounding the blast radius to two binaries plus one symlink, which the descriptor table encodes.

## Implementation notes

- **`--nobuild` for toolchain generation (FR-7).** A normal `build` would execute actions and hit
  the very dyld failure being repaired, deadlocking the fix. `--nobuild` stops after analysis,
  which is enough to configure `@local_config_cc`.
- **Atomic install (RK-9).** Compile → codesign → *verify `LC_UUID`* → `mv`. The verify step
  means a silently-still-broken binary is never installed; a `RETURN` trap removes the temp file
  on every exit path.
- **Symlink preservation (FR-5).** `wrapped_clang_pp` is re-pointed with `ln -sfn` after
  `wrapped_clang` is replaced, rather than being treated as a third compile target.
- **Error surfacing (deviation from design, improved during implementation).** The first version
  discarded Bazel's stderr on a failed `--nobuild`, producing an unactionable message. It now
  echoes Bazel's output indented and suggests `clean --expunge` for the stale-`@local_config_cc`
  case. This was found by testing a partially-purged output base, not by inspection.

## Deviations from design
One, above (error surfacing) — an addition, not a contract change. No exit code, flag, or
guarantee from `design/interface-contract.md` was altered.

## Queue
14 of 14 tasks complete (T-304 ADRs were produced in Phase 4).
