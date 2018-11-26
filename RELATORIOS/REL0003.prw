#Include 'Protheus.ch'
#INCLUDE "RPTDEF.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} TsteFWMsprinter
//TODO Descri��o auto-gerada.
@author rodrigo.santiago
@since 21/11/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TsteFWMsprinter()

 //**********************************************************

 LOCAL cPath := "\Spool\"
 LOCAL cFile := "imp_spool"
 LOCAL cFile1:= "imp_pdf"
 LOCAL lAdjustToLegacy  := .F.    //    Compatibilidade om TMSPrinter()
 LOCAL lDisabeSetup      := .F.    //    N�o exibe a Tela de Setup
 LOCAL lServer    := .T.    //    Indica Impress�o via SERVER
 LOCAL lViewPDF    := .F.    //    N�o exibe o PDF
 LOCAL oFont    := TFont():New('Courier new',, -10)


 private oReport    := NIL

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

 //oReport := FWMSPrinter():New(cFile ,2 ,lAdjustToLegacy ,cPath ,lDisabeSetup , , ,"PDF",lServer , , ,lViewPDF) // imp_spool
 oReport := FWMSPrinter():New(cFile1 ,6 ,lAdjustToLegacy ,cPath ,lDisabeSetup  , , ,"PDF",lServer , , ,lViewPDF)  // imp_pdf

 oReport:SetFont(oFont)    //    Fonte Padr�o do Relat�rio
 oReport:SetLandscape()    //    Paisagem
 oReport:SetPaperSize(9)    //    A4
 oReport:SetMargin(10,10,10,10)
 oReport:nHorzSize := 210
 oReport:nVertSize := 297
 oReport:cPathPDF := cPath    //    Caminho p/ salvar o PDF
 //    Gera Relat�rio
  ImpREL()
 //
 oReport:EndPage()
 oReport:Preview()    //    Gera PDF
 FreeObj(oReport)
 MS_FLUSH()

 //
 RESET ENVIRONMENT

RETURN

STATIC FUNCTION ImpREL()

 oReport:SAY(30,100, "T E S T E")
 oReport:SAY(30,300, "Relat�rio em PDF")


RETURN
