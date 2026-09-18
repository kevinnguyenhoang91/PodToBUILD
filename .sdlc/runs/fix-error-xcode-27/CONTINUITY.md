# CONTINUITY — Working Memory

Run: `fix-error-xcode-27` — "Fix build error on Xcode 27.0"

## Current Phase
**PROJECT COMPLETE** — Phases 0–11 complete, all gates PASS, final review PASS.
Phase 12 (Retirement) not triggered.

## Active Tasks
- None

## Completed Tasks
- Phase 0 Problem Discovery — root cause traced, GO decision, 5 alternatives evaluated
- Phase 1 Bootstrap — spec normalized, complexity = simple
- Phase 2 Product — 17 requirements, 9 acceptance criteria, 9 risks, 7 assumptions
- Phase 3 Story-Tasks — 1 epic, 3 stories, 15 tasks, acyclic dependency graph
- Phase 4 Architecture — ADR-001 (accepted), ADR-002 (pending APR-001)
- Phase 5 Design — CLI/exit-code contract, stateless health model, integration plan, NFRs
- Phase 6 Development — `tools/fix_toolchain_uuid.sh`, regression suite, Makefile, README (15/15 tasks)
- Phase 7 Testing — 18/18 assertions pass from an expunged output base; AC-6 fails (pre-existing)
- Phase 8 Security — 0 Critical/High/Medium
- Phase 9 Review — 3/3 reviewers PASS; 1 High + 3 Medium found and resolved
- Phase 10 DevOps — CI reaches the repair via the Makefile; no workflow change needed
- Phase 11 Observability — `--check` health probe, 5 SLIs, retirement trigger

## Decisions Made
- **ADR-001 (accepted)** — repair Bazel's `wrapped_clang` / `wrapped_clang_pp` /
  `libtool_check_unique` in place, re-linking from Bazel's own embedded sources without
  `-Wl,-no_uuid`. Root cause: `osx_cc_configure.bzl:109` strips `LC_UUID`; macOS 27 dyld rejects
  such binaries.
- **ADR-002 (pending APR-001)** — defer the Bazel 7/8 + Bzlmod + rules_apple migration.
  Non-blocking: it records a deferral and authorizes no code change.

## Mistakes & Learnings
1. **False-positive test oracle.** The AC-2 check first grepped for `missing LC_UUID`, a string
   the repair script prints itself — it would have failed a healthy build. Narrowed to `^dyld\[`.
   *Lesson: an oracle must not match the tool's own diagnostics.*
2. **Swallowed stderr hides the real cause.** The first `--nobuild` failure path discarded Bazel's
   output, making a stale `@local_config_cc.marker` invisible. Now echoed.
3. **Manually deleting a Bazel external dir leaves its `.marker`**, so Bazel will not regenerate
   it and analysis fails. `bazel clean --expunge` is the correct reset.
4. **Partial fixes can look complete.** Repairing only `wrapped_clang` made the build "succeed"
   while `libtool_check_unique` kept aborting silently, leaving duplicate-symbol checking off.
   *Lesson: enumerate every call site (`_compile_cc_file` is called twice), don't stop at green.*

## Next Steps (for the maintainer — none blocking)
1. Approve or reject **APR-001** (ADR-002, defer the Bazel migration).
2. Fix `make unit-test`: rules_apple 1.1.3's `xcodebuild` runner does not propagate `TEST_SRCDIR`,
   so 10 helpers abort (all 41 XCTest assertions pass). Belongs to the ADR-002 follow-up.
3. Optional DevOps items: `shellcheck` in CI, pin the runner image, run the regression suite in CI,
   fix `make build-example`'s stale `Examples/PINCache.podspec.json` path.

## Open Questions
- APR-001 approval decision (human).

## Blocked Items
- None.
