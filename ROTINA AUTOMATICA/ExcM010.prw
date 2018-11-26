#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'Protheus.ch'
#INCLUDE 'FWMVCDef.ch'

//------------------------------------------------------------------------
/*
EXEMPLO DE INCLUS�O MODELO 1  (Utilizando a fun��o FwMvcRotAuto apenas em car�ter did�tico)
*/
//------------------------------------------------------------------------
User Function m010Inc1Ra()
Local aDadoscab := {}
Local aDadosIte := {}
Local aItens    := {}
Local nX := 0
//Local nCodPro := 000504 // CValToChar(nCodPro)

Private oModel      := Nil
Private lMsErroAuto := .F.
Private aRotina     := {}

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EST"
//for nX := 1 to 400

oModel := FwLoadModel ("MATA010")
//Adicionando os dados do ExecAuto cab
aAdd(aDadoscab, {"B1_COD"       ,"PROD0012" 		 , Nil})
aAdd(aDadoscab, {"B1_DESC"      ,"PRODUTO TESTE"     , Nil})
aAdd(aDadoscab, {"B1_TIPO"      ,"PA"                , Nil})
aAdd(aDadoscab, {"B1_UM"        ,"UN"                , Nil})
aAdd(aDadoscab, {"B1_LOCPAD"    ,"01"                , Nil})
aAdd(aDadoscab, {"B1_LOCALIZ"   ,"N"                 , Nil})

//Chamando a inclus�o - Modelo 1
lMsErroAuto := .F.

FWMVCRotAuto( oModel,"SB1",MODEL_OPERATION_INSERT,{{"SB1MASTER", aDadoscab}})

	//	++nCodPro
	//Next nX
//Se houve erro no ExecAuto, mostra mensagem
If lMsErroAuto
 MostraErro()
//Sen�o, mostra uma mensagem de inclus�o
Else
 MsgInfo("Registro incluido!", "Aten��o")
EndIf
RESET ENVIRONMENT


Return Nil
