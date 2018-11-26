USER FUNCTION TMATA685()
Local nOpc   := 3 //-Opção de execução da rotina, informado nos parametros quais as opções possiveis
Local cEnvMod := "PCP"
Local aCabec := {}
Local aItens := {}
Local aLinha := {}
Local nQtd := 10


PRIVATE lMsErroAuto := .F.

RpcSetEnv( "99","01",,,cEnvMod,,,,,,)

aCabec := {{"BC_OP"      ,"00000101001   "      ,NIL}}

aItens := {{"BC_QUANT"   ,nQtd				    ,NIL},;
		   {"BC_PRODUTO" ,"000220         "     ,NIL},;
           {"BC_LOCORIG" ,"01"		            ,NIL},;
           {"BC_TIPO" 	 ,"R" 			        ,NIL},;
           {"BC_MOTIVO"  ,"FH"                  ,NIL},;
           {"BC_LOCAL"      ,"01"               ,NIL},;
		   {"BC_LOTECTL"    ,"TESTE"            ,NIL},;
		   {"BC_LOCALIZ"    ,"TESTE"            ,NIL},;
           {"BC_DTVALID" ,dDatabase 		    ,NIL},;
		   {"BC_LOCDEST"    ,"01"               ,NIL}}



           AAdd(aLinha ,aItens)
           MsExecAuto ( {|x,y,z| MATA685(x,y,z) }, aCabec, aLinha, nOpc)

    If lMsErroAuto
        MostraErro()
    Else
        Alert("Incluido com sucesso!")
    Endif
Return
