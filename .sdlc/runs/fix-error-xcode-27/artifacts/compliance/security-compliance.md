# Compliance Validation — Security (Phase 8)

**Agent:** sub-compliance-validator

| Control area | Applicable | Finding |
|---|---|---|
| Access control | No | No authn/authz surface; runs as the invoking developer. |
| Data protection / PII | No | Processes no personal data — Mach-O load commands and C++ source only. |
| Audit logging | N/A | Prints its actions to stdout; no regulated audit obligation applies to a local build step. |
| Cryptography | Limited | Ad-hoc code signature only (no key material). Matches Bazel's own signing step. |
| Change management | ✅ | Decisions recorded in ADR-001/ADR-002 and `governance/decision-log.json`; the HIGH-risk deferral is registered as APR-001. |
| Third-party risk | ✅ | No dependency added. Avoids committing a binary (rejected alternative A4). |
| Licensing | ✅ | Compiles Apache-2.0 sources from the already-vendored Bazel distribution; nothing is redistributed — outputs stay in the local Bazel cache. |

**Verdict: COMPLIANT.** No regulated data, no new obligations.
