#INCLUDE "PROTHEUS.CH"
user function MT110TEL
Local oNewDialog := PARAMIXB[1]
Local aPosGet    := PARAMIXB[2]
Local nOpcx      := PARAMIXB[3]
Local nReg       := PARAMIXB[4]
Public cEx	     := SPACE(5)

aadd(aPosGet[1],0)
aadd(aPosGet[1],0)

aPosGet[1,7]:=55
aPosGet[1,8]:=80
//@ nLinha, nColuna SAY cTexto SIZE nLargura,nAltura UNIDADE OF oObjetoRef
@ 39,aPosGet[1,7] SAY 'Exemplo' PIXEL SIZE 10,9 Of oNewDialog
@ 27,aPosGet[1,8] MSGET cEx PIXEL SIZE 10,08 Of oNewDialog

 RETURN
