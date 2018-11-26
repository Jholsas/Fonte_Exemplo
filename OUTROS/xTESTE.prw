#include 'protheus.ch'
#include 'parmtype.ch'

user function xTESTE()



if IsBlind() // essa função evita a chamada de interface grafica


	
		ConOut("     ___   _____   _     _   _____   _      ")
		ConOut("    /   | |  _  \ | |   / / |  _  \ | |     ")
		ConOut("   / /| | | | | | | |  / /  | |_| | | |     ")
		ConOut("  / / | | | | | | | | / /   |  ___/ | |     ")
		ConOut(" / /  | | | |_| | | |/ /    | |     | |___  ")
		ConOut("/_/   |_| |_____/ |___/     |_|     |_____| ")
		ConOut("Analista: Victor Araujo")
	Else
		Alert("TESTE")
		MsgBox("Confirma exportacao dos dados?","Atencao","YESNO")
		
	
	
 EndIf
return


/*
local aRet      := {}
local aRetUsr  := {}
local aRetGrp  := {}
local i

aRet := FWSFAllRules()
varinfo("aRet", aRet)

for i := 1 to len(aRet)
 aRetUsr := FWSFRulesUsers(aRet[i][2])
 conout("")
 conout("Usuários que pertencem a determinada regra")
 conout("Parametro utilizado " + iif(valType(aRet[i][2]) == "C", aRet[i][2], cValToChar(aRet[i][2])))
 varinfo("aRetUsr",aRetUsr)
 conout("")

 aRetGrp := FWSFRulesGroups(aRet[i][2])
 conout("")
 conout("Grupos que pertencem a determinada regra")
 conout("Parametro utilizado " + iif(valType(aRet[i][2]) == "C", aRet[i][2], cValToChar(aRet[i][2])))
 varinfo("aRetGrp",aRetGrp)
 conout("")
next i

return





/*
aUsers := FWSFAllRules()

Conout("TESTE")
return aUsers

	/*Local lRet
	IF Altera
	lRet := cUserName $ Alltrim('deise,ubaldo,guilherme,Administrador')
	else
	lRet := .T.

	endIf

return lRet*/