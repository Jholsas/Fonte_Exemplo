

User Function MT160PLN()
Local aPlanilha  := ParamIXB[1]
// Array contendo todos os dados da Planilha de Analise.
Local aAuditoria := ParamIXB[2]
 // Array contendo os dados do FOLDER AUDITORIA (SCE).
 Local aCotacao   := ParamIXB[3]
 // Array contendo os dados da cotacao (SC8).
 // ParamIXB[4]  Op��o do aRotina, sendo Analisar ou visualizar.
 //Valida��o do Usuario para interromper a analise e gera��o dos pedidos.
Alert("MT160PLN")

 Return {aNewPlanilha, aNewAuditoria}
