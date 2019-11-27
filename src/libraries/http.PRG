set procedure to Http additive 

define class Http as Custom 
	
	HTTPRequest = .null.
	
	procedure init
		this.HTTPRequest = createobject("WinHttp.WinHttpRequest.5.1")
	endproc 
	
	procedure open
		lparameters cMethod, cUrl, lAsync
		
		this.HTTPRequest.Open(cMethod, cUrl, lAsync)
	endproc 
	
	procedure setRequestHeader
		lparameters cHeader, cValue
		
		this.HTTPRequest.SetRequestHeader(cHeader, cValue)
	endproc 
	
	procedure send
		lparameters cBody, cResponsetext
		
		if empty(cBody)
			cBody = ""
		endif 
		
		this.HTTPRequest.Send(cBody)
		
		cResponsetext = this.HTTPRequest.Responsetext
		
		return this.HTTPRequest.status = 200
	endproc 
enddefine 