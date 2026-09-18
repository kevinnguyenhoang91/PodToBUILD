# Interface Contract — `tools/fix_toolchain_uuid.sh`

**Agent:** sub-interface-designer · **Phase:** 5

## CLI

```
tools/fix_toolchain_uuid.sh [--check] [--verbose] [-h|--help]
```

| Flag | Behavior |
|---|---|
| *(none)* | Detect and repair. Default mode; used by the `Makefile`. |
| `--check` | Detect and report only. **Never writes.** Exit 0 = all healthy, 1 = repair needed. Used by the regression test (AC-5) and by anyone verifying the retirement trigger. |
| `--verbose` | Echo the exact compile and codesign commands. |
| `-h`, `--help` | Usage to stdout, exit 0. |

## Environment

| Variable | Role |
|---|---|
| `BAZEL` | Bazel binary to query. Default `tools/bazel`. Lets `Examples/*` and CI point at their own. |
| `BAZEL_TARGETS` | Targets used to force toolchain generation when `local_config_cc` is absent. Default `:RepoTools :Compiler`. |
| `DEVELOPER_DIR` | Forwarded to `xcrun`, mirroring Bazel's own `env -i DEVELOPER_DIR=...`. |

## Exit codes

| Code | Meaning |
|---|---|
| 0 | All target binaries healthy — either already, or after a successful repair. In `--check`, means no repair needed. |
| 1 | `--check` only: repair is needed. Never returned in repair mode. |
| 2 | Environment error — `bazel info` failed, a required source or output path is missing, or a required tool is unavailable. Message names the expected path (AC-7). |
| 3 | Repair failed — compile, codesign, or post-repair `LC_UUID` verification did not succeed. The target binary is left **untouched** (atomic `mv` never ran). |

Non-Darwin hosts exit **0** immediately with a one-line note (AC-8).

## Contract guarantees

1. **Read-before-write.** No binary is modified unless its `LC_UUID` count is 0.
2. **Atomic.** Installation is `mv` from a temp file in the same directory. A failure at any
   earlier step leaves the original in place.
3. **Verified.** `LC_UUID` presence is re-checked on the new binary *before* it is installed.
4. **Bounded writes.** Only `$(bazel info output_base)/external/local_config_cc/{wrapped_clang,
   wrapped_clang_pp, libtool_check_unique}` and temp files in that same directory.
5. **Idempotent.** A second run in either mode makes no writes and leaves mtimes unchanged.

## Output (stdout)

```
fix_toolchain_uuid: output_base  = /private/var/tmp/_bazel_u/<hash>
fix_toolchain_uuid: install_base = /private/var/tmp/_bazel_u/install/<hash>
fix_toolchain_uuid: wrapped_clang         missing LC_UUID -> relinking ... ok
fix_toolchain_uuid: wrapped_clang_pp      symlink -> wrapped_clang ... ok
fix_toolchain_uuid: libtool_check_unique  missing LC_UUID -> relinking ... ok
fix_toolchain_uuid: 2 repaired, 0 already healthy
```

Healthy host:
```
fix_toolchain_uuid: wrapped_clang         LC_UUID present ... skip
fix_toolchain_uuid: libtool_check_unique  LC_UUID present ... skip
fix_toolchain_uuid: 0 repaired, 2 already healthy (nothing to do)
```

Diagnostics go to stderr; stdout stays parseable.

## Makefile contract

```make
fix-toolchain:
	@tools/fix_toolchain_uuid.sh

build: fix-toolchain
release: fix-toolchain
unit-test: fix-toolchain
```

`fix-toolchain` is `.PHONY` and must complete before any `tools/bazel build` line.
