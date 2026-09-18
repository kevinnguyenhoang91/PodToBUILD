# Technology Stack

**Agent:** sub-tech-stack-advisor · **Phase:** 4

| Concern | Choice | Rationale | Alternatives rejected |
|---|---|---|---|
| Repair language | **POSIX `sh`/`bash`** | Zero new dependencies (NFR-5); the operations are process orchestration, which shell expresses directly; matches `MakeGoldMaster.sh` and `IntegrationTests/RunTests.sh` already in-repo. | Python (adds an interpreter dependency to the build path; the repo's own Python usage is a Bazel toolchain concern, not a build-driver one); Swift (would need to be built by the very toolchain that is broken — circular). |
| Binary inspection | **`otool -l`** | Ships with Xcode; already a hard dependency of any Apple Bazel build; direct read of Mach-O load commands. | `dwarfdump --uuid` (prints nothing rather than failing when absent — ambiguous); `llvm-objdump` (not guaranteed on `PATH`). |
| Compilation | **`xcrun --sdk macosx clang`** | Exactly what Bazel itself uses in `_compile_cc_file`; guarantees the same compiler and SDK selection. | Bare `clang` (skips `xcrun`'s SDK/DEVELOPER_DIR resolution — would drift from Bazel). |
| Signing | **`codesign --identifier <n> --force --sign -`** | Verbatim from Bazel's own post-compile step; `--identifier` is required for the signature to be identical across architectures. | Skipping signing (binary would be rejected on arm64); `-Wl,-adhoc_codesign` (Bazel deliberately disables it and signs explicitly). |
| Path discovery | **`bazel info output_base` / `install_base`** | Authoritative and version-independent; no hard-coded `/private/var/tmp/_bazel_*` (RK-1, RK-5). | Hard-coded paths; `find` heuristics. |
| Integration point | **`Makefile` prerequisite target** | The documented entry point for every build/test/release flow (AS-5); a prerequisite guarantees ordering without wrapping Bazel. | A `tools/bazel` shell wrapper (the file is a committed Mach-O binary, not a script — replacing it would be a much larger change); a Bazel repository rule (cannot patch `@local_config_cc`, which Bazel owns). |

**No new third-party dependencies introduced.**
