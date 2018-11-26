#include "PROTHEUS.CH"
#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#include "APWEBEX.CH"
#INCLUDE "FWPrintSetup.ch"
#include "ap5mail.ch"
#include "tbiconn.ch"
#include "tbicode.ch"
#include "topconn.ch"



User Function GT1649()


Local aCA       :={OemToAnsi("Confirma"),OemToAnsi("Abandona")}
Local cCadastro := OemToAnsi("Impressao de solicitação")
Local aSays:={}, aButtons:={}
Local nOpca     := 0
Local cMsg := ""
Local lOk := .F.

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis tipo Private padrao de todos os relatorios         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Private aReturn    := {OemToAnsi('Zebrado'), 1,OemToAnsi('Administracao'), 2, 2, 1, '',1 } // ###
Private nLastKey   := 0
Private cPerg      := "GT1649"
Private _nItem     := 0
//ValidPerg()
//ValEstrut()

Pergunte(cPerg,.F.)

//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

AADD(aSays,OemToAnsi( "  Este programa ira imprimir a Solicitação"))
AADD(aSays,OemToAnsi( "obedecendo os parametros escolhidos pelo cliente.          "))

AADD(aButtons, { 5,.T.,{|| Pergunte(cPerg,.T. ) } } )
AADD(aButtons, { 1,.T.,{|| nOpca := 1,FechaBatch() }} )
AADD(aButtons, { 2,.T.,{|| nOpca := 0,FechaBatch() }} )

FormBatch( cCadastro, aSays, aButtons )
If nOpca == 1
	Processa( { |lEnd| ImpND() })
EndIf

Return .T.


Static Function ImpND()
#DEFINE DMPAPER_A4 9 	// A4 210 x 297 mm


Local cCont := space(50)
Local cMail := space(100)
Local oDlg
Local cUpd := ""
Local cQry := ""
Local cQtde  := MV_PAR03
Loca nVlrtot := 0


Private nHeight:=15
//Private lBold:= .F.
//Private lUnderLine:= .F.
//Private lPixel:= .T.
//Private lPrint:=.F.
// Private oFont1:= TFont():New( "Verdana",,26,,.t.,,,,,.f. )
// Private oFont2:= TFont():New( "Times New Roman",,14,,.t.,,,,,.f. ) //Verdana 09 Normal
// Private oFont3:= TFont():New( "Times New Roman",,14,,.f.,,,,,.f. ) //Verdana 09 negrito
// Private oFont4:= TFont():New( "Verdana",,10,,.t.,,,,,.f. ) //verdana tamanho 12 negrito
// Private oFont5:= TFont():New( "Times New Roman",,12,,.f.,,,,,.f. ) //verdana 10 negrito
// Private oFont6:= TFont():New( "Verdana",,6,,.f.,,,,,.f. ) //verdana 10 negrito
// Private oFont7:= TFont():New( "Verdana",,9,,.f.,,,,,.f. ) //verdana 10 negrito
Private oFont8:= TFont():New( "Times New Roman",,10,,.f.,,,,,.f. ) //verdana 10 negrito
Private oPrn

Private nLin:= 80


oPrn:=FwMSPrinter():New('TESTE',6,.T.,,.T.)

 	nLin +=80
 	nLin +=80
	oPrn:Say(nLin,0220,"Lorem ipsum adipiscing porta purus class donec ut, tellus elementum diam elit varius lectus tempor,," ,oFont8,100)
	nLin += 80
	oPrn:Say(nLin,0220,"gravida ultricies orci potenti posuere mattis. eget scelerisque dictum id mauris et posuere malesuada," ,oFont8,100)
	nLin += 80
	oPrn:Say(nLin,0220,"elit interdum rhoncus elit facilisis congue vel ut, non luctus platea urna at aliquam,",oFont8,100)
	nLin +=80
	oPrn:Say(nLin,0220,"libero vestibulum maecenas phasellus quis eget leo fames, tellus nibh mollis nulla orci torto",oFont8,100)
   	nLin +=80

	oPrn:Line(nLin,0020,nLin,2400)





//oPrn:Preview()    //ALTERADO PARA TRATAR ERRO APRESENTADO APOS ATUALIZAÇÃO    18/06/15 PATRICIA

//makedir("c:\solicitacao\") //cria pasta recibo no c: caso não exista
oPrn:cPathPDF := "C:\solicitacao\"  //salva o pdf na pasta recibo
//oPrn:SetViewPdf(.T.) // Não exibe o preview            //ALTERADO PARA .T.   //18/06/15 PATRICIA
oPrn:Preview()    //função que gera o arquivo em pdf para salvar no diretorio c:
//FERASE("\system\solicitacao\"+MV_PAR01+"_"+MV_PAR02+".pdf")

Return .T.






lAdjustToLegacy := .F.
 lDisableSetup  := .T.
 oPrinter := FWMSPrinter():New("Danfe.rel", IMP_PDF, lAdjustToLegacy, , lDisableSetup)
 // Ordem obrigátoria de configuração do relatório
 oPrinter:SetResolution(72)
 oPrinter:SetPortrait()
 oPrinter:SetPaperSize(DMPAPER_A4)
 oPrinter:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
 oPrinter:cPathPDF := "c:\directory\" // Caso seja utilizada impressão em IMP_PDF
