/*------------------------------------------------------------------*\
| DESCRIPTION:                                                       |
|--------------------------------------------------------------------|
| LINK:                                                              |
\*------------------------------------------------------------------*/

#Include "TOTVS.ch"
#Include "TBICONN.ch"

User Function TMATA650()
	Local nOpr    := 3
	Local aHeader := {}
	Local aArea   := {}

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	RPCSetEnv("99", "01", NIL, NIL, "PCP", NIL, {"SC2"})
		GetEnvInfo("MATA650.PRX")

		aArea := GetArea()

		// BEGIN: INCLUDE //
		If (nOpr == 3)
            AAdd(aHeader, {"C2_FILIAL",     FwXFilial("SC2"),    NIL})
            AAdd(aHeader, {"C2_NUM",        "OP0019",            NIL})
            AAdd(aHeader, {"C2_ITEM",       "01",                NIL})
            AAdd(aHeader, {"C2_SEQUEN",     "001",               NIL})
            AAdd(aHeader, {"C2_PRODUTO",    "PRDT0024",          NIL})
            AAdd(aHeader, {"C2_LOCAL",      "01",                NIL})
            AAdd(aHeader, {"C2_QUANT",      10,                  NIL})
            AAdd(aHeader, {"C2_DATPRF",     dDataBase,           NIL})
            AAdd(aHeader, {"C2_OPC",        "G01IT03/",          NIL})
            AAdd(aHeader, {"AUTEXPLODE",    "S",                 NIL})
		EndIf
		// END: INCLUDE //

        MsExecAuto({|w, x| MATA650(w, x)}, aHeader, nOpr)

		If (lMsErroAuto == .T.)
			MostraErro()

			ConOut(Repl("-", 80))
			ConOut(PadC("MATA650 automatic routine ended with error", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		Else
			ConOut(Repl("-", 80))
			ConOut(PadC("MATA650 automatic routine successfully ended", 80))
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
