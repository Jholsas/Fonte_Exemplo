#INCLUDE 'Protheus.CH'
#INCLUDE 'TOTVS.CH'
#INCLUDE "APWEBSRV.CH"

WSSTRUCT StruParam

WSDATA CNUM AS String

ENDWSSTRUCT


//CRIA O SERVICO
WSSERVICE SVMT018 Description "MATA018"

WSDATA DADOSPRD	AS StruParam
WSDATA CRET	AS STRING
WSMETHOD EXECMT018

ENDWSSERVICE

//CRIA O METODO
WSMETHOD EXECMT018 WSRECEIVE DADOSPRD WSSEND CRET WSSERVICE SVMT018

PRIVATE aVetor := {}   // array que recebera o titulo a receber
PRIVATE lMsErroAuto := .F.



        aVetor := {}
        lMsErroAuto := .F.

        aAdd(aVetor,{'BZ_COD'     ,"P018A           "   ,Nil})
        aAdd(aVetor,{'BZ_LOCPAD'  ,"01"       ,Nil})
        aAdd(aVetor,{'BZ_TE'      ,"001"      ,Nil})

        MSExecAuto({|v,x| MATA018(v,x)},aVetor,3)

        If !lMsErroAuto
           ::CRET:= 'Inserido/Alterado/Excluido com sucesso'
        Else
            ::CRET:='Erro na Inclusão/Alteração/Exclusão'
            MostraErro()
        Endif



return .T.










/*cNum := DADOSTIT:CNUM

//for i := 1 to 300

AADD(aVetor,{"E2_PREFIXO"	,"NF"           ,Nil})
AADD(aVetor,{"E2_NUM"	,cNum	,Nil})
AADD(aVetor,{"E2_PARCELA"	,"1"          ,Nil})
AADD(aVetor,{"E2_TIPO"	,"NF"           ,Nil})
AADD(aVetor,{"E2_FORNECE"	,"000001"      	,Nil})
AADD(aVetor,{"E2_LOJA"	,"01"          	,Nil})
AADD(aVetor,{"E2_EMISSAO"	,dDataBase      ,Nil})
AADD(aVetor,{"E2_VENCTO"	,dDataBase      ,Nil})
AADD(aVetor,{"E2_VALOR"  	,250           ,Nil})
AADD(aVetor,{"E2_HIST"    ,"TESTE" ,Nil})

MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aVetor,, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

If lMsErroAuto
conout("Erro")
Return .F.
Else
conout("Incluído titulo: "+cNum)
Endif

//	cNum := soma1(cNum)
//	aVetor := {}

//next

Return .T.
nunca fiz teste com essa execauto
