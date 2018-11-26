#Include "protheus.ch"

User Function AfterLogin()

Local cId	:= ParamIXB[1]
Local cNome := ParamIXB[2]

  ApMsgAlert("Usuário "+ cId + " - " + Alltrim(cNome)+" efetuou login às "+Time())

Return
