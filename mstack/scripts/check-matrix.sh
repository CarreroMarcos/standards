#!/usr/bin/env bash
# check-matrix.sh — verify HARNESS.md's capability-matrix totals.
# Counts full/degraded/unsupported cells in the per-runbook tables and
# compares against the "N cells filled: X full, Y degraded, Z unsupported"
# line in Matrix notes. Fails on mismatch (the 2026-10-09 hand-count error:
# "28 full, 12 degraded" summed to 40, not 45).
# Usage: check-matrix.sh <HARNESS.md>
set -u
f=${1:?usage: check-matrix.sh HARNESS.md}

# Extract only table bodies: rows between "| Harness | Cell |" headers and
# the next "###" heading. Count cell statuses there.
read -r full degraded unsupported < <(awk '
  /^\| Harness \| Cell \|/ { in_table=1; next }
  /^### / { in_table=0 }
  in_table && /^\|/ && !/^\|---/ {
    if ($0 ~ /\| full([ |—-])/) f++
    else if ($0 ~ /\| degraded/) d++
    else if ($0 ~ /\| unsupported/) u++
  }
  END { print f+0, d+0, u+0 }
' "$f")
total=$((full + degraded + unsupported))

# Parse the notes line: "- 45 cells filled: 32 full, 13 degraded, 0 unsupported."
notes=$(grep -E '^[[:space:]]*-[[:space:]]*[0-9]+ cells filled:' "$f" | head -1)
if [ -z "$notes" ]; then echo "check-matrix: no 'cells filled' notes line in $f"; exit 1; fi
read -r n_total n_full n_degraded n_unsupported < <(
  printf '%s\n' "$notes" | sed -E 's/^[^0-9]*([0-9]+) cells filled: ([0-9]+) full, ([0-9]+) degraded, ([0-9]+) unsupported.*/\1 \2 \3 \4/'
)
# A malformed notes line leaves sed's substitution unmatched: the whole line
# lands in n_total and the rest stay unset. Fail explicitly instead of
# tripping set -u (or integer-comparison errors) further down.
for var in n_total n_full n_degraded n_unsupported; do
  val=${!var:-}
  case $val in ''|*[!0-9]*) echo "check-matrix: unparseable notes line: $notes"; exit 1;; esac
done

ok=1
[ "$total" -eq "$n_total" ] || { echo "check-matrix: total mismatch: counted $total, notes say $n_total"; ok=0; }
[ "$full" -eq "$n_full" ] || { echo "check-matrix: full mismatch: counted $full, notes say $n_full"; ok=0; }
[ "$degraded" -eq "$n_degraded" ] || { echo "check-matrix: degraded mismatch: counted $degraded, notes say $n_degraded"; ok=0; }
[ "$unsupported" -eq "$n_unsupported" ] || { echo "check-matrix: unsupported mismatch: counted $unsupported, notes say $n_unsupported"; ok=0; }
[ "$ok" -eq 1 ] && echo "check-matrix: $total cells ($full full, $degraded degraded, $unsupported unsupported) — matches notes"
exit $((1 - ok))
