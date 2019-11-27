local cAllPath 
cAllPath = ""

SET TALK OFF


cRoot = sys(5) + sys(2003)

set path to cRoot 

loadPath("", addbs(cRoot) + "SRC", @cAllPath)
setProc("", addbs(cRoot) + "SRC\LIBRARIES")
cAllPath = strtran(cAllPath, addbs(cRoot) , "")
Set Path to (cAllPath)

function loadPath
	lparameters cRoot, cDir, cAllPath

	local nFiles, i, cName, cType, aDirFiles
	dimen aDirFiles[1]

	nFCount = adir(aDirFiles, addbs(cDir) + "*.*" , "A")
	if nFCount > 0
		cAllPath = cAllPath + iif(!empty(cAllPath), "; " , "") + cDir
	endif

	nFiles = adir(aDirFiles, addbs(cDir) + "*.*" , "D")

	for i = 1 to nFiles
		cName = aDirFiles(i, 1)
		cType = aDirFiles(i, 5)

		if "D" $ cType and cName <> "."
			=loadPath(cRoot, addbs(cDir) + cName, @cAllPath)
		endif
	next

endfunc

function setProc
	lparameters cRoot, cDir

	local nFiles, i, cName, cType, aDirFiles
	dimen aDirFiles(1)

	nFiles = adir(aDirFiles, cRoot + addbs(cDir) + "*.*" , "AD")

	for i = 1 to nFiles
		cName = aDirFiles(i, 1)
		cFullName = addbs(cDir) + cName
		cOnlyExt = justext(cName)
		cType = aDirFiles(i, 5)

		if "D" $ cType and cName <> "."
			=setProc(cRoot, addbs(cDir) + cName, lDeclarelibs)
		else
			do case
				case cOnlyExt = "PRG" and !("\"+upper(forceext(cName,"")+".") $ upper(set("Procedure")))
					set procedure to (cFullName) addi
				
				case cOnlyExt = "VCX" and !(upper(forceext(cName,"")) $ upper(set("Classlib")))	
					set classlib to (cFullName) addi
			endcase 
		endif
	next

endfunc