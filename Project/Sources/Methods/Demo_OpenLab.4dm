// Opens the Scale Lab window from the board, the menu, or a startup script.
// $params.lab is an optional prefill: {nativeWidth; pointsWidth; dpi}.
#DECLARE($params : Object)

var $title : Text
var $window : Integer
var $left; $top; $right; $bottom : Integer
$title:="DisplayScale — Scale Lab"

// One lab window at a time: bring the existing one forward.
ARRAY LONGINT($windows; 0)
WINDOW LIST($windows)
var $i : Integer
For ($i; 1; Size of array($windows))
	$window:=$windows{$i}
	If (Window process($window)=1) && (Get window title($window)=$title)
		GET WINDOW RECT($left; $top; $right; $bottom; $window)
		SET WINDOW RECT($left; $top; $right; $bottom; $window)
		return
	End if
End for

var $form : Object
If ((Count parameters>0) && (Value type($params)=Is object) && (Value type($params.lab)=Is object))
	$form:=$params
Else
	$form:=New object("lab"; New object("nativeWidth"; 3024; "pointsWidth"; 1512; "dpi"; 120))
End if

$window:=Open form window("ScaleLab"; Plain form window; Horizontally centered; Vertically centered)
SET WINDOW TITLE($title; $window)
DIALOG("ScaleLab"; $form; *)
