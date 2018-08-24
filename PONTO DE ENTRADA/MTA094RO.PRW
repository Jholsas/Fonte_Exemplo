#Include 'Protheus.ch'

User Function MTA094RO()

Local aRotina:= PARAMIXB[1]

//Validações do usuário
aAdd( aRotina, { "MT94RO", "U_MT94ROMsg", 0, 8,, .F. } )

Return (aRotina)


User Function MT94ROMsg()

Aviso( "MT94RO", "Ponto de Entrada MT94RO", {"Ok"}, 2 )

Return .T.
