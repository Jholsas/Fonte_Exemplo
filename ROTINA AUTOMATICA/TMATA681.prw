/*------------------------------------------------------------------*\
| DESCRIÇÃO: Esta rotina possibilita o apontamento de produção       |
| baseado no roteiro de operações de forma automática                |
|--------------------------------------------------------------------|
| LINK: http://tdn.totvs.com/pages/releaseview.action?pageId=6089272 |
\*------------------------------------------------------------------*/

#Include "TOTVS.ch"
#Include "TBICONN.ch"

User Function TMATA681()
    Local nOpc   := 5 // estorno
    Local aCabec := {}
    Local aRPO   := {}

    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .T.

    PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SH6"

	aRPO := GetApoInfo("MATA681.prx")

    ConOut(Repl("-", 80))
    ConOut(PadC("Rotina: " + aRPO[1], 80))
    ConOut(PadC("Data: " + DToC(aRPO[4]) + " " + aRPO[5], 80))
    ConOut(PadC("SmartClient: " + GetBuild(.T.), 80))
    ConOut(PadC("AppServer: " + GetBuild(.F.), 80))
    ConOut(PadC("Inicio: " + Time(), 80))
    ConOut(Repl("-", 80))

 	// INÍCIO: estorno //
    If nOpc == 5
    DBSelectArea("SH6")
    DBSetOrder(3)//H6_FILIAL, H6_PRODUTO, H6_OP, H6_OPERAC, H6_LOTECTL, H6_NUMLOTE, R_E_C_N_O_, D_E_L_E_T_
    MsSeek(xFilial("SH6") + "SERV0001       " +"00001901001   " + "01" +  "LOTE0004  ")
        aCabec := { {"H6_OP",           SH6->H6_OP	    ,    NIL},;
                    {"H6_PRODUTO",      SH6->H6_PRODUTO ,    NIL},;
                    {"H6_OPERAC",       SH6->H6_OPERAC  ,    NIL},;
                    {"H6_RECURSO",      SH6->H6_RECURSO ,    NIL},;
                    {"H6_DTAPONT",      SH6->H6_DTAPONT ,    NIL},;
                    {"H6_DATAINI",      SH6->H6_DATAINI ,    NIL},;
                    {"H6_HORAINI",      SH6->H6_HORAINI ,    NIL},;
                    {"H6_DATAFIN",      SH6->H6_DATAFIN ,    NIL},;
                    {"H6_HORAFIN",      SH6->H6_HORAFIN ,    NIL},;
                    {"H6_PT",           SH6->H6_PT	    ,    NIL},;
                    {"H6_LOCAL",        SH6->H6_LOCAL	,    NIL},;
                    {"H6_LOTECTL",      SH6->H6_LOTECTL ,    NIL},;
                    {"H6_QTDPROD",      SH6->H6_QTDPROD ,    NIL},;
                    {"AUTRECNO",        SH6->(Recno())  ,    Nil}}

*/
    EndIf
 	// FIM: INCLUSÃO //

    MsExecAuto({|x, y| MATA681(x, y)}, aCabec, nOpc)

    If (lMsErroAuto == .T.)
		MostraErro()
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA681 finalizado com erro!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	Else
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA681 finalizado com sucesso!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
	EndIf

	RESET ENVIRONMENT
Return NIL
