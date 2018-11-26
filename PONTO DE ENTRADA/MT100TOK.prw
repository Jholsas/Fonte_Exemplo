#Include "protheus.ch"
#Include "parmtype.ch"

User Function MT100TOK()
	Local lRet := .T. //MsgYesNo("Deseja continuar com o processo atual?", "Teste PE MT100TOK")

         IF INCLUI
            cNFiscal    := PADL(ALLTRIM(cNFiscal),TamSX3("F1_DOC")[1],'0')
         EndIF
Return lRet
