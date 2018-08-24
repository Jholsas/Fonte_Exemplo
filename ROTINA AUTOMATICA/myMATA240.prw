#Include 'Protheus.ch'
#Include 'Protheus.ch'
#include "tbiconn.ch"
User Function myMATA240()//



Local aVetor := {}

Private lMsErroAuto := .F.

prepare environment empresa "99" filial "01" modulo "est" TABLES "SD3","SB1"

aVetor := {}



aVetor:={  {"D3_TM"         ,"001"               ,NIL},;
           {"D3_COD"        ,"000220         "   ,NIL},;
           {"D3_QUANT"      ,10                  ,NIL},;
           {"D3_OP"         ,""                  ,NIL},;
           {"D3_LOCAL"      ,"01"                ,NIL},;
           {"D3_DOC"        ,""                  ,NIL},;
           {"D3_EMISSAO"    ,ddatabase           ,NIL},;
           {"D3_DTVALID"    ,ddatabase           ,NIL},;
           {"D3_CUSTO1"     ,10                  ,NIL},;
           {"D3_LOTECTL"    ,"TESTE"             ,NIL},;// se este campo estiver vazio, o sistema ira gerar um código automático.
           {"D3_NUMLOTE"    ,"TESTE"             ,NIL}}


MSExecAuto({|x,y| mata240(x,y)},aVetor,3) //Inclusao
//MSExecAuto({|x,y| mata240(x,y)},aVetor,5)

	If (lMsErroAuto == .T.)
			MostraErro()

			ConOut(Repl("-", 80))
			ConOut(PadC("MATA240 automatic routine ended with error", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		Else
			ConOut(Repl("-", 80))
			ConOut(PadC("MATA240 automatic routine successfully ended", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		EndIf

Return
