#!/usr/bin/env bash
# check-refs.sh — fail on references outside mstack/ (self-containment lint).
#
# Usage: check-refs.sh <target>...
# Fails (exit 1, file:line) on: ../, ~/, /home/, /root/, bare repo blob
# URLs (github.com/<org>/<repo>/blob/). A /tmp/ line passes only when it
# explicitly mentions scratch. Lines starting with `source:` are provenance
# metadata: they pass only when free of any relative path (../).
set -u

[ "$#" -gt 0 ] || { echo "check-refs.sh: no targets" >&2; exit 1; }

if command -v rg >/dev/null 2>&1; then
  hitgrep() { rg -o "$1"; }
else
  hitgrep() { grep -E -o "$1"; }
fi

pat='\.\./|~/|/home/|/root/|github\.com/[^/[:space:]]+/[^/[:space:]]+/blob/'

fail=0
for target in "$@"; do
  if [ ! -f "$target" ]; then echo "$target: not found" >&2; fail=1; continue; fi
  lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    if printf '%s\n' "$line" | grep -qE '^[[:space:]]*source:'; then
      printf '%s\n' "$line" | grep -qE '\.\./' &&
        { echo "$target:$lineno: relative path in source line '../'"; fail=1; }
      continue
    fi
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      echo "$target:$lineno: outside-repo reference '$hit'"; fail=1
    done < <(printf '%s\n' "$line" | hitgrep "$pat" || true)
    if printf '%s\n' "$line" | grep -qE '/tmp/'; then
      scratch_ok=1
      while IFS= read -r p; do
        case "$p" in *[Ss][Cc][Rr][Aa][Tt][Cc][Hh]*) ;; *) scratch_ok=0 ;; esac
      done < <(printf '%s\n' "$line" | grep -oE '/tmp/[^[:space:]]*' || true)
      [ "$scratch_ok" -eq 0 ] && { echo "$target:$lineno: outside-repo reference '/tmp/'"; fail=1; }
    fi
  done < "$target"
done

exit "$fail"
