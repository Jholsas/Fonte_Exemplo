#include "protheus.ch"
#include "parmtype.ch"

User Function CUSTOMERVENDOR()
    /*Local aParam 	 := PARAMIXB
	Local oObj 		 := aParam[1]
	Local cIdPonto 	 := aParam[2]
	Local lRet 		 := .T.
	Local cIdModel 	 := IIf(oObj != NIL, oObj:GetId(), aParam[3])
	Local cClasse 	 := IIf(oObj != NIL, oObj:ClassName(), "")
	Local nOperation := 0
    Local cMsg       := ""

	If (oObj != NIL .And. oObj:IsActive() == .T.)
		oModelPad  := FwModelActive()
		oModel     := oModelPad:GetModel("SA2MASTER")
		nOperation := oObj:GetOperation()

		If (cIdPonto == "FORMPRE")
			If (nOperation == 4 )
				oModel:LoadValue("A2_MSBLQD", Date()+5 )
               cMsg :="Ponto MVC"
               cMsg += "ID " + cIdModel + CRLF
               cMsg += "ID " + cIdPonto + CRLF
               xRet := ApMsgYesNo(cMsg + "Continua?")
			EndIf
		EndIf
	EndIf
Return (lRet)*/


    Local aParam := PARAMIXB
    Local xRet := .T.
    Local oObj := ""
    Local cIdPonto := ""
    Local cIdModel := ""
    Local lIsGrid := .F.
    Local nLinha := 0
    Local nQtdLinhas := 0
    Local cMsg := ""

    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)

        If cIdPonto == "MODELPOS"
            cMsg := "Chamada na valida��o total do modelo." + CRLF
            cMsg += "ID " + cIdModel + CRLF

            xRet := ApMsgYesNo(cMsg + "Continua?")

        ElseIf cIdPonto == "FORMPOS"
            cMsg := "Chamada na valida��o total do formul�rio." + CRLF
            cMsg += "ID " + cIdModel + CRLF

            If lIsGrid
                cMsg += "� um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
                cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
            Else
                cMsg += "� um FORMFIELD" + CRLF
            EndIf

            xRet := ApMsgYesNo(cMsg + "Continua?")

        ElseIf cIdPonto == "FORMLINEPRE"
            If aParam[5] == "DELETE"
                cMsg := "Chamada na pr� valida��o da linha do formul�rio. " + CRLF
                cMsg += "Onde esta se tentando deletar a linha" + CRLF
                cMsg += "ID " + cIdModel + CRLF
                cMsg += "� um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
                cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
                xRet := ApMsgYesNo(cMsg + " Continua?")
            EndIf

        ElseIf cIdPonto == "FORMLINEPOS"
            cMsg := "Chamada na valida��o da linha do formul�rio." + CRLF
            cMsg += "ID " + cIdModel + CRLF
            cMsg += "� um FORMGRID com " + Alltrim(Str(nQtdLinhas)) + " linha(s)." + CRLF
            cMsg += "Posicionado na linha " + Alltrim(Str(nLinha)) + CRLF
            xRet := ApMsgYesNo(cMsg + " Continua?")

        ElseIf cIdPonto == "MODELCOMMITTTS"
            ApMsgInfo("Chamada ap�s a grava��o total do modelo e dentro da transa��o.")

        ElseIf cIdPonto == "MODELCOMMITNTTS"
            ApMsgInfo("Chamada ap�s a grava��o total do modelo e fora da transa��o.")

        ElseIf cIdPonto == "FORMCOMMITTTSPRE"
            ApMsgInfo("Chamada ap�s a grava��o da tabela do formul�rio.")

        ElseIf cIdPonto == "FORMCOMMITTTSPOS"
            ApMsgInfo("Chamada ap�s a grava��o da tabela do formul�rio.")

        ElseIf cIdPonto == "MODELCANCEL"
            cMsg := "Deseja realmente sair?"
            xRet := ApMsgYesNo(cMsg)

        ElseIf cIdPonto == "BUTTONBAR"
            xRet := {{"Salvar", "SALVAR", {||u_TSMT020()}}}
        EndIf
    EndIf
Return xRet

User Function TSMT020()
    Alert("Buttonbar")
Return NIL
