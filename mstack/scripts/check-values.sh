#!/usr/bin/env bash
# check-values.sh — fail on bare magic numbers not declared in values.md.
#
# Usage: check-values.sh <values-file> <target>...
# A magic-looking number (digits + unit, e.g. 120s, 2 rounds) in a target
# fails when the hit text is absent from the values file's ## Allowlist
# section. Lines with an explicit TBD (...) marker are tolerated.
# The values file itself is skipped: its Value: lines are declarations.
# `values.md#<name>` references must name a declared entry.
set -u

values_file="${1:?usage: check-values.sh <values-file> <target>...}"
shift
[ "$#" -gt 0 ] || { echo "check-values.sh: no targets" >&2; exit 1; }
[ -f "$values_file" ] || { echo "check-values.sh: no such values file: $values_file" >&2; exit 1; }

if command -v rg >/dev/null 2>&1; then
  hitgrep() { rg -o "$1"; }
else
  hitgrep() { grep -E -o "$1"; }
fi

pat='\b[0-9]+\s*(s|ms|sec|secs|seconds|min|mins|minutes|round|rounds|retr|retries|times|x)\b'

mapfile -t declared < <(grep -E '^### ' "$values_file" | sed 's/^### //')
mapfile -t allowlist < <(awk '/^## Allowlist/{f=1;next} /^## /{f=0} f' "$values_file" | grep -o '"[^"]*"' | tr -d '"')

vreal=$(realpath "$values_file" 2>/dev/null || readlink -f "$values_file" 2>/dev/null || printf '%s' "$values_file")
fail=0

for target in "$@"; do
  if [ ! -f "$target" ]; then echo "$target: not found" >&2; fail=1; continue; fi
  treal=$(realpath "$target" 2>/dev/null || readlink -f "$target" 2>/dev/null || printf '%s' "$target")
  [ "$treal" = "$vreal" ] && continue
  lineno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    case "$line" in *"TBD ("*) continue ;; esac
    for ref in $(printf '%s\n' "$line" | grep -o 'values\.md#[A-Za-z0-9_.-]*' || true); do
      name=${ref#values.md#}
      known=0
      for d in "${declared[@]}"; do [ "$d" = "$name" ] && { known=1; break; }; done
      [ "$known" -eq 0 ] && { echo "$target:$lineno: unknown values.md reference '$name'"; fail=1; }
    done
    while IFS= read -r hit; do
      [ -z "$hit" ] && continue
      ok=0
      for a in "${allowlist[@]}"; do case "$a" in *"$hit"*) ok=1; break ;; esac; done
      [ "$ok" -eq 0 ] && { echo "$target:$lineno: undeclared magic number '$hit'"; fail=1; }
    done < <(printf '%s\n' "$line" | hitgrep "$pat" || true)
  done < "$target"
done

exit "$fail"
