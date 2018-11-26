User Function M160STRU
Local aStr := PARAMIXB[1]
Local aCabec := PARAMIXB[2]
Local aCpoSC8 := PARAMIXB[3]
Local nPos := aScan(aCpoSC8,"PLN_FORNEC")

If nPos > 0
//Adiciona campo no array contendo os configuracoes do campo "PLN_FORNEC"
aAdd(aStr,aStr[nPos])
aAdd(aCabec,aCabec[nPos])
aAdd(aCpoSC8,aCpoSC8[nPos])

//Exclui campo "PLN_FORNEC" da posicao antiga
aDel(aStr,nPos)
 aDel(aCabec,nPos)
 aDel(aCpoSC8,nPos)

//Ajusta tamanho do array
 aSize(aStr,len(aStr)-1)
 aSize(aCabec,len(aCabec)-1)
 aSize(aCpoSC8,len(aCpoSC8)-1)

//Inclui campo C8_TESTE na analise da cotacao quando disponivel
dbSelectArea("SX3")
dbSetOrder(2)
If dbSeek("C8_OBS03")
    aadd(aStr,{"C8_OBS03",SX3->X3_TIPO,SX3->X3_TAMANHO,SX3->X3_DECIMAL})
    aadd(aCabec,{"C8_OBS03","",RetTitle("C8_OBS03"),PesqPict("SC8","C8_OBS03")})
    aAdd(aCpoSC8,"C8_OBS03")
EndIf
EndIf

Return {aStr,aCabec,aCpoSC8}
