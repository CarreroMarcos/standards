#!/usr/bin/env bash
# test-lints.sh — assert the mstack lints behave on their fixtures.
# Fails on any mismatch. Resolves paths relative to itself; run from anywhere.
set -u
dir=$(cd "$(dirname "$0")" && pwd -P)
pass=0; fail=0
expect() { # expect <want-exit> <description> <command...>
  local want=$1; shift; local desc=$1; shift
  if "$@" >/dev/null 2>&1; then got=0; else got=$?; fi
  if [ "$got" -eq "$want" ]; then pass=$((pass + 1))
  else fail=$((fail + 1)); echo "FAIL: $desc (want exit $want, got $got)"; fi
}

RV="$dir/check-refs.sh"; VV="$dir/check-values.sh"
FX="$dir/fixtures"; VM="$dir/../values.md"

expect 0 "check-refs clean"            bash "$RV" "$FX/check-refs/clean.md"
expect 1 "check-refs violation"         bash "$RV" "$FX/check-refs/violation.md"
expect 0 "check-refs tmp-scratch pass"  bash "$RV" "$FX/check-refs/tmp-scratch.md"
expect 1 "check-refs tmp-bare flagged"  bash "$RV" "$FX/check-refs/tmp-bare.md"
expect 0 "check-values clean"           bash "$VV" "$VM" "$FX/check-values/clean.md"
expect 0 "check-values allowlisted"     bash "$VV" "$VM" "$FX/check-values/allowlisted.md"
expect 1 "check-values violation"       bash "$VV" "$VM" "$FX/check-values/violation.md"
expect 1 "check-values unknown ref"     bash "$VV" "$VM" "$FX/check-values/unknown-ref.md"
expect 0 "check-values TBD tolerated"   bash "$VV" "$VM" "$FX/check-values/tbd.md"

echo "test-lints: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
