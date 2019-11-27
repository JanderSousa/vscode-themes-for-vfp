clear

oColor = createobject("Color")
?oColor.Hex2Rgb2Register("#333", "")

define class Color as custom

	procedure Hex2Rgb2Register
		lparameters cHexForeColor, cHexBackColor
		
		local i, nPos, cReturn, cValue
 
		do case
			case empty(cHexForeColor) and empty(cHexBackColor)
				cForeColor = "RGB(0,0,0)"
				cBackColor = "RGB(255, 255, 255)"
			
			case empty(cHexForeColor)
				cBackColor = this.Hex2RGB(cHexBackColor)
				
				if cBackColor = "error"
					return "rgb(0, 0, 0, 255, 255, 255), NoAuto, NoAuto"
				endif 
				
				cForeColor = this.invertColor(&cBackColor)

			case empty(cHexBackColor)
				cForeColor = this.Hex2RGB(cHexForeColor)
				
				if cForeColor = "error"
					return "rgb(0, 0, 0, 255, 255, 255), NoAuto, NoAuto"
				endif
								
				cBackColor = this.invertColor(&cForeColor)
			
			otherwise 
				cForeColor = this.Hex2RGB(cHexForeColor)
				
				if cForeColor = "error"
					return "rgb(0, 0, 0, 255, 255, 255), NoAuto, NoAuto"
				endif
								
				cBackColor = this.Hex2RGB(cHexBackColor)
				
		endcase 

		cReturn = substr(cForeColor, 1, len(cForeColor) - 1) + "," + substr(cBackColor, 5)				

		return cReturn + ", NoAuto, NoAuto"
	endproc
	
	procedure invertColor
		lparameters nColor
		
		local R, G, B, nNewColor 
		
		nNewColor = rgb(255, 255, 255) - nColor
		R = Mod(nNewColor, 256)
		G = Mod(Int(nNewColor / 256), 256)
		B = Mod(Int(nNewColor / 65536), 256)

		return textmerge("RGB(<<R>>, <<G>>, <<B>>)")		
		
	endproc 
	
	procedure Hex2RGB
		lparameters cHexString
		
		local cReturn, nPos, i, cValue 
		
		if len(cHexString) = 4
			cHexString = cHexString + substr(cHexString, 2)
		endif 		
		
		cHexString = substr(cHexString, 1, 7)
		
		if len(cHexString) != 7 or cHexString != "#"
			return "error"		
		endif 			
		
		cReturn = "RGB("
		nPos = 2
		for i = 1 to 3
			cValue = this.Hex2Dec(substr(cHexString, nPos, 2))
			if i != 3
				cReturn = cReturn + cValue + ", "
			else
				cReturn = cReturn + cValue + ")"
			endif
			nPos = nPos + 2
		next	
		
		return cReturn	
	endproc 

	procedure Hex2Dec
		lparameters cHexString
		local i, cChar, nLen, nSum, nPos

		nLen = len(cHexString)
		nSum = 0
		nPos = 0
		for i = 1 to nLen
			cChar = substr(cHexString, nLen - nPos, 1)
			do case
				case upper(cChar) = [A]
					cChar = [10]
				case upper(cChar) = "B"
					cChar = [11]
				case upper(cChar) = [C]
					cChar = [12]
				case upper(cChar) = [D]
					cChar = [13]
				case upper(cChar) = [E]
					cChar = [14]
				case upper(cChar) = [F]
					cChar = [15]
			endcase
			nSum = nSum + val(upper(cChar)) * 16 ^ (i - 1)
			nPos = nPos + 1
		next

		return transform(nSum)

	endproc

enddefine