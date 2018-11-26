user function MT410BRW()

Local cFiltro :=""

ALERT("PONTO DE ENTRADA - MT410BRW")
//cFiltro := "SA1->A1_NOME = 'CLIENTE TESTE                           '"

// Limpar o filtro atual SET FILTER TO
// Setar filtro
//SET FILTER TO A1_FILIAL = '01' .and. A1_GRUPO = '02'
// Setar filtro dinamico
//cFiltro := "A1_FILIAL = '"+xFilial("SA1")+"' .AND. A1_GRUPO = '"+cGrpFiltro+"'"
cFiltro := "SA1->A1_NOME = 'CLIENTE TESTE                           '"
SET FILTER TO &(cFiltro)



Return
