User Function MT094LOK()

Local lRetorno := .T.
Local cTeste   := ""

// Codigo do usuario....

MsgInfo("Entrou no ponto MT094LOK")

    DbSelectArea("SC1")

    //SC7->(RecLock("SC7", .F.))
    // cTeste:= SC7->C7_NUM
        Alert("TESTE")
    SC1->(MsUnlock())



Return(  lRetorno )
