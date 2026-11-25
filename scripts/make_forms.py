#!/usr/bin/env python3
"""Generate the two demo forms. Run once; output is the deliverable .4DForm JSON."""
import json, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent / "Project/Sources/Forms"

def text(name, left, top, width, height, value, cls=None, align=None):
    o = {"type": "text", "left": left, "top": top, "width": width, "height": height, "text": value}
    if cls: o["class"] = cls
    if align: o["textAlign"] = align
    return o

def button(name, left, top, width, height, label, cls="action"):
    return {"type": "button", "left": left, "top": top, "width": width, "height": height,
            "text": label, "style": "roundedBevel", "class": cls, "events": ["onClick"]}

def input_(name, left, top, width, height, source, cls=None, hint=None, multiline=None,
           enterable=True, border=None):
    o = {"type": "input", "left": left, "top": top, "width": width, "height": height,
         "dataSource": source}
    if hint: o["dataSourceTypeHint"] = hint
    if cls: o["class"] = cls
    if multiline:
        o["multiline"] = "yes"
        o["wordwrap"] = "normal"
        o["scrollbarVertical"] = "automatic"
        o["events"] = ["onDataChange"]
    if not enterable:
        o["enterable"] = False
        o["focusable"] = True
        o["hideFocusRing"] = True
    if border: o["borderStyle"] = border
    return o

def stepper(left, top, source, lo, hi, step):
    return {"type": "stepper", "left": left, "top": top, "width": 14, "height": 26,
            "dataSource": source, "dataSourceTypeHint": "integer",
            "min": lo, "max": hi, "step": step, "events": ["onDataChange"]}

# ---------------------------------------------------------------- MonitorBoard
board_objs = {
    # page 0
    "canvas": {"type": "rectangle", "left": 0, "top": 0, "width": 1080, "height": 760, "fill": "automatic", "stroke": "transparent"},
}
board_page = {
    "title": text("title", 24, 16, 360, 34, "DisplayScale", "appTitle"),
    "subtitle": text("subtitle", 24, 54, 620, 20,
                     "Effective display scaling, read live from the operating system", "appSubtitle"),
    "platformBadge": text("platformBadge", 640, 22, 416, 24, "querying…", "badge", "right"),
    "rule": {"type": "rectangle", "left": 24, "top": 88, "width": 1032, "height": 1, "stroke": "transparent", "class": "rule"},

    "monitorsTitle": text("monitorsTitle", 24, 104, 380, 20, "Monitors", "section"),
    "monitorList": {
        "type": "listbox", "left": 24, "top": 128, "width": 380, "height": 208,
        "dataSource": "Form.rows", "currentItemSource": "Form.selectedRow",
        "selectionMode": "single", "resizingMode": "legacy",
        "rowHeight": "30px", "headerHeight": "26px",
        "borderStyle": "solid", "class": "list",
        "scrollbarVertical": "automatic",
        "alternateFill": "automaticAlternate",
        "events": ["onClick"],
        "columns": [
            {"name": "Device", "dataSource": "This.deviceLabel", "width": 190, "truncateMode": "none", "textAlign": "left", "verticalAlign": "middle"},
            {"name": "Scale", "dataSource": "This.scaleLabel", "width": 70, "truncateMode": "none", "textAlign": "right", "verticalAlign": "middle"},
            {"name": "Size", "dataSource": "This.sizeLabel", "width": 110, "truncateMode": "none", "textAlign": "right", "verticalAlign": "middle"},
        ],
    },
    "btnRefresh": button("btnRefresh", 24, 350, 110, 32, "Refresh"),
    "btnCopy": button("btnCopy", 142, 350, 110, 32, "Copy JSON"),
    "btnLab": button("btnLab", 260, 350, 144, 32, "Open Scale Lab"),

    "logTitle": text("logTitle", 24, 396, 380, 20, "API log", "section"),
    "logView": input_("logView", 24, 420, 380, 132, "Form.logText", "console",
                      multiline=True, enterable=False, border="none"),
    "statusText": text("statusText", 24, 558, 380, 20, "Waiting…", "status"),

    "mapTitle": text("mapTitle", 428, 104, 628, 20, "Desktop layout", "section"),
    "Map": {"type": "webArea", "left": 428, "top": 128, "width": 628, "height": 248,
            "class": "surface", "borderStyle": "solid"},

    "detailCard": {"type": "rectangle", "left": 428, "top": 388, "width": 628, "height": 176,
                   "class": "card", "stroke": "transparent"},
    "detailScale": text("detailScale", 444, 398, 150, 50, "—", "bigNumber"),
    "detailScaleLabel": text("detailScaleLabel", 444, 452, 150, 16, "effective scale", "muted"),
    "detailDevice": text("detailDevice", 444, 472, 160, 18, "—", "caption"),
    "detailCaption": text("detailCaption", 444, 490, 160, 16, "", "muted"),

    "stat1Caption": text("stat1Caption", 616, 398, 190, 16, "Native panel", "statCaption"),
    "stat1Value": text("stat1Value", 616, 416, 190, 22, "—", "statValue"),
    "stat2Caption": text("stat2Caption", 816, 398, 224, 16, "UI size", "statCaption"),
    "stat2Value": text("stat2Value", 816, 416, 224, 22, "—", "statValue"),
    "stat3Caption": text("stat3Caption", 616, 450, 190, 16, "Backing buffer", "statCaption"),
    "stat3Value": text("stat3Value", 616, 468, 190, 22, "—", "statValue"),
    "detailNote": input_("detailNote", 816, 448, 224, 64, "Form.noteText", "note", multiline=True,
                         enterable=False, border="none"),

    "probeTitle": text("probeTitle", 24, 600, 700, 20, "Error path — prelaunch target rejection", "section"),
    "btnProbe": button("btnProbe", 24, 624, 288, 32, "Probe the other platform target"),
    "probeView": input_("probeView", 24, 664, 1032, 42, "Form.probeText", "console",
                        multiline=True, enterable=False, border="none"),
    "toast": input_("toast", 24, 712, 1032, 20, "Form.toast", "toast",
                    enterable=False, border="none"),
}
board = {
    "$4d": {"version": "1", "kind": "form"},
    "windowSizingX": "fixed", "windowSizingY": "fixed",
    "windowMinWidth": 1080, "windowMinHeight": 760,
    "windowMaxWidth": 1080, "windowMaxHeight": 760,
    "width": 1080, "height": 760,
    "events": ["onLoad", "onClick", "onUnload"],
    "windowTitle": "DisplayScale — Monitor Board",
    "destination": "detailScreen",
    "method": "method.4dm",
    "pages": [{"objects": board_objs}, {"objects": board_page}],
}

# ---------------------------------------------------------------- ScaleLab
lab_objs = {
    "canvas": {"type": "rectangle", "left": 0, "top": 0, "width": 720, "height": 570, "fill": "automatic", "stroke": "transparent"},
}
lab_page = {
    "labTitle": text("labTitle", 24, 18, 520, 32, "Scale Lab", "appTitle"),
    "btnClose": button("btnClose", 600, 16, 96, 30, "Close"),
    "rule": {"type": "rectangle", "left": 24, "top": 88, "width": 672, "height": 1, "stroke": "transparent", "class": "rule"},

    "inputsTitle": text("inputsTitle", 32, 102, 640, 18, "Inputs", "section"),
    "nativeLabel": text("nativeLabel", 32, 126, 110, 16, "Native px width", "statCaption"),
    "inpNative": input_("inpNative", 32, 144, 96, 26, "Form.lab.nativeWidth", "field", hint="integer"),
    "stepNative": stepper(132, 144, "Form.lab.nativeWidth", 320, 16384, 60),

    "pointsLabel": text("pointsLabel", 170, 126, 100, 16, "UI point width", "statCaption"),
    "inpPoints": input_("inpPoints", 170, 144, 86, 26, "Form.lab.pointsWidth", "field", hint="integer"),
    "stepPoints": stepper(260, 144, "Form.lab.pointsWidth", 320, 16384, 40),

    "dpiLabel": text("dpiLabel", 298, 126, 90, 16, "Windows dpi", "statCaption"),
    "inpDpi": input_("inpDpi", 298, 144, 70, 26, "Form.lab.dpi", "field", hint="integer"),
    "stepDpi": stepper(372, 144, "Form.lab.dpi", 72, 384, 12),

    "labBig": text("labBig", 32, 188, 240, 56, "—", "hugeNumber"),
    "labCaption": text("labCaption", 32, 246, 420, 18, "…", "muted"),
    "labMac": text("labMac", 32, 278, 656, 24, "", "formulaLine"),
    "labWin": text("labWin", 32, 306, 656, 24, "", "formulaLine"),
    "LabVisual": {"type": "webArea", "left": 32, "top": 342, "width": 656, "height": 124,
                  "class": "surface", "borderStyle": "solid"},

    "btnUseDisplay": button("btnUseDisplay", 32, 478, 150, 30, "Use my display"),
    "presetRetina": button("presetRetina", 190, 478, 120, 30, "Retina 2×"),
    "presetMore": button("presetMore", 318, 478, 130, 30, "More space"),
    "presetWin125": button("presetWin125", 456, 478, 110, 30, "Win 125%"),
    "presetWin150": button("presetWin150", 574, 478, 110, 30, "Win 150%"),

    "hint1": text("hint1", 32, 518, 656, 18, "macOS: scale = native panel pixels ÷ UI point width.", "muted"),
    "hint2": text("hint2", 32, 536, 656, 18, "Windows: scale = effective DPI ÷ 96.", "muted"),
}
lab = {
    "$4d": {"version": "1", "kind": "form"},
    "windowSizingX": "fixed", "windowSizingY": "fixed",
    "windowMinWidth": 720, "windowMinHeight": 570,
    "windowMaxWidth": 720, "windowMaxHeight": 570,
    "width": 720, "height": 570,
    "events": ["onLoad", "onDataChange", "onClick", "onUnload"],
    "windowTitle": "DisplayScale — Scale Lab",
    "destination": "detailScreen",
    "method": "method.4dm",
    "pages": [{"objects": lab_objs}, {"objects": lab_page}],
}

for name, form in (("MonitorBoard", board), ("ScaleLab", lab)):
    d = ROOT / name
    d.mkdir(parents=True, exist_ok=True)
    (d / "form.4DForm").write_text(json.dumps(form, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    print("wrote", d / "form.4DForm")
