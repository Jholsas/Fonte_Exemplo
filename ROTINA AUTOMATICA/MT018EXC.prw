#include 'protheus.ch'
#include 'tbiconn.ch'
User Function EXECSBZ()

Local aCab            := {}
Local aItens        := {}
Local aItem        := {}
Local aAreaSM0    := {}
Local nOpc            := 3

Private lMsErroAuto    := .F.

/*If !MyOpenSm0Ex()
    __Quit()
EndIf
**/
// DbSelectArea("SM0")
// aAreaSM0 := SM0->(GetArea())
// SM0->(dbSetOrder(1))
// SM0->(dbGoTop())
// If SM0->(!EOF())
//     cEmpStart := AllTrim(SM0->M0_CODIGO)
//     cFilStart := AllTrim(SM0->M0_CODFIL)
// Endif

// RestArea(aAreaSM0)

// PREPARE ENVIRONMENT EMPRESA cEmpStart FILIAL cFilStart
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SB1"
If nOpc == 3 .Or. nOpc == 5

        aCab := {}
        lMsErroAuto := .F.

        aAdd(aCab,{'BZ_COD'     ,"MT018Z         "   ,Nil})
        aAdd(aCab,{'BZ_LOCPAD'  ,"01"       ,Nil})
        aAdd(aCab,{'BZ_TE'      ,"001"      ,Nil})

        MSExecAuto({|v,x| MATA018(v,x)},aCab,nOpc)

        If !lMsErroAuto
            Conout('Inserido/Alterado/Excluido com sucesso')
        Else
            Conout('Erro na Inclusão/Alteração/Exclusão')
            MostraErro()
        Endif

Elseif nOpc == 4
    aAdd(aCab,{'BZ_COD',"001",Nil})
    aAdd(aCab,{'BZ_LOCPAD',"01",Nil})
    aAdd(aCab,{'BZ_TE',"001",Nil})

    MSExecAuto({|v,x| MATA018(v,x)},aCab,nOpc)

    If !lMsErroAuto
        Conout('Inserido/Alterado/Excluido com sucesso')
    Else
        Conout('Erro na Inclusão/Alteração/Exclusão')
        MostraErro()
    Endif
Endif

RESET ENVIRONMENT

Return


User Function MT018STT()

    ConOut(PadC("STARJOB INICIO!!!", 80))

    StartJob("U_EXECSBZ", GetEnvServer(),.T.,"TESTE")

    ConOut(Repl("-", 80))
	ConOut(PadC("STARJOB FIM!!!", 80))
	ConOut(PadC("Ends at: " + Time(), 80))
	ConOut(Repl("-", 80))


Return
