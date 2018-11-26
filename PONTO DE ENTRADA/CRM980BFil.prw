#INCLUDE "PROTHEUS.CH"
User Function CRM980BFil()
//Expressão ADVPL
Local cFiltro :=""

// ALERT("PONTO DE ENTRADA - CRM980FIL")
 cFiltro := "SA1->A1_NOME = 'CLIENTE TESTE                           '"

cFiltro := "SA1->A1_COD = 'CLNT21'"
SET FILTER TO &(cFiltro)

Return ( cFiltro )
