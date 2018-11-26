//********* EXEMPLO PARA ENDERE�AR UM ITEM *********
#Include "RwMake.CH"
#include "tbiconn.ch"

User Function TMATA265()
Local aCabSDA    := {}
Local aItSDB         := {}
Local _aItensSDB := {}

Private	lMsErroAuto := .F.


PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"
//Cabe�alho com a informa��o do item e NumSeq que sera endere�ado.

aCabSDA := {{"DA_PRODUTO" ,"PRDTRET        " ,Nil},;
            {"DA_NUMSEQ"  ,"000164"     ,Nil}}

//Dados do item que ser� endere�ado

aItSDB := {{"DB_ITEM"	  ,"0001"	            ,Nil},;
           {"DB_ESTORNO"  ," "	                ,Nil},;
           {"DB_LOCALIZ"  ,"RUA TESTE      "    ,Nil},;
           {"DB_DATA"	  ,CtoD('11/09/2018')   ,Nil},;
           {"DB_QUANT"    ,10                   ,Nil}}

            aadd(_aItensSDB,aitSDB)

        //Executa o endere�amento do item

        MATA265( aCabSDA, _aItensSDB, 3)

    If lMsErroAuto
        MostraErro()
    Else
        MsgAlert("Processamento Ok!")
    Endif

    RESET ENVIRONMENT

 Return
 /*
 // ********* EXEMPLO PARA ESTORNAR UM ITEM *********
  #Include "RwMake.CH"
  #include "tbiconn.ch"
  User Function TMATA265()
  Local aCabSDA    := {}
  Local aItSDB         := {}
  Local _aItensSDB := {}

  Private	lMsErroAuto := .F.

  //Cabe�alho com a informa��o do item e NumSeq que sera endere�ado.

  aCabSDA := {{"DA_PRODUTO" ,"PROD-ENDER",Nil},;
              {"DA_NUMSEQ"  ,"001419",Nil}}
  //Dados do item que ser� endere�ado

  aItSDB := {{"DB_ITEM"	  ,"0001"	      ,Nil},;
             {"DB_ESTORNO"  ,"S "	      ,Nil},;
             {"DB_LOCALIZ"  ,"LOCAL"    ,Nil},;
             {"DB_DATA"	  ,dDataBase    ,Nil},;
             {"DB_QUANT"  ,20                  ,Nil}}
        aadd(_aItensSDB,aitSDB)
        //Executa o estorno do item

        MATA265( aCabSDA, _aItensSDB, 4)

    If lMsErroAuto
        MostraErro()
    Else
        MsgAlert("Processamento Ok!")
    Endif

Return
*/
