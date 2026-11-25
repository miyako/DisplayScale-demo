// Read the live primary monitor through the component and prefill the lab.
#DECLARE()

var $display : Object
var $result : Object
var $monitor : Object

$display:=cs.DisplayScale.Display.new(Is Windows ? "Windows-x64" : "macOS-universal")
$result:=$display.monitors()

If ($result.ok)
	If ($result.value.monitors.length>0)
		$monitor:=$result.value.monitors[0]
		If ($result.value.platform="macos")
			Form.lab.nativeWidth:=$monitor.nativePixels.width
			Form.lab.pointsWidth:=$monitor.bounds.right-$monitor.bounds.left
		Else
			Form.lab.nativeWidth:=3840
			Form.lab.pointsWidth:=1920
			Form.lab.dpi:=$monitor.dpi
		End if
	End if
End if
