#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

User Function MyMata020()
Local aCabec := {}
Local nOpc := 3


PRIVATE lMsErroAuto := .F.

//------------------------//| Abertura do ambiente |//------------------------
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SA2"
ConOut(Repl("-",80))
ConOut(PadC("Teste de Cadastro de Fornecedores",80))
ConOut("Inicio: "+Time())
//------------------------//| Teste de Inclusao    |//------------------------
//Em caso de Alteração utilizar o trecho comentado abaixo
/*Begin Transaction
 DbSelectArea("SA2")
            DbSetOrder(1)

            // A2_FILIAL + A2_COD + A2_LOJA
            MsSeek(fwxFilial("SA2") + "F00003" + "01")
*/
aCabec := {}
        aadd(aCabec,{"A2_COD"    ,"F00004",})
        aadd(aCabec,{"A2_LOJA"   ,"01",})
        aadd(aCabec,{"A2_NOME"   ,"F00004",})
        aadd(aCabec,{"A2_NREDUZ" ,"F00004",})
        aadd(aCabec,{"A2_END"    ,"ENDERECO",})
        aadd(aCabec,{"A2_EST"    ,"SP",})
        aadd(aCabec,{"A2_MUN"    ,"MUNICIPIO",})
        aadd(aCabec,{"A2_TIPO"   ,"F",})
MSExecAuto({|x,y| mata020(x,y)},aCabec,nOpc)
    If !lMsErroAuto
        ConOut("Incluido com sucesso! ")
    Else
    	ConOut("Erro na inclusao!")

    EndIf
    	ConOut("Fim  : "+Time())
    //End Transaction
RESET ENVIRONMENT
Return Nil
