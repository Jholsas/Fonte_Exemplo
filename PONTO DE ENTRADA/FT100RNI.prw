#Include "Protheus.ch"
User Function FT100RNI()
Local cCodReg     := ParamIXB[1]
Local cTabPreco   := ParamIXB[2]
Local cCondPg     := ParamIXB[3]
Local cFormPg     := ParamIXB[4]
Local aProdutos   := ParamIXB[5]
Local aProdDesc   := ParamIXB[6]
Local lContinua   := ParamIXB[7]
Local lRetorno    := ParamIXB[8]
Local lContVerba  := ParamIXB[9]
Local lExecao     := ParamIXB[10]
Local aRetPE      := {}

Alert("Passou no ponto FT100RNI!")
aRetPE := {aProdDesc,lContinua,lRetorno,lContVerba,lExecao}

Return aRetPE
