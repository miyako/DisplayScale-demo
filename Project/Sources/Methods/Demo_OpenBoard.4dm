// Initial window of the demo: window reuse, then the MonitorBoard form in
// worker 1. Called by On Startup and by the Demo menu.
#DECLARE($params : Object)

var $title : Text
var $window : Integer
$title:="DisplayScale — Monitor Board"

If (Count parameters=0)
	// Re-running the method (menu, second startup) brings the existing window
	// to the front instead of opening a duplicate.
	ARRAY LONGINT($windows; 0)
	WINDOW LIST($windows)
	var $i : Integer
	For ($i; 1; Size of array($windows))
		$window:=$windows{$i}
		If (Window process($window)=1) && (Get window title($window)=$title)
			var $left; $top; $right; $bottom : Integer
			GET WINDOW RECT($left; $top; $right; $bottom; $window)
			CALL FORM($window; Formula(SET WINDOW RECT($left; $top; $right; $bottom; $window)))
			return
		End if
	End for

	CALL WORKER(1; Current method name; {})

Else
	SET MENU BAR(1)
	$window:=Open form window("MonitorBoard"; Plain form window; Horizontally centered; Vertically centered)
	SET WINDOW TITLE($title; $window)
	DIALOG("MonitorBoard"; $params; *)
End if
