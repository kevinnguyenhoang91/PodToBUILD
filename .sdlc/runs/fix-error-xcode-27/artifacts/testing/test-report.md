# Test Report — Phase 7

**Agent:** stage-testing · Host: macOS 27.0 (Darwin 27.0.0, arm64), Xcode 27.0 (27A266a), Swift 6.4, Bazel 6.3.2

## Suite: `tools/test_fix_toolchain_uuid.sh --full`

Executed from a **fully expunged** Bazel output base (`bazel clean --expunge`), so the toolchain
was regenerated defective and repaired from scratch.

```
[AC-7] interface contract
  PASS  --help exits 0 (0)
  PASS  bad arg exits 2 (2)
  PASS  missing bazel exits 2 (2)
[AC-3] repair restores LC_UUID
  PASS  repair exits 0 (0)
  PASS  wrapped_clang has LC_UUID (2)
  PASS  wrapped_clang_pp has LC_UUID (2)
  PASS  libtool_check_unique has LC_UUID (2)
  PASS  wrapped_clang_pp is still a symlink
  PASS  wrapped_clang is loadable by dyld
  PASS  libtool_check_unique is loadable by dyld
[AC-5] idempotence
  PASS  second run exits 0 (0)
  PASS  no rewrite on healthy toolchain
  PASS  --check exits 0 when healthy (0)
[AC-1/2/4] full build
  PASS  make build exits 0 (0)
  PASS  bin/Compiler produced
  PASS  bin/RepoTools produced
  PASS  zero dyld errors (0)
  PASS  zero Abort trap (libtool_check_unique healthy) (0)

== 18 passed, 0 failed ==
```

## Acceptance criteria status

| AC | Status | Evidence |
|---|---|---|
| AC-1 clean build succeeds | ✅ PASS | `make build` exit 0 after expunge; `bin/Compiler` (2,332,336 B) and `bin/RepoTools` (2,425,040 B) produced |
| AC-2 no LC_UUID diagnostics | ✅ PASS | 0 lines matching `^dyld\[`; 0 `Abort trap` |
| AC-3 all drivers carry LC_UUID | ✅ PASS | `LC_UUID=2` (one per arch) on all three; all dyld-loadable |
| AC-4 duplicate-symbol checking restored | ✅ PASS | 0 `Abort trap` from `local_config_cc/libtool` (was 4 before the fix) |
| AC-5 idempotence | ✅ PASS | mtimes unchanged on 2nd run; `--check` exits 0 |
| **AC-6 `make unit-test` passes** | ❌ **FAIL — pre-existing, unrelated** | See below |
| AC-7 safe failure | ✅ PASS | exit 2 on bad arg, missing bazel, absent toolchain under `--check` |
| AC-8 non-Darwin no-op | ⚪ NOT EXERCISED | Guard is the first statement after arg parsing; no non-Darwin host available |
| AC-9 containment | ✅ PASS | `git status` shows only the 4 intended files; no writes outside the Bazel output base |

## Functional verification

`bin/Compiler Examples/PodSpecs/pop.podspec.json` produces correct Starlark output
(`load(...)`, `config_setting`, rule definitions) — the built tool works, not merely links.

## AC-6 — `make unit-test` fails (pre-existing defect, out of scope)

**Result:** `//:PodToBUILDTests` FAILED. **All 41 XCTest assertions pass** (`Executed 41 tests,
with 0 failures`). The target fails because 10 test helpers abort:

```
PodToBUILDTestsLib/TestUtils.swift:41: Fatal error: Missing bazel test base
```

`Tests/PodToBUILDTests/TestUtils.swift:39-41` requires `TEST_SRCDIR`:

```swift
guard let testSrcDir = ProcessInfo.processInfo.environment["TEST_SRCDIR"] else {
    fatalError("Missing bazel test base")
}
```

**Root cause (distinct from this run's):** `macos_unit_test` in rules_apple 1.1.3 runs tests via
`xcodebuild test-without-building` with a generated `.xctestrun`. Only variables listed in that
file's `TestingEnvironmentVariables` reach the test process, and `TEST_SRCDIR` is not among them
(`macos_test_runner.template.xctestrun` injects only `DYLD_*`, `XCInjectBundleInto`, and
`%(test_env)s`). `TEST_SRCDIR` never appears in the test log.

**Why it is unrelated to the toolchain fix:**
1. It is a *test-runtime environment* problem. The LC_UUID repair affects only whether
   `wrapped_clang`/`libtool_check_unique` can be dyld-loaded during **compile and link** actions.
2. Those actions all succeeded: the test bundle compiled, linked, was signed, and **ran**.
3. Reproduced identically with and without `--test_strategy=standalone`, so it is not the
   Makefile's test strategy.
4. It cannot have regressed from a prior state — before this fix the project could not build at
   all, so these tests had never run on this host.

**Why it was not fixed here:** the remedy is to patch rules_apple's runner template to forward
`TEST_SRCDIR` (requires patching a vendored `http_archive` dependency) or to redesign the test
fixture's path resolution. Both belong to the rules_apple/Bazel upgrade deferred in **ADR-002**;
doing either here would re-introduce exactly the dependency-graph blast radius ADR-001 avoided.

**Disposition:** raised as a known issue, documented in `README.md`, and logged for the ADR-002
follow-up. **AC-6 is not met and is not claimed as met.**

## Regression scope
Before → after on the same host, same targets:

| | Before | After |
|---|---|---|
| `make build` | FAILED, 0 useful actions | **Success, 69 actions** |
| dyld errors | 6+ per invocation | **0** |
| `libtool_check_unique` aborts | 4 per build | **0** |
| `bin/Compiler`, `bin/RepoTools` | not produced | **produced and functional** |
| XCTest assertions run | 0 (unbuildable) | **41, all passing** |

**Gate 7 — Test Coverage: PASS with one documented exception (AC-6).** All criteria attributable
to this change pass; the single failure is an independently-rooted pre-existing defect, evidenced
and disclosed rather than absorbed.
