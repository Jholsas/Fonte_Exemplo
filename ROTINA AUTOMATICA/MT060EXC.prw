#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"


User Function MyMata060()

Local PARAMIXB1 := {}
Local PARAMIXB2 := 3
Local cFornec	:= "FNC007"
Local cLoja	    := "01"
Local cNomeFor 	:= "VECTO TECNOLOGIA LTDA "
Local cProduto	:= "PRDT0002       "
Local cNomeProd	:= "MOUSE SEM FIO"

PRIVATE lMsErroAuto := .F.


//------------------------
//| Abertura do ambiente |
//------------------------

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EST" TABLES "SA5", "SA2", "SB1"

ConOut(Repl("-",80))
ConOut(PadC("Teste de Amarracao Produto x Fornecedor",80))
ConOut("Inicio: "+Time())

//------------------------
//| Teste de Inclusao    |
//------------------------
SA2->(DBSetOrder(1))
SA2->(MSSEEK(xFilial("SA2")+cFornec))

SB1->(DBSetOrder(1))
SB1->(MSSEEK(xFilial("SB1")+cProduto))

Begin Transaction

PARAMIXB1 := {}

 aadd(PARAMIXB1,{"A5_FORNECE"   ,SA2->A2_COD,})
 aadd(PARAMIXB1,{"A5_LOJA"      ,SA2->A2_LOJA ,})
 aadd(PARAMIXB1,{"A5_NOMEFOR"   ,SA2->A2_NOME ,})
 aadd(PARAMIXB1,{"A5_PRODUTO"   ,SB1->B1_COD   ,})
 aadd(PARAMIXB1,{"A5_NOMPROD"   ,SB1->B1_DESC  ,})

 MSExecAuto({|x,y| mata060(x,y)},PARAMIXB1,PARAMIXB2)

    If !lMsErroAuto
        ConOut("Incluido com sucesso! "+cFornec)
    Else
        ConOut("Erro na inclusao!")
        MostraErro()
    EndIf
        ConOut("Fim  : "+Time())
End Transaction
    RESET ENVIRONMENT

Return Nil
