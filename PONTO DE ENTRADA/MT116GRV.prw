User Function MT116GRV ()
    Local lRet := .T.

    If SF1->F1_UFORITR = " "
        Alert("preencha campo os campos ")
        lRet := .F.
        Else
        lRet := .T.
    EndIf


    Alert("MT116GRV")

return lRet
