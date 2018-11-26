User function xTesteMOV()
Local dDataIni  :=  FirstDay(dDataBase)
Local dDataFim  :=  LastDay(dDataBase)
Local cMoeda    := "01"
Local cTpSld1   := "1"
Local cConta    := "000000002"
Local nSaldo    := 0

nSaldo    := MovConta(cConta,dDataIni,dDataFim,cMoeda,cTpSld1,3,1)


// Efeito: Retorna o movimento do mês para a conta contábil "2101", partindo do primeiro dia do
// mês corrente, até o último dia do mês corrente, para a moeda "01", tipo de saldo "1".

//TRANSFORM( cValToChar(nSaldo), "@E 999.999,99")     // Resulta: 1.234,54


Alert("Retorno MovConta:  " + cValToChar(nSaldo))

Return
