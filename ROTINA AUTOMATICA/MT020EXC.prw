#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

User Function MyMata020()
Local aCabec := {}
Local nOpc := 4


PRIVATE lMsErroAuto := .F.

//------------------------//| Abertura do ambiente |//------------------------
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SA2"
ConOut(Repl("-",80))
ConOut(PadC("Teste de Cadastro de Fornecedores",80))
ConOut("Inicio: "+Time())
//------------------------//| Teste de Inclusao    |//------------------------
Begin Transaction
 DbSelectArea("SA2")
            DbSetOrder(1)

            // A2_FILIAL + A2_COD + A2_LOJA
            MsSeek(fwxFilial("SA2") + "F00003" + "01")

aCabec := {}
        aadd(aCabec,{"A2_COD"    ,SA2->A2_COD,})
        aadd(aCabec,{"A2_LOJA"   ,SA2->A2_LOJA,})
        aadd(aCabec,{"A2_NOME"   ,SA2->A2_NOME,})
        aadd(aCabec,{"A2_NREDUZ" ,SA2->A2_NREDUZ,})
        aadd(aCabec,{"A2_END"    ,SA2->A2_END,})
        aadd(aCabec,{"A2_EST"    ,SA2->A2_EST,})
        aadd(aCabec,{"A2_MUN"    ,SA2->A2_MUN,})
        aadd(aCabec,{"A2_TIPO"   ,"F",})
MSExecAuto({|x,y| mata020(x,y)},aCabec,nOpc)
    If !lMsErroAuto
        ConOut("Incluido com sucesso! ")
    Else
    	ConOut("Erro na inclusao!")

    EndIf
    	ConOut("Fim  : "+Time())
    End Transaction
RESET ENVIRONMENT
Return Nil
