#Include "totvs.ch"
#Include "tbiconn.ch"

User Function T75RUN()
    Local aArea := GetArea()

    Private oDlgForm := NIL
    Private oGrpForm := NIL
    Private oGetForm := NIL
    Private cGetForm := Space(250)
    Private oGrpAco  := NIL
    Private oBtnExec := NIL
    Private nJanLarg := 500
    Private nJanAltu := 120
    Private nJanMeio := ((nJanLarg) / 2) / 2
    Private nTamBtn  := 048

    If (IsBlind() == .T.)
        BatchProcess("SCHED", "SCHED", NIL, {|| T75EXEC()})
    Else
        DEFINE MSDIALOG oDlgForm TITLE "Execução de Funções" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
            @ 003, 003  GROUP oGrpForm TO 30, (nJanLarg/2)-1        PROMPT "Função: " OF oDlgForm COLOR 0, 16777215 PIXEL
                @ 010, 006  MSGET oGetForm VAR cGetForm SIZE (nJanLarg/2)-9, 013 OF oDlgForm COLORS 0, 16777215 PIXEL

            @ (nJanAltu/2)-30, 003 GROUP oGrpAco TO (nJanAltu/2)-3, (nJanLarg/2)-1 PROMPT "Ações: " OF oDlgForm COLOR 0, 16777215 PIXEL
                @ (nJanAltu/2)-24, nJanMeio - (nTamBtn/2) BUTTON oBtnExec PROMPT "Executar" SIZE nTamBtn, 018 OF oDlgForm ACTION(T75EXEC()) PIXEL
        ACTIVATE MSDIALOG oDlgForm CENTERED
    EndIf

    RestArea(aArea)
Return (NIL)

User Function T75MENU()
    MsApp():New("SIGAADV")
    oApp:CreateEnv()

    PtSetTheme("SUNSET")

    oApp:bMainInit:= {|| MsgRun("Configurando ambiente...", "Aguarde...",;
        {|| RPCSetEnv("99","01", "Administrador", " "), }), U_T75RUN(), Final("Término Normal")}

    __lInternet      := .T.
    lMsFinalAuto     := .F.
    oApp:lMessageBar := .T.
    oApp:cModDesc    := "SIGAADV"

    oApp:Activate()
Return (NIL)

Static Function T75EXEC()
    Local aArea    := GetArea()
    Local cFormula := Alltrim(cGetForm)
    Local cError   := ""
    Local bError   := ErrorBlock({|oError| cError := oError:Description})

    If !(Empty(cFormula))
        cFormula := "U_" + cFormula + "()"

        BEGIN SEQUENCE
            &(cFormula)
        END SEQUENCE

        ErrorBlock(bError)

        If !(Empty(cError))
            MsgStop("Houve um erro na fórmula digitada: " + CRLF + CRLF + cError, "Atenção")
        EndIf
    EndIf

    RestArea(aArea)
Return (NIL)

Static Function SCHEDDEF()
    Local aSchDef := {}

    AAdd(aSchDef, "P")      // R) RELATORIO | P) PROCESSO
    AAdd(aSchDef, "FIN370") // NOME DO GRUPO DE PERGUNTAS (SX1)
    AAdd(aSchDef, NIL)      // CALIAS (PARA RELATORIO)
    AAdd(aSchDef, NIL)      // AARRAY (PARA RELATORIO)
    AAdd(aSchDef, NIL)      // TITULO (PARA RELATORIO)
Return (aSchDef)
