#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICODE.CH"
#INCLUDE "AP5MAIL.CH"
#INCLUDE "PROTHEUS.CH"

#DEFINE ENTER CHR(13) + CHR(10)

/*/{Protheus.doc} FFINA002
Grava cotacoes de moeda a partir de WS da Banco Central
Fonte: http://blog.tiagocrizanto.com/configuracoes-do-webservice-do-banco-central-cotacoes-diversas/
C�DIGO	NOME
1		D�lar (venda)
10813	D�lar (compra)
21619	Euro (venda)
21620	Euro (compra)
21621	Iene (venda)
21622	Iene (compra)
21623	Libra esterlina (venda)
21624	Libra esterlina (compra)
21625	Franco Su��o (venda)
21626	Franco Su��o (compra)
21627	Coroa Dinamarquesa (venda)
21628	Coroa Dinamarquesa (compra)
21629	Coroa Norueguesa (venda)
21630	Coroa Norueguesa (compra)
21631	Coroa Sueca (venda)
21632	Coroa Sueca (compra)
21633	D�lar Australiano (venda)
21634	D�lar Australiano (compra)
21635	D�lar Canadense (venda)
21636	D�lar Canadense (compra)
@author Francisco
@since 14/11/2017
@version 12.1.17
@return Nil, Sem Retorno

@type function
/*/
User Function FFINA002()

	dbUseArea(.T.,"CTREECDX","sigamat.emp","SM0", .T., .F.)
	//dbUseArea(.T.,"DBFCDX","sigamat.emp","SM0", .T., .F.)

	//Executa para todas as empresas
	DBSELECTAREA("SM0")
	SM0->(DBGOTOP())
	WHILE SM0->(!EOF())
		StartJob( "U_FFINA02A", GetEnvServer(), .T., SM0->M0_CODIGO, SM0->M0_CODFIL )
		SM0->(DBSKIP())
	ENDDO

Return()

User Function FFINA02A( c_Empresa, c_Filial )

	Local o_Server		:= WSFachadaWSSGSService():New()	//Carrega o WS do Banco Central
	Local o_Explorer	:= clsExplorer():New()				//Classe com os m�todos para cria��o de pasta
	Local c_Caminho		:= "\COTACAO\"						//Pasta onde ser salvo as cota��es das moedas
	Local c_LogGeral	:= "\COTACAO\LOG\"					//Pasta onde ser salvo os logs
	Local c_ArqLog		:= ""								//Nome do arquivo de log
	Local c_Arquivo		:= ""								//Nome do Arquivo das cota��es salvas
	Local c_XML			:= ""								//Vari�vel com o XML de retorno do WS
	Local o_XML												//Objeto que retorna o XML
	Local cAviso		:= ""								//Vari�vel utilizada no XMLParser
	Local cErro			:= ""								//Vari�vel utilizada no XMLParser
	Local o_Data											//Objeto que retorna a data
	Local d_Cotacao		:= CTOD("  /  /  ")					//Data da Cota��o
	Local n_Valor		:= 0								//Valor da moeda
	Local a_Moedas		:= { 21635, 1, 21619 }				//[21635] - D�lar Canadense, [1] - D�lar Americano, [21619] - Euro :: Ambos - Venda
	Local nX			:= 1

	//��������������������������������������������������������������Ŀ
	//| Abertura do ambiente                                         |
	//����������������������������������������������������������������
	RpcSetType(3)
	RpcSetEnv( c_Empresa, c_Filial )

	//Verifica e cria pasta para o XML
	If !o_Explorer:mtdExistePasta( c_Caminho )
		If !o_Explorer:mtdCriaPasta( c_Caminho )
			Conout( "ERRO 001: Nao foi possivel criar a pasta" )
		EndIf
	EndIf

	If !o_Explorer:mtdExistePasta( c_LogGeral )
		If !o_Explorer:mtdCriaPasta( c_LogGeral )
			Conout( "ERRO 001: Nao foi possivel criar a pasta" )
		EndIf
	EndIf

	For nX:=1 To Len( a_Moedas )

		c_Arquivo		:= DTOS( Date() ) + "-" + Alltrim( Str( a_Moedas[ nX ] ) ) + ".txt"

		c_ArqLog := o_Explorer:mtdGravaLog( "Abertura de log" + ENTER, ".log" )
		o_Explorer:mtdEditaLog(c_ArqLog, c_Arquivo + ENTER)
		o_Explorer:mtdEditaLog(c_ArqLog, "Moeda: " + Alltrim( Str( a_Moedas[nX] ) ) + ENTER )

		//Define qual moeda ser� retornada
		o_Server:nin0	:= a_Moedas[ nX ]

		//Executa m�todo que retorna o �ltimo valor da cota��o em XML
		o_Server:getUltimoValorXML()

		//Retorna o XML montado
		c_XML	:=  o_Server:cgetUltimoValorXMLReturn

		//Salva o XML no servidor
		MemoWrite( c_Caminho + c_Arquivo, c_XML )

		//Transforma o XML em Objeto
		o_XML	:= XmlParser( c_XML, "_", @cAviso, @cErro )

		//Monta a data da cota��o
		o_Data		:= o_XML:_RESPOSTA:_SERIE:_DATA

		//Converte a string de data em formato de Data
		d_Cotacao	:= STOD( o_Data:_ANO:TEXT + StrZero( Val( o_Data:_MES:TEXT ), 2 ) + o_Data:_DIA:TEXT )
		o_Explorer:mtdEditaLog(c_ArqLog, "Data: " + o_Data:_ANO:TEXT + StrZero( Val( o_Data:_MES:TEXT ), 2 ) + o_Data:_DIA:TEXT + ENTER )

		//Retorna o valor da moeda
		n_Valor		:= Val( Replace( o_XML:_RESPOSTA:_SERIE:_VALOR:TEXT, ",", "." ) )
		o_Explorer:mtdEditaLog(c_ArqLog, "Valor: " + Replace( o_XML:_RESPOSTA:_SERIE:_VALOR:TEXT, ",", "." ) + ENTER )

		//Posiciona na tabela de moedas
		dbSelectArea( "SM2" )
		dbSetOrder( 1 )
		//If dbSeek( DTOS( d_Cotacao ), .T. )
		If dbSeek( DTOS( DDATABASE ), .T. )

			o_Explorer:mtdEditaLog(c_ArqLog, "Status: Atualizacao de moeda" + ENTER)
			RecLock( "SM2", .F.)
			If nX == 1
				SM2->M2_MOEDA2	:= n_Valor	//[21635] - D�lar Canadense
			ElseIf nX == 2
				SM2->M2_MOEDA3	:= n_Valor	//[1] - D�lar Americano
			Else
				SM2->M2_MOEDA4	:= n_Valor	//[21619] - Euro
			Endif
			MsUnLock()

		Else

			o_Explorer:mtdEditaLog(c_ArqLog, "Status: Moeda nova" + ENTER)
			RecLock( "SM2", .T.)
			//SM2->M2_DATA	:= d_Cotacao
			SM2->M2_DATA	:= DDATABASE
			If nX == 1
				SM2->M2_MOEDA2	:= n_Valor	//[21635] - D�lar Canadense
			ElseIf nX == 2
				SM2->M2_MOEDA3	:= n_Valor	//[1] - D�lar Americano
			Else
				SM2->M2_MOEDA4	:= n_Valor	//[21619] - Euro
			Endif
			MsUnLock()

		EndIf

		o_Explorer:mtdCopyFile( c_ArqLog, c_LogGeral + DTOS( Date() ) + "-" + Alltrim( Str( a_Moedas[ nX ] ) ) + ".txt", .T. )

	Next



Return()
