#Include "rwmake.ch"
#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"

User Function xTeste7 ()

Local cRet := ''

DbSelectArea('SC5')
DbSetOrder(1)
//SC5->C5_CLIENTE + SC5->C5_LOJACLI
If SC5->C5_TIPO $ 'B/D'
    cRet := Posicione('SA2',1,xFilial('SA2') + SC5->C5_CLIENTE + SC5->C5_LOJACLI,'A2_NOME')
ElseIf SC5->C5_TIPO $ 'N'
    cRet := Posicione('SA1',1,xFilial('SA1') + SC5->C5_CLIENTE + SC5->C5_LOJACLI,'A1_NOME')
Endif

Return cRet

/*User Function FRI736()

Private lFTitFunc := .T.
private aRotina := FWLoadMenuDef("FINA110")

FINA110()

Return*/

Return
