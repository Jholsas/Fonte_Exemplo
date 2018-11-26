#include "protheus.ch"
#include "parmtype.ch"

User Function ITEM()

	Local aParam 	 := PARAMIXB
	Local oObj 		 := aParam[1]
	Local cIdPonto 	 := aParam[2]
	Local lRet 		 := .T.
	Local cIdModel 	 := IIf(oObj != NIL, oObj:GetId(), aParam[3])
	Local cClasse 	 := IIf(oObj != NIL, oObj:ClassName(), "")
	Local nOperation := 0
//If aParam <> NIL
	If (oObj != NIL .And. oObj:IsActive() == .T.)

		oModelPad  := FwModelActive()
		oModel     := oModelPad:GetModel("SB5DETAIL")
		nOperation := oObj:GetOperation()

		If (cIdPonto == "FORMPRE")
			If (nOperation == 3 .And. IsInCallStack("A010COPIA") .And. ProcName(4) == "CANSETVALUE")
				alert ('limpou')
				oModel:LoadValue("B5_CEME", "1234")
				oModel:LoadValue("B5_DESCNFE", "")
				oModel:LoadValue("B5_COMPR",999)
			EndIf

		EndIf
	EndIf
Return (lRet)
