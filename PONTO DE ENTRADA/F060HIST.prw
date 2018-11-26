User Function F060HIST()

Local cSituacao := ""
Local cHistorico := ""

    Alert(" PE-F060HIST")

    If cSituacao == "1"
        cHistorico:= "SIMPLES"
    EndIf

Return cHistorico
