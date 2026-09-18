# Acceptance Criteria

**Agent:** sub-acceptance-criteria · **Phase:** 2

## AC-1 — Clean build succeeds (FR-1, FR-3, FR-6)
- **Given** macOS 27.0 / Xcode 27.0, repo-pinned Bazel 6.3.2, and a purged output base
- **When** `make build` is run
- **Then** it exits 0 and `bin/Compiler` and `bin/RepoTools` exist and are executable.

## AC-2 — No LC_UUID diagnostics (FR-2, FR-3, FR-4)
- **Given** a build run after the repair
- **When** the full build output is captured
- **Then** it contains zero occurrences of `missing LC_UUID`
  and zero occurrences of `Abort trap: 6`.

## AC-3 — All driver binaries carry LC_UUID (FR-3, FR-4, FR-5)
- **When** the repair has run
- **Then** `otool -l` on each of `wrapped_clang`, `wrapped_clang_pp`, `libtool_check_unique`
  reports ≥ 1 `LC_UUID` load command, and each is loadable by dyld (invoking it does not abort).

## AC-4 — Duplicate-symbol checking restored (FR-4)
- **Given** a link of a static archive (e.g. `libPodToBUILD.a`)
- **Then** `external/local_config_cc/libtool` completes without its `libtool_check_unique`
  subprocess aborting.

## AC-5 — Idempotence (NFR-1, NFR-2)
- **Given** an already-repaired output base
- **When** the repair script is run again
- **Then** it exits 0, reports each binary as already healthy, and performs no recompilation
  (verified by unchanged mtime on the binaries).

## AC-6 — Unit tests pass (R4)
- **When** `make unit-test` is run
- **Then** the Bazel test invocation exits 0.

## AC-7 — Safe failure (FR-8, FR-9)
- **Given** an environment where Bazel's embedded source path cannot be resolved
- **Then** the script exits non-zero and prints which path it expected and where it looked —
  it must not silently continue or leave a half-written binary in place.

## AC-8 — Non-Darwin no-op (NFR-4)
- **Given** `uname -s` != `Darwin`
- **Then** the script exits 0 immediately without invoking `xcrun`, `otool`, or `codesign`.

## AC-9 — Containment (NFR-3, NFR-6)
- **When** the repair runs
- **Then** `git status --porcelain` shows no new or modified tracked files beyond those
  intentionally added by this change, and no file outside the Bazel output base is written.
