#Include 'Protheus.ch'

User Function MaAvCrFin()

Local cQuerySE1 := ParamIxb[1]
Local cCodCli := ParamIxb[2]
Local cLoja := ParamIxb[3]

alert("PE - MaAvCrFin")

cQuerySE1 := "SELECT MIN(E1_VENCREA) VENCREAL "
cQuerySE1 += "FROM "+RetSqlName("SE1")+" SE1 "
cQuerySE1 += "WHERE SE1.E1_FILIAL='"+xFilial("SE1")+"' AND "
cQuerySE1 += "SE1.E1_CLIENTE='"+cCodCli+"' AND "
cQuerySE1 += "SE1.E1_LOJA='"+cLoja+"' AND "
cQuerySE1 += "SE1.E1_STATUS='A' AND "
cQuerySE1 += "SE1.D_E_L_E_T_=' ' "


Return (cQuerySE1)
