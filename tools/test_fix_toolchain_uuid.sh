#!/bin/bash
#
# Regression test for tools/fix_toolchain_uuid.sh
#
# Asserts AC-1..AC-5, AC-7, AC-8 from
# .sdlc/runs/fix-error-xcode-27/artifacts/product/acceptance-criteria.md
#
# Usage: tools/test_fix_toolchain_uuid.sh [--full]
#   --full  also expunge the Bazel output base and verify a from-scratch `make build`
#           (slow: forces a complete rebuild). Without it, the toolchain is left as-is.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FIX="tools/fix_toolchain_uuid.sh"
BAZEL="${BAZEL:-tools/bazel}"
FULL=0
[ "${1:-}" = "--full" ] && FULL=1

pass=0; fail=0
ok()   { echo "  PASS  $1"; pass=$((pass+1)); }
no()   { echo "  FAIL  $1"; fail=$((fail+1)); }
check(){ if [ "$2" = "$3" ]; then ok "$1 ($2)"; else no "$1 (expected '$3', got '$2')"; fi; }

echo "== fix_toolchain_uuid regression suite =="

# --- AC-8: non-Darwin no-op -------------------------------------------------------------------
echo "[AC-8] non-Darwin no-op"
if [ "$(uname -s)" = "Darwin" ]; then
    echo "  SKIP  running on Darwin; the guard is exercised on non-Darwin hosts"
else
    "$FIX" >/dev/null 2>&1; check "exits 0 off-Darwin" "$?" "0"
fi

# --- AC-7: interface / safe failure -----------------------------------------------------------
echo "[AC-7] interface contract"
"$FIX" --help >/dev/null 2>&1;  check "--help exits 0"        "$?" "0"
"$FIX" --bogus >/dev/null 2>&1; check "bad arg exits 2"       "$?" "2"
BAZEL=/nonexistent/bazel "$FIX" >/dev/null 2>&1
check "missing bazel exits 2" "$?" "2"

[ "$(uname -s)" = "Darwin" ] || { echo; echo "non-Darwin: $pass passed, $fail failed"; exit $((fail>0)); }

if [ "$FULL" -eq 1 ]; then
    echo "[setup] expunging Bazel output base (--full)"
    "$BAZEL" clean --expunge >/dev/null 2>&1
fi

# --- AC-3: repair produces LC_UUID on all three binaries --------------------------------------
echo "[AC-3] repair restores LC_UUID"
"$FIX" >/dev/null 2>&1; rc=$?
check "repair exits 0" "$rc" "0"

CC_DIR="$("$BAZEL" info output_base 2>/dev/null)/external/local_config_cc"
for b in wrapped_clang wrapped_clang_pp libtool_check_unique; do
    n="$(otool -l "$CC_DIR/$b" 2>/dev/null | grep -c 'cmd LC_UUID' || true)"
    if [ "${n:-0}" -ge 1 ]; then ok "$b has LC_UUID ($n)"; else no "$b has no LC_UUID"; fi
done

# wrapped_clang_pp must remain a symlink to wrapped_clang (FR-5)
if [ -L "$CC_DIR/wrapped_clang_pp" ]; then ok "wrapped_clang_pp is still a symlink"
else no "wrapped_clang_pp is not a symlink"; fi

# dyld must actually load them — the whole point (a bad binary aborts before main)
for b in wrapped_clang libtool_check_unique; do
    out="$("$CC_DIR/$b" 2>&1)"
    if printf '%s' "$out" | grep -q "missing LC_UUID"; then no "$b still rejected by dyld"
    else ok "$b is loadable by dyld"; fi
done

# --- AC-5: idempotence ------------------------------------------------------------------------
echo "[AC-5] idempotence"
m1="$(stat -f %m "$CC_DIR/wrapped_clang")"
m2="$(stat -f %m "$CC_DIR/libtool_check_unique")"
"$FIX" >/dev/null 2>&1; check "second run exits 0" "$?" "0"
n1="$(stat -f %m "$CC_DIR/wrapped_clang")"
n2="$(stat -f %m "$CC_DIR/libtool_check_unique")"
if [ "$m1" = "$n1" ] && [ "$m2" = "$n2" ]; then ok "no rewrite on healthy toolchain"
else no "binaries were rewritten despite being healthy"; fi

"$FIX" --check >/dev/null 2>&1; check "--check exits 0 when healthy" "$?" "0"

# --- AC-1 / AC-2 / AC-4: the build itself -----------------------------------------------------
if [ "$FULL" -eq 1 ]; then
    echo "[AC-1/2/4] full build"
    log="$(mktemp)"
    make build >"$log" 2>&1; rc=$?
    check "make build exits 0" "$rc" "0"
    [ -x bin/Compiler ]  && ok "bin/Compiler produced"  || no "bin/Compiler missing"
    [ -x bin/RepoTools ] && ok "bin/RepoTools produced" || no "bin/RepoTools missing"
    # Count real dyld diagnostics, NOT this script's own "missing LC_UUID -> relinking" lines.
    d="$(grep -c '^dyld\[' "$log" || true)"
    check "zero dyld errors" "${d:-0}" "0"
    a="$(grep -c 'Abort trap' "$log" || true)"
    check "zero Abort trap (libtool_check_unique healthy)" "${a:-0}" "0"
    rm -f "$log"
else
    echo "[AC-1/2/4] full build ... SKIP (pass --full to run)"
fi

echo
echo "== $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
