/*
 ----------------------------------------------------
 ----------------------------------------------------
 ------EXEMPLO MT120C1C----------------
 */
 User Function MT120C1C

 Local aRetTitle := PARAMIXB

 If Alias() == 'SC1'

 Aadd(aRetTitle, RetTitle('C1_OBS'))
 Aadd(aRetTitle, RetTitle('C1_TPOP'))
 Else
  Aadd(aRetTitle, RetTitle('C3_OBS'))
  Endif

  Return(aRetTitle)
