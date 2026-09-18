# Dependency Graph & Critical Path

**Agent:** sub-dependency-mapper · **Phase:** 3

```
T-101 (skeleton + Darwin guard)
  ├─> T-102 (resolve bazel paths, ensure local_config_cc) ─┐
  └─> T-103 (has_lc_uuid detection) ───────────────────────┤
                                                           v
                                              T-104 (relink + codesign + atomic mv)
                                                    │            │
                                     ┌──────────────┘            └──────────────┐
                                     v                                          v
                          T-105 (wrapped_clang + _pp symlink)      T-106 (libtool_check_unique)
                                     └──────────────┬─────────────────────────┘
                                                    v
                                          T-107 (path checks / errors)
                                                    v
                                          T-108 (progress output)
                                                    v
                                          T-201 (Makefile fix-toolchain)
                                                    v
                                     T-202 (build/release/unit-test depend on it)
                                        │            │
                                        v            v
                                  T-203 (standalone)  T-301 (regression script)
                                                     v
                                                 T-302 (clean verify)
                                                     v
                                                 T-303 (docs)

T-304 (ADRs) — independent, Phase 4
```

**Critical path:** T-101 → T-102/T-103 → T-104 → T-105/T-106 → T-107 → T-108 → T-201 → T-202 → T-301 → T-302 → T-303 (11 nodes).

**Parallelizable:** {T-102, T-103}; {T-105, T-106}; {T-203, T-301}; T-304 anytime.

**Total tasks:** 14. **No cycles.** Every task traces to ≥1 requirement and ≥1 acceptance criterion.
