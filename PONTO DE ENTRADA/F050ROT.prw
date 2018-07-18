User Function F050ROT

Local aRotina := ParamIxb

    aAdd( aRotina, { "F050ROT", "U_F050ROTMsg", 0, 8,, .F. } )

Return aRotina

User Function F050ROTMsg()

Aviso( "F050ROT", "Ponto de Entrada F050ROT", {"Ok"}, 2 )

Return .T.
