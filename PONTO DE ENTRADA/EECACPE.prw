User Function EECAC100()

Local cParam := If(Type("ParamIxb") = "A",ParamIxb[1],If(Type("ParamIxb") = "C",ParamIxb,""))


If cParam == "ANTES_SALVAR"
MsgInfo("Entrou no ponto de entrada 'ANTES_SALVAR'.")
lRet := .F.
Endif



If cParam == "AC100CRIT_CLIENTES"
MsgInfo("Entrou no ponto de entrada 'AC100CRIT_CLIENTES'.")
IF M->A1_TIPO == 'X' .AND. Empty(M->A1_CGC)
Msginfo("Campo CNPJ vazio","Atenção")
lValidCli := .F.
EndIF
Endif

Return Nil
