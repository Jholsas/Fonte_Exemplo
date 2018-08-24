/*---------------------------------------------------------------------------*\
| DESCRIPTION: This routine makes it possible to include, change or delete any |
| product in the Product Registration routine without GUI use.                 |
|------------------------------------------------------------------------------|
| LINK: http://tdn.totvs.com/display/public/PROT/MATA010+-+Cadastro+de+Produto |
\*----------------------------------------------------------------------------*/

#Include "totvs.ch"
#Include "tbiconn.ch"

User Function TMATA010()
	Local nOpr    := 4
	Local nX      := 0
	Local aHeader := {}
	Local aArea   := {}

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	RPCSetEnv("99", "01", NIL, NIL, "EST", NIL, {"SB1", "SB5"})
		GetEnvInfo("MATA010.PRX")

		aArea := GetArea()

		// BEGIN: INCLUDE //
		// For nX := 1 To 1000
			If (nOpr == 3)
				AAdd(aHeader, {"B1_COD",        "PROD001" + StrZero(nX, 6),    NIL})
				AAdd(aHeader, {"B1_DESC",       "PROD001" + StrZero(nX, 6),    NIL})
				AAdd(aHeader, {"B1_TIPO",       "PA",                         NIL})
				AAdd(aHeader, {"B1_UM",         "UN",                         NIL})
				AAdd(aHeader, {"B1_LOCPAD",     "01",                         NIL})
				AAdd(aHeader, {"B1_PICM",       0,                            NIL})
				AAdd(aHeader, {"B1_IPI",        0,                            NIL})
				AAdd(aHeader, {"B1_LOCALIZ",    "N",                          NIL})
				AAdd(aHeader, {"B1_CONTRAT",    "N",                          NIL})
				AAdd(aHeader, {"B1_PROC",       "",                           NIL})
			EndIf

			// MsExecAuto({|x, y| MATA010(x, y)}, aHeader, nOpr)

			// aHeader := {}
		// Next nX
		// END: INCLUDE //

		MsExecAuto({|x, y| MATA010(x, y)}, aHeader, nOpr)

		If (lMsErroAuto == .T.)
			MostraErro()

			ConOut(Repl("-", 80))
			ConOut(PadC("MATA010 automatic routine ended with error", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		Else
			ConOut(Repl("-", 80))
			ConOut(PadC("MATA010 automatic routine successfully ended", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		EndIf

		RestArea(aArea)
	RPCClearEnv()
Return (NIL)

/*----------------------------------------------------------*\
| DESCRIPTION: This function returns environment and routine |
| information without GUI use.                               |
|------------------------------------------------------------|
| AUTHOR: Guilherme Bigois       |      MODIFIED: 2018/05/23 |
\*----------------------------------------------------------*/

Static Function GetEnvInfo(cRoutine)
	Local aRPO := {}
    Default cRoutine := ""

    aRPO := GetApoInfo(cRoutine)

    If (Empty(aRPO) == .F.)
        ConOut(Repl("-", 80))
        ConOut(PadC("Routine: " + aRPO[1], 80))
        ConOut(PadC("Date: " + DToC(aRPO[4]) + " " + aRPO[5], 80))
        ConOut(Repl("-", 80))
        ConOut(PadC("SmartClient: " + GetBuild(.T.), 80))
        ConOut(PadC("AppServer: " + GetBuild(.F.), 80))
        ConOut(PadC("DbAccess: " + TCAPIBuild() + "/MSSQL" , 80))
		ConOut(Repl("-", 80))
        ConOut(PadC("Started at: " + Time(), 80))
        ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
        ConOut(PadC("An error occurred while searching routine data with GetEnvInfo()", 80))
        ConOut(Repl("-", 80))
    EndIf
Return (NIL)
