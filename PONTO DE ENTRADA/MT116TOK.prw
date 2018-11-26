User function MT116TOK()

Local lRet := .T.

    IF EMPTY(aInfAdic[10]) // Estado Origem
	alert("Campo F1_UFORITR, Campo Vazio!!!")
	lRet := .F.
	ElseIF EMPTY(aInfAdic[11]) // Cidade Origem
	alert("Campo F1_MUORITR, Campo Vazio!!!")
	lRet := .F.
	ElseIF EMPTY(aInfAdic[12]) // Estado Destino
	alert("Campo F1_UFDESTR, Campo Vazio!!!")
	lRet := .F.
	ElseIF EMPTY(aInfAdic[13]) // Cidade Destino
	alert("Campo F1_MUDESTR, Campo Vazio!!!")
	lRet := .F.
	Else

		 /*IF INCLUI
			cNFiscal	:= PADL(ALLTRIM(cNFiscal),TamSX3("F1_DOC")[1],'0')
		 EndIF
	//ENDIF*/

        lRet := .T.
    EndIf

return lRet
