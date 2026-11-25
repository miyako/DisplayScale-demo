// Bar visualisation for the Scale Lab: the native panel width is the full
// width, the UI width is the same panel divided by the scale factor.
#DECLARE($lab : Object)->$html : Text

var $native; $points; $ratio; $barW; $uiW : Real
$native:=$lab.nativeWidth
$points:=$lab.pointsWidth
If ($native<=0)
	$native:=1
End if
$ratio:=$points/$native
$barW:=592
$uiW:=$barW*$ratio
If ($uiW>$barW)
	$uiW:=$barW
End if

$html:="<!DOCTYPE html><html><head><meta charset='utf-8'><style>"
$html+=":root{color-scheme:light dark}"
$html+="html,body{margin:0;background:#FFFFFF;color:#1D1D1F;font-family:-apple-system,'Segoe UI',sans-serif;overflow:hidden}"
$html+="@media (prefers-color-scheme: dark){html,body{background:#2C2C2E;color:#F2F2F7}}"
$html+="text{font-family:inherit}</style></head><body>"
$html+="<svg width='656' height='124' viewBox='0 0 656 124' xmlns='http://www.w3.org/2000/svg'>"
$html+="<text x='16' y='18' font-size='11' font-weight='600' fill='currentColor'>Native panel · "+String($lab.nativeWidth)+" px</text>"
$html+="<rect x='16' y='24' width='"+String($barW; "###0")+"' height='20' rx='10' fill='#5E5CE6'/>"
$html+="<text x='28' y='38' font-size='11' fill='#FFFFFF'>"+String($lab.nativeWidth)+" px wide</text>"
$html+="<text x='16' y='68' font-size='11' font-weight='600' fill='currentColor'>UI width · "+String($lab.pointsWidth)+" pt</text>"
$html+="<rect x='16' y='74' width='"+String($uiW; "###0")+"' height='20' rx='10' fill='#30D158'/>"
If ($uiW>120)
	$html+="<text x='28' y='88' font-size='11' fill='#FFFFFF'>"+String($lab.pointsWidth)+" pt laid out</text>"
End if
$html+="<line x1='"+String(16+$barW; "###0")+"' y1='20' x2='"+String(16+$barW; "###0")+"' y2='98' stroke='#98989D' stroke-width='1' stroke-dasharray='3 3'/>"
$html+="<text x='620' y='68' font-size='20' font-weight='700' fill='#0A84FF' text-anchor='end'>"+String($lab.mac; "###0.0")+"%</text>"
$html+="<text x='620' y='88' font-size='10' fill='#98989D' text-anchor='end'>panel ÷ points</text>"
$html+="<text x='16' y='114' font-size='10' fill='#98989D'>Each UI point is backed by "+String($native/($points>0 ? $points : 1); "###0.00")+" panel pixels.</text>"
$html+="</svg></body></html>"
