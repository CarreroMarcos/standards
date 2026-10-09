#!/usr/bin/env bash
# check-frontmatter.sh — fail when a markdown file's YAML frontmatter doesn't parse.
# Usage: check-frontmatter.sh <file.md> [...]
# A file with no leading `---` block passes (nothing to validate).
# Reports `file:line:` for the frontmatter line where the parser failed.
set -u
bad=0
for f in "$@"; do
  [ -f "$f" ] || { echo "$f: file not found"; bad=1; continue; }
  out=$(python3 - "$f" <<'PY' 2>&1
import sys, yaml
path = sys.argv[1]
text = open(path, encoding="utf-8").read().splitlines()
if not text or text[0].strip() != "---":
    sys.exit(0)  # no frontmatter — nothing to validate
# Closing delimiter: first column-0 line that strips to ---. Block-scalar
# content is always indented in valid YAML, so a column-0 --- can never be
# inside one — no scalar tracking needed. Trailing whitespace tolerated.
end = None
for i in range(1, len(text)):
    if text[i].strip() == "---" and not text[i][:1].isspace():
        end = i
        break
if end is None:
    print(f"{len(text)}: frontmatter never closed (missing closing ---)")
    sys.exit(1)
try:
    yaml.safe_load("\n".join(text[1:end]))
except yaml.YAMLError as e:
    mark = getattr(e, "problem_mark", None)
    line = (mark.line + 2) if mark else 2  # +1 for 0-index, +1 for opening ---
    msg = str(e).splitlines()[0] if str(e) else "invalid YAML"
    print(f"{line}: {msg}")
    sys.exit(1)
PY
)
  if [ -n "$out" ]; then
    echo "$f:$out"
    bad=1
  fi
done
exit "$bad"
