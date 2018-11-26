User Function MT097LOK()
Local lRetorno := .T.
// Codigo do usuario....
If AllTrim (CUSERNAME) = 'APROVADOR'
    lRetorno := .F.
         MsgInfo("NEGADO!!!")
EndIf

return( lRetorno )
