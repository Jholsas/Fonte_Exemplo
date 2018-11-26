#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

User Function MT140EXC()

Local nOpc   := 3
Local nX
Local cCod   := ""
Local nVal   := 0
Local nQtd   := 0
Local nTotal := 0


    Private aCabec      := {}
    Private aItens      := {}
    Private aLinha      := {}
    Private lMsErroAuto := .F.

    PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SF1","SD1","SA1","SA2","SB1","SB2","SF4"

    aAdd(aCabec,{'F1_TIPO'      ,'N'        ,NIL})
    aAdd(aCabec,{'F1_FORMUL'    ,'N'        ,NIL})
    aAdd(aCabec,{'F1_DOC'       ,'00173'    ,NIL})
    aAdd(aCabec,{"F1_SERIE"     ,"NF"       ,NIL})
    aAdd(aCabec,{"F1_EMISSAO"   ,dDataBase  ,NIL})
    aAdd(aCabec,{'F1_FORNECE'   ,'000001'   ,NIL})
    aAdd(aCabec,{'F1_LOJA'      ,'01'       ,NIL})
    aAdd(aCabec,{"F1_ESPECIE"   ,"NF"       ,NIL})
    aAdd(aCabec,{"F1_COND"      ,'001'      ,NIL})
    aAdd(aCabec,{"F1_STATUS"    ,''         ,NIL})

 For nX := 1 To 3

    If nX == 1
        cCod   := "SERV0001"
        nQtd   := 6
        nVal   := 80
        nTotal := 480
    ElseIf nX == 2
        cCod := "SERV0002"
        nQtd   := 3
        nVal   := 852
        nTotal := 2556
    ElseIf nX == 3
        cCod := "12345"
        nQtd   := 7
        nVal   := 470
        nTotal := 3290
    EndIf


    aAdd(aLinha,{'D1_COD'   ,cCod       ,NIL})
    aAdd(aLinha,{"D1_QUANT" ,nQtd       ,Nil})
    aAdd(aLinha,{"D1_VUNIT" ,nVal       ,Nil})
    aAdd(aLinha,{"D1_TOTAL" ,nTotal     ,Nil})
    aAdd(aLinha,{"D1_TES"   ,''         ,NIL})


    aAdd(aItens,aLinha)
    aLinha := {}

Next nX
    MSExecAuto({|x,y,z,a,b| MATA140(x,y,z,a,b)}, aCabec, aItens, nOpc,,1)

  If lMsErroAuto
        MostraErro()
        ConOut(Repl("-", 80))
        ConOut(PadC("Teste MATA140 finalizado com erro!", 80))
        ConOut(PadC("Fim: " + Time(), 80))
        ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
        ConOut(PadC("Teste MATA140 finalizado com sucesso!", 80))
        ConOut(PadC("Fim: " + Time(), 80))
        ConOut(Repl("-", 80))
    EndIf

    RESET ENVIRONMENT

Return
