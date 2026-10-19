#!/usr/bin/env bash
# check-fixtures.sh — structural lint for mstack/references/routing-fixtures.md.
#
# Usage: check-fixtures.sh <fixture-file>...
# Fails (exit 1, file:line) on: a data row whose ID lacks the P/F prefix,
# an empty prompt/route/verdict cell, a verdict outside the known set, or
# a duplicate row ID. This guards the fixture's shape — it does not execute
# routes; semantic routing still needs the manual simulation pass in
# runbooks/skill-authoring-run.md.
set -u

[ "$#" -gt 0 ] || { echo "check-fixtures.sh: no targets" >&2; exit 1; }

fail=0
for target in "$@"; do
  if [ ! -f "$target" ]; then echo "$target: not found" >&2; fail=1; continue; fi
  lineno=0
  seen=""
  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))
    case "$line" in
      '|'*'|'*'|'*'|'*'|'*) ;;
      *) continue ;;
    esac
    id=$(printf '%s' "$line" | cut -d'|' -f2 | tr -d ' ')
    # Header ("ID") and separator ("----") rows are not data.
    [ "$id" = "ID" ] && continue
    [ -n "$id" ] || continue
    case "$id" in *[!-]* ) ;; *) continue ;; esac
    # Data rows must carry the P/F prefix.
    case "$id" in
      P*|F*) ;;
      *) echo "$target:$lineno: row id '$id' lacks P/F prefix" >&2; fail=1; continue ;;
    esac
    prompt=$(printf '%s' "$line" | cut -d'|' -f3 | tr -d ' ')
    route=$(printf '%s' "$line" | cut -d'|' -f4 | tr -d ' ')
    verdict=$(printf '%s' "$line" | cut -d'|' -f5 | awk '{print $1}')
    [ -n "$prompt" ] || { echo "$target:$lineno: empty prompt cell" >&2; fail=1; }
    [ -n "$route" ] || { echo "$target:$lineno: empty route cell" >&2; fail=1; }
    case "$verdict" in
      CLEAN|PROCEED|CONFIRM|BLOCKING|NEVER-ASKED) ;;
      *) echo "$target:$lineno: verdict '$verdict' not in {CLEAN, PROCEED, CONFIRM, BLOCKING, NEVER-ASKED}" >&2; fail=1 ;;
    esac
    case " $seen " in
      *" $id "*) echo "$target:$lineno: duplicate row id '$id'" >&2; fail=1 ;;
    esac
    seen="$seen $id"
  done < "$target"
done
exit "$fail"
