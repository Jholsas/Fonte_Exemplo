User Function F450GRAVA()

Local aSE1_SE21 := PARAMIXB
Local _nJuros := 50
Local nAbat := SumAbatRec(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"S",dDataBase)
Local nDescont := FaDescFin("SE1",dDataBase,SE1->E1_SALDO-nAbat,SE1->E1_MOEDA)

//Alert("Ponto - F450GRAVA")

If aSE1_SE21[1] == "SE1" //Titulos a Receber
RecLock("TRB",.F.)
Replace JUROS With _nJuros
Replace RECEBER With SE1->E1_SALDO - nAbat + SE1->E1_SDACRES - SE1->E1_SDDECRE - nDescont
Replace TESTE With "TESTE PE RC"
MsUnlock()
Elseif aSE1_SE21[1] == "SE2" //Titulos a Pagar
RecLock("TRB",.F.)
Replace JUROS With _nJuros
Replace PAGAR With SE2->E2_SALDO + SE1->E1_SDACRES - SE1->E1_SDDECRE
Replace TESTE With "TESTE PE PG"
MsUnlock()

Endif

Return
