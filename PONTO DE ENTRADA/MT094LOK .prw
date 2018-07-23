User Function MT094LOK()

Local lRetorno := .T.
Local cTeste   := ""

// Codigo do usuario....

MsgInfo("Entrou no ponto MT161OK")

    DbSelectArea("SC7")

    SC7->(RecLock("SC7", .F.))
       cTeste:= SC7->C7_NUM
        Alert(cTeste)
    SC7->(MsUnlock())



Return(  lRetorno )
