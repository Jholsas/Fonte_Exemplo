User Function MAVALMMAIL()
Local lEnvia := .T.
Local cEvento:= PARAMIXB[1]
//Código do usuário para validar se o e-mail será ou não enviado através da manipulação da variável lEnvia...

if cEvento == "032"
    lEnvia := .T.
else
    lEnvia:= .F.
EndIf

Alert("Email MATA045")


Return (lEnvia)
