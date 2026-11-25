// Recompute both platform formulas for the current lab inputs and refresh
// the big readout plus the bar visualisation.
#DECLARE()

var $mac; $win : Real
var $platform : Text

$platform:=Is macOS ? "macOS" : "Windows"

If (Form.lab.pointsWidth>0)
	$mac:=Form.lab.nativeWidth/Form.lab.pointsWidth*100
Else
	$mac:=0
End if
If (Form.lab.dpi>0)
	$win:=Form.lab.dpi/96*100
Else
	$win:=0
End if

Form.lab.mac:=$mac
Form.lab.win:=$win

OBJECT SET TITLE(*; "labBig"; String(Is macOS ? $mac : $win; "###0.0")+"%")
OBJECT SET TITLE(*; "labCaption"; "effective scale on "+$platform+" for these inputs")
OBJECT SET TITLE(*; "labMac"; "macOS    "+String(Form.lab.nativeWidth)+" px ÷ "+String(Form.lab.pointsWidth)+" pt = "+String($mac; "###0.0")+"%")
OBJECT SET TITLE(*; "labWin"; "Windows  "+String(Form.lab.dpi)+" dpi ÷ 96 = "+String($win; "###0.0")+"%")

WA SET PAGE CONTENT(*; "LabVisual"; Demo_LabHTML(Form.lab); "")
