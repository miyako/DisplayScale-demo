# Chokepoints, fails and findings

Everything below was observed while building this demo on macOS 27.2.1 (arm64)
with 4D 21.2 LTS (build 100694) and tool4d 21R4 (build 100224). Commands are
reproducible from the repository root unless stated otherwise.

## 1. The `0.1.3` component release has no macOS CLI

Impact: you cannot install the demo as a plain Dependency Manager release and
expect `monitors()` to work on a Mac.

* `Components/…/Resources/bin/` in the release carries a Windows x64 executable.
* The adapter resolves only `Resources/bin/<macOS|Windows>/display-scale[.exe]`
  and reports a prelaunch failure (`unsupported_architecture`, missing resource)
  instead of falling back to `PATH`.
* The component's own `AGENTS.md` documents that the universal macOS CLI and the
  Windows CLI come from separate native CI runners; a local development machine
  does not get one for free.

Workaround used here: build `cli/display-scale/main.cpp` locally and vendor it.

```sh
clang++ -std=c++17 -O2 -mmacosx-version-min=11.0 main.cpp \
  -framework CoreGraphics -framework CoreFoundation -o display-scale
```

Consequence for the demo: `Project/Sources/dependencies.json` intentionally
declares **no** `DisplayScale` dependency. Declaring it makes 4D try to resolve
a release, which fails for local development (`PackageManager Dependency
'DisplayScale' cannot be found`, or installs a package without the macOS CLI).
`scripts/install-component.sh` refreshes the vendored copy instead.

## 2. `Compile project` on a form-bearing project: crash not reproducible

Earlier notes claimed headless `Compile project` segfaults on any project with a
`Forms/` folder. That does **not** reproduce on the committed tree, and the
compiler had in fact never been given the chance to report the demo's own
errors (below). Retested 2026-11-26:

| Run | Result |
| --- | --- |
| tool4d 21.2 LTS (100694), `Compile project` in a startup method | exit 0, structured result |
| tool4d 21R4 (100224), same | exit 0, structured result |
| full 4D 21.2 LTS via LaunchServices, same | result written, no crash report |
| `Compile project(File(...))` of a form-bearing target from a form-less harness (the `do_Compile` → `_Open` path of the old report) | exit 0, structured result |
| same project, no forms / board only / lab only / both | exit 0 each, error count differs only by the form methods' errors |
| malformed `Forms/`: empty dir, method-only dir, `{}` form, `pages: []`, invalid JSON, empty file, stray `.DS_Store`, minimal smoke form | exit 0 each, no crash |

The old report (`4D-2026-11-25-210010.ips`, exit 139) faulted in
`VFormList_json::_LoadFolder` ← `V4DDatabase_Library::_Open` ← `do_Compile`.
It predates the first commit, so the likely trigger was a transient project
state (a draft or `zzz_*` smoke form) that no longer exists. If it returns,
bisect by deleting `Forms/<name>/` one at a time in a scratch copy.

Compile it like this (scratch copy, so no `DerivedData` lands in the repo):

```4d
var $r : Object
$r:=Compile project
LOG EVENT(Into system standard outputs; JSON Stringify($r; *); Information message)
```

The compiler's real findings, now fixed: `$row_ref` undeclared in
`DisplayScene.mapHTML`, and `#DECLARE($params : Object)` on the two form methods
(form methods take no parameters). `success` is `true` afterwards.

## 3. `cmake` is unavailable, so the CLI was built manually

The component's documented build path uses CMake. This machine has no `cmake`,
so the executable above was produced with a single `clang++` invocation. This is
a build deviation, not a code change: the produced binary reports `--version` as
`{"protocol":2,"version":"0.1.3"}` and `monitors` as protocol 2 JSON. Any release work must still use the
component's real build system.

Related trap: the demo's `README` and `scripts/install-component.sh` describe the
manual build, but a real package must not ship without provenance.

## 4. A sleeping display makes the CLI report `NO_MONITORS`

Impact: results are not purely "hardware state", they depend on the current
display power state.

Reproduction (macOS):

```sh
# let the display sleep, then
./Components/DisplayScale.4dbase/Resources/bin/macOS/display-scale monitors
# {"protocol":2,"error":{"code":"NO_MONITORS","message":"no display monitors found"}}
caffeinate -u -t 3          # wake the display
… monitors                  # real JSON again
```

`CGGetActiveDisplayList` returns zero displays while the panel is asleep, so the
CLI correctly fails. The demo surfaces this as a normal failure envelope
(`status: Query failed · NO_MONITORS`, detail scale readout `!`), which is also a
useful reminder that a scale query is a live observation, not a stored setting.

## 5. Launching 4D from a non-interactive shell loses WindowServer access

An app started straight from an automation shell has no window-server access;
`WA SET PAGE CONTENT` and the display query run in a different session context
(`screencapture` fails with "could not create image from display", the CLI inside
that process reports `NO_MONITORS`). Launch through LaunchServices instead:

```sh
open -n -a "/Applications/4D 21.2 LTS (100694)/4D.app" --args \
  --project=… --dataless --skip-onstartup --startup-method=zzz_smoke
```

Note the demo does not rely on this; it matters for automated verification.

## 6. `String(value; "0")` is a trap in this 4D build

Impact: silently corrupted SVG attributes and labels. Found while checking the
generated desktop-map markup.

```4d
String(592; "0")     // "<"      ← one filler character, not "592"
String(592.4; "0.0") // "<<<"
String(592; "###0")  // "592"    ← correct
```

A bare `"0"` or `"0.0"` format string yields the numeric format's filler glyph,
so `<rect width='<'>` and `scalePercent: "<"` appear instead of numbers. The
analyzer does not warn, and the value type is Text, so it survives JSON and HTML
serialisation.

Fix used here: use `"###0"` / `"###0.0"` (or no format at all) for numbers that
are concatenated into HTML/SVG/labels.

## 6b. 4D has no operator precedence: `This.selectedIndex=$i-1` crashes the map

Impact: `DisplayScene.mapHTML` raised `This operation is not compatible with the
two arguments.` (error 15) once per monitor, so the desktop map had text labels
and **no rectangles**. It only fails at runtime: `validate`, `Compile project`
(`success: true`) and the form load all pass.

4D evaluates operators strictly left to right:

```4d
1+2*3                         // 9, not 7
10+20/2                       // 15, not 20
This.selectedIndex=$i-1       // (This.selectedIndex=$i)-1  → Boolean minus number → error 15
20+(588-$spanX*$k)/2          // ((20+(588-$spanX))*$k)/2  → silently wrong layout
```

Where a wrong expression does not error it silently mis-draws, so the map
geometry (`$x+$w/2`, the centring offsets, `$offX+(…)*$k`) was also wrong.
Fix used here: parenthesise every mixed expression and compute the selection
test once (`$sel:=(This.selectedIndex=($i-1))`). Verified by running
`mapHTML()` interpreted: 0 errors, one `<rect>` per monitor, all coordinates
inside the 628×248 area.

## 7. Source-component classes are invisible to the LSP analyzer

`tool4d-lsp-stdio validate` reports:

```
Sources/Classes/DisplayScene.4dm:21:19: error: The class cs.DisplayScale is unknown.
```

The class resolves at runtime (the component is loaded, queries succeed). The
analyzer only sees compiled component metadata; a source component vendored in
`Components/` is unknown to it. Keep these three diagnostics (`DisplayScene.4dm`
constructor, `DisplayScene.4dm` probe, `Demo_LabUseCurrent.4dm`) in mind and do
not "fix" them by adding fake declarations.

## 8. 4D facts that cost time

* **`Form` is not assignable in method code.** `Form:=New object` is an analyzer
  syntax error. Callers must pass the Form object (`DIALOG(form; obj)`,
  `Open form window` + startup method) and the form method mutates its fields.
* **`onLoad`/`onUnload` only fire when the form declares them** in its `events`
  array. `onClick`/`onDataChange` likewise; the JSON key is `onClick`, not
  `onClicked`.
* **Collections cannot be concatenated with `+`.** Use `.combine()` (or push in
  a loop) when prepending/appending log entries.
* **`Max`/`Min` take collections, not scalars.** Use a ternary for two numbers.
* **`WA SET PAGE CONTENT` needs the fourth (baseURL) argument.** `WA SET PAGE
  CONTENT(*; "Map"; html; "")` is the smallest working form.
* **`open -n` racing an older 4D instance** produces `-10716 Object or
  Collection Expected` at class construction. Retry once no 4D process is alive.
* **A handled `4DRT [15] "This operation is not compatible with the two
  arguments"` error is raised while the board form loads.** It is raised inside
  the On Load path (a temporary `ON ERR CALL` captured it at the HEAD revision
  and after the input-binding fix alike) and 4D continues, so the form renders
  normally. Treat it as background noise: do not "fix" it by moving
  `WA SET PAGE CONTENT`, and do not use its presence to blame the demo code.
* **`OBJECT SET TITLE` on an input object sets a placeholder, not a value.**
  Display text that changes at runtime must go through a bound
  `"dataSource": "Form.x"` and `Form.x:=value`; that is why the note and the
  toast are inputs and not static text objects.
* **Screenshots are not available** in this automation session (no screen
  recording permission), so the README uses static form renders from
  `fourdform` rather than captures of the live windows.

## 9. Things that worked well and should be copied

* A form method that only *routes* (`FORM Event.code` / `FORM Event.objectName`)
  keeps the interactive logic small; the class owns all formatting.
* Rendering the desktop map as one SVG document in a web area avoids needing a
  canvas plug-in and gives crisp text; a plain 628×248 SVG scales cleanly.
* Keeping one `Display` instance per query and rebuilding `This.rows` makes the
  "no caching" story true in code, not just in prose.
* Deliberately probing the other platform target is a cheap way to demonstrate
  the prelaunch error envelope without breaking the working demo.
