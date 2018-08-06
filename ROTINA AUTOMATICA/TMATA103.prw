/*-----------------------------------------------------------------*\
| DESCRIPTION: This routine makes it possible to include, change or |
| delete any entry invoice at Entry Invoice routine without GUI     |
| use.                                                              |
|-------------------------------------------------------------------|
| LINK: http://tdn.totvs.com/pages/viewpage.action?pageId=235592777 |
\*-----------------------------------------------------------------*/

#Include "totvs.ch"
#Include "tbiconn.ch"

User Function TMATA103()
    Local nOpr	  := 3
	Local aHeader := {}
	Local aItems  := {}
	Local aLine   := {}
	Local aArea   := {}
	Local aColsCC := {}

	Local nX     := 0
	Local lXML   := .F.
	Local aInfos := {}
	Local oXML   := NIL

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	RPCSetEnv("99", "01", NIL, NIL, "FIN", NIL, {"SF1", "SE2", "SD1"})
		GetEnvInfo("MATA103.PRW")

		aArea := GetArea()

		// BEGIN: DEFAULT INCLUDE //
		If (nOpr == 3 .And. lXML == .F.)
			AAdd(aHeader, {"F1_TIPO",       "N",            NIL})
			AAdd(aHeader, {"F1_FORMUL",     "N",            NIL})
			AAdd(aHeader, {"F1_DOC",        "DCEN00123",    NIL})
			AAdd(aHeader, {"F1_SERIE",      "10",           NIL})
			AAdd(aHeader, {"F1_EMISSAO",    dDataBase,      NIL})
			AAdd(aHeader, {"F1_DESPESA",    0,              NIL})
			AAdd(aHeader, {"F1_FORNECE",    "FNC005",       NIL})
			AAdd(aHeader, {"F1_LOJA",       "1 ",           NIL})
			AAdd(aHeader, {"F1_ESPECIE",    "NFE",          NIL})
			AAdd(aHeader, {"F1_COND",       "001",          NIL})
			AAdd(aHeader, {"F1_DESCONT",    0,              NIL})
			AAdd(aHeader, {"F1_SEGURO",     0,              NIL})
			AAdd(aHeader, {"F1_FRETE",      0,              NIL})
			AAdd(aHeader, {"F1_VALMERC",    100,            NIL})
			AAdd(aHeader, {"F1_VALBRUT",    100,            NIL})
			AAdd(aHeader, {"F1_MOEDA",      1,              NIL})
			AAdd(aHeader, {"F1_TXMOEDA",    1,              NIL})
			AAdd(aHeader, {"F1_STATUS",     "A",            NIL})

			AAdd(aLine, {"D1_COD",       "PRDT0003",    NIL})
			AAdd(aLine, {"D1_QUANT",     3,             NIL})
			AAdd(aLine, {"D1_VUNIT",     100.11,        NIL})
			AAdd(aLine, {"D1_TOTAL",     300.33,        NIL})
			AAdd(aLine, {"D1_TES",       "222",         NIL})
			AAdd(aLine, {"D1_SEGURO",    0,             NIL})
			AAdd(aLine, {"D1_VALFRE",    0,             NIL})
			AAdd(aLine, {"D1_DESPESA",   0,             NIL})
			AAdd(aLine, {"D1_PICM",      4.11,          NIL})
			AAdd(aLine, {"D1_VALICM",    4.11,          NIL})
			AAdd(aLine, {"D1_RATEIO",    "1",           NIL})
			AAdd(aLine, {"AUTDELETA",    "N",           NIL})

			AAdd(aItems, aLine)

			If Empty(aColsCC)
                DbSelectArea("SDE")

                AAdd(aColsCC, {"0001", {}})
    			AAdd(aColsCC[1][2], {{"DE_ITEM",      "01"},;
                                    {"DE_PERC",       100},;
                                    {"DE_CC",         "CNTC0001"},;
                                    {"DE_CONTA",      "CCT00009"},;
                                    {"DE_ITEMCTA",    "IT0000002"},;
                                    {"DE_CLVL",       "CLV00001 "}})
			EndIf
		EndIf
		// END: DEFAULT INCLUDE //

		// BEGIN: INCLUDE WITH XML //
		If (nOpr == 3 .And. lXML == .T.)

			oXML := U_T46XML()
			aInfos := Array(16)

			For nX := 1 To Len(oXML:_DATA:_ITEM:_OBJECT:_PROPERTY)
				aInfos[nX] := oXML:_DATA:_ITEM:_OBJECT:_PROPERTY[nX]:TEXT
			Next nX

			Aadd(aHeader, {"F1_TIPO",       aInfos[1]})
			Aadd(aHeader, {"F1_FORMUL",     aInfos[2]})
			Aadd(aHeader, {"F1_DOC",        aInfos[3]})
			Aadd(aHeader, {"F1_SERIE",      aInfos[4]})
			Aadd(aHeader, {"F1_EMISSAO",    &(aInfos[5])})
			Aadd(aHeader, {"F1_FORNECE",    aInfos[6]})
			Aadd(aHeader, {"F1_LOJA",       aInfos[7]})
			Aadd(aHeader, {"F1_ESPECIE",    aInfos[8]})
			Aadd(aHeader, {"F1_COND",       aInfos[9]})
			Aadd(aHeader, {"F1_DESPESA",    Val(aInfos[10])})
			Aadd(aHeader, {"E2_NATUREZ",    aInfos[11]})

			Aadd(aLine, {"D1_COD",      aInfos[12],        NIL})
			Aadd(aLine, {"D1_QUANT",    Val(aInfos[13]),   NIL})
			Aadd(aLine, {"D1_VUNIT",    Val(aInfos[14]),   NIL})
			Aadd(aLine, {"D1_TOTAL",    Val(aInfos[15]),   NIL})
			Aadd(aLine, {"D1_TES",      aInfos[16],        NIL})

			Aadd(aItems, aLine)
		EndIf
		// END: INCLUDE WITH XML //

		// BEGIN: DELETE //
		If (nOpr == 5)
			DbSelectArea("SF1")
			DbSetOrder(1)
			MsSeek("01" + "DCEN00013" + "5  " + "FNC006" + "1 " + "N ")

			Aadd(aHeader, {"F1_TIPO",       SF1->F1_TIPO})
			Aadd(aHeader, {"F1_FORMUL",     SF1->F1_FORMUL})
			Aadd(aHeader, {"F1_DOC",        SF1->F1_DOC})
			Aadd(aHeader, {"F1_SERIE",      SF1->F1_SERIE})
			Aadd(aHeader, {"F1_EMISSAO",    SF1->F1_EMISSAO})
			Aadd(aHeader, {"F1_FORNECE",    SF1->F1_FORNECE})
			Aadd(aHeader, {"F1_LOJA",       SF1->F1_LOJA})
			Aadd(aHeader, {"F1_ESPECIE",    SF1->F1_ESPECIE})
			Aadd(aHeader, {"F1_COND",       SF1->F1_COND})
			Aadd(aHeader, {"F1_DESPESA",    SF1->F1_DESPESA})
		EndIf
		// END: DELETE //

		MsExecAuto({|x, y, z, w| MATA103(x, y, z, w)}, aHeader, aItems, nOpr, .F., NIL, NIL, NIL, aColsCC)

		If (lMsErroAuto == .T.)
			MostraErro()

			ConOut(Repl("-", 80))
			ConOut(PadC("MATA103 automatic routine ended with error", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		Else
			ConOut(Repl("-", 80))
			ConOut(PadC("MATA103 automatic routine successfully ended", 80))
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
