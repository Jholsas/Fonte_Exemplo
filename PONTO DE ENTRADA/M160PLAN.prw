User Function M160PLAN
Local cPar1 := PARAMIXB[1]
Local aPar1 := PARAMIXB[2]
Local aPar2 := PARAMIXB[3]
Local aRet := .T.

//..Customizacao do cliente

Alert("M160PLAN")

RecLock("SC8",.F.)
    aPar1[1][aScan(aPar2,"C8_OBS03")] := "M160PLAN"
MsUnlock()

Return aPar1
