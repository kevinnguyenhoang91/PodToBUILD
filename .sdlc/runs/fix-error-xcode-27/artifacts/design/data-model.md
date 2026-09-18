# State & Data Model

**Agent:** sub-data-model-designer · **Phase:** 5

The component is **stateless** — it persists nothing between runs. All state is derived at
invocation time, which is what makes it safe under `bazel clean --expunge` (RK-2).

## Derived values

| Value | Source | Notes |
|---|---|---|
| `OUTPUT_BASE` | `$BAZEL info output_base` | Per-workspace; changes between `Examples/*`. |
| `INSTALL_BASE` | `$BAZEL info install_base` | Per Bazel binary+version; holds `embedded_tools/`. |
| `CC_DIR` | `$OUTPUT_BASE/external/local_config_cc` | Repair target directory. |

## Target descriptor

Each repairable binary is described by a 2-tuple, iterated over by the same routine (T-104):

| `name` | `src_rel` (under `$INSTALL_BASE/embedded_tools/`) |
|---|---|
| `wrapped_clang` | `tools/osx/crosstool/wrapped_clang.cc` |
| `libtool_check_unique` | `tools/objc/libtool_check_unique.cc` |

`wrapped_clang_pp` is **not** a descriptor — it is a symlink to `wrapped_clang`, handled as a
post-step of that entry (FR-5).

## Binary health states

```
          ┌──────────────┐
          │  UNKNOWN     │  (not yet probed)
          └──────┬───────┘
                 │ otool -l | grep -c LC_UUID
        ┌────────┴────────┐
        v                 v
   ┌─────────┐       ┌──────────┐
   │ HEALTHY │       │ DEFECTIVE│
   │ (count  │       │ (count   │
   │  >= 1)  │       │  == 0)   │
   └────┬────┘       └────┬─────┘
        │ skip            │ compile -> codesign -> verify
        │                 │
        │        ┌────────┴────────┐
        │        │ verify passed?  │
        │      yes│              no│
        │        v                 v
        │   ┌──────────┐     ┌──────────────┐
        │   │ mv into  │     │ FAILED       │
        │   │ place    │     │ exit 3,      │
        │   │ HEALTHY  │     │ original     │
        │   └──────────┘     │ untouched    │
        v                    └──────────────┘
    (no writes)
```

`MISSING` (binary absent after generation) is an environment error → exit 2, not a repair attempt.

## Filesystem effects

| Path | Access | When |
|---|---|---|
| `$CC_DIR/wrapped_clang` | read + replace | only when DEFECTIVE |
| `$CC_DIR/wrapped_clang_pp` | symlink recreate | only when `wrapped_clang` was repaired |
| `$CC_DIR/libtool_check_unique` | read + replace | only when DEFECTIVE |
| `$CC_DIR/.fix_uuid.<name>.$$` | create + `mv`/`rm` | during repair; removed on any exit (trap) |
| `$INSTALL_BASE/embedded_tools/**` | **read only** | always |
| repo working tree | **never written** | — |
