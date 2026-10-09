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
expect_output() { # expect_output <description> <grep-pattern> <command...>
  local desc=$1; shift; local pat=$1; shift
  out=$("$@" 2>&1 || true)
  if printf '%s\n' "$out" | grep -q "$pat"; then pass=$((pass + 1))
  else fail=$((fail + 1)); echo "FAIL: $desc (pattern '$pat' not in output)"; fi
}

RV="$dir/check-refs.sh"; VV="$dir/check-values.sh"
FX="$dir/fixtures"; VM="$dir/../values.md"

expect 0 "check-refs clean"            bash "$RV" "$FX/check-refs/clean.md"
expect 1 "check-refs violation"         bash "$RV" "$FX/check-refs/violation.md"
expect 0 "check-refs tmp-scratch pass"  bash "$RV" "$FX/check-refs/tmp-scratch.md"
expect 1 "check-refs tmp-bare flagged"  bash "$RV" "$FX/check-refs/tmp-bare.md"
expect 1 "check-refs source-violation"  bash "$RV" "$FX/check-refs/source-violation.md"
expect 0 "check-values clean"           bash "$VV" "$VM" "$FX/check-values/clean.md"
expect 0 "check-values allowlisted"     bash "$VV" "$VM" "$FX/check-values/allowlisted.md"
expect 1 "check-values violation"       bash "$VV" "$VM" "$FX/check-values/violation.md"
expect 1 "check-values unknown ref"     bash "$VV" "$VM" "$FX/check-values/unknown-ref.md"
expect 0 "check-values TBD tolerated"   bash "$VV" "$VM" "$FX/check-values/tbd.md"
expect 0 "check-values self-skip"       bash "$VV" "$VM" "$VM"
expect 1 "check-values missing target"  bash "$VV" "$VM" "$FX/does-not-exist.md"
expect 1 "check-refs missing target"    bash "$RV" "$FX/does-not-exist.md"
expect 1 "check-refs no args"           bash "$RV"
expect_output "refs violation flags ../"      "outside-repo reference '\.\./"  bash "$RV" "$FX/check-refs/violation.md"
expect_output "refs violation flags ~/"       "outside-repo reference '~/'"  bash "$RV" "$FX/check-refs/violation.md"
expect_output "refs violation flags /root/"   "outside-repo reference '/root/'"  bash "$RV" "$FX/check-refs/violation.md"
expect_output "refs violation flags blob URL" "outside-repo reference 'github"  bash "$RV" "$FX/check-refs/violation.md"
expect_output "values violation flags 120s"   "undeclared magic number '120s'"  bash "$VV" "$VM" "$FX/check-values/violation.md"
expect_output "values violation flags 2 rounds" "undeclared magic number '2 rounds'"  bash "$VV" "$VM" "$FX/check-values/violation.md"
expect_output "values unknown ref named"      "unknown values.md reference 'nonexistent.value'"  bash "$VV" "$VM" "$FX/check-values/unknown-ref.md"
# The portability guard's exit-2 arm needs a BSD grep to fire; GNU hosts
# always pass the probe, so that arm is untestable here by construction.

echo "test-lints: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
