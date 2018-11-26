#Include 'Protheus.ch'

User Function MA103ATF()
Local aCab := ParamIXB[1]
Local aItens := ParamIXB[2]
Local nItem

Alert("TESTE PE MA103ATF")

//Adição de campos customizados - SN1
aAdd(aCab,{"N1_PRODUTO" , SD1->D1_COD })

//Adição de campos customizados - SN3
For nItem:=1 to Len(aItens)
aAdd(aItens[nItem],{"N3_CLVLCON", SD1->D1_CLVL })
Next nItem

Return({aCab,aItens})
