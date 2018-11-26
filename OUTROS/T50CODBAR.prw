#Include "TOTVS.ch"
#Include "TBICONN.ch"
#Include "FWPRINTSETUP.ch"

User Function T50CODBAR()
    Local oPrinter := ""
    Local cEAN     := "1234567890126"
    Local cCODE128 := "PRT00128EMP01"
    Local cINT25   := "453788732590245745441141366777"
    Local oFont    :=  TFont():New("Arial", 6, 14 )

    RPCSetEnv("99", "01")

         oPrinter := NIL
         oPrinter := FwMsPrinter():New("code" + StrZero(nX, 4) + ".rel", 6, .F., "c:\Temp\", .T., NIL, NIL, NIL, .F., .F., NIL, .F.)
         oPrinter:SetResolution(72)
         oPrinter:SetPortrait()
         oPrinter:SetPaperSize(DMPAPER_A4)
         oPrinter:SetMargin(0, 0, 0, 0)
         oPrinter:lServer  := .T.
         oPrinter:cPathPDF := "c:\Temp\"
         oPrinter:StartPage()
             oPrinter:Say(7, 1, "TESTE DE FONTES", oFont)
             oPrinter:FwMsBar("INT25"   /*cTypeBar*/, 01 /*nRow*/, 01 /*nCol*/, cINT25   /*cCode*/, oPrinter /*oPrint*/, .T. /*lCheck*/, /*Color*/, .T. /*lHorz*/, NIL /*nWidth*/, NIL /*nHeigth*/, .T. /*lBanner*/, "Arial" /*cFont*/, NIL /*cMode*/, .F. /*lPrint*/, 02 /*nPFWidth*/, 02 /*nPFHeigth*/, .F. /*lCmtr2Pix*/)
             oPrinter:FwMsBar("EAN13"   /*cTypeBar*/, 11 /*nRow*/, 01 /*nCol*/, cEAN     /*cCode*/, oPrinter /*oPrint*/, NIL /*lCheck*/, /*Color*/, .T. /*lHorz*/, NIL /*nWidth*/, NIL /*nHeigth*/, .T. /*lBanner*/, "Arial" /*cFont*/, NIL /*cMode*/, .F. /*lPrint*/, 02 /*nPFWidth*/, 02 /*nPFHeigth*/, .F. /*lCmtr2Pix*/)
             oPrinter:FwMsBar("CODE128" /*cTypeBar*/, 21 /*nRow*/, 01 /*nCol*/, cCODE128 /*cCode*/, oPrinter /*oPrint*/, NIL /*lCheck*/, /*Color*/, .T. /*lHorz*/, NIL /*nWidth*/, NIL /*nHeigth*/, .T. /*lBanner*/, "Arial" /*cFont*/, NIL /*cMode*/, .F. /*lPrint*/, 02 /*nPFWidth*/, 02 /*nPFHeigth*/, .F. /*lCmtr2Pix*/)
         oPrinter:EndPage()
         oPrinter:Print()
         oPrinter:Preview()



    RPCClearEnv()
Return (NIL)

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
Definição do interface

@author vieira.victor

@since 22/11/2018
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ViewDef()
Local oView
Local oModel := ModelDef()

oView := FWFormView():New()

oView:SetModel(oModel)

Return oView