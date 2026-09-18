# DevOps Report — Phase 10

**Agent:** stage-devops

## Existing pipeline

`.github/workflows/ci.yml` — single job on `macOS-latest`, `push`/`pull_request` to `master`
plus `workflow_dispatch` (added in commit `90cc3b9`). Installs CocoaPods, then runs `make ci`:

```make
ci: clean
	$(MAKE) unit-test
	$(MAKE) integration-test
	$(MAKE) build-test
```

## Impact of this change on CI

**No workflow file change is required.** The repair is wired into the `Makefile`, which is the
pipeline's only entry point, so CI picks it up automatically:

| `make ci` step | Reaches the repair? | How |
|---|---|---|
| `clean` | n/a | `rm -rf .build` + `tools/bazel clean` |
| `unit-test` | ✅ | `unit-test: fix-toolchain` |
| `integration-test` → `release` | ✅ | `release: fix-toolchain` |
| `build-test` → `build` | ✅ | `build: fix-toolchain` |

Ordering is safe in every case: `fix-toolchain` is a prerequisite, so Make runs it to completion
before the Bazel invocation in that recipe. It is idempotent, so the three entry points repairing
the same output base cost only the probe after the first.

**Runner compatibility.** On a `macOS-latest` image still on macOS ≤ 26, the `LC_UUID` probe finds
healthy binaries and the script is a no-op — so this change cannot regress CI on older images. As
GitHub rolls `macOS-latest` to macOS 27, the repair is what keeps the build green.

## Known CI state after this change

CI will still **fail at `make unit-test`** on a macOS 27 runner — not from the toolchain, but from
the pre-existing `TEST_SRCDIR` defect in rules_apple 1.1.3's `xcodebuild` test runner (Phase 7
report). The build steps themselves (`build`, `release`, `build-test`) are unblocked.

This is reported, not worked around: suppressing the test failure to turn CI green would hide a
real defect. It is routed to the ADR-002 follow-up.

## Recommendations (not applied — outside this run's scope)

| # | Recommendation | Rationale |
|---|---|---|
| 1 | Add a `shellcheck` step for `tools/*.sh` | Phase 8's injection review was manual because `shellcheck` is unavailable on this host; CI is the right place to automate it. |
| 2 | Pin the runner to a known macOS image instead of `macOS-latest` | Makes OS-major upgrades a deliberate, reviewable change rather than a surprise red build — precisely the failure mode this run addressed. |
| 3 | Run `tools/test_fix_toolchain_uuid.sh` in CI | Cheap regression guard; in `--full` mode it also proves the from-scratch path. |
| 4 | Fix `make build-example`'s stale `Examples/PINCache.podspec.json` path | Podspecs now live under `Examples/PodSpecs/`; found during Phase 7 smoke testing. |

These are deliberately **not** applied here: modifying CI is outward-facing and beyond
"fix the Xcode 27 build error". They are recorded for the maintainer to decide on.

## Deployment / release impact

`make release` and `make archive` are unaffected in content. `PodToBUILD.zip` still packages only
`bin/`, `BazelExtensions`, `Makefile`, `WORKSPACE`, `BUILD`, `LICENSE` — the repaired driver
binaries live in the Bazel cache and are **never shipped**. Releases can be cut again from a
macOS 27 host, which was impossible before this change.

**Gate 10 — Pipeline Green: PASS** for the scope of this change (build/release paths unblocked;
no workflow modification needed; pre-existing test failure disclosed rather than masked).
