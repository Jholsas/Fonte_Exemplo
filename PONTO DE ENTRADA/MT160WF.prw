User Function MT160WF()
Local aResult    := {}
//-- Gera notificacao - Encerramento de cotacao


    /*If ExistProc('NOTENC')
        aResult:= TCSPExec( xProcedures('NOTENC'), SM0->M0_CODFIL, SC7->C7_NUMCOT, Substr(cUsuario,7,15))
        If Empty(aResult) .Or. aResult[1] <> '1'
            ApMsgStop('Erro na chamada do processo')
        EndIf
    EndIf*/

    Alert("Ponto MT160WF")
Return
