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

## 2. Headless `Compile project` segfaults on projects with forms

Impact: CI-style compile validation of this demo is impossible in this
environment. This is a blocker, not a warning.

Reproduced with:

* 4D 21.2 LTS `Compile project` from `tooling/compiler` (project with forms)
* tool4d 21R4 build 100224, same projects
* full 4D.app, same result

Exit status 139. Crash report:
`4D-2026-11-25-210010.ips`, faulting thread
`VFormList_json::_LoadFolder` ← `VFormList_json::_Load` ←
`V4DDatabase_Library::_Open` ← `do_Compile`.

*Compiling the form-less component repository itself succeeds.* The difference
is the presence of `Project/Sources/Forms/`, so it is a form-loading crash in
this build, not a demo-specific mistake. Verify compile status on a 4D build
where `Compile project` opens a form-bearing project successfully.

Mitigation for reviewers: open the project interactively (4D or tool4d with a
startup method) and exercise the forms; do not treat a failed headless compile
as a demo code error without the crash log above.

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
