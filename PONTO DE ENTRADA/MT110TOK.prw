#include 'protheus.ch'
#include 'parmtype.ch'

user function MT110TOK()

	Local nPosPrd    := aScan(aHeader,{|x| AllTrim(x[2]) == 'C1_PRODUTO'})
	Local nPosItem    := aScan(aHeader,{|x| AllTrim(x[2]) == 'C1_ITEM'})
	Local lValido := .T.
	dbSelectArea('SC1')
	dbSetOrder(2)
	If MsSeek(xFilial('SC1') + aCols[ n][ nPosPrd] + cA110Num+aCols[ n][ nPosItem])
		If (C1_QUJE > 0) .Or. (C1_RESIDUO == 'S')       
			lValido := .F.    
		EndIf
	EndIf
	
	Alert("Chamou o PE!")

Return(lValido)