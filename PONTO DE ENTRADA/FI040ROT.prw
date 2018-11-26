#Include "TOTVS.ch"

User Function FI040ROT()
    Local aRotina := AClone(PARAMIXB)


    AAdd(aRotina, {"TESTE 1", "TESTE 1", 0, 3})
    AAdd(aRotina, {"TESTE 2", "TESTE 2", 0, 3})
    AAdd(aRotina, {"TESTE 3", "TESTE 3", 0, 3})
    AAdd(aRotina, {"TESTE 4", "TESTE 4", 0, 3})

Return (aRotina)

/*User Function FI040ROT()
    Local aRotina := {PARAMIXB2,PARAMIXB3,PARAMIXB4,PARAMIXB5,PARAMIXB6}

    Alert('Ponto de Entrada: FI040ROT');
    aAdd( aRotina, {"Novo Menu", "fuction", 0, 7})

Return aRotina
*/
