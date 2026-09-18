# Integration Plan

**Agent:** sub-integration-planner · **Phase:** 5

## External touchpoints

| System | Interaction | Failure handling |
|---|---|---|
| **Bazel 6.3.2** (`tools/bazel`) | `bazel info output_base\|install_base`; `build --nobuild` to force toolchain generation when absent (FR-7). | Non-zero `info` → exit 2 with the command echoed. |
| **Xcode 27 toolchain** | `xcrun --sdk macosx clang` (compile), `codesign` (sign), `otool -l` (probe). | Missing tool → exit 2 naming the tool. |
| **Bazel output base** | Replace two binaries, recreate one symlink. | Atomic `mv`; original preserved on any failure. |
| **`Makefile`** | `fix-toolchain` prerequisite on `build`, `release`, `unit-test`. | Make's own failure propagation; non-zero aborts the build. |

## Sequencing

```
make build
  │
  ├─ 1. fix-toolchain
  │      ├─ Darwin? ──no──> exit 0 (no-op)
  │      ├─ bazel info output_base / install_base
  │      ├─ local_config_cc present? ──no──> bazel build --nobuild $(BAZEL_TARGETS)
  │      ├─ probe + repair wrapped_clang (+ wrapped_clang_pp symlink)
  │      └─ probe + repair libtool_check_unique
  │
  └─ 2. tools/bazel build ... :RepoTools :Compiler     [now succeeds]
         └─ ditto bazel-bin/{RepoTools,Compiler} bin/
```

The `--nobuild` pass in step 1 is loading + analysis only — it configures `@local_config_cc`
without executing any action, so it cannot itself trip the dyld failure (RK-8).

## `Examples/*` (AS-7)

Each of the 10 examples runs Bazel in its own workspace, hence its own output base, hence its own
defective toolchain. They are **not** covered by the root `make build`.

Design response: the script takes `BAZEL` and `BAZEL_TARGETS` from the environment (see interface
contract) and is invocable standalone, so an example can run:

```sh
BAZEL=bazel BAZEL_TARGETS=//... /path/to/PodToBUILD/tools/fix_toolchain_uuid.sh
```

Scope decision: the root build and unit tests are wired now (FR-6); the examples are documented
in T-303 rather than having their 10 Makefiles edited, since `make build-test` is out of the
current run's success criteria and each example's Makefile is a published sample.

## Rollback
Delete `tools/fix_toolchain_uuid.sh` and the three `Makefile` prerequisites, then
`tools/bazel clean --expunge`. No other state exists. Total rollback cost: one revert commit.
