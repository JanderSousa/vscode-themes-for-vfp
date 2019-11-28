#DEFINE URL_SEARCH "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery"

do declarelibraries 

with createobject("Main")

	.getAllThemesInstalledFromId("f85e1d5d-e4e2-4428-9363-4084e04f8439", "lixo")
	retu
	.setTheme("8fd32a64-6d85-4818-ac27-a0a61ee9f612")
	retu
	.setTheme("fbb3d024-f8f2-460c-bdb5-99552f6d8c4b", "Dracula.json")
endwith 	



define class Main as Custom 
	
	oHTTP = .null.
	oJson = .null.
	oWsh = .null.
	oTheme = .null.
	
	cDirHome = sys(5) + sys(2003)
	cDirDownload = sys(5) + sys(2003) + "\download"
	cDirTheme = sys(5) + sys(2003) + "\theme"
	nPageSize = 30
	
	nDataSessionId = 1
	
	procedure init 
		lparameters nDataSessionId
		
		this.setDataSession(nDataSessionId)
		
		DECLARE Sleep IN Win32API INTEGER
		
		this.oHTTP = createobject("Http")
		this.oJson = createobject("Json")
		this.oTheme = createobject("theme")
		
	endproc 
	
	procedure setDataSession(nDataSessionId)
		if !empty(nDataSessionId)
			this.nDataSessionId  = nDataSessionId
		endif 	
		set datasession to (this.nDataSessionId)
	endproc 
	
	procedure getAllThemesInstalledFromId
		lparameters cPublisherId, cAlias
		
		local aFiles[1]
		
		create cursor (cAlias) (PublisherId c(40), File c(50))
		
		if this.getJson(cPublisherId, @aFiles)
			
			select (cAlias)
			for i=1 to alen(aFiles, 1)	
				append blank 
				replace PublisherId with cPublisherId,;
						File with juststem(aFiles[i, 1])
			next 
		else
			return .F.	
		endif 
		
	endproc 
	
	procedure getAllThemesInstalled
		lparameters cAlias
		
		local aDirectory[1], cName, cType, cFullName, cDir, nDir, i    
		
		this.dataStruct(cAlias)
		
		cDir = addbs(this.cDirTheme)
		nDir = adir(aDirectory, addbs(this.cDirTheme) + "*.*", "D")
		
		for i=1 to nDir
			cName = aDirectory[i, 1]
			cType = aDirectory[i, 5]
			cFullName = addbs(cDir + cName) + "info.xml"
			
			if "D" $ cType and cName != "."
				
				if file(cFullName)
					xmltocursor(filetostr(cFullName), "tmpInfo")
					select (cAlias)
					append from dbf("tmpInfo")
				endif 
					
			endif 
		next 
		
		use in select("tmpInfo")
	endproc 
	
	procedure searchTheme
		lparameters cSearch, nPage
		
		local cResponse, cBody

		if empty(cSearch)
			return .null.
		endif 
		
		cBody = this.resolveBody(cSearch, nPage)
		
		with this.oHTTP
			.open("POST", URL_SEARCH)
			.setRequestHeader('Content-Type','application/json')
			.setRequestHeader('Accept','application/json;api-version=3.0-preview.1')
			
			if !.send(cBody, @cResponse)
				return .null.
			endif 
			
			return this.oJson.decode(cResponse)
		endwith 
		
	endproc 
	
	procedure setTheme
		lparameters cPublisherId, cFileJson
		
		cPublisherId = alltrim(cPublisherId)
		
		if empty(cFileJson)
			return 
		endif 
		
		this.oTheme.setTheme(addbs(cPublisherId) + cFileJson)

	endproc 
	
	procedure getJson
		lparameters cPublisherId, aFiles
		
		dimension aFiles[1]
		
		if adir(aFiles, addbs(this.cDirTheme) + addbs(cPublisherId) + "*.json", "A") > 0
			return .T.
		else
			return .F.	
		endif 
		
	endproc 
	
	procedure getManifest
		lparameters cManifestUrl
		local cResponse
		
		if empty(cManifestUrl)
			return .null.
		endif 
		
		cResponse = this.getUrl(cManifestUrl)
		if isnull(cResponse)
			return .null.
		endif 
		return this.oJson.decode(cResponse)
	endproc 
	
	procedure getDetails
		lparameters cDetailUrl
		
		if empty(cDetailUrl)
			return .null.
		endif 
		
		return this.getUrl(cDetailUrl)
	endproc 	
	
	procedure getUrl
		lparameters cUrl
		
		cUrl = alltrim(cUrl)
		
		local cResponse
		
		with this.oHTTP
			.open("GET", cUrl)
			if !.send(.F., @cResponse)
				return .null.
			endif 
			
			return cResponse
		endwith 
	endproc	
	
	procedure dataStruct
		lparameters cAlias
		
		create cursor (cAlias) (publisherId c(40), displayName c(40), publisherDisplayName c(40), shortDescription c(100), fileManifest c(240), fileDetails c(240))
		
	endproc
	
	procedure appendResult
		lparameters cAlias, oJson
		
		local oResults, oExtensions, i, j, oPublisher, oVersions, oFiles, cFileDetails, cFileDetails
		
		this.dataStruct(cAlias)
		
		oResults = oJson.get("results", .null.)
		if isnull(oResults)
			return .F.
		endif 
		
		oExtensions = oResults.array[1]._extensions

		for each oExtension in oExtensions.array
			
			if vartype(oExtension) != "O"
				loop
			endif 
			
			oPublisher = oExtension.get("publisher", .null.)
			if isnull(oPublisher)
				loop 
			endif 
			
			oVersions = oExtension.get("versions", .null.)
			if isnull(oVersions)
				loop
			endif 
			
			cFileManifest = ""
			cFileDetails = ""
			for i=1 to alen(oVersions.array, 1)
				oVersion = oVersions.array[i]
				oFiles = oVersion.get("files")
			
				for j=1 to alen(oFiles.array, 1)
					oFile = oFiles.array[j]
					if oFile.get("assetType", "") = "Microsoft.VisualStudio.Code.Manifest"
						cFileManifest = oFile.get("source", "")
					else
						if oFile.get("assetType", "") = "Microsoft.VisualStudio.Services.Content.Details"
							cFileDetails = oFile.get("source", "")
						endif 	
					endif 
				next 				
			next 

			append blank in (cAlias)
			replace publisherId with oPublisher.get("publisherId", ""),;
					displayName with oExtension.get("displayName", ""),;
					publisherDisplayName with oPublisher.get("displayName", ""),;
					shortDescription with oExtension.get("shortDescription", ""),;
					fileManifest with cFileManifest,;
					fileDetails with cFileDetails in (cAlias)
		next 		
		
	endproc  
	
	procedure cloneDirectory
		lparameters cSourceUrl

		local cCurrentDirectory 
		cCurrentDirectory = sys(5) + sys(2003)
		
		if !directory(this.cDirDownload)
			mkdir (this.cDirDownload)
		endif 
		
		with createobject("wscript.shell")
			.CurrentDirectory = this.cDirDownload
			.Run(textmerge("git clone <<cSourceUrl>>"), 0)
			Sleep(2000)
		endwith 
		
		cd (cCurrentDirectory)
	endproc 
	
	procedure getRepositoryName
		lparameters cRepositoryUrl
		
		if lower(right(cRepositoryUrl, 4)) != ".git"
			return justfname(cRepositoryUrl)
		endif 
		
		return juststem(cRepositoryUrl)
	endproc 
	
	procedure install
		lparameters oExtension

		local cRepository, lReturn 
		
		cPublisherId = alltrim(oExtension.PublisherId)
		cFileManifest = alltrim(oExtension.FileManifest)		
		
		if empty(cFileManifest)
			return 
		endif 
		
		if empty(cPublisherId)
			return 
		endif 
		
		with this
			oJson = .getManifest(cFileManifest)
			if isnull(oJson)
				return .F.
			endif 
			
			oRepository = oJson.get("repository", .null.)		
			if isnull(oRepository)
				return .F.
			endif 
			
			cRepository = oRepository.get("url")
			cRepository = strextract(cRepository, "http", "", 1, 5)

			if empty(cRepository)
				messagebox("Git repository not found.")
				return .F.
			endif 

			.cloneDirectory(cRepository)

			cPath = addbs(.cDirDownload) + .getRepositoryName(cRepository)
			if !.build(cPath, oJson._contributes._themes.array[1]._path)
				return .F.
			endif 
			
			lReturn = .T.
			for each theme in oJson._contributes._themes.array
				lReturn = lReturn and .copyTheme(cPath + theme._path, cPublisherId)
			next
			
		endwith 
		
		oFilesystem = createobject("Scripting.FileSystemObject")
		
		try 
			oFilesystem.DeleteFolder(cPath, .T.)
		catch 
		endtry 	
		
		if lReturn
			this.dataStruct("crsExtInstall")
			insert into crsExtInstall from name oExtension 
			cursortoxml("crsExtInstall", "cXmlToFile", 0, 32)
			cPath = addbs(this.cDirTheme) + addbs(cPublisherId) + "info.xml"
			strtofile(cXmlToFile, cPath)
		endif 
		
		return lReturn 	
	endproc 
	
	procedure build
		lparameters cPath, cPathTheme

		local cCurrentDirectory, lReturn, cCommand
		cCurrentDirectory = sys(5) + sys(2003)

		if file(cPath + cPathTheme)
			return .T.
		endif 

		with createobject("wscript.shell")
			.CurrentDirectory = cPath
			if .Run("npm install", 0, .T.) > 0
				messagebox("npm install failed.")
				return .F.
			endif
			Sleep(2000)
			** I found a project where the build script doesn't work. 
			** I will try to work around the problem by running the build file directly
			if .Run("npm run vscode:prepublish", 0, .T.) > 0
				if .Run("npm run build", 0, .T.) > 0
					Sleep(2000)
					
					do case
					
						case file("build.js")
							cCommand = "node build.js"
						
						case file("build.ts")	
							cCommand = "node build.ts"
					
						case file(".\src\build.js")
							cCommand = "ts-node .\src\build.js"
							
						case file(".\src\build.ts")
							cCommand = "ts-node .\src\build.ts"						
						 
					endcase 
					
					if !empty(cCommand)	
						cFullPath = addbs(cPath) + justpath(cPathTheme)
						if !directory(cFullPath)
							mkdir (cFullPath)
						endif 
							
						lReturn = .Run(cCommand, 0, .T.) = 0
					endif 
				else
					lReturn = .T.	
				endif 	
			else
				lReturn = .T.	
			endif 
		endwith 
		
		cd (cCurrentDirectory)		
		return lReturn
	endproc 
	
	procedure copyTheme
		lparameters cFile, cRepositoryName

		cCopyToPath = addbs(this.cDirTheme) + cRepositoryName
		cCopyToFile = addbs(cCopyToPath) +  justfname(cFile)
		if !directory(cCopyToPath)
			mkdir (cCopyToPath)
		endif 
		
		Sleep(2000)
		if file(cFile)
			copy file (cFile) to (cCopyToFile)  
		endif 	
	
	endproc 

	procedure resolveBody
		lparameters cSearch, nPage
		
		local cBody
		
		if empty(cSearch)
			return ""
		endif 
		
		if empty(nPage)
			nPage = 1
		endif 
		
		text to cBody textmerge noshow 
		{
		   "filters": [
		      {
		       "criteria": [
		          	{ "filterType": 5, "value": "Themes" },
		          	{"filterType": 1, "value": "<<cSearch>>"},
		       ],
				"pageNumber":<<nPage>>,"pageSize":<<this.nPageSize>>,"sortBy":0,"sortOrder":0
		      },
		    ],
		  	"assetTypes":["Microsoft.VisualStudio.Code.Manifest", "Microsoft.VisualStudio.Services.Content.Details"],"flags":914
		}
		endtext 
		
		
		return cBody
	endproc 
	
enddefine 