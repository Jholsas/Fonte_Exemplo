#include 'protheus.ch'
#include 'parmtype.ch'

user function M450LEG()
	
Local aCores:= {}
//Formato do item do array de cores {“condição”, “cor”}. Exemplo:

aCores := { {"C9_BLCRED == '  '" ,'BR_PINK' },;  //Item Liberado 
            {"C9_BLCRED == '10' .And. C9_BLEST=='10'",'DISABLE'} }  //Item Faturado

	
return aCores







