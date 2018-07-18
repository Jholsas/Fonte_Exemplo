#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"

User Function F060COL()

	Local aRet := paramixb[1] 

	AADD(aRet,{"A1_EST"   , "", Titulo("A1_EST") , ""})

Return aRet

Static Function Titulo(cCampo)
	Local aArea   := GetArea()
	Local aSx3    := SX3->(GetArea())
	Local cTitulo := cCampo

	If AllTrim(SX3->X3_CAMPO) != AllTrim(cCampo)
		DbSelectArea("SX3")
		DbSetOrder(2)

		If DbSeek(cCampo)
			cTitulo := X3Titulo()		
		End If
	Else
		cTitulo := X3Titulo()	
	End If

	RestArea(aSx3)
	RestArea(aArea)

Return(cTitulo)



