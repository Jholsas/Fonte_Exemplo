#include 'protheus.ch'
#include 'parmtype.ch'
#include "rwmake.ch"
user function FA100ROT()

	Local aRotina := aClone(PARAMIXB[1]) //Adiciona Rotina Customizada a EnchoiceBar
	aAdd( aRotina, { 'Teste PE' ,'U_FA100USER', 0 , 7 })

	Return aRotina //Rotina chamada pelo botão criado na EnchoiceBar

	User Function FA100 USER()

	MsgAlert("Teste de Ponto de Entrada")

	Return .T.

return