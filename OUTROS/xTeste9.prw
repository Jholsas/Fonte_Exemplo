//Exemplo NextNumero()
User Function NextNum()

Local cNum := ''

cNum := NextNumero("SB1",1,"B1_COD",.F., "000001")

DbSelectArea("SB1")
DbSetOrder(1)

If ( !dbSeek( xFilial("SB1") + cNum ))
    Reclock("SB1", .T.)
        SB1->B1_FILIAL 	:= xFilial("SB1")
        SB1->B1_COD 	:= cNum
        // SB1->B1_TIPO 	:= 1
        // SB1->B1_ITEM 	:= "001"
        // SB1->B1_PRODUTO := "PRODUTO 1"
        // SB1->B1_UM 		:= "UN"
        // SB1->B1_QUANT 	:= 1
        // SB1->B1_PRECO 	:= 30
        // SB1->B1_TOTAL 	:= 30
        // SB1->B1_QTSEGUM := 0
        // SB1->B1_IPI 	:= 0
        // SB1->B1_DATPRF 	:= ddatabase
        // SB1->B1_EMISSAO := ddatabase
        // SB1->B1_LOCAL 	:= "N"
        // SB1->B1_FORNECE := "000001"
        // SB1->B1_LOJA 	:= "01"
        // SB1->B1_COND 	:= "001"
        SB1->( MsUnlock() )
    EndIf

    Return cNum // retorno


// exemplo de GetSXENum()
User Function GetNum()

Local cCliente := GetSXENum("SA1","A1_COD")

SA1->( dbSetOrder(1) )
    If SA1->(dbSeek(xFilial('SA1') + cCliente))
        MsgAlert("Cliente já existe")
        Else    Reclock("SA1", .T.)
            SA1->A1_COD := cCliente
            SA1->A1_LOJA := "01"
            SA1->A1_NOME := "TESTE"
            SA1->(MsUnlock())
            ConfirmSX8()
    EndIf
Return
