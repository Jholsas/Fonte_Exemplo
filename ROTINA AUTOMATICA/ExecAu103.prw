#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"

user function ExecAu103()


	local nOpc		:= 3 // 3) INCLUSÃO
	local aCabec	:= {}
	local aItens	:= {}
	local aLinha	:= {}

	private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SF1", "SD1", "SA1", "SA2", "SB1", "SB2", "SF4"
	//PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

	ConOut(Repl("-", 80))
	ConOut(PadC("Teste MATA103 iniciado!", 80))
	ConOut(PadC("Inicio: " + Time(), 80))
	ConOut(Repl("-", 80))

	// INÍCIO: INCLUSÃO //

		// BEGIN: DEFAULT INCLUDE //
		If (nOpc == 3 )
			AAdd(aCabec, {"F1_TIPO"		,   "N"			,NIL})
			AAdd(aCabec, {"F1_FORMUL"	,   " "			,NIL})
			AAdd(aCabec, {"F1_DOC"		,   "00103"		,NIL})
			AAdd(aCabec, {"F1_SERIE"	,   "NF"		,NIL})
			AAdd(aCabec, {"F1_EMISSAO"	,   dDataBase	,NIL})
			AAdd(aCabec, {"F1_DESPESA"	,   0			,NIL})
			AAdd(aCabec, {"F1_FORNECE"	,   "000001"	,NIL})
			AAdd(aCabec, {"F1_LOJA"		,   "01"		,NIL})
			AAdd(aCabec, {"F1_ESPECIE"	,   "NF"		,NIL})
			AAdd(aCabec, {"F1_COND"		,   "001"		,NIL})
			AAdd(aCabec, {"F1_DESCONT"	,   0			,NIL})
			AAdd(aCabec, {"F1_SEGURO"	,   0			,NIL})
			AAdd(aCabec, {"F1_FRETE"	,   0			,NIL})
			AAdd(aCabec, {"F1_VALMERC"	,   100			,NIL})
			AAdd(aCabec, {"F1_VALBRUT"	,   100			,NIL})
			AAdd(aCabec, {"F1_MOEDA"	,   1			,NIL})
			AAdd(aCabec, {"F1_TXMOEDA"	,   1			,NIL})
			AAdd(aCabec, {"F1_STATUS"	,   "A"			,NIL})
			//AAdd(aCabec, {"F1_UFORITR"	,   "AC"		,NIL})
			//AAdd(aCabec, {"F1_MUORITR"	,   "00179"		,NIL})
			//AAdd(aCabec, {"F1_UFDESTR"	,   "BA"		,NIL})
			//AAdd(aCabec, {"F1_MUDESTR"	,   "21708"		,NIL})


			AAdd(aLinha, {"D1_COD"		,   "12345"		,NIL})
			AAdd(aLinha, {"D1_QUANT"	,   3			,NIL})
			AAdd(aLinha, {"D1_VUNIT"	,   100.11		,NIL})
			AAdd(aLinha, {"D1_TOTAL"	,   300.33		,NIL})
			AAdd(aLinha, {"D1_TES"		,   "001"		,NIL})
			AAdd(aLinha, {"D1_SEGURO"	,   0			,NIL})
			AAdd(aLinha, {"D1_VALFRE"	,   0			,NIL})
			AAdd(aLinha, {"D1_DESPESA"	,   0			,NIL})
			AAdd(aLinha, {"D1_PICM"		,   4.11		,NIL})
			AAdd(aLinha, {"D1_VALICM"	,   4.11		,NIL})
			AAdd(aLinha, {"D1_RATEIO"	,   "1"			,NIL})
			AAdd(aLinha, {"AUTDELETA"	,   "N"			,NIL})

			AAdd(aItens, aLinha)

		EndIf

	// FIM: INCLUSÃO //

	MATA103(aCabec,aItens,3)
	MSExecAuto({|x, y, z, w| MATA103(x, y, z, w)}, aCabec, aItens, nOpc, )

	if lMsErroAuto
		//MostraErro()
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA103 finalizado com erro!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	else
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA103 finalizado com sucesso!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	endIf

	RESET ENVIRONMENT
return(.T.)
