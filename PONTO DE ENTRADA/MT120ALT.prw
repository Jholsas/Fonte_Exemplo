
User Function MT120ALT()

    Local lExecuta := .T.
        If Paramixb[1] == 4  // Alteração
        Alert("MT120ALT")
        dbSelectArea('SC7')
            If SC7->C7_TIPO == 1 .And. SC7->C7_CODTAB <> '002'
              lExecuta := .F.
            EndIf
        EndIf
Return( lExecuta )
