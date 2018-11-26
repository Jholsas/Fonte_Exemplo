#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE 'Protheus.ch'
#INCLUDE 'FWMVCDef.ch'

//------------------------------------------------------------------------
/*
EXEMPLO DE INCLUSÃO MODELO 1
*/
//------------------------------------------------------------------------
User Function MT010MVC()
Local oModel      := Nil
Private lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EST"

oModel  := FwLoadModel ("MATA010")
oModel:SetOperation(MODEL_OPERATION_INSERT)
oModel:Activate()
oModel:SetValue("SB1MASTER","B1_COD"        ,"PRDT0010")
oModel:SetValue("SB1MASTER","B1_DESC"       ,"PRODUTO EXC MVC")
oModel:SetValue("SB1MASTER","B1_TIPO"       ,"PA")
oModel:SetValue("SB1MASTER","B1_UM"         ,"UN")
oModel:SetValue("SB1MASTER","B1_LOCPAD"     ,"01")
oModel:SetValue("SB1MASTER","B1_LOCALIZ"    ,"N")


If oModel:VldData()
    oModel:CommitData()
     MsgInfo("Registro INCLUIDO!", "Atenção")
Else
    VarInfo("",oModel:GetErrorMessage())
EndIf

oModel:DeActivate()
oModel:Destroy()

oModel := NIL

Return Nil
