#include 'protheus.ch'
#include 'parmtype.ch'

user function MT110APV()
	Local cParam1:=ParamIxb[1]
	Local nParam2:=ParamIxb[2]
	Local lRet:=.F.
	
	// Validações //
	
	
	IF SC1->C1_APROV == 'L'
		dDate := Date()
		Alert(dDate)
		lRet := .T.
	EndIF
	

Return lRet
