#Include 'Protheus.ch'
#Include 'Protheus.ch'
#include "tbiconn.ch"

User Function MyCOMA010()
Local aCabec    := {}
Local aItens	:= {}
Local cCodTab   := "000"
Local cFornec	:= ""
Local cLoja	:= ""
Local cProd	:= ""
Local cNomeProd	:= ""
Local PARAMIXB1 := 4

PRIVATE lMsErroAuto := .F.

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Abertura do ambiente                                         |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "AIA","AIB"
    ConOut(Repl("-",80))
    ConOut(PadC("Teste de Manutencao da Tabela de Precos",80))
    ConOut("Inicio: "+Time())

cFornec   := SA2->A2_COD
cLoja	  := Posicione("SA2",1,xFilial("SA2")+cFornec,"A2_LOJA")
cProd     := SB1->B1_COD
cNomeProd := Posicione("SB1",1,xFilial("SB1")+cProd,"B1_DESC")
dDataDe   := dDataBase
dDataAte  := CtoD("01/01/2030")
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Teste de Altera豫o                                            |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
    /*dbSelectAreas("SA2")
	dbSetOrder(1)
	dbSeek(xFilial("SA2") + cFornec)*/

   	aCabec := {}
        aadd(aCabec,{"AIA_CODFOR",cFornec,})
        aadd(aCabec,{"AIA_LOJFOR",cLoja,})
        aadd(aCabec,{"AIA_CODTAB",cCodTab,})
        aadd(aCabec,{"AIA_DESCRI","TESTE",})
        aadd(aCabec,{"AIA_DATDE",dDataDe,})
        aadd(aCabec,{"AIA_DATATE",dDataAte,})
    aItens := {}
        aAdd(aItens,{})
        aadd(aItens[len(aItens)],{"AIB_ITEM","0002",})
        aadd(aItens[len(aItens)],{"AIB_CODPRO",cProd,})
        aadd(aItens[len(aItens)],{"AIB_DESCRI",cNomeProd,})
        aadd(aItens[len(aItens)],{"AIB_PRCCOM",10,})
        aadd(aItens[len(aItens)],{"AIB_DATVIG",dDataBase,})
    PARAMIXB2 := aClone(aCabec)
    PARAMIXB3 := aClone(aItens)
MSExecAuto({|x,y,z| coma010(x,y,z)},PARAMIXB1,PARAMIXB2,PARAMIXB3)
    If !lMsErroAuto
    	ConOut("Alterado com sucesso! "+cCodTab)
    Else
    	ConOut("Erro na inclusao!")
        MostraErro()
    EndIf
    	ConOut("Fim  : "+Time())


 RESET ENVIRONMENT

 Return Nil
