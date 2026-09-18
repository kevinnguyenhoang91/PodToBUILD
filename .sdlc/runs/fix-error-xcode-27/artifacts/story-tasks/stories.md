# Epics, Stories & Tasks

**Agents:** sub-story-writer, sub-task-decomposer · **Phase:** 3

## EPIC-1 — Restore buildability on Xcode 27

### STORY-1.1 — Repair the Bazel C++ driver binaries
> As a PodToBUILD developer on macOS 27, I want Bazel's generated `wrapped_clang` and
> `libtool_check_unique` to carry `LC_UUID`, so that dyld can load them and my build succeeds.

Satisfies FR-2, FR-3, FR-4, FR-5, FR-8, FR-9, NFR-1…NFR-6. Verified by AC-2, AC-3, AC-4, AC-5, AC-7, AC-8, AC-9.

| Task | Description | Deps |
|---|---|---|
| T-101 | Create `tools/fix_toolchain_uuid.sh` skeleton: `set -euo pipefail`, usage, Darwin guard (NFR-4/AC-8). | — |
| T-102 | Resolve `output_base` and `install_base` via `bazel info`; ensure `local_config_cc` exists, generating it with `build --nobuild` if not (FR-7). | T-101 |
| T-103 | Implement `has_lc_uuid()` detection helper over `otool -l` (FR-2). | T-101 |
| T-104 | Implement `relink()`: recompile from Bazel's embedded source with Bazel's exact flags minus `-Wl,-no_uuid`, ad-hoc codesign, atomic `mv` into place (FR-3, RK-9). | T-102, T-103 |
| T-105 | Apply to `wrapped_clang` (src `tools/osx/crosstool/wrapped_clang.cc`) and recreate the `wrapped_clang_pp` symlink (FR-5). | T-104 |
| T-106 | Apply to `libtool_check_unique` (src `tools/objc/libtool_check_unique.cc`) (FR-4). | T-104 |
| T-107 | Add existence checks + actionable error messages for every resolved path (FR-9, AC-7). | T-102, T-104 |
| T-108 | Add progress/summary output: inspected / repaired / already-healthy (NFR-8). | T-105, T-106 |

### STORY-1.2 — Wire the repair into the build
> As a developer or CI job, I want the repair to happen automatically, so that a clean checkout
> or a post-`bazel clean` build just works.

Satisfies FR-6, R6. Verified by AC-1, AC-6.

| Task | Description | Deps |
|---|---|---|
| T-201 | Add a `fix-toolchain` target to the `Makefile`. | T-108 |
| T-202 | Make `build`, `release` and `unit-test` depend on it. | T-201 |
| T-203 | Keep the script standalone-invocable for `Examples/*` and direct `tools/bazel` users (AS-5, AS-7). | T-201 |

### STORY-1.3 — Verify and document
> As a maintainer, I want proof the fix works and a record of why it exists, so it can be
> removed confidently when Bazel is upgraded.

Satisfies R10, NFR-7, NFR-8. Verified by AC-1, AC-6.

| Task | Description | Deps |
|---|---|---|
| T-301 | Regression script asserting AC-1…AC-5 end-to-end from a purged output base. | T-202 |
| T-302 | Run `make build` + `make unit-test` from a clean state; capture evidence. | T-301 |
| T-303 | Document the workaround (README section) with the removal trigger. | T-202 |
| T-304 | Record ADR-001 (repair approach) and ADR-002 (deferred Bazel migration). | — |
