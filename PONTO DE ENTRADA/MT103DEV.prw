

User Function MT103DEV()
Local dDtDe      := PARAMIXB[1]
Local dDtAte     := PARAMIXB[2]
Local cCliente   := PARAMIXB[3]
Local cLoja      := PARAMIXB[4]
Local cFieldQry  := PARAMIXB[5]
Local cQuery     := ""
// Customização do cliente

cQuery := " SELECT " + cFieldQry //Cabeçalho da "Query" obrigatório do parâmetro "PARAMIXB[5]"
cQuery += " FROM " + RetSqlName("SF2")
cQuery += " WHERE F2_FILIAL = '" + xFilial("SF2") + "'"
cQuery += " AND F2_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "'"

Alert("Ponto de entrada - MT103DEV")
Return cQuery
