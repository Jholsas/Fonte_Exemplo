

#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"


User Function MT030EXC()

    Local nOpc   := 3 // 3) INCLUSÃO || 4) ALTERAÇÃO
	Local aCabec := {}

	Private lMsErroAuto := .F.
    Private lMsHelpAuto := .T.

	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SA1"

	GetEnvInfo("MATA030.PRX")

	// INÍCIO: INCLUSÃO //
	If nOpc == 3
			aCabec := {	{"A1_COD",       "CLT009",                   NIL},;
                        {"A1_LOJA",      "01",                       NIL},;
                        {"A1_NOME",      "ROGER DOGS PETS",          NIL},;
                        {"A1_PESSOA",    "J",                        NIL},;
                        {"A1_NREDUZ",    "RODROGS",                  NIL},;
                        {"A1_BAIRRO",    "AMERICANÓPOLIS",           NIL},;
                        {"A1_TIPO",      "F",                        NIL},;
                        {"A1_END",       "RUA FERNANDO GOMES",       NIL},;
                        {"A1_MUN",       "JACAREÍ",                  NIL},;
                        {"A1_EST",       "SP",                       NIL}}
	EndIf
	// FIM: INCLUSÃO //

	MsExecAuto({|x, y| MATA030(x, y)}, aCabec, nOpc)

	If (lMsErroAuto == .T.)
		MostraErro()
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA030 finalizado com erro!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	Else
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA030 finalizado com sucesso!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	EndIf

	RESET ENVIRONMENT
Return NIL

/*------------------------------------------------------------------*\
| DESCRIÇÃO: Esta função tem como objetivo retornar informações do   |
| ambiente e rotina sem a necessidade de abertura do SmartClient     |
|--------------------------------------------------------------------|
| AUTOR: Guilherme Bigois         |        MODIFICADO EM: 01/03/2018 |
\*------------------------------------------------------------------*/

Static Function GetEnvInfo(cRotina)
	Local aRPO := {}
    Default cRotina := ""

    aRPO := GetApoInfo(cRotina)

    If !Empty(aRPO)
        ConOut(Repl("-", 80))
        ConOut(PadC("Rotina: " + aRPO[1], 80))
        ConOut(PadC("Data: " + DToC(aRPO[4]) + " " + aRPO[5], 80))
        ConOut(Repl("-", 80))
        ConOut(PadC("SmartClient: " + GetBuild(.T.), 80))
        ConOut(PadC("AppServer: " + GetBuild(.F.), 80))
        ConOut(PadC("DbAccess: " + TCAPIBuild() + "/MSSQL" , 80))
		ConOut(Repl("-", 80))
        ConOut(PadC("Inicio: " + Time(), 80))
        ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
        ConOut(PadC("Ocorreu um erro ao pesquisar os dados do ambiente pela funcao GetEnvInfo()", 80))
        ConOut(Repl("-", 80))
    EndIf
Return NIL
