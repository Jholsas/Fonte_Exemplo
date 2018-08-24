#INCLUDE "RWMAKE.CH"

User Function A103VCTO()
Local aPELinhas     := PARAMIXB[1]
Local nPEValor      := PARAMIXB[2]
Local cPECondicao   := PARAMIXB[3]
Local nPEValIPI     := PARAMIXB[4]
Local dPEDEmissao   := PARAMIXB[5]
Local nPEValSol     := PARAMIXB[6]
Local aVencto       := {}

// Customizacoes do cliente
Alert("Ponto de entrada - A103VCTO ")

Return aVencto //Array com os vencimentos para geração dos títulos.
