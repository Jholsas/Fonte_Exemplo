#Include "totvs.ch"
#Include "tbiconn.ch"


User Function EECAP100Inc()
Local aItens := {}
Local aDadosAuto := {} // Array com os dados a serem enviados pela MsExecAuto() para gravação automática dos itens do ativo
Local aCab := {}

Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.


PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EEC" TABLES "EE7", "EE8"

aCab:={ {'EE7_FILIAL'   ,'01'             ,NIL},;
        {'EE7_IMPORT'   ,'001'            ,NIL},;
        {'EE7_IMLOJA'   ,'01'             ,NIL},;
        {'EE7_IMPODE'   ,"IMPORTADOR"     ,NIL},;
        {'EE7_FORN'     ,'001'            ,NIL},;
        {'EE7_FOLOJA'   ,'01'             ,NIL},;
        {'EE7_FORNDE'   ,"FORNECEDOR"     ,NIL},;
        {'EE7_IDIOMA'   ,"INGLES-INGLES"  ,NIL},;
        {'EE7_CONDPA'   ,'001'            ,NIL},;
        {'EE7_DIASPA'   ,'30'             ,NIL},;
        {'EE7_DESCPA'   ,"COND.PAGAMENTO" ,NIL},;
        {'EE7_MPGEXP'   ,'003'            ,NIL},;
        {'EE7_DSCMPE'   ,"COBRANCA"       ,NIL},;
        {'EE7_INCOTE'   ,'FOB'            ,NIL},;
        {'EE7_MOEDA'    ,'US$'            ,NIL},;
        {'EE7_FRPPCC'   ,'PP'             ,NIL},;
        {'EE7_VIA'      ,'02'             ,NIL},;
        {'EE7_VIA_DE'   ,"VIA TRANSP."    ,NIL},;
        {'EE7_ORIGEM'   ,'AGA'            ,NIL},;
        {'EE7_DSCORI'   ,"ACEGUA-RS"      ,NIL},;
        {'EE7_DEST'     ,'VYX'            ,NIL},;
        {'EE7_DSCDES'   ,"VITORIA-ES"     ,NIL},;
        {'EE7_PAISET'   ,'105'            ,NIL},;
        {'EE7_TIPTRA'   ,'1'              ,NIL,.T.}}
// Array com os dados a serem enviados pela MsExecAuto() para gravação automática da capa do bem
//Private lMsHelpAuto := .f. // Determina se as mensagens de help devem ser direcionadas para o arq. de log
//Private lMsErroAuto := .f. // Determina se houve alguma inconsistência na execução da rotina
aAdd(aItens,{{'EE8_COD_1'   ,'0001'     ,NIL},;
            {'EE8_VMDES'    ,"CARRO"    ,NIL},;
            {'EE8_FORN'     ,'001'      ,NIL},;
            {'EE8_FOLOJA'   ,'01'       ,NIL},;
            {'EE8_SLDINI'   , 10        ,NIL},;
            {'EE8_EMBAL1'   , '001'     ,NIL},;
            {'EE8_QE'       , 1         ,NIL},;
            {'EE8_QTDM1'    , 10        ,NIL},;
            {'EE8_PSLQUN'   , 2         ,NIL},;
            {'EE8_POSIPI'   , 01011010  ,NIL},;
            {'EE8_PRECO'    , 10        ,NIL}})
MSExecAuto( {|X,Y,Z| EECAP100(X,Y,Z)},aCab ,aItens, 3)
If lMsErroAuto
lRetorno := .F.
MostraErro()
Else
lRetorno:=.T.
EndIf
RESET ENVIRONMENT

Return

Static Function GetEnvInfo(cRotina)
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
        ConOut(PadC("Ocorreu um erro ao pesquisar os dados do ambiente pela funcao GetEnvInfo()", 80))
        ConOut(Repl("-", 80))
    EndIf
Return NIL
