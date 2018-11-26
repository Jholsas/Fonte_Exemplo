#Include "TOTVS.ch"

User Function MT161OK()
    Local aProp := PARAMIXB[1]
    Local cTipo := PARAMIXB[2]
    Local lCont := .T.
    // Local cObs01:= ""
    // Local cObs02:= ""

// C8_FILIAL+C8_NUM+C8_PRODUTO
    // cObs01:= POSICIONE("SC8",3,XFILIAL("SC8")+"000037"+"000220","C8_OBS")
    // cObs02:= POSICIONE("SC8",3,XFILIAL("SC8")+"000037"+"0101010","C8_OBS")
    // MsgInfo("Entrou no ponto MT161OK")
    // Alert(cObs01)
    // Alert(cObs02)

    Alert("Ponto - MT161OK")

Return (lCont)
