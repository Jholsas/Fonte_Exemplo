#Include "TOTVS.ch"

User Function MATA094()
    Local aParam     := PARAMIXB
    Local oObj       := NIL
    Local xRet       := .T.
    Local lIsGrid    := .F.
    Local cMsg       := ""
    Local cIdPonto   := ""
    Local cIdModel   := ""
    Local nLinha     := 0
    Local nQtdLinhas := 0

    If (aParam <> NIL)
        oObj     := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid  := (Len(aParam) > 3)

        If (cIdPonto == "MODELPOS")
            cMsg := "Chamada na validação total do modelo." + CRLF
            cMsg += "ID " + cIdModel + CRLF

            xRet := MsgYesNo(cMsg + "Continua?")
        ElseIf (cIdPonto == "MODELVLDACTIVE")
            cMsg := "Chamada na ativação do modelo de dados."
                  //If oObj:GetOperation() == 4
                  //If (IsInCallStack("A94ExLiber") == .T.)
                    //    SCR->CR_OBS:="TESTE 2"
                  //EndIf
                // EndIf
			xRet := MsgYesNo(cMsg + "Continua?")
        ElseIf (cIdPonto == "FORMPOS")
            cMsg := "Chamada na validação total do formulário." + CRLF
            cMsg += "ID " + cIdModel + CRLF

            If (lIsGrid == .T.)
                cMsg += "É um FORMGRID com " + AllTrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
                cMsg += "Posicionado na linha " + AllTrim(Str(nLinha)) + CRLF
            Else
                cMsg += "É um FORMFIELD" + CRLF
            EndIf

            xRet := MsgYesNo(cMsg + "Continua?")
        ElseIf (cIdPonto == "FORMLINEPRE")
            If aParam[5] == "DELETE"
                cMsg := "Chamada na pré validação da linha do formulário." + CRLF
                cMsg += "Onde esta se tentando deletar a linha" + CRLF
                cMsg += "ID " + cIdModel + CRLF
                cMsg += "É um FORMGRID com " + AllTrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
                cMsg += "Posicionado na linha " + AllTrim(Str(nLinha)) + CRLF

                xRet := MsgYesNo(cMsg + " Continua?")
            EndIf
        ElseIf (cIdPonto == "FORMLINEPOS")
            cMsg := "Chamada na validação da linha do formulário." + CRLF
            cMsg += "ID " + cIdModel + CRLF
            cMsg += "É um FORMGRID com " + AllTrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
            cMsg += "Posicionado na linha " + AllTrim(Str(nLinha)) + CRLF

            xRet := MsgYesNo(cMsg + " Continua?")
        ElseIf (cIdPonto == "MODELCOMMITTTS")
            MsgInfo("Chamada após a gravação total do modelo e dentro da transação.")
        ElseIf (cIdPonto == "MODELCOMMITNTTS")
            MsgInfo("Chamada após a gravação total do modelo e fora da transação.")
        ElseIf (cIdPonto == "FORMCOMMITTTSPRE")
            MsgInfo("Chamada após a gravação da tabela do formulário.")
        ElseIf (cIdPonto == "FORMCOMMITTTSPOS")
            MsgInfo("Chamada após a gravação da tabela do formulário.")
        ElseIf (cIdPonto == "MODELCANCEL")
            cMsg := "Deseja realmente sair?"

            xRet := MsgYesNo(cMsg)
        ElseIf (cIdPonto == "BUTTONBAR")
            xRet := {{"Botão", "BOTÃO", {|| MsgInfo("Buttonbar")}}, {"Botão2", "BOTÃO2", {|| MsgInfo("Buttonbar2")}} }

        EndIf
    EndIf
Return (xRet)
