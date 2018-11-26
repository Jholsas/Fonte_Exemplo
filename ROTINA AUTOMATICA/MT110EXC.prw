#Include "TOTVS.ch"
#Include "TBICONN.ch"

User Function MyMata110()
Local aCabec := {}
Local aItens := {}
Local aLinha := {}
Local lOk    := .T.

Private lMsHelpAuto := .T.
PRIVATE lMsErroAuto := .F.
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Abertura do ambiente                                         |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

ConOut(Repl("-",80))
ConOut(PadC(OemToAnsi("Teste de Alteracao "),80))

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SC1","SB1"


        ConOut(OemToAnsi("Inicio: ")+Time())

        dbSelectarea("SC1")
        dbsetorder(1)
        //C1_FILIAL, C1_NUM, C1_ITEM
        MsSeek(xFilial("SC1")+"015599"+"0001")

            aCabec := {}
            aItens := {}

                aadd(aCabec,{"C1_NUM"    ,SC1->C1_NUM})
                aadd(aCabec,{"C1_SOLICIT","TESTE "})
                aadd(aCabec,{"C1_EMISSAO",SC1->C1_EMISSAO})

            aLinha := {}
            aadd(aLinha,{"C1_ITEM"   ,SC1->C1_ITEM,Nil})
            aadd(aLinha,{"C1_PRODUTO",SC1->C1_PRODUTO,Nil})
            aadd(aLinha,{"C1_QUANT"  ,SC1->C1_QUANT,Nil})
            aadd(aItens,aLinha)

        //旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
        //| Teste de Alteracao                                           |
        //읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸

        MSExecAuto({|x,y,z| mata110(x,y,z)},aCabec,aItens,4)
        If !lMsErroAuto
            ConOut(OemToAnsi("Alterado com sucesso! ")+cDoc)
        Else
            ConOut(OemToAnsi("Erro na Alteracao!"))
            MostraErro()
        EndIf

        ConOut(OemToAnsi("Fim  : ")+Time())

  RESET ENVIRONMENT

Return(.T.)
