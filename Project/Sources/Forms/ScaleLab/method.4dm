// ScaleLab form method. The two platform formulas are recomputed on every
// data change so the relationship between panel pixels, points and dpi is
// visible while typing.
#DECLARE($params : Object)

Case of

	: (FORM Event.code=On Load)
		// A form method cannot assign Form itself, so Demo_OpenLab always
		// passes {lab; ...}. Guard here only documents the contract.
		If (Value type(Form)=Is object)
			If (Value type(Form.lab)=Is object)
				Demo_LabUpdate()
			End if
		End if

	: (FORM Event.code=On Data Change)
		Demo_LabUpdate()

	: (FORM Event.code=On Clicked)
		var $name : Text
		$name:=FORM Event.objectName
		Case of

			: ($name="btnClose")
				CANCEL

			: ($name="btnUseDisplay")
				Demo_LabUseCurrent
				Demo_LabUpdate()

			: ($name="presetRetina")
				Form.lab.nativeWidth:=3024
				Form.lab.pointsWidth:=1512
				Form.lab.dpi:=120
				Demo_LabUpdate()

			: ($name="presetMore")
				Form.lab.nativeWidth:=3024
				Form.lab.pointsWidth:=1800
				Form.lab.dpi:=120
				Demo_LabUpdate()

			: ($name="presetWin125")
				Form.lab.nativeWidth:=3840
				Form.lab.pointsWidth:=1920
				Form.lab.dpi:=120
				Demo_LabUpdate()

			: ($name="presetWin150")
				Form.lab.nativeWidth:=3840
				Form.lab.pointsWidth:=1920
				Form.lab.dpi:=144
				Demo_LabUpdate()

		End case

End case
