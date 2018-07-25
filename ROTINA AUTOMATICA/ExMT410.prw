#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

user Function ExMT410()

Local aCabec := {}
Local aItens := {}
Local aLinha := {}
Local nX     := 0
Local nY     := 0
Local cDoc   := ""
Local lOk    := .T.

PRIVATE lMsErroAuto := .F.
//****************************************************************
//* Abertura do ambiente
//****************************************************************
ConOut(Repl("-",80))
ConOut(PadC("Teste de Inclusao de 10 pedidos de venda  com 30 itens cada",80))
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT" TABLES "SC5","SC6","SA1","SA2","SB1","SB2","SF4"
//****************************************************************
//* Verificacao do ambiente para teste
//****************************************************************
dbSelectArea("SB1")
dbSetOrder(1)
If !SB1->(MsSeek(xFilial("SB1")+"12345"))
    lOk := .F.
    ConOut("Cadastrar produto: 12345")
EndIf
dbSelectArea("SF4")
dbSetOrder(1)
If !SF4->(MsSeek(xFilial("SF4")+"501"))
    lOk := .F.
    ConOut("Cadastrar TES: 501")
EndIf
dbSelectArea("SE4")
dbSetOrder(1)
If !SE4->(MsSeek(xFilial("SE4")+"001"))
    lOk := .F.
    ConOut("Cadastrar condicao de pagamento: 001")
EndIf
If !SB1->(MsSeek(xFilial("SB1")+"0000000001"))
    lOk := .F.
    ConOut("Cadastrar produto: 0000000001")
EndIf
dbSelectArea("SA1")
dbSetOrder(1)
If !SA1->(MsSeek(xFilial("SA1")+"000001"))
    lOk := .F.
    ConOut("Cadastrar cliente: 000001")
EndIf
If lOk
    ConOut("Inicio: "+Time())
    For nY := 1 To 10
        cDoc :=GetSxeNum("SC5","C5_NUM")
        RollBAckSx8()
        aCabec := {}
        aItens := {}
        aadd(aCabec,{"C5_NUM"   ,cDoc,Nil})
        aadd(aCabec,{"C5_TIPO" ,"N",Nil})
        aadd(aCabec,{"C5_CLIENTE","000012",Nil})
        aadd(aCabec,{"C5_LOJACLI","01",Nil})
        aadd(aCabec,{"C5_TIPOCLI","F",Nil})
        aadd(aCabec,{"C5_CONDPAG","001",Nil})
        /*If cPaisLoc == "PTG"
            aadd(aCabec,{"C5_DECLEXP","TESTE",Nil})
        Endif*/
        For nX := 1 To 30
            aLinha := {}
            aadd(aLinha,{"C6_ITEM",StrZero(nX,2),Nil})
            aadd(aLinha,{"C6_PRODUTO","0000000001",Nil})
            aadd(aLinha,{"C6_QTDVEN",1,Nil})
            aadd(aLinha,{"C6_PRCVEN",100,Nil})
            aadd(aLinha,{"C6_PRUNIT",100,Nil})
            aadd(aLinha,{"C6_VALOR",100,Nil})
            aadd(aLinha,{"C6_TES","502",Nil})
            aadd(aItens,aLinha)
       Next nX
        //****************************************************************
        //* Teste de Inclusao
        //****************************************************************
        MATA410(aCabec,aItens,3)
        If !lMsErroAuto
            ConOut("Incluido com sucesso! "+cDoc)
        Else
            ConOut("Erro na inclusao!")
        EndIf
       Next nY
    ConOut("Fim  : "+Time())
    //****************************************************************
    //* Teste de alteracao
    //****************************************************************
    aCabec := {}
    aItens := {}
    aadd(aCabec,{"C5_NUM",cDoc,Nil})
    aadd(aCabec,{"C5_TIPO","N",Nil})
    aadd(aCabec,{"C5_CLIENTE",SA1->A1_COD,Nil})
    aadd(aCabec,{"C5_LOJACLI",SA1->A1_LOJA,Nil})
    aadd(aCabec,{"C5_LOJAENT",SA1->A1_LOJA,Nil})
    aadd(aCabec,{"C5_CONDPAG",SE4->E4_CODIGO,Nil})
    If cPaisLoc == "PTG"
        aadd(aCabec,{"C5_DECLEXP","TESTE",Nil})
    Endif
   For nX := 1 To 30
        aLinha := {}
        aadd(aLinha,{"LINPOS","C6_ITEM",StrZero(nX,2)})
        aadd(aLinha,{"AUTDELETA","N",Nil})
        aadd(aLinha,{"C6_PRODUTO",SB1->B1_COD,Nil})
        aadd(aLinha,{"C6_QTDVEN",2,Nil})
        aadd(aLinha,{"C6_PRCVEN",100,Nil})
        aadd(aLinha,{"C6_PRUNIT",100,Nil})
        aadd(aLinha,{"C6_VALOR",200,Nil})
        aadd(aLinha,{"C6_TES","501",Nil})
        aadd(aItens,aLinha)
   Next nX
    ConOut(PadC("Teste de alteracao",80))
    ConOut("Inicio: "+Time())
    MATA410(aCabec,aItens,4)
    ConOut("Fim  : "+Time())
    ConOut(Repl("-",80))
    //****************************************************************
    //* Teste de Exclusao
    //****************************************************************
    ConOut(PadC("Teste de exclusao",80))
    ConOut("Inicio: "+Time())
    MATA410(aCabec,aItens,5)
    If !lMsErroAuto
        ConOut("Exclusao com sucesso! "+cDoc)
    Else
        ConOut("Erro na exclusao!")
    EndIf
    ConOut("Fim  : "+Time())
    ConOut(Repl("-",80))
EndIf
RESET ENVIRONMENT
Return(.T.)
