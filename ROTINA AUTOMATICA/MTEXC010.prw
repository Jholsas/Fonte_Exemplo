#INCLUDE "TBICONN.CH"
#INCLUDE 'Protheus.ch'

User Function MTEXC010()
Local aVetor := {}

private lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EST"

//--- Exemplo: Inclusao --- //
aVetor:= { {"B1_COD"        ,"SERV0005"     ,NIL},;
           {"B1_DESC"       ,"CONSULTORIA"  ,NIL},;
           {"B1_TIPO"       ,"PA"           ,Nil},;
           {"B1_UM"         ,"AR"           ,Nil},;
           {"B1_LOCPAD"     ,"01"           ,Nil},;
           {"B1_PICM"       ,0              ,Nil},;
           {"B1_IPI"        ,0              ,Nil},;
           {"B1_CONTRAT"    ,"N"            ,Nil},;
           {"B1_LOCALIZ"    ,"N"            ,Nil}}

MSExecAuto({|x,y| Mata010(x,y)},aVetor,3)
 /*
//--- Exemplo: Alteracao --- //
aVetor:= { {"B1_COD" ,"9994" ,NIL},;
 {"B1_DESC" ,"PRODUTO TESTE - ALTERADO" ,NIL}}

MSExecAuto({|x,y| Mata010(x,y)},aVetor,4)

//--- Exemplo: Exclusao --- //
aVetor:= { {"B1_COD" ,"9994" ,NIL},;
 {"B1_DESC" ,"PRODUTO TESTE - ROTINA AUTOMATICA" ,NIL}}

MSExecAuto({|x,y| Mata010(x,y)},aVetor,5)
 */
If lMsErroAuto
 MostraErro()
//Senão, mostra uma mensagem de inclusão
Else
 ConOut("Registro incluido!", "Atenção")
EndIf

RESET ENVIRONMENT


Return
