#include 'protheus.ch'
#include 'parmtype.ch'
#include "rwmake.ch"
user function FA100ROT()

	Local aRotina := aClone(PARAMIXB[1]) //Adiciona Rotina Customizada a EnchoiceBar
	aAdd( aRotina,{ 'Opc Unica' ,'U_FA100USER', 0 , 7 })
	aAdd(aRotina,{ "Varias Opc" ,{{'OPC1'  , 'U_OPC1',0, 1 },{'OPC2'  , 'U_OPC2',0, 1 },{'OPC3'  , 'U_OPC3',0, 2 },{'OPC4'  , 'U_OPC4',0, 2 }},0,6, ,.F.})

	Return aRotina //Rotina chamada pelo botão criado na EnchoiceBar

	User Function FA100USER()

	MsgAlert("Teste de Ponto de Entrada - FA100ROT")

	Return .T.

return
