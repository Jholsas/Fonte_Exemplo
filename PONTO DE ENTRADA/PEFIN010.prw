#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINA010
Exemplo de uso dos pontos de entrada padr�o para o cadastro de Naturezas em MVC

@author Pedro Pereira Lima
@since 30/05/2017
@version 12.1.17

/*/
//-------------------------------------------------------------------------------------------
User Function FINA010()
Local aParam := PARAMIXB
Local xRet := .T.
Local oObjForm
Local cIdExec
Local cIdForm

//-----------------------------------------------------------------------------------------------------
// Na hip�tese dos par�metros serem nulos, aborto a execu��o dos pontos de entrada do MVC
//-----------------------------------------------------------------------------------------------------
If aParam != Nil
oObjForm := aParam[1]
cIdExec := aParam[2]
cIdForm := aParam[3]

//-----------------------------------------------------------------------------------------------------
// Valida��o total do modelo - MODELPOS
//-----------------------------------------------------------------------------------------------------
If cIdExec == 'MODELPOS'

//-----------------------------------------------------------------------------------------------------
// Para valida��o de exclus�o, utilizar a constante MODEL_OPERATION_INSERT e o m�todo GetOperation()
//-----------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_INSERT // Equivale ao FA010INC
Alert('Apenas para exemplificar que, na inclus�o de um novo registro, essa valida��o pode ser utilizada para confirmar ou n�o a grava��o')
xRet := .T.
EndIf

//-----------------------------------------------------------------------------------------------------
// Para valida��o de exclus�o, utilizar a constante MODEL_OPERATION_UPDATE e o m�todo GetOperation()
//-----------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_UPDATE // Equivale ao FA010ALT
Alert('Apenas para exemplificar que, na altera��o de um novo registro, essa valida��o pode ser utilizada para confirmar ou n�o a grava��o')
xRet := .T.
EndIf

//-----------------------------------------------------------------------------------------------------
// Para valida��o de exclus�o, utilizar a constante MODEL_OPERATION_DELETE e o m�todo GetOperation()
//-----------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_DELETE // Equivale ao F010CAND e ao F10NATDEL
Alert('Execu��o da p�s valida��o do model quando executado o "Delete"')
Help(,,'Pontos de Entrada MVC',,'Help do p�s valid do MVC ap�s valida��o do ponto de entrada default do MVC',1,0)
xRet := .F.
EndIf

//-----------------------------------------------------------------------------------------------------
// Antes da grava��o da tabela do formul�rio - FORMCOMMITTTSPRE
//-----------------------------------------------------------------------------------------------------
ElseIf cIdExec == 'FORMCOMMITTTSPRE'

//--------------------------------------------------------------------------------------------------------------------
// Para grava��es adicionais antes da inclus�o, utilizar a constante MODEL_OPERATION_INSERT e o m�todo GetOperation()
//--------------------------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_INSERT // Equivale ao FIN010INC
Alert('A inclus�o pode ter dados manipulados como grava��o adicional neste momento, antes da confirma��o da transa��o')
xRet := Nil
EndIf

//--------------------------------------------------------------------------------------------------------------------
// Para grava��es adicionais antes da altera��o, utilizar a constante MODEL_OPERATION_INSERT e o m�todo GetOperation()
//--------------------------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_UPDATE // Equivale ao FIN010ALT
Alert('A altera��o pode ter dados manipulados como grava��o adicional neste momento, antes da confirma��o da transa��o')
xRet := Nil
EndIf

//--------------------------------------------------------------------------------------------------------------------
// Para grava��es adicionais antes da exclus�o, utilizar a constante MODEL_OPERATION_INSERT e o m�todo GetOperation()
//--------------------------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_DELETE // Equivale ao FIN010EXC
Alert('A exclus�o pode ter dados manipulados como grava��o adicional neste momento, antes da confirma��o da transa��o')
xRet := Nil
EndIf
EndIf

EndIf

Return xRet
