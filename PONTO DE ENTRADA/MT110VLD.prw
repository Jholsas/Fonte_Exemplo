#include 'protheus.ch'
#include 'parmtype.ch'

user function MT110VLD()

	Local ExpN1    := Paramixb[1]
	Local ExpL1    := .T.   
	//Validações do Cliente

	IF SC1->C1_APROV == 'L'
		dDate := Date()
		Alert(dDate)
	EndIF
	

return ExpL1