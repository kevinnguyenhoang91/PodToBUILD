# Normalized Spec — Fix build error on Xcode 27.0

**Source:** run title + direct reproduction (no written spec supplied)
**Run:** `fix-error-xcode-27` · **Normalized:** 2026-09-18

## Context
PodToBUILD builds with a repo-pinned **Bazel 6.3.2** (`.bazelversion`, committed `tools/bazel`),
`rules_apple` 1.1.3, WORKSPACE mode. Host is macOS 27.0 / Xcode 27.0 / Swift 6.4.

## Problem
`make build` fails: every C/C++/ObjC action aborts with
`dyld: missing LC_UUID load command in external/local_config_cc/wrapped_clang`.
Cause: Bazel 6.3.2's embedded `osx_cc_configure.bzl` links its generated toolchain driver
binaries with `-Wl,-no_uuid`; macOS 27's dyld refuses to load a Mach-O executable lacking
`LC_UUID`. Three generated binaries are affected — `wrapped_clang` (fatal),
`wrapped_clang_pp` (fatal, symlink), `libtool_check_unique` (silent: `libtool` swallows the
abort, disabling duplicate-symbol checking).

## Requirements

| ID | Requirement | Priority |
|---|---|---|
| R1 | `make build` must complete successfully on macOS 27 / Xcode 27.0 with Bazel 6.3.2 | MUST |
| R2 | No `missing LC_UUID` diagnostic in build output | MUST |
| R3 | `libtool_check_unique` must execute successfully (restore duplicate-symbol detection) | MUST |
| R4 | `make unit-test` must pass | MUST |
| R5 | Repair must be idempotent and a no-op when `LC_UUID` is already present | MUST |
| R6 | Repair must re-apply automatically after `bazel clean --expunge` | MUST |
| R7 | Repair must not commit binaries, vendor a toolchain, or mutate the repo/system toolchain | MUST |
| R8 | Repair must no-op on non-Darwin hosts | SHOULD |
| R9 | Repair must fail loudly, with an actionable message, if Bazel's embedded sources move | SHOULD |
| R10 | Long-term migration off Bazel 6.3.2 must be recorded as a decision with a retirement trigger | SHOULD |

## Solution (approved Phase 0)
`tools/fix_toolchain_uuid.sh` — guarded, idempotent re-link of the affected binaries from
Bazel's **own embedded sources**, using Bazel's exact compile command minus `-Wl,-no_uuid`,
followed by ad-hoc codesign. Invoked from the `Makefile` before `build`/`release`.

## Out of Scope
- Bazel 7/8 + Bzlmod migration (ADR-002, deferred).
- Pre-existing Swift 6.4 warnings in `Sources/PodToBUILD/Workspace.swift`.

## Complexity
**Simple** — 10 requirements, single component, one new script + one Makefile hook, no new deps.
