User Function MT410Inc()
    Local aArea       := GetArea()
    Local aAreaC5     := SC5->(GetArea())
    Local nOpcao      := 0
    Private cCadastro := "Pedido de Venda - AxInclui"

    DbSelectArea('SCS')
    SC5->(DbSetOrder(1)) //C5_FILIAL + C5_COD
    SC5->(DbGoTop())

    //Chama a inclusão
    nOpcao := AxInclui('SC5', 0, 3)
    If nOpcao == 1
        MsgInfo("Produto incluído: "+SC5->C5_COD, "Atenção")
    EndIf

    RestArea(aAreaC5)
    RestArea(aArea)


Return
