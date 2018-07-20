#include 'protheus.ch'
#include 'parmtype.ch'

user function MBRWBTN()
	Local cText := ""
	Local lRet	:= .T.
	Local cRot

	cRot:= FUNNAME()
	If cRot == "MATA145"
		cText := "Alias [ " + PARAMIXB[1]				+ " ]" + CRLF
		cText += "Recno [ " + AllTrim(Str(PARAMIXB[2])) + " ]" + CRLF
		cText += "Recno [ " + AllTrim(Str(PARAMIXB[3])) + " ]" + CRLF
		cText += "Recno [ " + PARAMIXB[4]				+ " ]" + CRLF

		lRet := MsgYesNo(cText,"Deseja Executar?")

		/*If PARAMIXB[3] == 4
			Alert("PONTO ENTRADA!!! - Você não pode altera!!!")


		EndIf*/

	EndIf

Return lRet
