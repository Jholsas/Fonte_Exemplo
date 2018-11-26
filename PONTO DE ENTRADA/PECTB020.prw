#INCLUDE 'PROTHEUS.CH'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'

User Function CTBA020()

Local aParam     := PARAMIXB
Local xRet       := .T.
Local oObj       := ''
Local cIdPonto   := ''
Local cIdModel   := ''
Local lIsGrid    := .F.
Local nLinha     := 0
Local nQtdLinhas := 0
Local cClasse 	 := ''
Local cMsg       := ''


If aParam <> NIL

       oObj       := aParam[1]
       cIdPonto   := aParam[2]
       cIdModel   := aParam[3]
       lIsGrid    := ( Len( aParam ) > 3 )

      /* If lIsGrid
             nQtdLinhas := oObj:GetQtdLine()
             nLinha     := oObj:nLine
      EndIf*/

If cIdPonto == "MODELPOS"
	If (oObj:GetOperation() == MODEL_OPERATION_INSERT .Or. oObj:GetOperation() == MODEL_OPERATION_UPDATE)

		If Empty(oObj:GetValue("CVDDETAIL","CVD_CODPLA")) .And. Empty(oObj:GetValue("CVDDETAIL","CVD_ENTREF"))
			MsgInfo("Plano Referencial não preenchido!","Validação Pl. Referencial")
			//Help(" ",1,"Ctb020CRef",,STR0074,1,0)
            xRet := .F.
		EndIf
	EndIf
EndIf

EndIf

Return xRet
