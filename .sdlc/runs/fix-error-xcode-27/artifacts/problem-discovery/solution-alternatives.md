# Solution Alternatives

**Agent:** sub-solution-space-explorer · **Phase:** 0

Five alternatives evaluated, including the mandatory don't-build option.

---

## A1 — Don't build (wait for upstream / tell users to downgrade Xcode)
- **How:** Document "use Xcode ≤ 26" and wait for a Bazel upgrade.
- **Pros:** Zero engineering cost.
- **Cons:** Xcode downgrades are impractical and increasingly impossible; the pinned Bazel 6.3.2
  will never receive the upstream fix. This is indefinite paralysis, not a wait.
- **Verdict:** ❌ Rejected — the cost of inaction is total project stoppage.

## A2 — Upgrade Bazel to a release that dropped `-Wl,-no_uuid`
- **How:** Bump `.bazelversion` / `tools/bazel` to Bazel 7.x/8.x.
- **Pros:** Fixes the cause at the source; no local hack; keeps us on a supported toolchain.
- **Cons:** Large blast radius. `WORKSPACE` pins `rules_apple` **1.1.3** (2022) and a matching
  `rules_swift`/`apple_support`; those do not work unmodified on Bazel 7/8 (Bzlmod default,
  `--incompatible_*` flips, `objc_library` moves). `Makefile` declares
  `TESTED_BAZEL_VERSION=6.3.2`; ten `Examples/*` and the integration tests all assume 6.x.
  This is a multi-day migration with its own failure surface.
- **Verdict:** ⚠️ Correct long-term direction, wrong first move. Deferred — recorded as ADR-002.

## A3 — Switch to `apple_support`'s `apple_cc_configure()` / `@local_config_apple_cc`
- **How:** Newer `apple_support` ships its own crosstool whose `wrapped_clang` is built without
  `-no_uuid`, registered via `apple_cc_configure()`.
- **Verified infeasible:** the `apple_support` pulled in transitively by rules_apple 1.1.3 has
  **no** `crosstool/` directory and **no** `apple_cc_configure` symbol (checked in the fetched
  external repo). Using it requires upgrading `apple_support`, which drags in A2's migration.
- **Verdict:** ❌ Rejected — collapses into A2.

## A4 — Vendor a full prebuilt `local_config_cc` and `--override_repository` it
- **How:** Commit a generated `local_config_cc` with a good `wrapped_clang`, override the repo.
- **Cons:** Freezes absolute Xcode/SDK paths, arch list, and toolchain identifiers into the repo;
  breaks on every Xcode update and on any machine with a different Xcode location. Committing a
  Mach-O binary also adds a supply-chain surface.
- **Verdict:** ❌ Rejected — brittle and higher-risk than the defect.

## A5 — Re-link the two defective binaries in place, from Bazel's own source ✅
- **How:** A guarded script (`tools/fix_toolchain_uuid.sh`) that, after Bazel generates
  `external/local_config_cc`, checks each of `wrapped_clang` and `libtool_check_unique` for
  `LC_UUID` and — only if missing — recompiles it from Bazel's **own embedded source**
  (`$(bazel info install_base)/embedded_tools/tools/osx/crosstool/wrapped_clang.cc`,
  `.../tools/objc/libtool_check_unique.cc`) using the identical command line minus
  `-Wl,-no_uuid`, then ad-hoc codesigns it. Hooked into the `Makefile` before the real build.
- **Pros:**
  - Same source, same compiler, same flags as Bazel would use — one flag removed. No behavioral
    drift, nothing vendored, no binaries committed.
  - Idempotent and self-disabling: exits as a no-op when `LC_UUID` is already present, so it
    costs nothing on healthy hosts and disappears automatically after the A2 migration.
  - Scoped to Bazel's output base; touches neither the repo nor the system toolchain.
  - Fixes `libtool_check_unique` too, restoring duplicate-symbol detection.
- **Cons:** Reaches into Bazel's output base — a supported-in-practice but unofficial seam.
  Must re-run after `bazel clean --expunge` (handled by hooking the build entry point).
- **Empirically validated:** produced `LC_UUID=2`; build went from `FAILED` to
  `INFO: Build completed successfully, 44 total actions`.
- **Verdict:** ✅ **Selected.**

---

## Decision Matrix

| | Unblocks now | Risk | Effort | Reversible | Self-retiring |
|---|---|---|---|---|---|
| A1 Don't build | ❌ | — | none | — | — |
| A2 Bazel upgrade | ⚠️ eventually | High | Days | Hard | n/a |
| A3 apple_cc_configure | ❌ infeasible | High | Days | Hard | n/a |
| A4 Vendor toolchain | ✅ | High | Medium | Medium | ❌ |
| **A5 Re-link in place** | **✅ proven** | **Low** | **Hours** | **Trivial** | **✅** |

**Selected: A5**, with **A2 recorded as the planned follow-up** (ADR-002).
