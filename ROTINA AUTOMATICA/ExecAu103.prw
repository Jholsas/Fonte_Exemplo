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

	//PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SF1", "SD1", "SA1", "SA2", "SB1", "SB2", "SF4"
	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

	//ConOut(Repl("-", 80))
	//ConOut(PadC("Teste MATA103 iniciado!", 80))
	//ConOut(PadC("Inicio: " + Time(), 80))
	//ConOut(Repl("-", 80))

	// INÍCIO: INCLUSÃO //
	if nOpc == 3

		aadd(aCabec,{"F1_TIPO"              ,"N"     , nil})
		aadd(aCabec,{"F1_FORMUL"            ," "      , nil})
		aadd(aCabec,{"F1_DOC"               ,"00083" , nil})
		aadd(aCabec,{"F1_SERIE"             ,"NF "    , nil})
		aadd(aCabec,{"F1_EMISSAO"           ,dDataBase, nil})
		aadd(aCabec,{"F1_DESPESA"           ,0     , nil})
		aadd(aCabec,{"F1_FORNECE"           ,"000005", nil})
		aadd(aCabec,{"F1_LOJA"              ,""      , nil})
		aadd(aCabec,{"F1_ESPECIE"           ,"NFE  "   , nil})
		aadd(aCabec,{"F1_COND"              ,"001"   , nil})
		aadd(aCabec,{"F1_DESCONT"           ,0     , nil})
		aadd(aCabec,{"F1_FRETE"             ,0     , nil})

		aadd(aLinha, {"D1_COD"              ,"12345           " ,nil})
		aadd(aLinha, {"D1_QUANT"            ,2		 ,nil})
		aadd(aLinha, {"D1_VUNIT"            ,100  ,nil})
		aadd(aLinha, {"D1_TOTAL"            ,200  ,nil})
		aadd(aLinha, {"D1_TES"              ,"001"   ,nil})

		aadd(aItens, aLinha)
	endIf
	// FIM: INCLUSÃO //

	MATA103(aCabec,aItens,3)
	MSExecAuto({|x, y, z, w| MATA103(x, y, z, w)}, aCabec, aItens, nOpc, )

	if lMsErroAuto
		MostraErro()
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
