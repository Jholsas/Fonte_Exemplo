#Include "totvs.ch"
#Include "tbiconn.ch"

User Function FIN040MAIN()
	Local nX := 0
	Local nNumTit := 1000

	For nX := 1 To 5
		StartJob("U_FIN040EXC", GetEnvServer(), .F., nNumTit)

		nNumTit += 1000
	Next nX
Return (NIL)

User Function FIN040EXC(nNumTit)
	Local aArray := {}
	Local aArea  := {}
	Local nX     := 0

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	RPCSetEnv("99", "01")
		aArea := GetArea()

		For nX := 1 To 600
			aArray := { {"E1_PREFIXO"  ,"   "                  ,NIL    },;
						{"E1_NUM"      ,CValToChar(nNumTit)    ,NIL    },;
						{"E1_PARCELA"  ,"  "                   ,NIL    },;
						{"E1_TIPO"     ,"RA"                   ,NIL    },;
						{"E1_NATUREZ"  ,"0000000001"
						       ,NIL    },;
						{"E1_CLIENTE"  ,"000001"  		       ,NIL    },;
						{"E1_LOJA"	   ,"01"				   ,NIL    },;
						{"E1_EMISSAO"  ,CtoD('19/06/2018')	   ,NIL    },;
						{"E1_VENCTO"   ,CtoD('19/06/2018')	   ,NIL    },;
						{"E1_VENCREA"  ,CtoD('19/06/2018')	   ,NIL    },;
						{"E1_VALOR"    ,350				       ,NIL    },;
						{"E1_VLCRUZ"   ,350   				   ,NIL    },;
						{"E1_PORTADO"  ,"341"                  ,NIL    },;
						{"E1_AGEDEP"   ,"0001 "                ,NIL, .T.}}

			MsExecAuto( {|x, y| FINA040(x, y)}, aArray, 3)

			++nNumTit
		Next nX

		If (lMsErroAuto == .T.)
			MostraErro()

			ConOut(Repl("-", 80))
			ConOut(PadC("FINA040 finalizada com erro!", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		Else
			ConOut(Repl("-", 80))
			ConOut(PadC("FINA040 finalizada com sucesso!", 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		EndIf

		RestArea(aArea)
	RPCClearEnv()
Return (NIL)
