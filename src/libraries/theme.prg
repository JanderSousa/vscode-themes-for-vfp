#DEFINE VFP_OPTIONS_KEY1	"Software\Microsoft\VisualFoxPro\"
#DEFINE VFP_OPTIONS_KEY2	"\Options"
#DEFINE HKEY_CURRENT_USER	-2147483647  && BITSET(0,31)+1

do declarelibraries

with createobject("Theme")
	.setTheme("8fd32a64-6d85-4818-ac27-a0a61ee9f612\dracula")
endwith

return

DEFINE CLASS Theme as Custom

	oJson = .null.
	oColor = .null.

	cDirHome = Sys(5) + sys(2003)
	cPathTheme = Sys(5) + sys(2003) + "\theme"
	DIMENSION aEditorColors[1, 2]

	cVFPOptPath = VFP_OPTIONS_KEY1 + _vfp.version + VFP_OPTIONS_KEY2

	procedure init
		this.oJson = createobject("Json")
		this.oColor = createobject("Color")
	endproc

	procedure setTheme
		lparameters cFileTheme

		local cEntry, cTheme, cEditorForeGround, cEditorBackGround, cColorToRegister, cForeGround, cStyle, cEntryStyle
		local oJsonDecoded, oColors
		local i, j

		cTheme = this.getTheme(cFileTheme)

		oJsonDecoded = this.oJson.Decode(cTheme)

		if isnull(oJsonDecoded)
			return .f.
		endif

		oColors = oJsonDecoded.get("colors", .null.)

		cEditorForeGround = oColors.get("editor_foreground", "")
		cEditorBackGround = oColors.get("editor_background", "")

		cColorToRegister = this.oColor.Hex2Rgb2Register(cEditorForeGround, cEditorBackGround)

		if cColorToRegister = "error"
			return .F.
		endif

		this.addInArray("EditorNormalColor", cColorToRegister)
		this.addInArray("EditorOperatorColor", cColorToRegister)
		this.addInArray("EditorVariableColor", cColorToRegister)
		this.addInArray("EditorStringColor", cColorToRegister)
		this.addInArray("EditorCommentColor", cColorToRegister)
		this.addInArray("EditorKeywordColor", cColorToRegister)
		this.addInArray("EditorConstantColor", cColorToRegister)

		oTokenColors = oJsonDecoded.get("tokenColors", .null.)

		if isnull(oTokenColors) or vartype(oTokenColors) != "O"
			return .F.
		endif

		for each oToken in oTokenColors.array
			cForeGround = ""
			uScope = oToken.get("scope")
			if vartype(uScope) = "C"
				oSettings = oToken.get("settings")
				for i=1 to getwordcount(uScope, ",")
					this.getColors(alltrim(getwordnum(uScope, i, ",")), oSettings, @cForeGround, @cEntry, @cStyle, @cEntryStyle)
					if !empty(cForeGround)
						cColorToRegister = this.oColor.Hex2Rgb2Register(cForeGround, cEditorBackGround)
						if cColorToRegister = "error"
							return .f.
						endif

						this.addInArray(cEntry, cColorToRegister)
					endif

					if !empty(cStyle)
						this.addInArray(cEntryStyle, cStyle)
					endif
				next
			else
				if vartype(uScope) = "O" and pemstatus(uScope, "Array", 5)
					oSettings = oToken.get("settings")
					for i=1 to alen(uScope.array, 1)
						scope = uScope.array[i]
						for j=1 to getwordcount(scope, ",")
							this.getColors(alltrim(getwordnum(scope, j, ",")), oSettings, @cForeGround, @cEntry, @cStyle, @cEntryStyle)

							if !empty(cForeGround)
								if cColorToRegister = "error"
									return .f.
								endif

								cColorToRegister = this.oColor.Hex2Rgb2Register(cForeGround, cEditorBackGround)
								this.addInArray(cEntry, cColorToRegister)
							endif

							if !empty(cStyle)
								this.addInArray(cEntryStyle, cStyle)
							endif
						next
					next

				endif
			endif
		next

		this.register()
		this.update()
	endproc

	procedure update
		this.setScreenColors()

		sys(3056)

		cd (this.cDirHome)
	endproc

	procedure getColors
		lparameters cScope, oSettings, cForeGround, cEntry, cStyle, cEntryStyle

		local cFontStyle, cWord
		store "" to cWord, cForeGround, cEntry, cStyle, cEntryStyle

		cScope = lower(cScope)

		do case
			case cScope == "string" or cScope == "string.quoted"
				cWord = "String"

			case cScope == "comment"
				cWord = "Comment"

			case cScope == "keyword"
				cWord = "Keyword"

			case cScope == "constant" or cScope == "constant.numeric"
				cWord = "Constant"

			case cScope == "keyword.operator"
				cWord = "Operator"
		endcase

		if !empty(cWord)
			cForeGround = oSettings.get("foreground")
			cFontStyle = oSettings.get("fontStyle", "")
			cEntry = textmerge("Editor<<cWord>>Color")
			cEntryStyle = textmerge("Editor<<cWord>>Style")

			if !empty(cForeGround)
				do case
					case empty(cFontStyle)
						cStyle = "-1"
					case lower(cFontStyle) = "normal"
						cStyle = "0"
					case lower(cFontStyle) = "bold"
						cStyle = "1"
					case lower(cFontStyle) = "italic"
						cStyle = "2"
				endcase
			endif
		endif

	endproc

	procedure register

		local oRegApi
		local i
		local cRegKey

		oRegApi = newobject("Registry", home() + "FFC\Registry.VCX")

		for i=1 to alen(this.aEditorColors, 1)
			oRegApi.SetRegKey(this.aEditorColors[i, 1], this.aEditorColors[i, 2], this.cVFPOptPath, HKEY_CURRENT_USER, .t.)
		endfor

		return .t.

	endproc

	procedure addInArray
		lparameters cEntry, cRegValue

		local nIndex
		nIndex = ascan(this.aEditorColors, cEntry, 1, -1, 1, 15)

		if nIndex = 0
			if empty(this.aEditorColors)
				this.aEditorColors[1, 1] = cEntry
				nIndex = 1
			else
				nIndex = alen(this.aEditorColors, 1) + 1
				dimension this.aEditorColors[nIndex, 2]
				this.aEditorColors[nIndex, 1] = cEntry
			endif
		endif

		this.aEditorColors[nIndex, 2] = cRegValue

	endproc

	procedure getTheme
		lparameters cFileTheme

		local cTheme
		cTheme = ""
		cFileTheme = addbs(this.cPathTheme) + forceext(cFileTheme, "json")
		if file(cFileTheme)
			cTheme = chrtran(filetostr(cFileTheme), "/$", "")
		endif

		return cTheme
	endproc

	function setScreenColors
		local cEditorVariableColor, cForeColor, cBackColor, cRegKey
		local oRegApi

		oRegApi = newobject("Registry", home() + "FFC\Registry.VCX")

		oRegApi.getregkey("EditorVariableColor", @cEditorVariableColor, this.cVFPOptPath, HKEY_CURRENT_USER)

		cForeColor = substr(cEditorVariableColor, 5, at(",", cEditorVariableColor, 3) - 5)
		cBackColor = substr(cEditorVariableColor, at(",", cEditorVariableColor, 3) + 1, at(")", cEditorVariableColor, 1) - at(",", cEditorVariableColor, 3) - 1)

		_screen.forecolor = rgb(&cForeColor)
		_screen.backcolor = rgb(&cBackColor)

	endfunc

enddefine