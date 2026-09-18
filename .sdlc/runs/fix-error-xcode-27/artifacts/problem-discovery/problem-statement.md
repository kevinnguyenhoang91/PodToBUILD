# Problem Statement — Fix build error on Xcode 27.0

**Agent:** sub-problem-statement-extractor
**Phase:** 0 — Problem Discovery
**Date:** 2026-09-18

## Raw Input
Run title: "Fix build error on Xcode 27.0". No written spec was supplied; the problem was
characterized by direct reproduction against the working tree.

## Reproduction (verified)

Host: macOS 27.0 (Darwin 27.0.0, arm64), Xcode 27.0 (27A266a), Apple Swift 6.4.
Repo pins Bazel **6.3.2** (`.bazelversion`, committed `tools/bazel` Mach-O launcher).

```
$ make build      # tools/bazel build ... :RepoTools :Compiler
ERROR: .../external/podtobuild-Yams/BUILD.bazel:6:13: Compiling Sources/CYaml/src/parser.c failed:
  (Aborted): wrapped_clang failed: error executing command external/local_config_cc/wrapped_clang ...
dyld[36843]: missing LC_UUID load command in .../external/local_config_cc/wrapped_clang
dyld[36843]: missing LC_UUID load command
...
FAILED: Build did NOT complete successfully
```

Every C/C++/ObjC compile and link action aborts. `make build`, `make unit-test`,
`make release`, `make build-test` and CI are all blocked.

## Measured Root Cause

`external/local_config_cc/wrapped_clang` is a Mach-O universal binary that carries **no
`LC_UUID` load command**:

```
$ otool -l external/local_config_cc/wrapped_clang | grep -c LC_UUID
0
```

That binary is generated at repository-rule time by Bazel's own embedded
`tools/cpp/osx_cc_configure.bzl`. Its `_compile_cc_file()` helper links with
`-Wl,-no_uuid` (added upstream for build reproducibility):

```python
# <install_base>/embedded_tools/tools/cpp/osx_cc_configure.bzl:91-115
def _compile_cc_file(repository_ctx, src_name, out_name, timeout):
    xcrun_result = repository_ctx.execute([... "clang",
        "-mmacosx-version-min=10.13", "-std=c++11", "-lc++",
        "-arch", "arm64", "-arch", "x86_64",
        "-Wl,-no_adhoc_codesign",
        "-Wl,-no_uuid",              # <-- strips LC_UUID
        "-O3", "-o", out_name, src_name])
```

The dyld shipped with macOS 27 / Xcode 27 **refuses to load a Mach-O executable that has no
`LC_UUID`**, aborting the process before `main()`. Older dyld tolerated its absence, which is
why the identical Bazel version built fine on earlier macOS releases.

`_compile_cc_file()` is called exactly twice (`osx_cc_configure.bzl:219`, `:228`), so exactly
two generated binaries are defective:

| Binary | LC_UUID | Impact |
|---|---|---|
| `local_config_cc/wrapped_clang` | 0 | **Fatal** — all C/C++/ObjC compiles abort |
| `local_config_cc/wrapped_clang_pp` | 0 | **Fatal** — symlink to `wrapped_clang` |
| `local_config_cc/libtool_check_unique` | 0 | **Silent degradation** — `libtool` (line 52) ignores the abort, so duplicate-symbol checking is skipped on every static-archive link |
| `local_config_cc/xcode-locator-bin` | 1 | Unaffected (built by `xcode_configure.bzl`, no `-no_uuid`) |
| `local_config_xcode/xcode-locator-bin` | 1 | Unaffected |

## Problem Statement (measurable)

> On macOS 27 / Xcode 27, PodToBUILD cannot be built at all, because Bazel 6.3.2 generates its
> C++ toolchain driver binaries (`wrapped_clang`, `wrapped_clang_pp`, `libtool_check_unique`)
> without an `LC_UUID` load command, which the macOS 27 dynamic loader rejects. Additionally,
> `libtool_check_unique` fails silently, disabling duplicate-symbol detection on every archive
> link even where the build appears to succeed.

## Success Criteria

| ID | Criterion | Measurement |
|---|---|---|
| SC-1 | `make build` completes successfully on Xcode 27.0 | exit 0, `bin/Compiler` + `bin/RepoTools` produced |
| SC-2 | No `missing LC_UUID` message anywhere in build output | `grep -c "missing LC_UUID"` == 0 |
| SC-3 | `libtool_check_unique` runs successfully (duplicate-symbol checking restored) | no `Abort trap: 6` from `external/local_config_cc/libtool` |
| SC-4 | `make unit-test` passes | bazel test exit 0 |
| SC-5 | Fix is a no-op on hosts that are already healthy | script detects `LC_UUID` present and exits without relinking |
| SC-6 | Fix survives `bazel clean` and toolchain regeneration | re-applied automatically by the build entry point |

## Out of Scope
- Migrating off Bazel 6.3.2 / WORKSPACE to Bzlmod (tracked separately; see ADR-002).
- The pre-existing Swift 6.4 compiler *warnings* in `Sources/PodToBUILD/Workspace.swift`
  (non-blocking; noted in Phase 9).
