#include 'protheus.ch'
#include 'parmtype.ch'

user function xTeste1()

 Local aSize := {}
 Local bOk := {|| }
 Local bCancel:= {|| }
 Local oMainWnd
 Local nX:= 0
 local cAux := ''
aSize := MsAdvSize(.F.)
 /*
 MsAdvSize (http://tdn.totvs.com/display/public/mp/MsAdvSize+-+Dimensionamento+de+Janelas)
 aSize[1] = 1 -> Linha inicial área trabalho.
 aSize[2] = 2 -> Coluna inicial área trabalho.
 aSize[3] = 3 -> Linha final área trabalho.
 aSize[4] = 4 -> Coluna final área trabalho.
 aSize[5] = 5 -> Coluna final dialog (janela).
 aSize[6] = 6 -> Linha final dialog (janela).
 aSize[7] = 7 -> Linha inicial dialog (janela).
 */
For nX := 1 To 1500
cAux := StrZero(nX,4)
Define MsDialog oDialog TITLE "Titulo" STYLE DS_MODALFRAME From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL
 //Se não utilizar o MsAdvSize, pode-se utilizar a propriedade lMaximized igual a T para maximizar a janela
 //oDialog:lMaximized := .T. //Maximiza a janela
 //Usando o estilo STYLE DS_MODALFRAME, remove o botão X
/*
seu codigo
*/
@010,120 BUTTON cAux SIZE 080, 047 PIXEL OF oDialog ACTION (nOpca := 1, oDialog:End())
ACTIVATE MSDIALOG oDialog ON INIT EnchoiceBar(oDialog, bOk , bCancel) CENTERED
//	oDialog:deactivate()
//	oDialog:Destroy()
FreeObj(oDialog)
Next nX

Return


		//ConOut(Repl("-", 80))
        //ConOut(PadC("SCHEDULE", 80))
        //ConOut(Repl("-", 80))

//return
