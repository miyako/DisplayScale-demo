// DisplayScene -- state, formatting and HTML rendering for the MonitorBoard form.
// The component itself is cs.DisplayScale.Display; this class only presents its
// read-only result. Nothing here caches a scale value between queries: every
// refresh launches a fresh CLI call through the component.

property _display : Object
property result : Object
property value : Object
property rows : Collection
property selected : Object
property selectedIndex : Integer
property lastError : Object
property log : Collection
property probeText : Text
property toast : Text
property elapsedMs : Integer
property queriedAt : Text
property versionText : Text

Class constructor()
	This._display:=cs.DisplayScale.Display.new(Is Windows ? "Windows-x64" : "macOS-universal")
	This.rows:=New collection
	This.log:=New collection
	This.probeText:=""
	This.toast:=""
	This.elapsedMs:=0
	This.queriedAt:=""
	This.selectedIndex:=-1
	This.versionText:=""
	This.query()

Function query()
	var $start : Integer
	var $version : Object
	$version:=This._display.version()
	If ($version.ok)
		This.versionText:=String($version.value.version)
	Else
		This.versionText:="unavailable"
	End if
	$start:=Milliseconds
	This.result:=This._display.monitors()
	This.elapsedMs:=Milliseconds-$start
	This.queriedAt:=String(Current time)
	If (This.result.ok)
		This.value:=This.result.value
		This.lastError:=Null
		This.rows:=This._buildRows(This.value)
		This.selectedIndex:=0
		This.selected:=(This.rows.length>0) ? This.rows[0] : Null
		This._appendLog("monitors() ok — "+String(This.rows.length)+" monitor(s), "+String(This.elapsedMs)+" ms")
	Else
		This.value:=Null
		This.rows:=New collection
		This.selectedIndex:=-1
		This.selected:=Null
		This.lastError:=This.result.error
		This._appendLog("monitors() failed — "+String(This.lastError.code)+": "+String(This.lastError.message))
	End if

Function selectRow($row : Object)
	If ($row=Null)
		return
	End if
	var $i : Integer
	For ($i; 1; This.rows.length)
		If (This.rows[$i-1].device=$row.device)
			This.selectedIndex:=$i-1
			This.selected:=This.rows[$i-1]
			return
		End if
	End for

Function copyJSON()->$copied : Boolean
	If (This.result=Null)
		This.toast:="Nothing to copy yet"
		return False
	End if
	SET TEXT TO PASTEBOARD(JSON Stringify(This.result; *))
	This.toast:="Raw result JSON copied to the clipboard"
	This._appendLog("clipboard ← JSON Stringify(result)")
	$copied:=True

// Deliberately request the other platform's target: the adapter rejects the
// selection before it looks for an executable, so this demonstrates the
// prelaunch error envelope without a real failure.
Function probeCrossPlatform()->$result : Object
	var $other : Text
	var $probe : Object
	$other:=Is Windows ? "macOS-universal" : "Windows-x64"
	$probe:=cs.DisplayScale.Display.new($other)
	$result:=$probe.monitors()
	If ($result.ok)
		This.probeText:="Unexpected success for target "+$other
		This.toast:="Probe unexpectedly succeeded"
	Else
		This.probeText:="target "+$other+" → ok:false · "+String($result.error.code)+" · "+String($result.error.message)
		This.toast:="Prelaunch rejection captured — no executable was launched"
	End if
	This._appendLog("probe target "+$other+" → "+($result.ok ? "ok" : String($result.error.code)))

Function bindForm()
	var $d : Object
	var $badge : Text
	Form.rows:=This.rows
	Form.selectedRow:=This.selected
	Form.logText:=This._logText()
	Form.probeText:=This.probeText
	Form.toast:=This.toast
	$d:=This.detail()
	OBJECT SET TITLE(*; "detailScale"; $d.scale)
	OBJECT SET TITLE(*; "detailDevice"; $d.device)
	OBJECT SET TITLE(*; "detailCaption"; $d.caption)
	OBJECT SET TITLE(*; "stat1Caption"; $d.nativeLabel)
	OBJECT SET TITLE(*; "stat1Value"; $d.nativeValue)
	OBJECT SET TITLE(*; "stat2Caption"; $d.uiLabel)
	OBJECT SET TITLE(*; "stat2Value"; $d.uiValue)
	OBJECT SET TITLE(*; "stat3Caption"; $d.backingLabel)
	OBJECT SET TITLE(*; "stat3Value"; $d.backingValue)
	Form.noteText:=$d.note
	OBJECT SET TITLE(*; "statusText"; This._statusText())
	$badge:=(This.value=Null) ? "no data" : (This.value.platform+" · protocol "+String(This.value.protocol)+" · cli "+This.versionText)
	OBJECT SET TITLE(*; "platformBadge"; $badge)
	WA SET PAGE CONTENT(*; "Map"; This.mapHTML(); "")
	If (This.selectedIndex>=0)
		LISTBOX SELECT ROW(*; "monitorList"; This.selectedIndex+1; lk replace selection)
	End if

Function detail()->$d : Object
	var $m; $b : Object
	var $pw; $ph : Real
	$d:=New object("scale"; "—"; "device"; "No monitor selected"; "caption"; ""; \
		"nativeLabel"; "Native panel"; "nativeValue"; "—"; \
		"uiLabel"; "UI size"; "uiValue"; "—"; \
		"backingLabel"; "Mode"; "backingValue"; "—"; \
		"note"; "Select a monitor to inspect its effective scaling.")
	If (This.value=Null)
		If (This.lastError#Null)
			$d.scale:="!"
			$d.device:="Query failed"
			$d.caption:=String(This.lastError.code)
			$d.note:=String(This.lastError.message)
		End if
		return $d
	End if
	If (This.selected=Null)
		return $d
	End if
	$m:=This.selected.monitor
	$b:=$m.bounds
	$pw:=$b.right-$b.left
	$ph:=$b.bottom-$b.top
	$d.scale:=String(Int($m.scalePercent+0.5))+"%"
	$d.device:=$m.device
	$d.caption:=(($m.primary) ? "Primary display" : "Secondary display")+" · "+This.value.platform
	If (This.value.platform="macos")
		$d.nativeLabel:="Native panel"
		$d.nativeValue:=String($m.nativePixels.width)+" × "+String($m.nativePixels.height)+" px"
		$d.uiLabel:="UI size"
		$d.uiValue:=String($pw)+" × "+String($ph)+" pt"
		$d.backingLabel:="Backing buffer"
		$d.backingValue:=String($m.backingPixels.width)+" × "+String($m.backingPixels.height)+" px"
		$d.note:="Each point is drawn with "+String($m.backingPixels.width/$pw; "###0.0")+" backing pixels; the UI covers "+String($m.scalePercent; "###0.0")+"% of the panel width."
	Else
		$d.nativeLabel:="Effective DPI"
		$d.nativeValue:=String($m.dpi)+" dpi"
		$d.uiLabel:="Desktop size"
		$d.uiValue:=String($pw)+" × "+String($ph)+" px"
		$d.backingLabel:="DPI formula"
		$d.backingValue:=String($m.dpi)+" / 96 = "+String($m.scalePercent; "###0.0")+"%"
		$d.note:="Bounds use physical desktop pixels; a negative origin is valid on a multi-monitor desktop."
	End if
	return $d

// Parameters for the Scale Lab prefilled from the selected monitor.
Function labParams()->$params : Object
	var $m; $b : Object
	$params:=New object("lab"; New object("nativeWidth"; 3024; "pointsWidth"; 1512; "dpi"; 120))
	If (This.value#Null) & (This.selected#Null)
		$m:=This.selected.monitor
		$b:=$m.bounds
		If (This.value.platform="macos")
			$params.lab.nativeWidth:=$m.nativePixels.width
			$params.lab.pointsWidth:=$b.right-$b.left
		Else
			$params.lab.nativeWidth:=3840
			$params.lab.pointsWidth:=1920
			$params.lab.dpi:=$m.dpi
		End if
		$params.lab.device:=$m.device
	End if
	return $params

Function _statusText()->$s : Text
	If (This.result=Null)
		return "Waiting for the first query…"
	End if
	If (This.result.ok)
		return "Last query "+This.queriedAt+" · "+String(This.elapsedMs)+" ms · "+String(This.rows.length)+" monitor(s)"
	End if
	return "Query failed · "+String(This.lastError.code)

Function _logText()->$text : Text
	var $entries : Collection
	$entries:=New collection
	var $i : Integer
	For ($i; 1; This.log.length)
		$entries.push(This.log[$i-1])
	End for
	$text:=$entries.join(Char(13))

Function _appendLog($message : Text)
	var $entry : Collection
	$entry:=New collection(String(Current time)+"  "+$message)
	$entry.combine(This.log)
	This.log:=$entry
	If (This.log.length>40)
		This.log.remove(40; This.log.length-40)
	End if

Function _buildRows($value : Object)->$rows : Collection
	var $mac : Boolean
	var $m; $b; $row : Object
	$mac:=($value.platform="macos")
	$rows:=New collection
	For each ($m; $value.monitors)
		$b:=$m.bounds
		$row:=New object
		$row.device:=$m.device
		$row.deviceLabel:=$m.primary ? ($m.device+"  ★") : $m.device
		$row.scaleLabel:=String(Int($m.scalePercent+0.5))+"%"
		$row.primaryLabel:=$m.primary ? "Primary" : ""
		If ($mac)
			$row.sizeLabel:=String($b.right-$b.left)+" × "+String($b.bottom-$b.top)+" pt"
			$row.modeLabel:=String($m.nativePixels.width)+" × "+String($m.nativePixels.height)+" px"
		Else
			$row.sizeLabel:=String($b.right-$b.left)+" × "+String($b.bottom-$b.top)+" px"
			$row.modeLabel:=String($m.dpi)+" dpi"
		End if
		$row.monitor:=$m
		$rows.push($row)
	End for each

Function mapHTML()->$html : Text
	var $bg; $fg; $muted; $line; $card : Text
	$bg:="#F5F5F7"
	$fg:="#1D1D1F"
	$muted:="#6E6E73"
	$line:="#D1D1D6"
	$card:="#FFFFFF"
	$html:="<!DOCTYPE html><html><head><meta charset='utf-8'><style>"
	$html+=":root{color-scheme:light dark;--bg:"+$bg+";--fg:"+$fg+";--muted:"+$muted+";--line:"+$line+";--card:"+$card+";}"
	$html+="@media (prefers-color-scheme: dark){:root{--bg:#1C1C1E;--fg:#F2F2F7;--muted:#98989D;--line:#3A3A3C;--card:#2C2C2E;}}"
	$html+="*{box-sizing:border-box}html,body{height:100%;margin:0;background:var(--bg);color:var(--fg);font-family:-apple-system,'Segoe UI',sans-serif;overflow:hidden}"
	$html+=".head{display:flex;justify-content:space-between;align-items:baseline;padding:12px 18px 0;font-size:12px;color:var(--muted)}"
	$html+=".head b{font-size:13px;color:var(--fg);font-weight:600}"
	$html+=".empty{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;align-items:center;justify-content:center;text-align:center;padding:24px}"
	$html+=".empty .code{font-family:ui-monospace,Menlo,monospace;font-size:12px;color:#FF9F0A}"
	$html+="svg{display:block}</style></head><body>"
	If (This.rows.length=0)
		$html+="<div class='empty'><div class='code'>"+(This.lastError#Null ? String(This.lastError.code) : "no monitors")+"</div>"
		$html+="<div>"+(This.lastError#Null ? String(This.lastError.message) : "The component returned no active monitor.")+"</div></div>"
		$html+="</body></html>"
		return $html
	End if
	var $unit : Text
	$unit:=(This.value.platform="macos") ? "points" : "pixels"
	$html+="<div class='head'><span><b>Desktop layout</b> · bounds in "+$unit+"</span><span>"+String(This.rows.length)+" display(s)</span></div>"
	// Fit every monitor's bounds into the 628x248 area.
	var $minX; $minY; $maxX; $maxY : Real
	var $b : Object
	var $first : Boolean
	$first:=True
	For each ($row_ref; This.rows)
		$b:=$row_ref.monitor.bounds
		If ($first)
			$minX:=$b.left
			$maxX:=$b.right
			$minY:=$b.top
			$maxY:=$b.bottom
			$first:=False
		Else
			If ($b.left<$minX)
				$minX:=$b.left
			End if
			If ($b.top<$minY)
				$minY:=$b.top
			End if
			If ($b.right>$maxX)
				$maxX:=$b.right
			End if
			If ($b.bottom>$maxY)
				$maxY:=$b.bottom
			End if
		End if
	End for each
	var $spanX; $spanY; $availW; $availH; $k; $offX; $offY : Real
	$spanX:=$maxX-$minX
	$spanY:=$maxY-$minY
	$availW:=588
	$availH:=172
	$k:=$availW/$spanX
	If (($availH/$spanY)<$k)
		$k:=$availH/$spanY
	End if
	$offX:=20+(588-$spanX*$k)/2
	$offY:=44+(172-$spanY*$k)/2
	var $i : Integer
	var $x; $y; $w; $h : Real
	var $color; $label; $pct : Text
	var $colors : Collection
	$colors:=New collection("#5E5CE6"; "#30D158"; "#FF9F0A"; "#FF375F"; "#64D2FF")
	$html+="<svg width='628' height='248' viewBox='0 0 628 248' xmlns='http://www.w3.org/2000/svg'>"
	For ($i; 1; This.rows.length)
		$b:=This.rows[$i-1].monitor.bounds
		$x:=$offX+($b.left-$minX)*$k
		$y:=$offY+($b.top-$minY)*$k
		$w:=($b.right-$b.left)*$k
		$h:=($b.bottom-$b.top)*$k
		$color:=$colors[($i-1)%5]
		$label:=This._shortDevice(This.rows[$i-1].device)
		$pct:=String(Int(This.rows[$i-1].monitor.scalePercent+0.5))+"%"
		$html+="<rect x='"+String($x; "###0.0")+"' y='"+String($y; "###0.0")+"' width='"+String($w; "###0.0")+"' height='"+String($h; "###0.0")+"' rx='10' fill='"+$color+"' fill-opacity='0."+((This.selectedIndex=$i-1) ? "95" : "68")+"' stroke='"+((This.selectedIndex=$i-1) ? "#0A84FF" : $color)+"' stroke-width='"+((This.selectedIndex=$i-1) ? "3" : "1")+"'/>"
		$html+="<text x='"+String($x+$w/2; "###0.0")+"' y='"+String($y+$h/2-2; "###0.0")+"' text-anchor='middle' font-size='13' font-weight='600' fill='#FFFFFF'>"+$label+"</text>"
		$html+="<text x='"+String($x+$w/2; "###0.0")+"' y='"+String($y+$h/2+14; "###0.0")+"' text-anchor='middle' font-size='11' fill='#FFFFFF' fill-opacity='0.92'>"+$pct+(This.rows[$i-1].monitor.primary ? " · primary" : "")+"</text>"
	End for
	$html+="</svg></body></html>"
	return $html

Function _shortDevice($device : Text)->$short : Text
	var $pos : Integer
	$pos:=Position("\\"; $device; *)
	While ($pos>0)
		$device:=Substring($device; $pos+1)
		$pos:=Position("\\"; $device; *)
	End while
	$short:=$device
	If (Length($short)>18)
		$short:=Substring($short; 1; 17)+"…"
	End if
	return $short
