

User Function MT103DEV
Local dDtDe := PARAMIXB[1]
Local dDtAte := PARAMIXB[2]
Local cQuery := ""
// Customização do cliente
/*cQuery := "     SELECT * "
cQuery += "     FROM " + RetSqlName("SF2")
cQuery += "     WHERE F2_FILIAL  = '" + xFilial("adminSF2") + "' "
cQuery += "     AND F2_EMISSAO BETWEEN '" + DtoS(dDtDe) + "' AND '" + DtoS(dDtAte) + "' "
cQuery += "     AND F2_DOC>='000010'"
*/

Alert("TESTE")
Return //cQuery
