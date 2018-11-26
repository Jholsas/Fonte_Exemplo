#include "tbiconn.ch"

User Function FIN100MAIN()
	Local nX := 0

	For nX := 1 To 2
		StartJob("U_FIN100EXC", GetEnvServer(), .T., StrZero(nX,2))


	Next nX
Return (NIL)


user function FIN100EXC(cAuxFil)

local aFINA100 := {}

RPCSetEnv("99", cAuxFil)
		aArea := GetArea()

//PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FIN"

private lMsErroAuto := .F.

               aFINA100 := {{"E5_DATA"    ,dDataBase               ,Nil},;
                            {"E5_MOEDA"   ,"M1"                    ,Nil},;
                            {"E5_VALOR"   ,400                     ,Nil},;
                            {"E5_NATUREZ" ,"0000000001"            ,Nil},;
                            {"E5_DEBITO"  ,"000000002 "            ,Nil},;
                            {"E5_CREDITO" ,"000000001 "            ,Nil},;
                            {"E5_BANCO"   ,"237"                   ,Nil},;
                            {"E5_AGENCIA" ,"0002"                  ,Nil},;
                            {"E5_CONTA"   ,"000002"                ,Nil},;
                            {"E5_BENEF"   ,"TESTE AUTO - BENEF"    ,Nil},;
                            {"E5_TIPOLAN" ,"X"                     ,Nil},;
                            {"E5_HISTOR"  ,"TABELA FK5/E5_IDOR01 " ,Nil}}

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,3)

       If (lMsErroAuto == .T.)
			MostraErro()
			ConOut(Repl("-", 80))
			ConOut(PadC("FINA100 finalizada com erro! FILIAL:" + cAuxFil, 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		Else
			ConOut(Repl("-", 80))
			ConOut(PadC("Movto. Bancario Pagar incluido com sucesso !!! FILIAL:" + cAuxFil, 80))
			ConOut(PadC("Ends at: " + Time(), 80))
			ConOut(Repl("-", 80))
		EndIf

		RestArea(aArea)
	RPCClearEnv()
Return (NIL)



//RESET ENVIRONMENT

//return


/*#INCLUDE "Protheus.ch"

User Function FIN100EXC()
Local nOpc     := 0
Local aFINA100 := {}

Private lMsErroAuto := .F.

While .T.

    nOpc := 0
    nOpc := Aviso("TESTE EXECAUTO DO FINA100", "Escolha a opção do menu da rotina FINA100 a ser executada via EXECAUTO",{"PAGAR","RECEBER","EXCLUIR","CANCELAR","TRANSF.","EST. TRANSF."})

    If nOpc == 1
        aFINA100 := {{"E5_DATA"        ,dDataBase             ,Nil},;
                     {"E5_MOEDA"       ,"M1"                  ,Nil},;
                     {"E5_VALOR"       ,500                   ,Nil},;
                     {"E5_NATUREZ"     ,"001"                 ,Nil},;
                     {"E5_BANCO"       ,"001"                 ,Nil},;
                     {"E5_AGENCIA"     ,"001"                 ,Nil},;
                     {"E5_CONTA"       ,"001"                 ,Nil},;
                     {"E5_BENEF"       ,"TESTE AUTO - BENEF"  ,Nil},;
                     {"E5_HISTOR"      ,"TESTE AUTO - AUTO"   ,Nil}}

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,3)

        If lMsErroAuto
            MostraErro()
        Else
            MsgAlert("Movto. Bancario Pagar incluido com sucesso !!!")
        EndIf

    ElseIf nOpc == 2
        aFINA100 := {{"E5_DATA"        ,dDataBase             ,Nil},;
                     {"E5_MOEDA"       ,"M1"                  ,Nil},;
                     {"E5_VALOR"       ,1500                  ,Nil},;
                     {"E5_NATUREZ"     ,"001"                 ,Nil},;
                     {"E5_BANCO"       ,"001"                 ,Nil},;
                     {"E5_AGENCIA"     ,"001"                 ,Nil},;
                     {"E5_CONTA"       ,"001"                 ,Nil},;
                     {"E5_HISTOR"      ,"TESTE AUTO - AUTO"   ,Nil}}

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,4)

        If lMsErroAuto
            MostraErro()
        Else
            MsgAlert("Movto. Bancario Receber incluido com sucesso !!!")
        EndIf

    ElseIf nOpc == 3
        dbSelectArea("SE5")
        SE5->(dbSetOrder(1))
        SE5->(dbSeek(xFilial("SE5")+DToS(dDataBase) ))
        aFINA100 := {{"E5_DATA"           ,SE5->E5_DATA           ,Nil},;
                     {"E5_MOEDA"          ,SE5->E5_MOEDA          ,Nil},;
                     {"E5_VALOR"          ,SE5->E5_VALOR          ,Nil},;
                     {"E5_NATUREZ"        ,SE5->E5_NATUREZ        ,Nil},;
                     {"E5_BANCO"          ,SE5->E5_BANCO          ,Nil},;
                     {"E5_AGENCIA"        ,SE5->E5_AGENCIA        ,Nil},;
                     {"E5_CONTA"          ,SE5->E5_CONTA          ,Nil},;
                     {"E5_HISTOR"         ,SE5->E5_HISTOR         ,Nil},;
                     {"E5_TIPOLAN"        ,SE5->E5_TIPOLAN        ,Nil} }

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,5)

        If lMsErroAuto
            MostraErro()
        Else
            MsgAlert("Exclusão realizada com sucesso !!!")
        EndIf

    ElseIf nOpc == 4
        dbSelectArea("SE5")
        SE5->(dbSetOrder(1))
        SE5->(dbSeek(xFilial("SE5")+DToS(dDataBase) ))
        dbSkip() //colocado apenas para esta sequencia de testes
        aFINA100 := {{"E5_DATA"         ,SE5->E5_DATA       ,Nil},;
                     {"E5_MOEDA"        ,SE5->E5_MOEDA      ,Nil},;
                     {"E5_VALOR"        ,SE5->E5_VALOR      ,Nil},;
                     {"E5_NATUREZ"      ,SE5->E5_NATUREZ    ,Nil},;
                     {"E5_BANCO"        ,SE5->E5_BANCO      ,Nil},;
                     {"E5_AGENCIA"      ,SE5->E5_AGENCIA    ,Nil},;
                     {"E5_CONTA"        ,SE5->E5_CONTA      ,Nil},;
                     {"E5_HISTOR"       ,SE5->E5_HISTOR     ,Nil},;
                     {"E5_TIPOLAN"      ,SE5->E5_TIPOLAN    ,Nil} }

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,6)

        If lMsErroAuto
          MostraErro()
        Else
            MsgAlert("Cancelamento realizada com sucesso !!!")
        EndIf


    ElseIf nOpc == 5
        aFINA100 := {{"CBCOORIG"         ,"001"                       ,Nil},;
                     {"CAGENORIG"        ,"001"                       ,Nil},;
                     {"CCTAORIG"         ,"001"                       ,Nil},;
                     {"CNATURORI"        ,"001"                       ,Nil},;
                     {"CBCODEST"         ,"002"                       ,Nil},;
                     {"CAGENDEST"        ,"002"                       ,Nil},;
                     {"CCTADEST"         ,"002"                       ,Nil},;
                     {"CNATURDES"        ,"002"                       ,Nil},;
                     {"CTIPOTRAN"        ,"CH"                        ,Nil},;
                     {"CDOCTRAN"         ,"123456"                    ,Nil},;
                     {"NVALORTRAN"       ,2500                        ,Nil},;
                     {"CHIST100"         ,"TESTE TRF VIA EXECAUTO"    ,Nil},;
                     {"CBENEF100"        ,"TESTE TRF VIA EXECAUTO"    ,Nil} }

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,7)

        If lMsErroAuto
            MostraErro()
        Else
            MsgAlert("Transferência executada com sucesso !!!")
        EndIf

    //Estorno da Transferencia
    ElseIf nOpc == 6
        aFINA100 := {{"AUTNRODOC"       ,"123456"                 ,Nil},;
                     {"AUTDTMOV"        ,dDataBase                ,Nil},;
                     {"AUTBANCO"        ,"001"                    ,Nil},;
                     {"AUTAGENCIA"      ,"001"                    ,Nil},;
                     {"AUTCONTA"        ,"001"                    ,Nil} }

        MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,8)

        If lMsErroAuto
            MostraErro()
        Else
            MsgAlert("Transferência cancelada com sucesso !!!")
        EndIf
    EndIf
    If nOpc == 0
        Exit
    Endif
Enddo

Return(Nil)
*/
