#Include 'Protheus.ch'
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

User Function TMata010()

	Local aVetor := {}

	Local n1 := 0

	private lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "ATF"

dbSelectarea("SB1")
dbsetorder(1)



 for n1:= 1 to 1200

    MsSeek(xFilial("SB1")+"0000000001     ")

	aVetor:= {{"B1_COD"         ,SB1->B1_COD     ,NIL},;
		{"B1_DESC"        ,SB1->B1_DESC ,NIL},;
		{"B1_TIPO"    	,SB1->B1_TIPO        ,Nil},;
		{"B1_UM"      	,SB1->B1_UM             ,Nil},;
		{"B1_LOCPAD"  	,SB1->B1_LOCPAD              ,Nil},;
		{"B1_PICM"    	,SB1->B1_PICM               ,Nil},;
		{"B1_IPI"     	,SB1->B1_IPI                 ,Nil},;
		{"B1_CONTRAT" 	,SB1->B1_CONTRAT              ,Nil},;
		{"B1_LOCALIZ" 	,SB1->B1_LOCALIZ              ,Nil}}


//		{"B1_GRUPO",  	,"0001"			, NIL},;

	MSExecAuto({|x,y| Mata010(x,y)},aVetor,4)


	If lMsErroAuto
 		Conout("Erro na inclus�o ")
// 		Mostraerro()
 	Else
 		Conout("Produto alterado com sucesso" + cvaltochar(n1))
	Endif

 next
Return
