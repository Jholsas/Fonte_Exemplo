#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"


User Function RCOMR01()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Declaracao de variaveis                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Private oReport  := Nil
Private oSecCab	 := Nil


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Definicoes/preparacao para impressao      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ReportDef()
oReport:PrintDialog()

Return Nil


Static Function ReportDef()

oReport := TReport():New("RCOMR01","Cadastro de Produtos",,{|oReport| PrintReport(oReport)},"Impressão de cadastro de produtos.")
oReport:SetLandscape(.T.)

oSecCab := TRSection():New( oReport , "Produtos", {"QRY"} )
TRCell():New( oSecCab, "B1_COD"     , "QRY")
TRCell():New( oSecCab, "B1_DESC"    , "QRY")
TRCell():New( oSecCab, "B1_TIPO"    , "QRY")
TRCell():New( oSecCab, "B1_UM"      , "QRY")

//TRFunction():New(/*Cell*/             ,/*cId*/,/*Function*/,/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,/*lEndSection*/,/*lEndReport*/,/*lEndPage*/,/*Section*/)
TRFunction():New(oSecCab:Cell("B1_COD"),/*cId*/,"COUNT"     ,/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F.           ,.T.           ,.F.        ,oSecCab)

Return Nil



Static Function PrintReport(oReport)

Local cQuery     := ""

cQuery += " SELECT " + CRLF
cQuery += "     SB1.B1_COD " + CRLF
cQuery += "    ,SB1.B1_DESC " + CRLF
cQuery += "    ,SB1.B1_TIPO " + CRLF
cQuery += "    ,SB1.B1_UM " + CRLF
cQuery += "  FROM " + RetSqlName("SB1") + " SB1 " + CRLF
cQuery += " WHERE SB1.B1_FILIAL = '" + xFilial ("SB1") + "' " + CRLF
cQuery += "   AND SB1.D_E_L_E_T_ = ' ' " + CRLF
cQuery := ChangeQuery(cQuery)

If Select("QRY") > 0
	Dbselectarea("QRY")
	QRY->(DbClosearea())
EndIf

TcQuery cQuery New Alias "QRY"

oSecCab:BeginQuery()
oSecCab:EndQuery({{"QRY"},cQuery})
oSecCab:Print()


Return Nil
