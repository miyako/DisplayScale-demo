# Working in this demo repository

This is a **demo** of the [DisplayScale](https://github.com/miyako/DisplayScale)
component, not the component itself. Read `README.md` first, then
`docs/FINDINGS.md` — many of the surprises here are already documented there.

## Tooling

`.agents/` is a submodule of [miyako/skills](https://github.com/miyako/skills)
(branch `dist`): Agent Skills for 4D plus JSON schemas. It also ships small
helper binaries under `tools/`:

```sh
# read-only checks used while developing this demo
tools/4dlsp/tool4d-lsp-stdio validate --workspace Project/ Sources/Classes/DisplayScene.4dm
tools/4dform/fourdform Project/Sources/Forms/MonitorBoard/form.4DForm -o /tmp/board.png
```

`fourdform` only renders static previews (web areas are placeholders); a real
preview needs a running 4D. Regenerate both form PNGs in `docs/` when the form
layout changes.

## Invariants

1. The forms are **generated**. Edit `scripts/make_forms.py`, then re-run it; do
   not hand-edit `form.4DForm` JSON without also updating the script.
2. `Project/Sources/dependencies.json` stays empty. The vendored component in
   `Components/` is the source of truth for the demo; declaring a dependency
   breaks local runs (see `docs/FINDINGS.md` §1).
3. Numeric text going into SVG/HTML/labels uses `"###0"` / `"###0.0"` formats,
   never bare `"0"` / `"0.0"` (`docs/FINDINGS.md` §6).
4. `Form` is data, `DisplayScene` is behaviour. Keep formatting in the class.
5. Temporary `zzz_*` methods and smoke forms must not be committed. Delete them
   and `Project/DerivedData/` before committing.
6. The three `cs.DisplayScale is unknown` LSP diagnostics are expected
   (source-component class); runtime resolves them. Do not silence them with
   fake declarations.

## Verifying by hand

* Interactive: open `Project/DisplayScale-demo.4DProject` in 4D 21.x.
* Headless-ish: launch through LaunchServices, never straight from an
  automation shell (`docs/FINDINGS.md` §5):

  ```sh
  open -n -a "/Applications/4D 21.2 LTS (100694)/4D.app" --args \
    --project=$PWD/Project/DisplayScale-demo.4DProject --dataless \
    --skip-onstartup --startup-method=zzz_check
  ```

* Keep the display awake while querying (`caffeinate -u -t 30`), otherwise the
  CLI legitimately reports `NO_MONITORS` (`docs/FINDINGS.md` §4).
* Headless `Compile project` currently crashes on form-bearing projects; do not
  blame the demo code for that (`docs/FINDINGS.md` §2).

## Updating the vendored component

```sh
scripts/install-component.sh                  # sibling checkout at ../DisplayScale
scripts/install-component.sh --component-src /path/to/DisplayScale
```

The script copies `component/DisplayScale/` into `Components/DisplayScale.4dbase`
and rebuilds `Resources/bin/macOS/display-scale` with `clang++` (no CMake on this
machine). Re-run it whenever the component interface changes, then refresh the
version string shown on the board (the `cli …` part of the badge comes from
`Display.version()`).
