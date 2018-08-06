#INCLUDE "TOTVS.CH"

user FUNCTION testOleContainer()

Local oDlg
local aTela
local nLargura
local nAltura
Local oPainel



  DEFINE DIALOG oDlg TITLE "Exemplo TOleContainer" FROM 180,180 TO 1000,1000 PIXEL
  oDlg:lMaximized:= .T.
    aTela := MsAdvSize()
    nLargura := aTela[5]
    nAltura := aTela[6]
  oTOleContainer := TOleContainer():New(01, 01, nLargura , nAltura , oPainel, .T., 'C:\Users\vieira.victor\Downloads\ShellExecute.pdf')
  ACTIVATE DIALOG oDlg CENTERED

RETURN
