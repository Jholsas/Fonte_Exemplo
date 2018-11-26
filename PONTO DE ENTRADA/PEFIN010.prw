#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINA010
Exemplo de uso dos pontos de entrada padrão para o cadastro de Naturezas em MVC

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
// Na hipótese dos parâmetros serem nulos, aborto a execução dos pontos de entrada do MVC
//-----------------------------------------------------------------------------------------------------
If aParam != Nil
oObjForm := aParam[1]
cIdExec := aParam[2]
cIdForm := aParam[3]

//-----------------------------------------------------------------------------------------------------
// Validação total do modelo - MODELPOS
//-----------------------------------------------------------------------------------------------------
If cIdExec == 'MODELPOS'

//-----------------------------------------------------------------------------------------------------
// Para validação de exclusão, utilizar a constante MODEL_OPERATION_INSERT e o método GetOperation()
//-----------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_INSERT // Equivale ao FA010INC
Alert('Apenas para exemplificar que, na inclusão de um novo registro, essa validação pode ser utilizada para confirmar ou não a gravação')
xRet := .T.
EndIf

//-----------------------------------------------------------------------------------------------------
// Para validação de exclusão, utilizar a constante MODEL_OPERATION_UPDATE e o método GetOperation()
//-----------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_UPDATE // Equivale ao FA010ALT
Alert('Apenas para exemplificar que, na alteração de um novo registro, essa validação pode ser utilizada para confirmar ou não a gravação')
xRet := .T.
EndIf

//-----------------------------------------------------------------------------------------------------
// Para validação de exclusão, utilizar a constante MODEL_OPERATION_DELETE e o método GetOperation()
//-----------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_DELETE // Equivale ao F010CAND e ao F10NATDEL
Alert('Execução da pós validação do model quando executado o "Delete"')
Help(,,'Pontos de Entrada MVC',,'Help do pós valid do MVC após validação do ponto de entrada default do MVC',1,0)
xRet := .F.
EndIf

//-----------------------------------------------------------------------------------------------------
// Antes da gravação da tabela do formulário - FORMCOMMITTTSPRE
//-----------------------------------------------------------------------------------------------------
ElseIf cIdExec == 'FORMCOMMITTTSPRE'

//--------------------------------------------------------------------------------------------------------------------
// Para gravações adicionais antes da inclusão, utilizar a constante MODEL_OPERATION_INSERT e o método GetOperation()
//--------------------------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_INSERT // Equivale ao FIN010INC
Alert('A inclusão pode ter dados manipulados como gravação adicional neste momento, antes da confirmação da transação')
xRet := Nil
EndIf

//--------------------------------------------------------------------------------------------------------------------
// Para gravações adicionais antes da alteração, utilizar a constante MODEL_OPERATION_INSERT e o método GetOperation()
//--------------------------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_UPDATE // Equivale ao FIN010ALT
Alert('A alteração pode ter dados manipulados como gravação adicional neste momento, antes da confirmação da transação')
xRet := Nil
EndIf

//--------------------------------------------------------------------------------------------------------------------
// Para gravações adicionais antes da exclusão, utilizar a constante MODEL_OPERATION_INSERT e o método GetOperation()
//--------------------------------------------------------------------------------------------------------------------
If oObjForm:GetOperation() == MODEL_OPERATION_DELETE // Equivale ao FIN010EXC
Alert('A exclusão pode ter dados manipulados como gravação adicional neste momento, antes da confirmação da transação')
xRet := Nil
EndIf
EndIf

EndIf

Return xRet
