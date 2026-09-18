# Security Report — Phase 8

**Agent:** stage-security · Scope: changes introduced by this run

## sub-secret-scanner
Scanned `tools/fix_toolchain_uuid.sh`, `tools/test_fix_toolchain_uuid.sh`, `Makefile`, `README.md`
for credentials, private keys, tokens and cloud keys.

**Result: CLEAN.** No matches. The scripts hold no credentials; the only signing operation is
`codesign --sign -`, an **ad-hoc** signature that uses no identity, no key material, and no
keychain access — identical to Bazel's own behavior.

## sub-owasp-reviewer

| Concern | Finding |
|---|---|
| **Command injection** | All variable expansions that reach a command are double-quoted. The single deliberately-unquoted expansion is `$BAZEL_TARGETS` (word-splitting is the intent — it is a target list), explicitly marked `# shellcheck disable=SC2086`. Remaining unquoted `$VAR` occurrences are all inside message strings or numeric `exit`/`return` codes — not command arguments. |
| **Path traversal** | Every path is derived from `bazel info output_base` / `install_base`; no user-supplied path is interpolated into a write target. `CC_DIR` and `EMBEDDED` are fixed suffixes of those. |
| **`eval` / dynamic execution** | None. No `eval`, no `source` of untrusted input, no `/dev/tcp`. |
| **Privilege escalation** | None. No `sudo`, no setuid, no `chmod 777`. Runs entirely as the invoking user. |
| **Network** | None. No `curl`, `wget`, `nc`, or `ssh`. Nothing is downloaded. |
| **Untrusted input into the compiler** | The only compile inputs are Bazel's own embedded sources under `$(bazel info install_base)/embedded_tools/` — the same files Bazel itself compiles. No downloaded, generated, or user-supplied source is compiled. |
| **TOCTOU / partial writes** | Compile → codesign → verify → atomic `mv`. A failure at any step leaves the original binary untouched; a `RETURN` trap removes the temp file. |
| **Symlink handling** | `ln -sfn` targets a fixed name inside `CC_DIR`; no symlink is followed to a caller-controlled destination. |

**Result: no findings at Critical, High, or Medium.**

## sub-dependency-scanner
**No dependencies added, removed, or upgraded by this change.** `WORKSPACE` and
`third_party/repositories.bzl` are untouched (3 git-pinned deps, unchanged).

Standing observations (pre-existing, not introduced here):
- `rules_apple` 1.1.3 (2022) and Bazel 6.3.2 are both well behind current releases. Tracked in
  **ADR-002**; a security advisory against either is listed there as a trigger to revisit.
- The rejected alternative A4 would have **committed a Mach-O binary** to the repo. Rejecting it
  avoided adding a binary supply-chain surface — the chosen approach adds none.

## sub-policy-validator

| Policy | Status |
|---|---|
| No secrets in source | ✅ |
| No new network egress | ✅ |
| No new third-party dependencies | ✅ |
| No committed binaries | ✅ |
| Writes scoped to a build cache, not the repo or system | ✅ (`$(bazel info output_base)/external/local_config_cc/` only) |
| No privileged operations | ✅ |
| Reversible | ✅ (delete 2 files + 3 Makefile prerequisites; `bazel clean --expunge`) |

## Threat model summary

The realistic threat is **an attacker who can already write to the Bazel output base**, since the
script compiles and installs a binary there. Such an attacker can already replace `wrapped_clang`
directly and achieve arbitrary code execution during any build — this change does not widen that
surface. It does not read attacker-controllable input, and its compile inputs come only from the
local Bazel install, which is already trusted to the same degree.

**Gate 8 — Security Clear: PASS.** 0 Critical, 0 High, 0 Medium.

**Note:** `shellcheck` is not installed on this host, so the injection review was performed
manually against the patterns above rather than by an automated linter. Adding `shellcheck` to CI
is recommended in Phase 10.
