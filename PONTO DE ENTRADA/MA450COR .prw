#include 'protheus.ch'
#include 'parmtype.ch'

user function MA450COR ()
	
Local aLegenda:= {}
//Formato do item da legenda {“cor”, “texto legenda”}. Exemplo:
aLegenda := {  {'BR_PINK' ,'Item Liberado'           },;
				{'DISABLE','Item Faturado'           },;
				 {'BR_AZUL','Item Bloqueado - Credito'} }

	
return aLegenda