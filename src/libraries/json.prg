set procedure to json.prg additive 

Define Class Json As Custom

	nPos = 0
	nLen = 0
	cJson = ''
	cError = ''

	Procedure encode(xExpr)

		Local cTipo, cProp, cJsonValue, cRetVal, aProp[1], i, nTotElem

		If Type('ALen(xExpr)')=='N'
			cTipo = 'A'
		Else
			cTipo = Vartype(xExpr)
		Endif

		Do Case
			Case cTipo == 'D'
				Return '"' + Dtos(xExpr) + '"'

			Case cTipo == 'N'
				Return Transform(xExpr)

			Case cTipo == 'L'
				Return Iif(xExpr, 'true', 'false')

			Case cTipo == 'X'
				Return 'null'

			Case cTipo == 'C'
				xExpr = Allt(xExpr)
				xExpr = Strtran(xExpr, '\', '\\' )
				xExpr = Strtran(xExpr, '/', '\/' )
				xExpr = Strtran(xExpr, Chr(9),  '\t' )
				xExpr = Strtran(xExpr, Chr(10), '\n' )
				xExpr = Strtran(xExpr, Chr(13), '\r' )
				xExpr = Strtran(xExpr, '"', '\"' )
				Return '"' + xExpr + '"'

			Case cTipo == 'O'
				=Amembers(aProp, xExpr)
				cRetVal = ''
				For Each cProp In aProp

					If Type('xExpr.'+cProp)=='U' Or cProp == 'CLASS'
						Loop
					Endif

					If Type( 'ALen(xExpr.'+cProp+')' ) == 'N'
						cJsonValue = ''
						nTotElem = Eval('ALen(xExpr.'+cProp+')')
						For i=1 To nTotElem
							cmd = 'cJsonValue=cJsonValue+","+ this.encode( xExpr.'+cProp+'[i])'
							&cmd.
						Next
						cJsonValue = '[' + Substr(cJsonValue,2) + ']'
					Else
						cJsonValue = This.encode( Evaluate( 'xExpr.'+cProp ) )
					Endif

					If Left(cProp,1) == '_'
						cProp = Substr(cProp,2)

					Endif

					cRetVal = cRetVal + ',' + '"' + Lower(cProp) + '":' + cJsonValue

				Next

				Return '{' + Substr(cRetVal,2) + '}'

			Case cTipo == 'A'
				Local valor, cRetVal

				cRetVal = ''
				For Each valor In xExpr
					cRetVal = cRetVal + ',' +  This.encode( valor )
				Next

				Return  '[' + Substr(cRetVal,2) + ']'
		Endcase

		Return ''

	Procedure Decode(cJson)

		Local retValue

		cJson = Strtran(cJson,Chr(9),'')
		cJson = Strtran(cJson,Chr(10),'')
		cJson = Strtran(cJson,Chr(13),'')
		cJson = This.fixUnicode(cJson)

		This.nPos  = 1
		This.cJson = cJson
		This.nLen  = Len(cJson)
		This.cError = ''

		retValue = This.parsevalue()

		If Not Empty(This.cError)
			Return .Null.
		Endif

		If This.getToken() != .Null.
			This.setError('Junk at the end of JSON input')
			Return Null
		Endif

		Return retValue
		
	Endproc 
	
	Procedure parsevalue()

		Local token
		token = This.getToken()
		If token == .Null.
			This.setError('Nothing to parse')
			Return .Null.
		Endif

		Do Case
			Case token == '"'
				Return This.parseString()

			Case Isdigit(token) Or token == '-'
				Return This.parseNumber()

			Case token == 'n'
				Return This.expectedKeyword('null', .Null.)

			Case token == 'f'
				Return This.expectedKeyword('false', .F.)

			Case token == 't'
				Return This.expectedKeyword('true', .T.)

			Case token == '{'
				Return This.parseObject()

			Case token == '['
				Return This.parseArray()

			Otherwise
				This.setError('Unexpected token')

		Endcase

	Endproc 

	Procedure expectedKeyword(cWord, eValue)
		Local i, cChar
		
		For i=1 To Len(cWord)
			cChar = This.getChar()

			If cChar != Substr(cWord, i, 1)
				This.setError("Expected keyword '" + cWord + "'")
				Return ''
			Endif

			This.nPos = This.nPos + 1
		Next

		Return eValue
	Endproc 
	
	Procedure parseObject()
		Local retval, cPropName, xValue

		retval = Createobject('myObj')

		This.nPos = This.nPos + 1

		If This.getToken() != '}'

			Do While .T.
				cPropName = This.parseString()

				If Not Empty(This.cError)
					Return .Null.
				Endif

				If This.getToken() != ':'
					This.setError("Expected ':' when parsing object")
					Return .Null.
				Endif

				This.nPos = This.nPos + 1
				xValue = This.parsevalue()

				If Not Empty(This.cError)
					Return .Null.
				Endif

				retval.Set(cPropName, xValue)

				If This.getToken() != ','
					Exit
				Endif

				This.nPos = This.nPos + 1
			Enddo

		Endif

		If This.getToken() != '}'
			This.setError("Expected '}' at the end of object")
			Return .Null.
		Endif

		This.nPos = This.nPos + 1

		Return retval
	Endproc 

	Procedure parseArray()

		Local retval, xValue

		retval = Createobject('MyArray')

		This.nPos = This.nPos + 1    && Eat [

		If This.getToken() != ']'
		
			Do While .T.
				xValue = This.parsevalue()

				If Not Empty(This.cError)
					Return .Null.
				Endif

				retval.Add( xValue )

				If This.getToken() != ','
					Exit
				Endif

				This.nPos = This.nPos + 1
			Enddo

			If This.getToken() != ']'
				This.setError('Expected ] at the end of array')
				Return .Null.
			Endif
			
		Endif

		This.nPos = This.nPos + 1

		Return retval
	Endproc 

	Procedure parseString()

		Local cRetVal, c

		If This.getToken() != '"'
			This.setError('Expected "')
			Return ''
		Endif

		This.nPos = This.nPos + 1    && Eat "

		cRetVal = ''

		Do While .T.
			c = This.getChar()
			If c == ''
				Return ''
			Endif

			If c == '"'
				This.nPos = This.nPos + 1
				Exit
			Endif

			If c == '\'
				This.nPos = This.nPos + 1

				If (This.nPos>This.nLen)
					This.setError('\\ at the end of input')
					Return ''
				Endif

				c = This.getChar()
				If c == ''
					Return ''
				Endif

				Do Case
					Case c == '"'
						c = '"'
					Case c == '\'
						c='\'

					Case c == '/'
						c='/'
						
					Case c == 'b'
						c = Chr(8)

					Case c=='t'
						c = Chr(9)

					Case c == 'n'
						c = Chr(10)

					Case c == 'f'
						c = Chr(12)

					Case c == 'r'
						c = Chr(13)

					Otherwise
						This.setError('Invalid escape sequence in string literal')
						Return ''
				Endcase

			Endif

			cRetVal = cRetVal + c

			This.nPos = This.nPos + 1

		Enddo

		Return cRetVal

	Endproc 

	Procedure parseNumber()

		Local nStartPos, c, isInt, cNumber

		If Not (Isdigit(This.getToken()) Or This.getToken() == '-')
			This.setError('Expected number literal')
			Return 0
		Endif

		nStartPos = This.nPos

		c = This.getChar()

		If c == '-'
			c = This.nextChar()
		Endif

		If c == '0'
			c = This.nextChar()
		Else
			If Isdigit(c)
				c = This.nextChar()
				
				Do While Isdigit(c)
					c = This.nextChar()
				Enddo
			Else
				This.setError('Expected digit when parsing number')
				Return 0
			Endif
		Endif

		isInt = .T.

		If c == '.'
			c = This.nextChar()

			If Isdigit(c)

				c = This.nextChar()

				isInt = .F.

				Do While Isdigit(c)
					c = This.nextChar()
				Enddo
			Else
				This.setError('Expected digit following dot comma')
				Return 0
			Endif
		Endif

		cNumber = Substr(This.cJson, nStartPos, This.nPos - nStartPos)

		Return Val(cNumber)

	Procedure getToken()

		Local char1

		Do While .T.
			If This.nPos > This.nLen
				Return Null
			Endif

			char1 = Substr(This.cJson, This.nPos, 1)

			If char1 == ' '
				This.nPos = This.nPos + 1
				Loop
			Endif

			Return char1
		Enddo
	Endproc 

	Procedure getChar()

		If This.nPos > This.nLen
			This.setError('Unexpected end of JSON stream')
			Return ''
		Endif

		Return Substr(This.cJson, This.nPos, 1)
	Endproc 

	Procedure nextChar()

		This.nPos = This.nPos + 1

		If This.nPos > This.nLen
			Return ''
		Endif

		Return Substr(This.cJson, This.nPos, 1)
	Endproc 

	Procedure setError(cMsg)

		This.cError= 'ERROR parsing JSON at Position:'+Allt(Str(This.nPos,6,0))+' '+cMsg

	Endproc

	Procedure getError()
	
		Return This.cError
		
	Endproc 

	Procedure fixUnicode(cStr)

		cStr = Strtran(cStr,'\u00e1','á')
		cStr = Strtran(cStr,'\u00e9','é')
		cStr = Strtran(cStr,'\u00ed','í')
		cStr = Strtran(cStr,'\u00f3','ó')
		cStr = Strtran(cStr,'\u00fa','ú')
		cStr = Strtran(cStr,'\u00c1','Á')
		cStr = Strtran(cStr,'\u00c9','É')
		cStr = Strtran(cStr,'\u00cd','Í')
		cStr = Strtran(cStr,'\u00d3','Ó')
		cStr = Strtran(cStr,'\u00da','Ú')
		cStr = Strtran(cStr,'\u00f1','ñ')
		cStr = Strtran(cStr,'\u00d1','Ñ')

		Return cStr
	
	Endproc 

Enddefine


*

* class used to return an array

*

Define Class myArray As Custom

	nSize = 0

	Dimension Array[1]

	Procedure Add(xExpr)
		This.nSize = This.nSize + 1

		Dimension This.Array[this.nSize]

		This.Array[this.nSize] = xExpr

		Return
	Endproc 

	Procedure Get(n)
		Return This.Array[n]
	Endproc 	

	Procedure getsize()
		Return This.nSize
	Endproc 	

Enddefine


Define Class myObj As Custom

	Hidden ;
		ClassLibrary,Comment, ;
		BaseClass,ControlCount, ;
		Controls,Objects,Object,;
		Height,HelpContextID,Left,Name, ;
		Parent,ParentClass,Picture, ;
		Tag,Top,WhatsThisHelpID,Width

	Procedure Set(cPropName, xValue)

		Local nLen, cmd, i
		cPropName = '_' + cPropName
		cPropName = Chrtran(cPropName, ".-:@/", "_____")
		
		if cPropName = "_include"
			return 
		endif 

		Do Case

			Case Type('ALen(xValue)') == 'N'
				This.AddProperty(cPropName + '(1)')
				nLen = Alen(xValue)
				cmd = 'Dimension This.' + cPropName + ' [ ' + Str(nLen, 10, 0) + ']'
				&cmd.

				For i=1 To nLen
					cmd = 'This.'+cPropName+ ' [ '+Str(i,10,0)+'] = xValue[i]'
					&cmd.
				Next

			Case Type('this.'+cPropName) == 'U'
				This.AddProperty(cPropName, @xValue)
				
			Otherwise
				cmd = 'this.'+cPropName+'=xValue'
				&cmd
		Endcase

	Endproc 

	Procedure Get (cPropName, uDefault)
		
		Local cmd
		cPropName = '_' + cPropName

		If Type('this.' + cPropName) == 'U'
			Return uDefault
		Else
			cmd = 'return this.'+cPropName
			&cmd
		Endif

		Return uDefault

	Endproc

Enddefine