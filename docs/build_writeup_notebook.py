#!/usr/bin/env python3
"""Convert WRITEUP.md into a self-contained Jupyter notebook.

- Splits the markdown into one cell per `---`-delimited section.
- Embeds every docs/screenshots/*.png as a base64 data URI (downscaled),
  so the notebook renders standalone on Kaggle with no attached dataset.
"""
import base64, json, re, subprocess, tempfile, pathlib

ROOT = pathlib.Path("/Volumes/Data/Developments/apple/quack-app")
SHOTS = ROOT / "docs" / "screenshots"
md = (ROOT / "WRITEUP.md").read_text()

tmp = pathlib.Path(tempfile.mkdtemp())
cache: dict[str, str] = {}

def data_uri(name: str) -> str | None:
    if name in cache:
        return cache[name]
    src = SHOTS / name
    if not src.exists():
        return None
    small = tmp / name
    # Downscale so the largest side is 760 px — keeps the notebook lean.
    subprocess.run(["sips", "-Z", "760", str(src), "--out", str(small)],
                   capture_output=True, check=True)
    b64 = base64.b64encode(small.read_bytes()).decode()
    uri = f"data:image/png;base64,{b64}"
    cache[name] = uri
    return uri

def repl(m: re.Match) -> str:
    alt, name = m.group(1), m.group(2)
    uri = data_uri(name)
    return f"![{alt}]({uri})" if uri else m.group(0)

md = re.sub(r"!\[([^\]]*)\]\(docs/screenshots/([^)]+)\)", repl, md)

# One markdown cell per section (sections divided by a lone `---`).
sections = re.split(r"\n[ \t]*---[ \t]*\n", md)
cells = []
for sec in sections:
    sec = sec.strip("\n")
    if sec:
        cells.append({"cell_type": "markdown", "metadata": {}, "source": sec})

nb = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python", "version": "3"},
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}
out = ROOT / "WRITEUP.ipynb"
out.write_text(json.dumps(nb, indent=1))
print(f"wrote {out}  ({len(cells)} markdown cells, {out.stat().st_size // 1024} KB, "
      f"{len(cache)} images embedded)")
