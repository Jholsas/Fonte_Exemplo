 USER FUNCTION MT120PCOK()
 Local lOk := .T.

 If Inclui
     MsgInfo( UsrRetName(RetCodUsr()), 'USUARIO que esta Incluindo' )
EndIf

 /*If !MsgYesNo("Deseja validar este ponto de entrada MT120PCOK?")
    lOk := .F.
Endif*/

Return lOk
