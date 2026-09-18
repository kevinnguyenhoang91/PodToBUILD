# Requirements

**Agent:** sub-requirement-parser · **Phase:** 2 · Source: `specs/normalized-spec.md`

## Functional

| ID | Requirement | Priority | Source |
|---|---|---|---|
| FR-1 | The build must produce `bin/Compiler` and `bin/RepoTools` on macOS 27 / Xcode 27.0 with the repo-pinned Bazel 6.3.2. | MUST | SC-1 |
| FR-2 | A repair step must detect whether Bazel's generated `local_config_cc` driver binaries carry an `LC_UUID` load command. | MUST | R2 |
| FR-3 | When `LC_UUID` is absent, the repair must re-link `wrapped_clang` from Bazel's own embedded `wrapped_clang.cc`, using Bazel's exact command line minus `-Wl,-no_uuid`, then ad-hoc codesign it. | MUST | R1 |
| FR-4 | The repair must apply the same treatment to `libtool_check_unique`, restoring duplicate-symbol detection. | MUST | R3 |
| FR-5 | `wrapped_clang_pp` must resolve to a repaired binary (it is a symlink to `wrapped_clang`; the symlink must be preserved or recreated). | MUST | R1 |
| FR-6 | The repair must run automatically before the compile/link actions of `make build` and `make release`. | MUST | R6 |
| FR-7 | If `local_config_cc` has not been generated yet, the repair must trigger its generation (loading/analysis only, no build actions) before inspecting it. | MUST | R6 |
| FR-8 | The repair must locate Bazel's embedded sources via `bazel info install_base`, never a hard-coded path. | MUST | R9 |
| FR-9 | The repair must exit non-zero with an actionable message if an expected source or output path is missing. | SHOULD | R9 |

## Non-Functional

| ID | Requirement | Priority |
|---|---|---|
| NFR-1 | **Idempotent** — re-running changes nothing once binaries are healthy. | MUST |
| NFR-2 | **No-op cost** — on a healthy host the repair adds only cheap `otool`/`bazel info` checks, not a recompile. | MUST |
| NFR-3 | **Scoped writes** — writes confined to `$(bazel info output_base)/external/local_config_cc/`. No writes to the repo, `/usr`, or the Xcode installation. | MUST |
| NFR-4 | **Portable no-op** — exits successfully and silently on non-Darwin hosts. | SHOULD |
| NFR-5 | **No new dependencies** — POSIX shell plus tools already required by the build (`xcrun`, `clang`, `otool`, `codesign`, `bazel`). | MUST |
| NFR-6 | **No committed binaries** — nothing vendored into the repo. | MUST |
| NFR-7 | **Self-retiring** — becomes a permanent no-op once the repo moves to a Bazel without `-Wl,-no_uuid`. | SHOULD |
| NFR-8 | **Observable** — prints what it inspected, what it repaired, and what it skipped. | SHOULD |
