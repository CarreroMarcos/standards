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
expect_no_output() { # expect_no_output <description> <grep-pattern> <command...>
  local desc=$1; shift; local pat=$1; shift
  out=$("$@" 2>&1 || true)
  if printf '%s\n' "$out" | grep -q "$pat"; then fail=$((fail + 1)); echo "FAIL: $desc (pattern '$pat' found in output)"
  else pass=$((pass + 1)); fi
}

RV="$dir/check-refs.sh"; VV="$dir/check-values.sh"; FF="$dir/check-frontmatter.sh"; MX="$dir/check-matrix.sh"
FX="$dir/fixtures"; VM="$dir/../values.md"

# rg-less stub PATH: symlink everything except rg, so the scripts take
# their grep-fallback branches and we assert those behave identically.
# (Defined before first use — norv is called by expect lines below.)
# The default-path expects exercise the preferred tool (rg when present);
# the norv block deterministically covers the fallback.
if command -v rg >/dev/null 2>&1; then
  RG_PRESENT=1
else
  RG_PRESENT=0
  echo "test-lints: WARNING — rg not found; default-path expects exercise the grep branch (fallback covered deterministically via norv)"
fi
noroot=$(mktemp -d)
for f in /usr/bin/* /bin/*; do
  b=$(basename "$f"); [ "$b" = "rg" ] && continue
  [ -e "$noroot/$b" ] || ln -s "$f" "$noroot/$b" 2>/dev/null || true
done
norv() { PATH="$noroot" "$@"; }
# The portability guard's exit-2 arm needs a BSD grep to fire. Simulate it
# with a stub grep that always fails the probe (exit 1 → empty probe →
# guard fires exit 2).
badroot=$(mktemp -d)
printf '#!/usr/bin/env bash\nexit 1\n' > "$badroot/grep"
chmod +x "$badroot/grep"
badgv() { PATH="$badroot:$noroot" "$@"; }
expect 2 "check-values portability guard fires" badgv bash "$VV" "$VM" "$FX/check-values/clean.md"
# Wrong-token probe: a grep that returns a plausible-but-wrong token must
# still trip the guard's != "120s" comparison.
wrongroot=$(mktemp -d)
printf '#!/usr/bin/env bash\necho "999x"\n' > "$wrongroot/grep"
chmod +x "$wrongroot/grep"
wrongv() { PATH="$wrongroot:$noroot" "$@"; }
expect 2 "check-values guard fires on wrong probe" wrongv bash "$VV" "$VM" "$FX/check-values/clean.md"
# The portability guard's exit-2 arm needs a BSD grep to fire; GNU hosts
# always pass the probe, so that arm is untestable here by construction.

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
expect_output "refs violation flags /home/" "outside-repo reference '/home/'"  bash "$RV" "$FX/check-refs/violation.md"
expect_output "values violation flags 120s"   "undeclared magic number '120s'"  bash "$VV" "$VM" "$FX/check-values/violation.md"
expect_output "values violation flags 2 rounds" "undeclared magic number '2 rounds'"  bash "$VV" "$VM" "$FX/check-values/violation.md"
expect_output "values violation flags 30 times" "undeclared magic number '30 times'"  bash "$VV" "$VM" "$FX/check-values/violation.md"
expect_output "values unknown ref named"      "unknown values.md reference 'nonexistent.value'"  bash "$VV" "$VM" "$FX/check-values/unknown-ref.md"
expect_output "refs no-rg flags ../" "outside-repo reference" norv bash "$RV" "$FX/check-refs/violation.md"
expect_output "values no-rg flags 120s" "undeclared magic number '120s'" norv bash "$VV" "$VM" "$FX/check-values/violation.md"
expect 1 "check-refs no-rg violation"   norv bash "$RV" "$FX/check-refs/violation.md"
expect 0 "check-refs no-rg clean"       norv bash "$RV" "$FX/check-refs/clean.md"
expect 1 "check-values no-rg violation" norv bash "$VV" "$VM" "$FX/check-values/violation.md"
expect 0 "check-values no-rg clean"     norv bash "$VV" "$VM" "$FX/check-values/clean.md"
expect 0 "check-refs no-rg tmp-scratch" norv bash "$RV" "$FX/check-refs/tmp-scratch.md"
expect 1 "check-refs no-rg tmp-bare"   norv bash "$RV" "$FX/check-refs/tmp-bare.md"
expect 1 "check-refs no-rg tmp-mixed"   norv bash "$RV" "$FX/check-refs/tmp-mixed.md"
expect 1 "check-refs no-rg src-violation" norv bash "$RV" "$FX/check-refs/source-violation.md"
expect 1 "check-values no-rg unknown-ref" norv bash "$VV" "$VM" "$FX/check-values/unknown-ref.md"
expect 0 "check-values no-rg allowlisted" norv bash "$VV" "$VM" "$FX/check-values/allowlisted.md"
expect 1 "check-values cofire"          bash "$VV" "$VM" "$FX/check-values/cofire.md"
expect_output "check-values cofire ref" "unknown values.md reference 'nope.value'" bash "$VV" "$VM" "$FX/check-values/cofire.md"
expect_output "check-values cofire num" "undeclared magic number '90s'" bash "$VV" "$VM" "$FX/check-values/cofire.md"
expect 1 "check-values tbd-ref"         bash "$VV" "$VM" "$FX/check-values/tbd-ref.md"
expect_output "check-values tbd-ref named" "unknown values.md reference 'missing.entry'" bash "$VV" "$VM" "$FX/check-values/tbd-ref.md"
# Self-hosting: the lints must pass on the shipped docs themselves.
expect 0 "values lint clean on docs" bash "$VV" "$VM" "$dir"/../hub.md "$dir"/../values.md "$dir"/../README.md "$dir"/../HARNESS.md "$dir"/../principles-distilled.md "$dir"/../references/eval-protocol.md
expect 0 "values lint clean on runbooks" bash "$VV" "$VM" "$dir"/../runbooks/*.md "$dir"/../runbooks/examples/*.md
expect 0 "values lint clean on skills" bash "$VV" "$VM" "$dir"/../skills/*/SKILL.md
expect 0 "frontmatter clean fixture" bash "$FF" "$FX/check-frontmatter/clean.md"
expect 0 "frontmatter block-scalar rule not a delimiter" bash "$FF" "$FX/check-frontmatter/block-scalar-rule.md"
expect 1 "frontmatter bad-colon fixture" bash "$FF" "$FX/check-frontmatter/bad-colon.md"
expect_output "frontmatter bad-colon reports line" "bad-colon.md:3:" bash "$FF" "$FX/check-frontmatter/bad-colon.md"
expect 1 "frontmatter missing file" bash "$FF" "$FX/check-frontmatter/nonexistent.md"
expect 1 "frontmatter unclosed fixture" bash "$FF" "$FX/check-frontmatter/missing-close.md"
expect_output "frontmatter unclosed reports" "never closed" bash "$FF" "$FX/check-frontmatter/missing-close.md"
expect 0 "frontmatter no-frontmatter fixture" bash "$FF" "$FX/check-frontmatter/no-frontmatter.md"
expect_no_output "frontmatter no-frontmatter silent" "no-frontmatter.md" bash "$FF" "$FX/check-frontmatter/no-frontmatter.md"
expect 0 "frontmatter empty file" bash "$FF" "$FX/check-frontmatter/empty.md"
expect 1 "frontmatter mixed files exit 1" bash "$FF" "$FX/check-frontmatter/clean.md" "$FX/check-frontmatter/bad-colon.md"
expect_output "frontmatter mixed reports bad file" "bad-colon.md:3:" bash "$FF" "$FX/check-frontmatter/clean.md" "$FX/check-frontmatter/bad-colon.md"
expect_no_output "frontmatter mixed silent on clean file" "clean.md" bash "$FF" "$FX/check-frontmatter/clean.md" "$FX/check-frontmatter/bad-colon.md"
expect 0 "frontmatter clean on docs" bash "$FF" "$dir"/../hub.md "$dir"/../values.md "$dir"/../README.md "$dir"/../HARNESS.md "$dir"/../principles-distilled.md "$dir"/../references/eval-protocol.md
expect 0 "frontmatter clean on runbooks" bash "$FF" "$dir"/../runbooks/*.md "$dir"/../runbooks/examples/*.md
expect 0 "frontmatter clean on skills" bash "$FF" "$dir"/../skills/*/SKILL.md
expect 0 "refs lint clean on docs" bash "$RV" "$dir"/../hub.md "$dir"/../values.md "$dir"/../README.md "$dir"/../HARNESS.md "$dir"/../principles-distilled.md "$dir"/../references/eval-protocol.md
expect 0 "refs lint clean on runbooks" bash "$RV" "$dir"/../runbooks/*.md "$dir"/../runbooks/examples/*.md
expect 0 "refs lint clean on skills" bash "$RV" "$dir"/../skills/*/SKILL.md
expect 0 "refs lint no-rg clean on runbooks" norv bash "$RV" "$dir"/../runbooks/*.md "$dir"/../runbooks/examples/*.md
expect 0 "refs lint no-rg clean on skills" norv bash "$RV" "$dir"/../skills/*/SKILL.md
expect 0 "values lint no-rg clean on runbooks" norv bash "$VV" "$VM" "$dir"/../runbooks/*.md "$dir"/../runbooks/examples/*.md
expect 0 "values lint no-rg clean on skills" norv bash "$VV" "$VM" "$dir"/../skills/*/SKILL.md
expect 1 "check-values no-rg tbd-ref" norv bash "$VV" "$VM" "$FX/check-values/tbd-ref.md"
expect_output "check-values no-rg tbd-ref named" "unknown values.md reference 'missing.entry'" norv bash "$VV" "$VM" "$FX/check-values/tbd-ref.md"
expect 1 "check-refs mixed targets" bash "$RV" "$FX/does-not-exist.md" "$FX/check-refs/clean.md" "$FX/check-refs/violation.md"
expect_output "check-refs mixed targets report" "violation.md:3:" bash "$RV" "$FX/does-not-exist.md" "$FX/check-refs/clean.md" "$FX/check-refs/violation.md"
expect 1 "check-values no values file"  bash "$VV" "$FX/does-not-exist.md" "$FX/check-values/clean.md"
expect_output "check-values zero args usage" "usage:" bash "$VV"
expect 1 "check-refs tmp-mixed flagged" bash "$RV" "$FX/check-refs/tmp-mixed.md"
expect 0 "decades allowlisted" bash "$VV" "$FX/check-values/values-allow-1970s.md" "$FX/check-values/decades.md"
expect 1 "decades flagged without allowlist" bash "$VV" "$VM" "$FX/check-values/decades.md"
expect 0 "tbd suppresses number" bash "$VV" "$VM" "$FX/check-values/tbd-number.md"
# Script-behavior tests use self-contained fixtures only, so a script
# regression is distinguishable from documentation drift.
expect 0 "matrix clean fixture" bash "$MX" "$FX/check-matrix/clean.md"
expect 1 "matrix mismatch flagged" bash "$MX" "$FX/check-matrix/mismatch.md"
expect 1 "matrix split mismatch flagged" bash "$MX" "$FX/check-matrix/split-mismatch.md"
expect 0 "matrix unsupported cell clean" bash "$MX" "$FX/check-matrix/unsupported-clean.md"
expect 1 "matrix missing notes flagged" bash "$MX" "$FX/check-matrix/no-notes.md"
expect_output "matrix missing notes message" "no 'cells filled' notes line" bash "$MX" "$FX/check-matrix/no-notes.md"
# Docs-consistency check (separate): the live HARNESS.md matrix must match
# its own notes line. Fails on docs drift, not script bugs.
expect 0 "docs: matrix totals match notes" bash "$MX" "$dir"/../HARNESS.md

echo "test-lints: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
