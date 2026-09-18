# System Design — Toolchain UUID Repair

**Agent:** stage-architecture · **Phase:** 4

## Where this sits

```
 developer / CI
       │  make build
       v
 ┌───────────────────────────────────────────────────┐
 │ Makefile                                          │
 │   build: fix-toolchain                            │
 │     └─> tools/fix_toolchain_uuid.sh   <-- NEW     │
 │   then: tools/bazel build :RepoTools :Compiler    │
 └───────────────────────────────────────────────────┘
       │
       v
 ┌───────────────────────────────────────────────────┐
 │ Bazel 6.3.2 (tools/bazel, repo-pinned)            │
 │   repo rule: @bazel_tools//tools/cpp:             │
 │     osx_cc_configure.bzl  _compile_cc_file()      │
 │       clang ... -Wl,-no_uuid   <-- THE DEFECT     │
 │   generates -> $(output_base)/external/           │
 │                  local_config_cc/                 │
 │                    wrapped_clang        (no UUID) │
 │                    wrapped_clang_pp  -> symlink   │
 │                    libtool_check_unique (no UUID) │
 └───────────────────────────────────────────────────┘
       │
       v  every C/C++/ObjC compile & link action
 ┌───────────────────────────────────────────────────┐
 │ macOS 27 dyld — rejects Mach-O without LC_UUID    │
 └───────────────────────────────────────────────────┘
```

The repair is a **pre-build reconciliation step**: it lets Bazel generate the toolchain exactly
as it normally would, then corrects the two binaries in place before any action consumes them.
Nothing in Bazel, the repo's rules, or the WORKSPACE graph changes.

## Component: `tools/fix_toolchain_uuid.sh`

| Stage | Responsibility |
|---|---|
| **Guard** | Exit 0 unless `uname -s` is `Darwin`. |
| **Locate** | `bazel info output_base` / `install_base`. If `external/local_config_cc` is absent, force generation with `build --nobuild`. |
| **Detect** | For each target binary, `otool -l <bin> \| grep -c LC_UUID`. Zero ⇒ needs repair. |
| **Repair** | Recompile from `$(install_base)/embedded_tools/<src>` with Bazel's exact flags minus `-Wl,-no_uuid`; `codesign --identifier <name> --force --sign -`; atomic `mv` into place. |
| **Restore** | Re-point `wrapped_clang_pp` at the repaired `wrapped_clang`. |
| **Report** | Print per-binary status: `repaired` / `already healthy` / `skipped`. |

## Key architectural properties

- **Non-invasive.** Writes only inside `$(bazel info output_base)/external/local_config_cc/`.
  The repo, the system toolchain and the Xcode installation are untouched.
- **Source-faithful.** Compiles Bazel's own shipped `.cc` sources with Bazel's own command line;
  exactly one flag is dropped. No forked or vendored code.
- **Self-disabling.** The `LC_UUID` detection is the enable condition. On a healthy host — a
  future Bazel, or an older macOS — the script does nothing and costs two cheap probes.
- **Stateless.** Derives everything from `bazel info` at run time; no cache, no marker file,
  nothing to invalidate.
- **Failure-loud.** Any unresolvable path aborts with the expected location (AC-7); never a
  silent partial repair.

## Data flow (repair of one binary)

```
name, src_rel
   │
   ├─ bin = $output_base/external/local_config_cc/$name
   ├─ has_lc_uuid(bin)? ── yes ──> report "already healthy", return
   │                       no
   v
 src = $install_base/embedded_tools/$src_rel     [must exist, else fail]
   │
   v
 xcrun clang -arch arm64 -arch x86_64 -mmacosx-version-min=10.13 -std=c++11 -lc++ \
        -Wl,-no_adhoc_codesign -O3 -o $tmp $src      [note: -Wl,-no_uuid omitted]
   │
   v
 codesign --identifier $name --force --sign - $tmp
   │
   v
 verify has_lc_uuid($tmp)                         [else fail]
   │
   v
 mv -f $tmp $bin                                  [atomic, same filesystem]
```
