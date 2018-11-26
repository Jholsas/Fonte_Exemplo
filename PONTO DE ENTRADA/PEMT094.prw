#Include "TOTVS.ch"

User Function MATA094()
Local aParam     := PARAMIXB
    Local oObj       := NIL
    Local xRet       := .T.
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local i
    Local j

    If (aParam <> NIL)
        oObj     := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]

        If cIdPonto == 'MODELPOS'
            oGridDoc := oObj:GetModel("GridDoc")
            //aRet  := oGridDoc:oFormModelStruct:GetArrayPos({"C7_ITEM", "C7_PRODUTO" })
            aRet  := oGridDoc:oFormModelStruct:GetArrayPos({"C7_PRODUTO"})
            For i := 1 To oGridDoc:GetQTDLine()
                oGridDoc:GoLine(i)
                For j := 1 To Len(aRet)
                    xRet := oGridDoc:GetValueByPos(aRet[j],oGridDoc:GetLine())
                Next j
                MsgInfo("Retorno da linha " + cValToChar(oGridDoc:GetLine()) + " : Produto : " + xRet)
            Next i
       EndIf
    EndIf
Return (xRet)
