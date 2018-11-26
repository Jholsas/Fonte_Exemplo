#include "Protheus.ch"

User function xTeste14 ()

LOCAL nHandle := FCreate("\arquivo.txt")

IF nHandle == -1
    MsgAlert("O Arquivo não foi criado:" + STR(FERROR()))
 BREAK

ELSE

FWRITE(nHandle, "TESTE FCREATE - SCHEDULE")
FCLOSE(nHandle)

ENDIF

return

User function CriaTxt()

ConOut(PadC("STARJOB INICIO!!!", 80))

    StartJob("U_xTeste14", GetEnvServer(),.T.,"TESTE")

    ConOut(Repl("-", 80))
	ConOut(PadC("STARJOB FIM!!!", 80))
	ConOut(PadC("Ends at: " + Time(), 80))
	ConOut(Repl("-", 80))

Return
