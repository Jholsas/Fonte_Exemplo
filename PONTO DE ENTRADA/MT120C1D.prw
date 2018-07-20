//----------------EXEMPLO MT120C1D----------------
User Function MT120C1D
Local aRet
Dados := PARAMIXB
If Alias() == 'SC1'
 Aadd(aRetDados, SC1->C1_OBS)
 Aadd(aRetDados, SC1->C1_TPOP)

 Else
 Aadd(aRetDados, SC3->C3_OBS)

 Endif

 Return(aRetDados)
