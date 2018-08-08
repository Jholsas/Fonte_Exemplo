USER FUNCTION TMATA685()
Local nOpc   := 3 //-Op��o de execu��o da rotina, informado nos parametros quais as op��es possiveis
Local cEnvMod := "PCP"
Local aCabec := {}
Local aItens := {}
Local aLinha := {}

PRIVATE lMsErroAuto := .F.

RpcSetEnv( "99","01",,,cEnvMod,,,,,,)

aCabec := {{"BC_OP"      ,"00000201001"     ,NIL}}
aItens := {{"BC_QUANT"   ,10				,NIL},;
		   {"BC_PRODUTO" ,"TESTE"       	,NIL},;
           {"BC_LOCORIG" ,"01"		        ,NIL},;
           {"BC_TIPO" 	 ,"R" 			    ,NIL},;
           {"BC_DTVALID" ,dDatabase 		,NIL},;
           {"BC_MOTIVO"  ,"FH"              ,NIL}}

           AAdd(aLinha ,aItens)
           MsExecAuto ( {|x,y,z| MATA685(x,y,z) }, aCabec, aLinha, 3)

    If lMsErroAuto
        MostraErro()
    Else
        Alert("T�tulo inclu�do com sucesso!")
    Endif
Return
