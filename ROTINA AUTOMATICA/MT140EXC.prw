#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

User Function MT140EXC()

Local nOpc := 3

    Private aCabec      := {}
    Private aItens      := {}
    Private aLinha      := {}
    Private lMsErroAuto := .F.

    PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SF1","SD1","SA1","SA2","SB1","SB2","SF4"

    aAdd(aCabec,{'F1_TIPO'      ,'N'        ,NIL})
    aAdd(aCabec,{'F1_FORMUL'    ,'N'        ,NIL})
    aAdd(aCabec,{'F1_DOC'       ,'00044'   ,NIL})
    aAdd(aCabec,{"F1_SERIE"     ,"NF"       ,NIL})
    aAdd(aCabec,{"F1_EMISSAO"   ,dDataBase  ,NIL})
    aAdd(aCabec,{'F1_FORNECE'   ,'000001'   ,NIL})
    aAdd(aCabec,{'F1_LOJA'      ,'01'       ,NIL})
    aAdd(aCabec,{"F1_ESPECIE"   ,"NF"       ,NIL})
    aAdd(aCabec,{"F1_COND"      ,'001'      ,NIL})
    aAdd(aCabec,{"F1_STATUS"    ,''         ,NIL})

    aAdd(aItens,{'D1_COD'   ,"12345"   ,NIL})
    aAdd(aItens,{"D1_QUANT" ,500      ,Nil})
    aAdd(aItens,{"D1_VUNIT" ,50      ,Nil})
    aAdd(aItens,{"D1_TOTAL" ,25000      ,Nil})
    aAdd(aItens,{"D1_TES"   ,''     ,NIL})
    aAdd(aItens,{"D1_PEDIDO",'000456'     ,NIL})
    aAdd(aItens,{"D1_ITEMPC",'0001'     ,NIL})

    aAdd(aLinha,aItens)

    MSExecAuto({|x,y,z,a,b| MATA140(x,y,z,a,b)}, aCabec, aLinha, nOpc,,)

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
