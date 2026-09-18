# ADR-001 — Repair Bazel's C++ driver binaries in place to restore `LC_UUID`

**Agent:** sub-adr-writer · **Status:** Accepted · **Date:** 2026-09-18
**Risk classification:** MEDIUM (build tooling; reversible; no production or data impact)

## Context
macOS 27 / Xcode 27 ship a dyld that refuses to load any Mach-O executable without an `LC_UUID`
load command. Bazel 6.3.2 — pinned by this repo via `.bazelversion` and the committed
`tools/bazel` binary — generates its C++ toolchain driver binaries with `-Wl,-no_uuid`
(`embedded_tools/tools/cpp/osx_cc_configure.bzl:109`, added upstream for build reproducibility).

Consequently `external/local_config_cc/wrapped_clang`, its `wrapped_clang_pp` symlink, and
`libtool_check_unique` all lack `LC_UUID`. Every C/C++/ObjC compile and link action aborts, and
`libtool`'s duplicate-symbol check fails silently. The project is unbuildable.

## Decision
Add `tools/fix_toolchain_uuid.sh`: a guarded, idempotent step that runs before the Bazel build,
detects the missing `LC_UUID`, and re-links the affected binaries **from Bazel's own embedded
sources** using **Bazel's exact compile command with `-Wl,-no_uuid` removed**, then ad-hoc
codesigns them exactly as Bazel does. Hook it into `make build`, `make release` and
`make unit-test`.

## Rationale
- **Proven.** Validated end-to-end before adoption: `FAILED` → `Build completed successfully,
  44 total actions`.
- **Minimal delta.** Same source, same compiler, same SDK, same flags — one flag removed, and that
  flag governs only the presence of a build-ID load command, not code generation.
- **Contained.** Writes only inside Bazel's output base. Nothing vendored, no binary committed,
  no change to `WORKSPACE`, `BUILD`, or any rule.
- **Free when unnecessary.** The `LC_UUID` probe is the enable condition, so the script is a
  no-op on healthy hosts and on non-Darwin platforms.
- **Also fixes a latent defect.** Restores `libtool_check_unique`, re-enabling duplicate-symbol
  detection that is currently skipped on every archive link.

## Consequences

**Positive** — project builds again on current Xcode; duplicate-symbol checking restored;
no toolchain migration forced under time pressure; trivially removable.

**Negative** — depends on Bazel's output-base layout (`external/local_config_cc/`) and its
embedded source paths, an unofficial seam. Mitigated by resolving everything through
`bazel info` and failing loudly on any missing path (RK-1, RK-5).

**Accepted trade-off** — re-introducing `LC_UUID` gives up the byte-for-byte reproducibility
that `-no_uuid` was added to provide. Acceptable here: these are local build drivers, consumed
only during the build, and never packaged into `PodToBUILD.zip` (the `archive` target ships only
`bin/`, `BazelExtensions`, `Makefile`, `WORKSPACE`, `BUILD`, `LICENSE`).

## Alternatives considered
See `problem-discovery/solution-alternatives.md` — A1 don't-build, A2 upgrade Bazel,
A3 `apple_cc_configure` (verified infeasible on the pinned `apple_support`), A4 vendor a
prebuilt toolchain. A5 selected.

## Retirement trigger
Delete this script and its `Makefile` hooks once the repo moves to a Bazel release that no longer
passes `-Wl,-no_uuid` (see ADR-002). The script's self-disabling guard means it becomes inert —
and provably unnecessary — before it is removed.
