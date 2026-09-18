# ADR-002 — Defer the Bazel 7/8 + Bzlmod migration

**Agent:** sub-adr-writer · **Status:** Proposed — **awaiting human approval**
**Date:** 2026-09-18 · **Risk classification:** HIGH (architecture / technology choice)

## Context
The true upstream fix for the `LC_UUID` failure is to stop using a Bazel that passes
`-Wl,-no_uuid`. That means upgrading from the pinned Bazel 6.3.2 to a 7.x/8.x release.

That upgrade is not self-contained. It pulls in:
- `rules_apple` **1.1.3** (2022) and its transitive `rules_swift` / `apple_support`, none of
  which work unmodified on Bazel 7/8;
- WORKSPACE → Bzlmod migration (Bzlmod is the default from Bazel 7 and WORKSPACE is removed in 9);
- `--incompatible_*` flag flips and the `objc_library` relocation;
- `Makefile: TESTED_BAZEL_VERSION=6.3.2`, the 10 `Examples/*` sub-builds, and
  `IntegrationTests/RunTests.sh`, all of which assume 6.x.

## Decision
**Defer.** Unblock Xcode 27 with the contained repair in ADR-001, and schedule the migration as
its own piece of work with its own validation.

## Rationale
Bundling a multi-day dependency migration into an urgent build unblock would mean shipping two
large, interacting changes with no working baseline to bisect against. ADR-001 restores a green
build first, which is precisely what makes the migration safe to attempt afterwards.

## Consequences
- The repo stays on an unsupported-in-practice Bazel 6.3.2 and accumulates further drift (RK-7).
- Each new macOS/Xcode major release carries a risk of a similar incompatibility.
- ADR-001 must be kept until this is done.

## Trigger for revisiting
Any of: another Xcode/macOS incompatibility that ADR-001 cannot contain; a required
`rules_apple`/`rules_swift` feature or fix; or a security advisory against Bazel 6.3.2.

## Governance
`risk-policy.yaml` classifies `architecture decision|technology choice|adr` as **HIGH**, which
requires human approval. Registered in `governance/pending-approvals.json` as `APR-001`.

**This ADR records a deferral — it authorizes no change to the codebase.** ADR-001 is
independently implementable and is not blocked by it, so the pipeline continues; the approval
governs whether and when the migration is scheduled.
