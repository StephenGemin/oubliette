#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

passes=0
failures=0

assert_true() {
    local desc="$1"; shift
    local rc=0
    "$@" 2>/dev/null || rc=$?
    if [ "$rc" -eq 0 ]; then
        passes=$((passes + 1))
        printf "  %-54s ok\n" "$desc"
    else
        failures=$((failures + 1))
        printf "  %-54s FAIL\n" "$desc"
    fi
}

assert_nonempty() {
    local desc="$1"
    local val="$2"
    if [ -n "$val" ]; then
        passes=$((passes + 1))
        printf "  %-54s ok\n" "$desc"
    else
        failures=$((failures + 1))
        printf "  %-54s FAIL\n" "$desc"
    fi
}

TEST_DIR=$(mktemp -d)
TEST_PREFIX="$TEST_DIR/prefix"
TEST_NOTES="$TEST_DIR/notes"
OBL="$TEST_PREFIX/bin/obl"

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

cd "$PROJECT_ROOT"

PREFIX="$TEST_PREFIX" bash scripts/install.sh > /dev/null

# ------------------------------------------------------------------ #
# rm command  (rm prompts for confirmation on stdin)                   #
# ------------------------------------------------------------------ #
echo "rm"

add_out=$(OBL_DIR="$TEST_NOTES" EDITOR=true "$OBL" add "Rm Test Note" 2>&1)
rm_id=$(echo "$add_out" | grep -oE '[0-9a-f]{8}' | head -1)

assert_nonempty "obl add returns an id" "$rm_id"

# Declining the prompt keeps the note
assert_true "obl rm answered 'n' keeps the file" \
    sh -c "printf 'n\n' | OBL_DIR='$TEST_NOTES' EDITOR=true '$OBL' rm '$rm_id' >/dev/null && \
           [ -n \"\$(find '$TEST_NOTES' -name '${rm_id}_*.md')\" ]"

# Confirming the prompt removes the note
assert_true "obl rm answered 'y' deletes the file" \
    sh -c "printf 'y\n' | OBL_DIR='$TEST_NOTES' EDITOR=true '$OBL' rm '$rm_id' >/dev/null && \
           [ -z \"\$(find '$TEST_NOTES' -name '${rm_id}_*.md')\" ]"

# Remove by title
add_out2=$(OBL_DIR="$TEST_NOTES" EDITOR=true "$OBL" add "Rm By Title" 2>&1)
rm_id2=$(echo "$add_out2" | grep -oE '[0-9a-f]{8}' | head -1)
assert_true "obl rm by title deletes the file" \
    sh -c "printf 'y\n' | OBL_DIR='$TEST_NOTES' EDITOR=true '$OBL' rm 'Rm By Title' >/dev/null && \
           [ -z \"\$(find '$TEST_NOTES' -name '${rm_id2}_*.md')\" ]"

# Unknown target
assert_true "obl rm unknown id exits non-zero" \
    sh -c "! printf 'y\n' | OBL_DIR='$TEST_NOTES' EDITOR=true '$OBL' rm 'no-such-note' 2>/dev/null"

# Missing argument
assert_true "obl rm missing arg exits non-zero" \
    sh -c "! OBL_DIR='$TEST_NOTES' EDITOR=true '$OBL' rm 2>/dev/null"

# ------------------------------------------------------------------ #
# Summary                                                              #
# ------------------------------------------------------------------ #
echo ""
echo "Results: $passes passed, $failures failed"
[ "$failures" -eq 0 ]
