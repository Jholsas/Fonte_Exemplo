#INCLUDE "TOTVS.CH"

user function xTeste12()

LOCAL aArqDir := DIRECTORY("*.PRW", "C:\Users\vieira.victor\Documents\TesteFerase\*.prw" )

    AEVAL(aArqDir, { | aFile | MsgAlert(aFile[F_NAME]) } )

  /*
*/


return



User Function Directory()
Local aFiles := {}
Local nX := 0

aFiles := Directory("C:\Users\vieira.victor\Documents\TesteFerase\*.prw", "D")
For nX := 1 to Len( aFiles )
 Conout('Arquivo: ' + aFiles[nX,1] + ' - Size: ' + AllTrim(Str(aFiles[nX,2])) )


IF FERASE("C:\Users\vieira.victor\Documents\TesteFerase\" + aFiles[nX,1]) == -1
    MsgStop('Falha na deleção do Arquivo ( FError'+str(ferror(),4)+             ')')
  Else
    MsgStop('Arquivo deletado com sucesso.')
  ENDIF
Next nX

Return( Nil )
