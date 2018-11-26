#Include 'Protheus.ch'
#Include 'Parmtype.ch'

User Function tststartjob ()
  Local lret := .F.
  Local nX := 0
  Local nY := 1

  For nX := 1 To 5
   startjob("u_inijob",getenvserver(),.T.,"TESTE " + cvaltochar(nY))
  nY++
  Next nX

Return

user function inijob (cTxt)
  	ConOut(Repl("-", 80))
			ConOut(PadC("INICIO " + cTxt, 80))
   ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))

   ConOut(Repl("-", 80))
			ConOut(PadC("FIM " + cTxt, 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do modelo de Dados

@author vieira.victor

@since 22/11/2018
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function ModelDef()
Local oModel

 
Local oStr1:= Nil
oModel := MPFormModel():New('ModelName')
oModel:addFields('FIELD1',,oStr1)

Return oModel