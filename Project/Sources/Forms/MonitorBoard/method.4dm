// MonitorBoard form method. Every button and the list box are routed here so
// the interactive surface is easy to follow: query, select, copy, probe, lab.
#DECLARE($params : Object)

Case of

	: (FORM Event.code=On Load)
		Form.scene:=cs.DisplayScene.new()
		Form.scene.bindForm()

	: (FORM Event.code=On Clicked)
		var $name : Text
		$name:=FORM Event.objectName
		Case of

			: ($name="btnRefresh")
				Form.scene.query()
				Form.scene.toast:="Fresh query — the CLI runs per call, nothing is cached"
				Form.scene.bindForm()

			: ($name="btnCopy")
				Form.scene.copyJSON()
				Form.scene.bindForm()

			: ($name="btnProbe")
				Form.scene.probeCrossPlatform()
				Form.scene.bindForm()

			: ($name="btnLab")
				Demo_OpenLab(Form.scene.labParams())

			: ($name="monitorList")
				Form.scene.selectRow(Form.selectedRow)
				Form.scene.bindForm()

		End case

End case
