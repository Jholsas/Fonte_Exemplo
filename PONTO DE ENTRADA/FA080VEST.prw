#include 'protheus.ch'
#include 'parmtype.ch'

user function FA080VEST()

	Local lRet := .T.

	Local nOpcC:= PARAMIXB 

	If nOpcC == 5     //Estorno

		lRet := MsgYesNo("Confirma Estorno da Baixa?")

	ElseIf nOpcC == 6     //Cancelamento 

		lRet := MsgYesNo("Confirma Cancelamento da Baixa?")

	EndIf


return lRet


