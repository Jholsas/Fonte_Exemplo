#include 'protheus.ch'
#include 'parmtype.ch'

user function MA410MNU()// desconsiderar

		aadd(aRotina,{'TESTE ','U_FONTE' , 0 , 3,0,NIL})
		aAdd(aRotina,{ "&Marinha Mercante" ,{{'E&nvia Arquivo'  , 'U_TMSREL02',0, 1 },{'E&nvia Arquivo 2'  , 'U_TMSREL02',0, 1 },{'E&nvia Arquivo 3'  , 'U_TMSREL02',0, 2 },{'E&nvia Arquivo 4'  , 'U_TMSREL02',0, 2 }},0,6, ,.F.})


Desconsiderar inforemações abaixo
	/*ONDE:Parametros do array a Rotina:
	1. Nome a aparecer no cabecalho
	2. Nome da Rotina associada
	3. Reservado
	4. Tipo de Transação a ser efetuada:
	1 - Pesquisa e Posiciona em um Banco de Dados
	2 - Simplesmente Mostra os Campos
	3 - Inclui registros no Bancos de Dados
	4 - Altera o registro corrente
	5 - Remove o registro corrente do Banco de Dados
	5. Nivel de acesso
	6. Habilita Menu Funcional*/


return aRotina
