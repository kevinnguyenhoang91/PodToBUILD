#!/bin/bash
#
# fix_toolchain_uuid.sh — restore LC_UUID on Bazel's generated C++ driver binaries.
#
# WHY THIS EXISTS
#   Bazel 6.3.2 (pinned by this repo via .bazelversion and tools/bazel) generates its macOS C++
#   toolchain drivers with `-Wl,-no_uuid`:
#
#       <install_base>/embedded_tools/tools/cpp/osx_cc_configure.bzl:109
#
#   That flag was added upstream for build reproducibility, and it strips the LC_UUID load
#   command from the resulting Mach-O binaries. The dyld shipped with macOS 27 / Xcode 27
#   refuses to load an executable that has no LC_UUID, so every C/C++/ObjC action aborts with:
#
#       dyld: missing LC_UUID load command in external/local_config_cc/wrapped_clang
#
#   Two generated binaries are affected (the two calls to _compile_cc_file):
#     * wrapped_clang         — fatal: every compile and link aborts
#     * libtool_check_unique  — silent: external/local_config_cc/libtool ignores the abort, so
#                               duplicate-symbol checking is skipped on every archive link
#   (wrapped_clang_pp is a symlink to wrapped_clang.)
#
# WHAT THIS DOES
#   Lets Bazel generate the toolchain exactly as it normally would, then — only if LC_UUID is
#   actually missing — recompiles the affected binaries from Bazel's OWN embedded sources using
#   Bazel's OWN command line with `-Wl,-no_uuid` removed, ad-hoc codesigns them the same way
#   Bazel does, and installs them atomically.
#
#   Writes are confined to $(bazel info output_base)/external/local_config_cc/. The repo, the
#   system toolchain and the Xcode installation are never modified.
#
# RETIREMENT
#   The LC_UUID probe is the enable condition, so this is a no-op once the repo moves to a Bazel
#   that no longer passes -Wl,-no_uuid (see ADR-002). `--check` exiting 0 on a freshly generated
#   toolchain is the executable proof that this script can be deleted.
#
# See .sdlc/runs/fix-error-xcode-27/artifacts/architecture/ADR-001-toolchain-uuid-repair.md

set -euo pipefail

PROG="fix_toolchain_uuid"

# Exit codes (see design/interface-contract.md)
readonly EX_OK=0        # healthy, or successfully repaired
readonly EX_NEEDED=1    # --check only: repair is needed
readonly EX_ENV=2       # environment error (missing path/tool, bazel info failed)
readonly EX_REPAIR=3    # repair failed; target binary left untouched

CHECK_ONLY=0
VERBOSE=0

usage() {
    cat <<EOF
Usage: ${PROG}.sh [--check] [--verbose] [-h|--help]

Restores the LC_UUID load command on Bazel's generated C++ driver binaries so that
macOS 27 / Xcode 27 dyld can load them.

  --check     Detect and report only; never writes.
              Exit 0 = all healthy, ${EX_NEEDED} = repair needed.
  --verbose   Echo the exact compile and codesign commands.
  -h, --help  Show this help.

Environment:
  BAZEL           Bazel binary to query        (default: tools/bazel)
  BAZEL_TARGETS   Targets used to force toolchain generation
                  when local_config_cc is absent (default: :RepoTools :Compiler)
  DEVELOPER_DIR   Forwarded to xcrun, mirroring Bazel's own invocation.

Exit codes: 0 ok · ${EX_NEEDED} repair needed (--check) · ${EX_ENV} environment error · ${EX_REPAIR} repair failed
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --check)    CHECK_ONLY=1 ;;
        --verbose)  VERBOSE=1 ;;
        -h|--help)  usage; exit $EX_OK ;;
        *)          echo "${PROG}: unknown argument: $1" >&2; usage >&2; exit $EX_ENV ;;
    esac
    shift
done

log()  { echo "${PROG}: $*"; }
err()  { echo "${PROG}: $*" >&2; }
dbg()  { [ "$VERBOSE" -eq 1 ] && echo "${PROG}: + $*" >&2 || true; }

# --- NFR-4: no-op on anything that isn't macOS ------------------------------------------------
if [ "$(uname -s)" != "Darwin" ]; then
    log "not Darwin ($(uname -s)) — nothing to do"
    exit $EX_OK
fi

need_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        err "required tool not found on PATH: $1"
        exit $EX_ENV
    }
}
need_tool otool
need_tool xcrun
need_tool codesign

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BAZEL="${BAZEL:-${REPO_ROOT}/tools/bazel}"
BAZEL_TARGETS="${BAZEL_TARGETS:-:RepoTools :Compiler}"

if ! command -v "$BAZEL" >/dev/null 2>&1 && [ ! -x "$BAZEL" ]; then
    err "bazel not found or not executable: $BAZEL (override with BAZEL=...)"
    exit $EX_ENV
fi

bazel_info() {
    local key="$1" val
    if ! val="$("$BAZEL" info "$key" 2>/dev/null)"; then
        err "'$BAZEL info $key' failed — cannot locate the Bazel $key"
        exit $EX_ENV
    fi
    [ -n "$val" ] || { err "'$BAZEL info $key' returned nothing"; exit $EX_ENV; }
    printf '%s' "$val"
}

OUTPUT_BASE="$(bazel_info output_base)"
INSTALL_BASE="$(bazel_info install_base)"
CC_DIR="${OUTPUT_BASE}/external/local_config_cc"
EMBEDDED="${INSTALL_BASE}/embedded_tools"

log "output_base  = ${OUTPUT_BASE}"
log "install_base = ${INSTALL_BASE}"

# --- FR-7: make sure Bazel has actually generated the C++ toolchain ---------------------------
# Loading + analysis only (--nobuild): configures @local_config_cc without executing any action,
# so this pass cannot itself trip the dyld failure we are here to fix.
if [ ! -d "$CC_DIR" ]; then
    if [ "$CHECK_ONLY" -eq 1 ]; then
        err "${CC_DIR} does not exist — run a build (or drop --check) to generate the toolchain"
        exit $EX_ENV
    fi
    log "local_config_cc not generated yet — configuring via '--nobuild' on ${BAZEL_TARGETS}"
    dbg "$BAZEL build --nobuild $BAZEL_TARGETS"
    # shellcheck disable=SC2086
    if ! bazel_out="$("$BAZEL" build --nobuild $BAZEL_TARGETS 2>&1)"; then
        err "failed to configure the C++ toolchain via '$BAZEL build --nobuild $BAZEL_TARGETS'"
        err "bazel said:"
        printf '%s\n' "$bazel_out" | sed 's/^/    /' >&2
        err "if @local_config_cc is stale or partially removed, run: $BAZEL clean --expunge"
        exit $EX_ENV
    fi
fi
[ -d "$CC_DIR" ] || { err "expected toolchain directory is still missing: ${CC_DIR}"; exit $EX_ENV; }

# --- FR-2: LC_UUID probe ----------------------------------------------------------------------
# Universal binaries report one LC_UUID per architecture; >= 1 means present.
has_lc_uuid() {
    local bin="$1" n
    n="$(otool -l "$bin" 2>/dev/null | grep -c 'cmd LC_UUID' || true)"
    [ "${n:-0}" -ge 1 ]
}

# --- FR-3/FR-4: relink one binary without -Wl,-no_uuid ----------------------------------------
# Mirrors _compile_cc_file() in osx_cc_configure.bzl exactly, minus that one flag. The flag only
# suppresses emission of the LC_UUID load command; it does not affect code generation.
relink() {
    local name="$1" src_rel="$2"
    local bin="${CC_DIR}/${name}"
    local src="${EMBEDDED}/${src_rel}"
    local tmp="${CC_DIR}/.fix_uuid.${name}.$$"

    [ -e "$src" ] || { err "Bazel's embedded source is missing: ${src}"; return $EX_ENV; }

    # RK-9: build into a temp file in the same directory, install with an atomic mv.
    trap 'rm -f "$tmp"' RETURN

    dbg "xcrun --sdk macosx clang -arch arm64 -arch x86_64 ... -o $tmp $src"
    if ! env -i DEVELOPER_DIR="${DEVELOPER_DIR:-}" xcrun --sdk macosx clang \
            -mmacosx-version-min=10.13 \
            -std=c++11 \
            -lc++ \
            -arch arm64 \
            -arch x86_64 \
            -Wl,-no_adhoc_codesign \
            -O3 \
            -o "$tmp" \
            "$src" 2>/dev/null; then
        err "failed to compile ${src}"
        return $EX_REPAIR
    fi

    # --identifier is required for the signature to match across architectures (as Bazel does).
    dbg "codesign --identifier $name --force --sign - $tmp"
    if ! env -i codesign --identifier "$name" --force --sign - "$tmp" 2>/dev/null; then
        err "failed to codesign ${tmp}"
        return $EX_REPAIR
    fi

    # Verify before installing — never replace a good binary with an equally broken one.
    if ! has_lc_uuid "$tmp"; then
        err "relinked ${name} still has no LC_UUID — refusing to install it"
        return $EX_REPAIR
    fi

    mv -f "$tmp" "$bin" || { err "failed to install ${bin}"; return $EX_REPAIR; }
    return $EX_OK
}

# --- Target descriptors (see design/data-model.md) --------------------------------------------
TARGETS=(
    "wrapped_clang:tools/osx/crosstool/wrapped_clang.cc"
    "libtool_check_unique:tools/objc/libtool_check_unique.cc"
)

repaired=0
healthy=0
needed=0

for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"
    src_rel="${entry#*:}"
    bin="${CC_DIR}/${name}"
    label="$(printf '%-21s' "$name")"

    if [ ! -e "$bin" ]; then
        err "expected toolchain binary is missing: ${bin}"
        exit $EX_ENV
    fi

    if has_lc_uuid "$bin"; then
        log "${label} LC_UUID present ... skip"
        healthy=$((healthy + 1))
        continue
    fi

    needed=$((needed + 1))
    if [ "$CHECK_ONLY" -eq 1 ]; then
        log "${label} missing LC_UUID ... NEEDS REPAIR"
        continue
    fi

    printf '%s: %s missing LC_UUID -> relinking ... ' "$PROG" "$label"
    if relink "$name" "$src_rel"; then
        echo "ok"
        repaired=$((repaired + 1))
    else
        rc=$?
        echo "FAILED"
        exit $rc
    fi

    # FR-5: wrapped_clang_pp is a symlink to wrapped_clang; make sure it still points at the
    # binary we just installed.
    if [ "$name" = "wrapped_clang" ]; then
        ln -sfn "$bin" "${CC_DIR}/wrapped_clang_pp"
        log "$(printf '%-21s' 'wrapped_clang_pp') symlink -> wrapped_clang ... ok"
    fi
done

if [ "$CHECK_ONLY" -eq 1 ]; then
    if [ "$needed" -gt 0 ]; then
        log "${needed} binary/binaries need repair"
        exit $EX_NEEDED
    fi
    log "all ${healthy} binaries healthy (nothing to do)"
    exit $EX_OK
fi

if [ "$repaired" -eq 0 ]; then
    log "0 repaired, ${healthy} already healthy (nothing to do)"
else
    log "${repaired} repaired, ${healthy} already healthy"
fi
exit $EX_OK
