USER FUNCTION TMATA685()
Local nOpc   := 3 //-Opção de execução da rotina, informado nos parametros quais as opções possiveis
Local cEnvMod := "PCP"
Local aCabec := {}
Local aItens := {}
Local aLinha := {}

PRIVATE lMsErroAuto := .F.

RpcSetEnv( "99","01",,,cEnvMod,,,,,,)

aCabec := {{"BC_OP"      ,"OP000601001"     ,NIL}}
aItens := {{"BC_QUANT"   ,10				,NIL},;
		   {"BC_PRODUTO" ,"MODCNTC0001"     ,NIL},;
           {"BC_LOCORIG" ,"01"		        ,NIL},;
           {"BC_TIPO" 	 ,"R" 			    ,NIL},;
           {"BC_DTVALID" ,dDatabase 		,NIL},;
           {"BC_MOTIVO"  ,"FH"              ,NIL}}

           AAdd(aLinha ,aItens)
           MsExecAuto ( {|x,y,z| MATA685(x,y,z) }, aCabec, aLinha, 6)

    If lMsErroAuto
        MostraErro()
    Else
        Alert("Excluido com sucesso!")
    Endif
Return
