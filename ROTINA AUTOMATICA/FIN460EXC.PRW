/*------------------------------------------------------------------*\
| DESCRIÇÃO: Esta rotina possibilita a inclusão/alteração/exclusão   |
| de qualquer conta no cadastro de Contas Contábeis de forma         |
| automática.                                                        |
|--------------------------------------------------------------------|
| LINK: http://tdn.totvs.com/pages/viewpage.action?pageId=2856568311 |
\*------------------------------------------------------------------*/

#Include "protheus.ch"
#Include "parmtype.ch"
#Include "fwmvcdef.ch"
#Include "tbiconn.ch"

User Function c1FINA460()
    Local oModel   := NIL
    Local lRet     := .T.
    Local cLog     := ""
    Local nZ:=0
    Local nOpc     := 3 //3-Liquidação,4-Reliquidacao,5-Cancelamento da liquidação
    Local cLiqCan  := Space(6)  //numero da liquidacao a cancelar
    Local aParcelas:={}
    Local nValor   := 2000  //Valor a liquidar
    Local cCond    := '03' //Condicao de pagamento 4x
    local cNum:= "XX100001E"// Numero do Titulo
    Private aMsLog := {}
    Private lMsErroAuto := .F.

    PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "CTB" TABLES "CT1", "CVD", "CVS"

    EnvInfo("FINA460.PRW")

    If  oModel == NIL
        oModel := FwLoadModel("FINA460")
        oModel:SetOperation(nOpc)
        oModel:Activate()
    EndIf

    oModel:SetValue("SE1MASTER",    "cCondicao" ,cCond)
    oModel:SetValue("SE1MASTER",    "cNatureza" ,"0000000001"          )
    oModel:SetValue("SE1MASTER",    "E1_TIPO"   ,"NF"          )
    oModel:SetValue("SE1MASTER",    "cCLIENTE"  ,"001   "       )
    oModel:SetValue("SE1MASTER",    "nMoeda"    ,1              )
    oModel:SetValue("SE1MASTER",    "cLOJA"     ,"01"           )

    oModel:SetValue("SE1DETAIL",    "E1_PREFIXO","NF1"          )
    oModel:SetValue("SE1DETAIL",    "E1_BCOCHQ" ,"001"          )
    oModel:SetValue("SE1DETAIL",    "E1_AGECHQ" ,"001"          )
    oModel:SetValue("SE1DETAIL",    "E1_CTACHQ" ,"001"          )
    oModel:SetValue("SE1DETAIL",    "E1_NUM"    ,cNum           )
    oModel:SetValue("SE1DETAIL",    "E1_EMITCHQ","OSCAR PEREIRA")
    oModel:SetValue("SE1DETAIL",    "E1_VENCTO" ,aParcelas[nZ,1])
    oModel:SetValue("SE1DETAIL",    "E1_VLCRUZ" ,aParcelas[nZ,2])
    /*
    oModel:SetValue("CTSDETAIL",    "CTS_FILIAL",     "")
    oModel:SetValue("CTSDETAIL",    "CTS_CODPLA",     "")
    oModel:SetValue("CTSDETAIL",    "CTS_CONTAG",     "")
    */
    If oModel:VldData()
        oModel:CommitData()
    Else
        aLog := oModel:GetErrorMessage()

        For nX := 1 To Len(aLog)
            If !Empty(aLog[nX])
                cLog += Alltrim(aLog[nX]) + CRLF
            EndIf
        Next nX

        lMsErroAuto := .T.
        lRet := .F.

        AutoGRLog(cLog)
    EndIf

    If lMsErroAuto
        MostraErro()
        ConOut(Repl("-", 80))
        ConOut(PadC("Teste FINA460 finalizado com erro!", 80))
        ConOut(PadC("Fim: " + Time(), 80))
        ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
        ConOut(PadC("Teste FINA460 finalizado com sucesso!", 80))
        ConOut(PadC("Fim: " + Time(), 80))
        ConOut(Repl("-", 80))
    EndIf

    oModel:DeActivate()

    RESET ENVIRONMENT
Return lRet

/*------------------------------------------------------------------*\
| DESCRIÇÃO: Esta função tem como objetivo retornar informações do   |
| ambiente e rotina sem a necessidade de abertura do SmartClient     |
|--------------------------------------------------------------------|
| AUTOR:                          |        MODIFICADO EM: 01/03/2018 |
\*------------------------------------------------------------------*/

Static Function ENVINFO(cRotina)
    Local aRPO := {}
    Default cRotina := ""

    aRPO := GetApoInfo(cRotina)

    If !Empty(aRPO)
        ConOut(Repl("-", 80))
        ConOut(PadC("Rotina: " + aRPO[1], 80))
        ConOut(PadC("Data: " + DToC(aRPO[4]) + " " + aRPO[5], 80))
        ConOut(Repl("-", 80))
        ConOut(PadC("SmartClient: " + GetBuild(.T.), 80))
        ConOut(PadC("AppServer: " + GetBuild(.F.), 80))
        ConOut(PadC("DbAccess: " + TCAPIBuild() + "/MSSQL" , 80))
        ConOut(Repl("-", 80))
        ConOut(PadC("Inicio: " + Time(), 80))
        ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
        ConOut(PadC("Ocorreu um erro ao pesquisar os dados do ambiente pela funcao EnvInfo()", 80))
        ConOut(Repl("-", 80))
    EndIf
Return NIL
