#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "PROTHEUS.CH"

user function mBrws()

	/*LOCAL cAlias := 'JBR' 

	PRIVATE cCadastro := 'Cadastro de Fornecedores'

	PRIVATE aRotina     := { }


	AADD(aRotina, { 'Pesquisar', 'AxPesqui', 0, 1 })

	AADD(aRotina, { 'Visualizar', 'AxVisual'  , 0, 2 })

	AADD(aRotina, { 'Incluir'      , 'AxInclui'   , 0, 3 })

	AADD(aRotina, { 'Alterar'     , 'AxAltera'  , 0, 4 })

	AADD(aRotina, { 'Excluir'     , 'AxDeleta' , 0, 5 })

	AADD(aRotina, { 'TESTE'     , 'U_FONTE' , 0, 6 })


	dbSelectArea(cAlias)

	dbSetOrder(1)

	mBrowse(6, 1, 22, 75, cAlias)


*/


	MSGALERT( "Utilizando Date()"  + DATE() )                // Resulta: 28/05/12

	MSGALERT( "Utilizando Date() + 30"  + DATE() + 30 )          // Resulta: 27/06/12

//	MSGALERT( DATE() – 10 )          // Resulta: 28/04/12



	dData := DATE()



	MSGALERT("Utilizando CMONTH(dData)" + CMONTH(dData) )          // Resulta: Maio



	// Calcula a idade de uma pessoa que nasceu em 13/09/69 por meio da diferença entre a corrente e a data do seu nascimento.

	//MSGALERT( INT( ( DATE() – CTOD(“13/09/69”) ) / 365 ) )

RETURN NIL


