#Include 'Protheus.ch'

User Function MT094END()

Local cDocto  := PARAMIXB[1]
Local cTipo   := PARAMIXB[2]
Local nOpc    := PARAMIXB[3]
Local cFilDoc := PARAMIXB[4]

 // Valida��es do usu�rio.
 Alert("TESTE - MT094END")
 CN120MedEnc(recno())

Return
