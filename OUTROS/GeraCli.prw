#Include "rwmake.ch"
#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºFuncao    ³GeraCli   ºAutor ³Rhander Pena        º Data ³ 17/07/18     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Cria Clientes SA1                                          º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Brascargo                                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function GeraCli()
// u_GeraCli()
Local aCli             := {}
Local cCodCli          := 'TTTTTT'
Local cLojCli          := '01'
Local nLoja            := '01'
Local cCNPCli          := '85671428653'
Local cNomCli          := 'Rhander Pena Rodrigues'
Local cEndCli          := 'Rua TESTE'
Local cNroCli          := '333'
Local cBaiCli          := 'BAIRRO TESTE'
Local cCodMunCli       := '05309'
Local cMunCli          := 'VITORIA'
Local cUFCli           := 'SP'
Local cCEPCli          := ''
Local cIECli           := ''
Local cFonCli          := ''
Local cTipo     	   := "F"
Local cDDD     	   	   := ""
Local cEMAIL     	   := ""

// FORA DO WEB
Local cPessoa          := ''
Local cContrib         := ''

//Local lMsErroAuto  	   := .F.

private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"


cPessoa    	:= iif( Len(Alltrim(cCNPCli)) = 14, "J","F")
cContrib    := iif( Alltrim(cIECli) 	  = '', "2","1")

DbSelectArea('SA1')
SA1->(DbSetOrder(3))
If !SA1->(DbSeek(xFilial("SA1")+cCNPCli) )

	aAdd(aCli, {"A1_COD"	, cCodCli             	, Nil})
	aAdd(aCli, {"A1_LOJA"	, cLojCli             	, Nil})
	aAdd(aCli, {"A1_FILIAL"	, xFilial("SA1")      	, Nil})
	aAdd(aCli, {"A1_PESSOA"	, cPessoa             	, Nil})
	aAdd(aCli, {"A1_NOME"	, cNomCli             	, Nil})
	aAdd(aCli, {"A1_NREDUZ" , cNomCli      		    , Nil})
	aAdd(aCli, {"A1_END"    , cEndCli              	, Nil})
	aAdd(aCli, {"A1_TIPO"   , cTipo                	, NIL})
	aAdd(aCli, {"A1_EST"    , cUFCli               	, Nil})
	//aAdd(aCli, {"A1_COD_MUN", cCodMunCli           	, Nil})
	aAdd(aCli, {"A1_MUN"    , cMunCli              	, Nil})
	aAdd(aCli, {"A1_BAIRRO" , cBaiCli               , Nil})
	aAdd(aCli, {"A1_DDD"    , cDDD              	, Nil})
	aAdd(aCli, {"A1_TEL"    , cFonCli              	, Nil})
	aAdd(aCli, {"A1_CGC"    , cCNPCli              	, Nil})
	aAdd(aCli, {"A1_EMAIL"  , cEMAIL              	, Nil})
	aAdd(aCli, {"A1_YWFCOB" , cEMAIL                , Nil})
	aAdd(aCli, {"A1_INSCR"  , cIECli               	, Nil})
	aAdd(aCli, {"A1_CEP"    , cCEPCli              	, Nil})
	//aAdd(aCli, {"A1_PAIS"   , '105'              	, Nil})
	//aAdd(aCli, {"A1_CODPAIS", '01058'      			, Nil})
	//aAdd(aCli, {"A1_CONTRIB", cContrib      		, Nil})
	aAdd(aCli, {"A1_NATUREZ", '0000000001'      		, Nil})
	//aAdd(aCli, {"A1_VEND", 	  '000001'      		, Nil})
	//aAdd(aCli, {"A1_GRPTRIB", '001'					, Nil})

	lMsErroAuto := .F.
	MsExecAuto({|x,y| MATA030(x,y)}, aCli, 3)
	If lMsErroAuto
	     MostraErro()
	Else
	     Alert('FOI')
	EndIf
Else
	Alert('JA TEM')
EndIF

RESET ENVIRONMENT

Return(.T.)
