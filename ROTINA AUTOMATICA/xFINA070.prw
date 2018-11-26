#Include 'Protheus.ch'
#Include "TOPCONN.CH"
#Include "Tbiconn.ch"

User Function FINA070EXC()

	Local aBaixa 		:= {}

	Private lMsErroAuto	:= .F.


	PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"
//VALIDA CONTABILIZACAO ONLINE
	/*Pergunte("FIN070", .F.)
	If mv_par04 == 01
		conout("Online-Sim")
	Else
		conout("Online-Não")
	Endif*/

	dbSelectArea("SE1")
	SE1->(dbSetOrder(1))
	SE1->(dbGoTop())

	conout("Teste de Baixa/Cancelamento") /**/

	aBaixa := {{"E1_PREFIXO"  ,"D  "                  ,Nil    },;
			   {"E1_NUM"      ,"LDQ0007  "            ,Nil    },;
			   {"E1_PARCELA"  ,"0A"                   ,Nil    },;
			   {"E1_TIPO"     ,"NF "                  ,Nil    },;
			   {"E1_CLIENTE"  ,"000001"               ,Nil    },;
			   {"E1_LOJA"     ,'01'                   ,Nil    },;
			   {"E1_NATUREZ"  ,"0000000001"           ,Nil    },;
			   {"AUTMOTBX"    ,"NOR"                  ,Nil    },;
			   {"CBANCO"      ,"341"                  ,Nil    },;
			   {"CAGENCIA"    ,"0001 "                ,Nil    },;
			   {"CCONTA"      ,"000001"               ,Nil    },;
			   {"AUTDTBAIXA"  ,CtoD("14/08/2018")     ,Nil    },;
			   {"AUTDTCREDITO",CtoD("14/08/2018")     ,Nil    },;
			   {"AUTHIST"     ,"TESTE FINA070"  	  ,Nil    }}
			   //{"NVALREC"     ,200					  ,Nil    }}
			   //{"AUTJUROS"    ,0                      ,Nil,.T.}}
				//

	MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3) //3 - Baixa de Título, 4 - Altera, 5 - Cancelamento de baixa, 6 - Exclusão de Baixa.

	If lMsErroAuto
		MostraErro()
	Else
		conout("CANCELADO/BAIXADO COM SUCESSO!" + E1_NUM)
	Endif

	RESET ENVIRONMENT
Return (Nil)


/*user function tstSchedule()

		ConOut(PadC("STARJOB INICIO!!!", 80))

	StartJob("U_FINA070EXC", GetEnvServer(),.T.,"TESTE")

			ConOut(Repl("-", 80))
			ConOut(PadC("STARJOB FIM!!!", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))

Return (Nil)*/
