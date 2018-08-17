#Include 'Protheus.ch'
#Include 'TBICONN.ch'


User Function TFINA460()

Local cNum:=""//PADR("000001",TamSx3("E1_NUM")[1])
Local nZ:=0
Local aCab:={}
Local aItens:={}
Local nOpc:=3//3-Liquidação,4-Reliquidacao,5-Cancelamento da liquidação
Local cFiltro :=""
Local cLiqCan := Space(6)  //numero da liquidacao a cancelar
Local aParcelas:={}
Local nValor := 3000  //Valor a liquidar
Local cCond := '001' //Condicao de pagamento 4x
Local nRadio := 1
Local oRadio
Local oLiqCan

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

cNum := PadR("LDQ0007", TamSX3("E1_NUM")[1])
//Tela utilizada apenas para exemplo
nOpca := 0
DEFINE MSDIALOG oDlg FROM  094,1 TO 240,300 TITLE "Liquidação Automatica" PIXEL
@ 010,010 Radio oRadio VAR nRadio;
    ITEMS "Liquidar",;
        "Reliquidar",;
        "Cancelar";
              3D SIZE 50,10 OF oDlg PIXEL ;
              ON CHANGE (oLiqCan:lReadOnly := If(nRadio != 3 ,.T.,.F.))

@ 022,070 SAY "Cancel. Liquidação:" SIZE 49, 07 OF oDlg PIXEL
@ 030,070 MSGET oLiqCan VAR cLiqCan Valid !Empty(cLiqCan)  SIZE 49, 11 OF oDlg PIXEL hasbutton

DEFINE SBUTTON FROM 55,085 TYPE 1 ENABLE OF oDlg ACTION (nOpca := 1, oDlg:End())
DEFINE SBUTTON FROM 55,115 TYPE 2 ENABLE OF oDlg ACTION (nOpca := 0, oDlg:End())

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1
   If nRadio == 1 .or. nRadio == 2

      If nRadio == 1  //liquidacao
         nOpc := 3
         //Filtro do Usuário
         cFiltro := "E1_FILIAL=='"+xFilial("SE1")+"' .And. "
         cFiltro += "E1_CLIENTE=='000001'.And. E1_LOJA =='01' .And. "
         cFiltro += "E1_SITUACA$'0FG' .And. E1_SALDO>0 .and. "
         cFiltro += 'Empty(E1_NUMLIQ)'
      Else
         nOpc := 4  //reliquidacao
         //Filtro do Usuário
         cFiltro := "E1_FILIAL=='"+xFilial("SE1")+"' .And. "
         cFiltro += "E1_CLIENTE=='000001'.And. E1_LOJA =='01' .And. "
         cFiltro += "E1_SITUACA$'0FG' .And. E1_SALDO>0 .and. "
         cFiltro += '!Empty(E1_NUMLIQ)'
      Endif



      //Array do processo automatico (aAutoCab)
      aCab:={ {"cCondicao" ,cCond },;
              {"cNatureza" ,"0000000001" },;
              {"E1_TIPO"  ,"NF " },;
              {"cCLIENTE"  ,"000001"},;
              {"nMoeda"  ,1   },;
              {"cLOJA"   ,"01"  }}

      //------------------------------------------------------------
      //Monta as parcelas de acordo com a condição de pagamento
      //------------------------------------------------------------
      aParcelas:=Condicao(nValor,cCond,,dDataBase)

      //--------------------------------------------------------------
      //Não é possivel mandar Acrescimo e Decrescimo junto.
      //Se mandar os dois valores maiores que zero considera Acrescimo
      //--------------------------------------------------------------
      For nZ:=1 to Len(aParcelas)
        //Dados das parcelas a serem geradas
        Aadd(aItens,{{ "E1_PREFIXO","D  "  },;//Prefixo
                   {"E1_BCOCHQ" ,"341"  },;//Banco
                   {"E1_AGECHQ" ,"0001"  },;//Agencia
                   {"E1_CTACHQ" ,"000001"  },;//Conta
                   {"E1_NUM"  ,cNum   },;//Nro. cheque (dará origem ao numero do titulo)
                   {"E1_EMITCHQ" ,"VICTOR"  },;//Emitente do cheque
                   {"E1_VENCTO" ,aParcelas[nZ,1]},;//Data boa
                   {"E1_VLCRUZ" ,aParcelas[nZ,2]},;//Valor do cheque/titulo
                   {"E1_ACRESC" ,0    },;//Acrescimo
                   {"E1_DECRESC" ,0    }})//Decrescimo


         cNum:=Soma1(cNum,Len(Alltrim(cNum)))
      Next nZ

      If Len(aParcelas) > 0
         //Liquidacao e reliquidacao
         //FINA460(nPosArotina,aAutoCab,aAutoItens,nOpcAuto,cAutoFil,cNumLiqCan)
         FINA460(,aCab,aItens,nOpc,cFiltro)//Inclusao

         // Este aviso funciona apenas para teste monousuario
         Alert("Liquidacao Incluida -> "+GetMv("MV_NUMLIQ"))
      Endif
   Else
      nOpc := 5
     //Cancelamento
     FINA460(,,,nOpc,,cLiqCan) //Cancelamento
     Alert("Liquidacao Cancelada -> "+cLiqCan)
   Endif
EndIf
RESET ENVIRONMENT

Return
