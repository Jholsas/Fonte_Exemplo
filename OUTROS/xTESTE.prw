#include 'protheus.ch'
#include 'parmtype.ch'

user function xTESTE()
	Local lRet 
	IF Altera
	lRet := cUserName $ Alltrim('deise,ubaldo,guilherme,Administrador')
	else
	lRet := .T.
	
	endIf
	
return lRet