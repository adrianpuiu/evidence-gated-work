#!/usr/bin/env bash
# Validate and package a skill without polluting the source tree.
# Usage: scripts/publish.sh <skill-dir>   (writes a .skill zip into dist/)
set -euo pipefail

skill_dir="${1:?usage: scripts/publish.sh <skill-dir>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill_dir="$(cd "$skill_dir" && pwd)"
name="$(basename "$skill_dir")"

python -m venv "$root/.venv" >/dev/null 2>&1 || true
if command -v uv >/dev/null 2>&1; then
  uv pip install --python "$root/.venv/bin/python" --quiet pyyaml
else
  "$root/.venv/bin/python" -m pip install --quiet pyyaml
fi

"$root/.venv/bin/python" "$root/scripts/quick_validate.py" "$skill_dir"

mkdir -p "$root/dist"
rm -f "$root/dist/$name.skill"
"$root/.venv/bin/python" - "$root" "$skill_dir" "$root/dist/$name.skill" <<'PY'
import sys
from pathlib import Path

root, skill_dir, out = (Path(p) for p in sys.argv[1:4])
sys.path.insert(0, str(root))
from scripts.package_skill import should_exclude  # noqa: E402
import zipfile

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
    for path in sorted(skill_dir.rglob("*")):
        rel = path.relative_to(skill_dir.parent)
        if path.is_file() and not should_exclude(rel):
            zf.write(path, rel.as_posix())
print(f"packaged {out}")
PY
