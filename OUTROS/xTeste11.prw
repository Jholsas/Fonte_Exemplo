#include 'protheus.ch'
#include 'parmtype.ch'

user function xTeste11(cDigito)

Local cNumero := "123456789012"

//ConOut("TESTE" + cDigito)
return cNumero

Static Function Mod10( cNumero )

// Verifico o numero de digitos e impar
// Caso seja, adiciono um caracter
If Len(cNumero)%2 #0
    cNumero := "0"+cNumero
EndIf



Return cNumero
