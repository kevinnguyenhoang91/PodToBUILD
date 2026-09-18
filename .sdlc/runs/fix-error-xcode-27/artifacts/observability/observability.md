# Observability — Phase 11

**Agent:** stage-observability

This is a local build-time component, not a running service: there is no process to monitor, no
endpoint to probe, and no telemetry backend. "Observability" here means **the build tells you the
truth about its own toolchain**, and it is achieved through exit codes, structured output, and a
check command — the things a developer or a CI log actually consumes.

## Health check

`tools/fix_toolchain_uuid.sh --check` is the health probe. It never writes.

| Exit | Meaning | Action |
|---|---|---|
| 0 | Both driver binaries carry `LC_UUID` | Healthy — and, on a freshly generated toolchain, proof the script can be deleted (NFR-7) |
| 1 | Repair needed | Run without `--check` (or just `make build`) |
| 2 | Environment error | Message names the missing path/tool |

```sh
tools/fix_toolchain_uuid.sh --check && echo "toolchain healthy"
```

## Signals emitted

| Signal | Where | Meaning |
|---|---|---|
| `output_base` / `install_base` lines | stdout, every run | Which Bazel state is being inspected — the first thing to check when the repair appears to "not take" |
| `<name> LC_UUID present ... skip` | stdout | Binary healthy; nothing done |
| `<name> missing LC_UUID -> relinking ... ok` | stdout | Repair applied |
| `N repaired, M already healthy` | stdout, final line | Machine-greppable summary |
| Bazel's stderr, indented | stderr, on `--nobuild` failure | The actual reason toolchain generation failed |
| `--verbose` command echo | stderr | Exact `clang` / `codesign` invocations, for reproducing by hand |

Diagnostics go to stderr and status to stdout, so the summary stays parseable in a CI log.

## SLIs / SLOs (build-health, measured by the regression suite)

| Indicator | Objective | Current |
|---|---|---|
| `make build` succeeds on macOS 27 | 100% | ✅ verified from an expunged output base |
| dyld `missing LC_UUID` errors per build | 0 | ✅ 0 (was 6+) |
| `libtool_check_unique` aborts per build | 0 | ✅ 0 (was 4) |
| Added wall-clock on a healthy toolchain | < 1 s | ✅ sub-second (2× `bazel info`, 2× `otool`) |
| Repair idempotent | no rewrite when healthy | ✅ mtimes unchanged |

`tools/test_fix_toolchain_uuid.sh --full` measures all five.

## Alerting

The alerting channel is **CI failure**, which already exists. Two conditions worth naming:

1. **Repair stops working** — `make build` fails again with `dyld: missing LC_UUID`. Most likely
   cause: Bazel's embedded source layout changed. The script exits 2 naming the path it expected.
2. **Repair becomes unnecessary** — `--check` exits 0 on a *freshly generated* toolchain. This is
   the ADR-001 retirement trigger: the Bazel upgrade has landed and the script can be deleted.
   Recommendation 3 in the DevOps report (running the suite in CI) would surface this
   automatically rather than by someone remembering to check.

## Deliberately not added
No metrics export, log shipping, dashboards, or tracing. A ~250-line local build step does not
warrant a telemetry pipeline, and adding one would be pure overhead on every developer's build.

**Gate 11 — Observability Ready: PASS.** Health check, structured signals, measurable SLIs, and
a named alerting path — proportionate to a build-time component.
