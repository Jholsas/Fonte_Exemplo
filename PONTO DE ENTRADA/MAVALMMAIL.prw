User Function MAVALMMAIL()
Local lEnvia := .T.
Local cEvento:= PARAMIXB[1]
//C�digo do usu�rio para validar se o e-mail ser� ou n�o enviado atrav�s da manipula��o da vari�vel lEnvia...

if cEvento == "032"
    lEnvia := .T.
else
    lEnvia:= .F.
EndIf

Alert("Email MATA045")


Return (lEnvia)
