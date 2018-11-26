#include 'protheus.ch'
#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "TBICONN.CH"

user function EOSA010()  //teste 14/03/2017

	local aCab 		:= {}
	local aItem		:= {}
	local nOpc 		:= 4
	local i
	local cCodTab 	:= "001"
	local cNomeTab 	:= "TESTE 01                      "
	local cHoraDe 	:= "00:00"
	local cHoraAte 	:= "23:59"
	local cTpHorario 	:= "1"
	local cTabAtiv 	:= "1"
	local cItem 		:= "001"
	local cProduto 	:= "0000000001     "
	local nPrcVen 	:= 50
	local nPrcVen2 	:= 20
	local cAtivo 		:= "1"
	local aItens		:={}
	PRIVATE lMsErroAuto := .F.



	PREPARE ENVIRONMENT EMPRESA '99' FILIAL '01'

	aAdd(aCab,	{"DA0_CODTAB"	, cCodTab	, NIL})
	aAdd(aCab,	{"DA0_DESCRI"	, cNomeTab	, NIL})
	aAdd(aCab,	{"DA0_DATDE"	, dDatabase	, NIL})
	aAdd(aCab,	{"DA0_HORADE"	, cHoraDe	, NIL})
	aAdd(aCab,	{"DA0_TPHORA"	, cTpHorario, NIL})
	aAdd(aCab,	{"DA0_ATIVO"	, cTabAtiv	, NIL})

//aItem:={}

	aAdd(aItem,{	{"DA1_ITEM"	, cItem		, NIL},;
					{"DA1_CODPRO"	, cProduto	, NIL},;
					{"DA1_PRCVEN"	, nPrcVen	, NIL},;
					{"LINPOS","DA1_ITEM"	 			,'001'},;
					{"AUTDELETA","N"					,Nil}})

//aadd(aItens, aItem)
//aItem:={}
/*	aAdd(aItem,{	{"DA1_ITEM"	, "0004"		, NIL},;
					{"DA1_CODPRO"	, "TB0000000000002"	, NIL},;
					{"DA1_PRCVEN"	,nPrcVen2 , NIL}})
					//{"LINPOS","DA1_ITEM"	 			,'0002'},;
					//{"AUTDELETA","S"					,Nil}})*/

//aadd(aItens, aItem)

	Omsa010(aCab,aItem,nOpc)

	If lMsErroAuto

		DisarmTransaction()
		Mostraerro()
	Else
		conout("ALterado com sucesso.")
	EndIf
	RESET ENVIRONMENT
Return(.T.)
