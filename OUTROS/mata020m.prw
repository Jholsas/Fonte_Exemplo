#INCLUDE "MATA020.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWADAPTEREAI.CH"
#include "TbIconn.ch"
#include "TopConn.ch"

Static lCGCValido	:= .F.	// Variavel usada na validacao do CNPJ/CPF (utilizando o Mashup)
Static lConfBco	:= .F. // Confirmacao da Dialog de amarracao fornecedor x bancos (Localizados) - FIL

/*/{Protheus.doc} MATA020
Cadastro de fornecedor.

Esse fonte é usado por todos os paises, por esse motivo tudo que existir aqui deve ser referente ao
padrão. Se alguma regra se aplica somente a um pais ou a alguns paises, a regra deve ser escrita
no fonte correspondente ao pais(es).

As validações e integrações realizadas após/durante a gravação estão definidas nos eventos do modelo,
na classe MATA020EVDEF.

@type function
@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Function MATA020M(xRotAuto,nOpcAuto)
Local oBrowse
Local lRotMata020 := IsInCallStack("MATA020")

DEFAULT nOpcAuto := 3

	// Carrega as perguntas mesmo se for rotina automatica, pois na gravação olha o conteudo dos MV_PAR
	Pergunte("MTA020",.F.)

	If ValType(xRotAuto) == "A"
		A020Auto(xRotAuto, nOpcAuto)
	Else

		oBrowse := BrowseDef()
		oBrowse:Activate()

		A020F12End()
	EndIf

Return( .T. )

/*/{Protheus.doc} BrowseDef
Define o browse padrão para o cadastro de fornecedor.

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Static Function BrowseDef()
Local oBrowse
Local cFiltraSA2	:= " "
Local aMemUser	:= {}

	//Habilita a perguntas da rotina
	Set Key VK_F12 to F12Init()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SA2")
	oBrowse:SetDescription(STR0006) //"Fornecedores"

	//Verificacao de filtro na Mbrowse
	If ( ExistBlock("MA020FIL") )
		cFiltraSA2 := AllTrim(ExecBlock("MA020FIL",.F.,.F.))
		oBrowse:SetFilterDefault(cFiltraSA2)
	EndIf

Return oBrowse

/*/{Protheus.doc} IntegDef
Função necessaria para o EAI.

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Static Function IntegDef( cXml, nTypeTrans, cTypeMessage )

	Local aRet := {}

	aRet:= MATI020( cXml, nTypeTrans, cTypeMessage )

Return aRet

/*/{Protheus.doc} A020Auto
Função que realiza a rotina automatica para o MATA020 em MVC.

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Static Function A020Auto(aRotAuto, nOpcAuto)
Local nPosFor
Local nPosLoja
Local nPosMun
Local oModel := FWLoadModel("MATA020M")

	//|Obter o A2_COD_MUN direto da base quando a alteração for originada do Portal do Fornecedor  |
	//|Tal funcionalidade foi implementada inicialmente para que as alterações efetuadas no Portal |
	//|não sejem barradas pela rotina automática, porém será necessário rever WebService do Portal |
	//|Implementar a consulta F3 para o campo etc. 												   |
	If IsInCallStack("PUTSUPPLIER")
		nPosFor:=aScan(aRotAuto,{|x| AllTrim(x[1])== "A2_COD"})
		nPosLoja:=aScan(aRotAuto,{|x| AllTrim(x[1])== "A2_LOJA"})
		nPosMun:=aScan(aRotAuto,{|x| AllTrim(x[1])== "A2_COD_MUN"})
		If nPosFor>0 .And. nPosLoja>0 .And. nPosMun==0
			DbSelectArea("SA2")
			DbSetOrder(1)
			MsSeek(xFilial("SA2")+aRotAuto[nPosFor][2]+aRotAuto[nPosLoja][2])
			If !Eof()
				AADD(aRotAuto,{"A2_COD_MUN",SA2->A2_COD_MUN,NIL})
			EndIf
		EndIf
	EndIf

	// ------------------------------------------------------------------------------------------------
	// Aqui é usado o LoadModel() e não ModelDef() pois o LoadModel trata a localização e carrega o
	// o model referente a localização (se houver)
	// Se for colocado modeldef() vai carregar o modelo default e não o localizado
	// ------------------------------------------------------------------------------------------------
	FWMVCRotAuto(oModel,"SA2",nOpcAuto,{{"SA2MASTER",aRotAuto}},,.T.)

	//Tratamento realizado para evitar Reference counter overflow.
	oModel:DeActivate()
	oModel:Destroy()
	oModel:=Nil

Return

/*/{Protheus.doc} A020Deactivate
Executado no deactivate do modelo de dados.

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Static Function A020Deactivate(oModel)
	//Limpa a variavel estatica do MATA020 que controla a validação de CGC
	A020ClearVar()
Return

/*/{Protheus.doc} A020F12End
Remove o atalho definido para a tecla F12.
As rotinas localizadas usam essa função depois que o browse é desativado.

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Function A020F12End()
	//Remove tecla de atalho
	Set Key VK_F12 To
Return

/*/{Protheus.doc} F12Init
Função usada como saida para o seguinte problema:
	Se é feito "Set Key VK_F12 to pergunte("MTA020", .T.)" ao apertar F12 não executa o atalho
	Se é feito "Set Key VK_F12 to F12Init()" o atalho funciona corretamente

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Static Function F12Init()
pergunte("MTA020",.T.)
Return Nil

/*/{Protheus.doc} A020Bancos
Abre uma view com o grid de bancos do fornecedor.
Esse grid faz parte do modelo de dados do fornecedor, por isso, os dados dele serão salvos
somente quando o modelo MATA020 for gravado.

@type function

@author Juliane Venteu
@since 02/02/2017
@version P12.1.17

/*/
Function A020Bancos(oView,cFieldsBanco)
Local oModel := oView:GetModel()
Local oViewBancos
Local oExecView
Local oStr
Local aMT020FIL

DEFAULT cFieldsBanco :=  "|FIL_BANCO|FIL_AGENCI|FIL_CONTA|FIL_TIPO|FIL_DETRAC|FIL_MOEDA|FIL_DVAGE|FIL_DVCTA|FIL_TIPCTA|FIL_MOVCTO|"

	//Adiciona na view campos que o usuario desejar da tabela FIL
	If ExistBlock("MT020FIL")
		aMT020FIL := ExecBlock("MT020FIL", .F.,.F.)
		If ValType(aMT020FIL) == 'A' .And. Len("aMT020FIL") >= 2
			cFieldsBanco	+= aMT020FIL[1]
		EndIf
	EndIf

	oStr:= FWFormStruct(2, 'FIL', {|cField| AllTrim(Upper(cField)) $ AllTrim(Upper(cFieldsBanco)) })

	//--------------------------------------------------------------------------------
	//	Monta a view para exibir o grid
	// oView é passado por parametro para indicar que oViewBancos é filho do oView
	//--------------------------------------------------------------------------------
	oViewBancos := FWFormView():New(oView)
	oViewBancos:SetModel(oModel)
	oViewBancos:AddGrid('FORM' , oStr,'BANCOS' )
	oViewBancos:CreateHorizontalBox( 'BOX', 100)
	oViewBancos:SetOwnerView('FORM','BOX')
	oViewBancos:SetCloseOnOk({|| A020MVldBc(oView)})
	oViewBancos:SetAfterOkButton({|| A020MSetBc(oView)})

	//--------------------------------------------------------------------------------
	// Monta a janela para exibir o view. Não é usado o FWExecView porque o FWExecView
	// obriga a passar o fonte para carregar a View e aqui já temos a view pronta
	//--------------------------------------------------------------------------------
	oExecView := FWViewExec():New()
	oExecView:SetView(oViewBancos)
	oExecView:setTitle(STR0084)
	oExecView:SetModel(oModel)
	oExecView:setModal(.F.)
	oExecView:setOperation(oModel:GetOperation())
	oExecView:openView(.F.)

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³fVariavel ³ Autor ³Julio C.Guerato        ³ Data ³31.05.2010³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Atualiza variáveis após a inclusão, alteracao, exclusão     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³fVariavel(ExpN1)                                        	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1: Opcao de avaliacao                                   ³±±
±±³          ³       [1] Inclusao                                         ³±±
±±³          ³       [2] Alteracao                                        ³±±
±±³          ³       [3] Exclusao                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³.T.														  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA020                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function A020ClearVar(nOpcA)
	lCGCValido:= .F.
Return (.T.)


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³A020ValDoc³ Autor ³ Fernando Machima      ³ Data ³ 07.06.04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Validacao do campo NIT. Nao permitir cadastrar dois fornece-³±±
±±³          ³dores com o mesmo NIT                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A020ValDoc()                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum												      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F. 												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Cadastro de fornecedores                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function A020ValDoc()

Local lRet     := .T.
Local lFound   := .F.
Local cCodForn := Space(TamSX3("A2_COD")[1])
Local cLojForn := Space(TamSX3("A2_LOJA")[1])
Local aArea    := GetArea()

DbSelectArea("SA2")
DbSetOrder(3)
If !Empty(M->A2_CGC) .And. DbSeek(xFilial("SA2")+M->A2_CGC)
	While !Eof() .And. xFilial("SA2")+M->A2_CGC == SA2->A2_FILIAL+SA2->A2_CGC .And. !lFound
		//Desconsiderar se for o proprio fornecedor ou uma de suas filiais
		If M->A2_COD == SA2->A2_COD
			DbSkip()
			Loop
		EndIf
		lFound    := .T.
		lRet      := .F.
		cCodForn  := SA2->A2_COD
		cLojForn  := SA2->A2_LOJA
	End
EndIf

If !lRet
	MsgAlert(STR0051,"A020NIT")
EndIf

RestArea(aArea)

Return (lRet)


/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³A020NomFav ³ Autor ³ Rodolfo K. Rosseto   ³ Data ³ 22/03/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³ Posiciona e restaura o SA2                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ExpC1 := A020NomFav()                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum												      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpC1 = Nome do favorecido								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA020                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
//RETIRAR STATIC
Static Function A020NomFav()

Local aAreaSA2  := {}
Local cNomeFav  := ''

If !INCLUI
	aAreaSA2 := SA2->(GetArea())
	cNomeFav := Posicione("SA2",1,xFilial("SA2")+SA2->A2_CODFAV+SA2->A2_LOJFAV,"A2_NOME")
	RestArea(aAreaSA2)
EndIf

Return cNomeFav


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³A020Cep   ³ Autor ³ Eduardo Riera         ³ Data ³30.11.2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Utilizacao dos dados fornecidos pelos correios             ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpC1: CEP                                                  ³±±
±±³          ³ExpA2: Array com os dados que serao preenchidos             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//RETIRAR STATIC
Static Function A020Cep(cTipo)

DEFAULT cTipo := ""
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Avalia o site dos correios - Mashups                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If GetNewPar("MV_MASHUPS",.F.) .And. !_SetAutoMode()
	Do Case
		Case cTipo == "E"
			CepMashups(M->A2_CEPE,{"M->A2_ENDENT","M->A2_BAIRROE","M->A2_MUNE","M->A2_ESTE"})
		Case cTipo == "C"
			CepMashups(M->A2_CEPC,{"M->A2_ENDCOB","M->A2_BAIRROC","M->A2_MUNC","M->A2_ESTC"})
		OtherWise
			CepMashups(M->A2_CEP,{"M->A2_END","M->A2_BAIRRO","M->A2_MUN","M->A2_EST"})
	EndCase
EndIf
Return(.T.)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³MTA020AtOp ³ Autor ³ Vitor Raspa          ³ Data ³ 06.Dez.06³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Atualiza os dados do Fornecedor no cadastro da Operadora   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MTA020AtOp()                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
//RETIRAR STATIC
Static Function MTA020AtOp()
Local aCodigos   := {}
Local nOpcao     := 0
Local oDlg
Private cCodOpe  := CriaVar('DEG->DEG_CODOPE',.F.)
Private cNomOpe  := CriaVar('DEG->DEG_NOMOPE',.F.)

DEFINE MSDIALOG oDlg FROM 00,00 TO 090,350 PIXEL TITLE STR0030 //-- 'Atualiza Dados na Operadora'

@ 011,005 SAY RetTitle('DEG_CODOPE') SIZE 100,15 COLOR CLR_HBLUE PIXEL
@ 010,045 MSGET cCodOpe  F3 "DEG" PICTURE  PesqPict("DEG","DEG_CODOPE") SIZE 6,9  ;
			VALID TMSValField(,.T.,'DEG_NOMOPE') .And. TMSValField(,.F.,'cNomOpe') PIXEL
@ 010,070 MSGET cNomOpe WHEN .F. SIZE 100,9 PIXEL
DEFINE SBUTTON FROM 30,115 TYPE 1 OF oDlg ENABLE ACTION (nOpcao := 1,oDlg:End())
DEFINE SBUTTON FROM 30,145 TYPE 2 OF oDlg ENABLE ACTION (nOpcao := 0,oDlg:End())

ACTIVATE MSDIALOG oDlg CENTERED

If nOpcao == 1
	AAdd( aCodigos, {SA2->(A2_COD+A2_LOJA),'','','',''} )
	CursorWait()
	MsgRun( STR0031,; //-- "Atualizando dados junto a Operadora"
			STR0032,; //-- "Aguarde..."
			{|| TMSAtualOp( cCodOpe, '5', aCodigos, .T. ) } )
	CursorArrow()
EndIf

Return
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³A020WizFac³ Autor ³ Gustavo G. Rueda      ³ Data ³27/11/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada da rotina que permite uma manutencao facil no      ³±±
±±³          ³ cadastro.                                                  ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³.T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//RETIRAR STATIC
Static Function A020WizFac()
Local	cCmps		:=	""
Local	aPar  		:=	{}
Local	cMVA020FAC	:=	GetNewPar("MV_A020FAC","")

cCmps	:=	"A2_BAIRRO/A2_MUN/A2_EST/A2_ESTADO/A2_CEP/A2_TIPO/A2_NATUREZ/A2_TRANSP/A2_PRIOR/A2_RISCO/"
cCmps	+=	"A2_COND/A2_CONTA/A2_TIPORUR/A2_RECISS/A2_PAIS/A2_PAISDES/A2_GRUPO/A2_ATIVIDA/A2_VINCULA/A2_EMAIL/A2_HPAGE/A2_CODMUN/"
cCmps	+=	"A2_RECINSS/A2_TPISSRS/A2_CODLOC/A2_CODPAIS/A2_TPESSOA/A2_GRPTRIB/A2_CONTAB/A2_PAISORI/A2_CNAE/A2_CIVIL/A2_COD_MUN/"
cCmps	+=	"A2_MSBLQL/A2_TIPAWB/A2_DTPAWB/A2_RECSEST/A2_RECPIS/A2_RECCOFI/A2_RECCSLL/A2_CALCIRF/A2_VINCULO/A2_DTINIV/A2_DTFIMV/"
cCmps	+=	"A2_RECFET/A2_CODINSS/A2_CTARE/A2_IBGE/A2_FRETISS/"
cCmps	+=	cMVA020FAC

aAdd(aPar,{"SA2","A2_COD+' - '+A2_NOME", cCmps, ""})

MATA984(aPar[1,1],aPar[1,2],aPar[1,3],,aPar[1,4])

Return .T.

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³A120SXB   | Autor ³Aline Sebrian          ³ Data ³ 20/06/08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Inclusão de Fornecedores através da tecla F3.               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//RETIRAR STATIC
Static Function A020SXB()
	FWExecView(,"MATA020",3,,{|| .T.})
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³A020WebbIcºAutor  ³Marcelo Custodio    º Data ³  22/04/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Permite incluir fornecedor atraves da rotina de reprocessa  º±±
±±º          ³mento da integracao ACC.                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao Compras X ACC.                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//RETIRAR STATIC
Static Function A020WebbIc(aFields)
Local oModel
Local nOK
Local nX

Default aFields := {}

	If Len(aFields) > 0
		oModel := FWLoadModel("MATA020M")
		oModel:SetOperation(MODEL_OPERATION_INSERT)
		oModel:Activate()

		For nX:=1 to Len(aFields)
			oModel:SetValue("SA2MASTER",aFields[nX][1], aFields[nX][2])
		Next nX
	EndIf

	nOK := FWExecView(,"MATA020M",3,,{|| .T.},,,,,,,oModel)

	//----------------------------------------------------------------
	// Compatibilização do retorno.. a função retornava o AxInclui
	// por isso foi tratado para retornar igual o AxInclui
	//----------------------------------------------------------------
	If nOK == 0 // OK
		nOK == 1
	ElseIf nOK == 1 //Cancelou
		nOK == 2
	EndIf

Return nOK

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³HtmlPicPes| Autor ³ Aline S Damasceno  	³ Data ³03/12/12  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna a picture do CGC ou CPF para o Client HTML         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ ExpL1 := PicPes(cTipPes)                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ cTipPes - F-Fisica/J-Juridica                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Client HTML      										  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
//RETIRAR STATIC
Static Function HTMLPP(cTipPes)
Local cPict := ""
if cTipPes == "F"
	cPict := "@R 99999999999"
else
	cPict := "@R 99999999999999"
endif
cPict := cPict + "%C"
Return cPict

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ A080Hist     ºAutor  ³Wemerson Randolfo     º Data ³ 03/09/12 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Visualizacao do historico das alteracoes                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ Nao ha                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ .T. ou .F.                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºAplicacao ³ Funcao chamada pelo menu                                      º±±
±±º          ³                                                               º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
//RETIRAR STATIC
Static Function A020Hist()
Local lRet

lRet := HistOperFis("SS3",SA2->A2_COD,SA2->A2_NOME,"S3_COD")
Return lRet

//-----------------------------------------------------
/*/{Protheus.doc}A020NumRa
	Validacao do codigo do funcionario

@author Jose Delmondes
@since 25/02/2014
/*/
//------------------------------------------------------
//RETIRAR STATIC
Static Function A020NUMRA(cNumRa)
Local lRet 	:= .T.

If !Empty(cNumRa)
	dbSelectArea("SRA")
	dbSetOrder(1)
	If msSeek(xFilial("SRA")+cNumRa) .And. SRA->RA_SITFOLH == "D"
		MsgAlert("Funcionario Demitido.")
		lRet := .F.
	EndIf
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A020FilSRA()
Gatilho responsavel por atualizar dados do fornecedor conforme tabela de funcionario
@author Leonardo Quintania
@since 06/02/2015
@version 1.0
@return NIL
/*/
//-------------------------------------------------------------------
//RETIRAR STATIC
Static Function A020FilSRA(cMat)

Default cMat := &(ReadVar())

If !Empty(cMat)
	If SRA->(MsSeek(xFilial("SRA")+cMat)) //Atualiza os dados do fornecedor com o funcionario encontrado.
		M->A2_NOME 			:= SRA->RA_NOMECMP
		M->A2_NREDUZ		:= SRA->RA_NOME
		M->A2_END			:= SRA->RA_ENDEREC
		M->A2_BAIRRO		:= SRA->RA_BAIRRO
		M->A2_EST			:= SRA->RA_ESTADO
		M->A2_MUN			:= SRA->RA_MUNICIP
		M->A2_CEP			:= SRA->RA_CEP
		M->A2_CGC			:= SRA->RA_CIC
		M->A2_PFISICA		:= SRA->RA_RG
		M->A2_TEL			:= StrTran(SRA->RA_TELEFON,"-","")
		M->A2_BANCO			:= Substr(SRA->RA_BCDEPSA,1,TamSX3("A2_BANCO")[1])
		M->A2_AGENCIA		:= Substr(SRA->RA_BCDEPSA,TamSX3("A2_BANCO")[1] +1,TamSX3("A2_AGENCIA")[1])
		M->A2_NUMCON		:= SRA->RA_CTDPFGT
		M->A2_EMAIL			:= SRA->RA_EMAIL
	EndIf
Else
	Help(" ",1,"MATIMPORT")
EndIf

Return cMat

//-------------------------------------------------------------------
/*/{Protheus.doc} A020SICAF()
Rotina que realiza consulta aos dados de fornecedores no SICAF e permite inclusão de fornecedor / participante
@author Rogerio Melonio
@since 22/06/2015
@version 1.0
@return NIL
/*/
//-------------------------------------------------------------------
//RETIRAR STATIC
Static Function A020SICAF()

FWExecView (STR0072, "GCPA180",  MODEL_OPERATION_INSERT,,{||.T.},,,,,,,)

Return Nil

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³A020CC2SA2ºAutor  ³Rodrigo M Pontes    º Data ³  17/11/15   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Filtro da consulta padrão CC2SA2                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//RETIRAR STATIC
Static Function A020CC2SA2()

Local cFiltro	:= ""

If Type("M->A2_EST") <> "U"
	cFiltro := "CC2->CC2_EST==M->A2_EST"
Else
	cFiltro := "!Empty(CC2->CC2_EST)"
Endif

Return cFiltro

/*/{Protheus.doc} A020VldUCod
//Realiza a validação referente a mensagem única CustomerVendorReserveID
@author caio.y
@since 08/06/2017
@version undefined

@type function
/*/
//RETIRAR STATIC
Static Function A020VldUCod()
Local lRet			:= .T.
Local aAreaSA1	:= SA1->(GetArea())
Local aAreaSA2	:= SA2->(GetArea())
Local lIntUnqCod	:= FwHasEAI("MATA020B")

//-- Valida unificação de códigos
If lIntUnqCod .And. INCLUI

    If !Empty(M->A2_CGC)
        SA2->(dbSetOrder(3))
        If SA2->(MsSeek(xFilial("SA2") + M->A2_CGC ))
            Help( " " , 1 , "EXISTCLI" ,,, 2 , 0 )
            lRet    := .F.
        EndIf
    EndIf

    If lRet

        If M->A2_TIPO == "J" //-- Juridico
            If !Empty(M->A2_CGC) .And. !Empty(M->A2_INSCR)
                SA1->(dbSetOrder(3))
                If SA1->(MsSeek(xFilial("SA1") + M->A2_CGC ))
                    If RTrim(M->A2_INSCR) == RTrim(SA1->A1_INSCR)
                        M->A2_COD    := SA1->A1_COD
                    Else
                        lRet    := MATA020B(.F.,M->A2_COD,"MATA020" )
                    EndIf
                Else
                    lRet    := MATA020B(.F.,M->A2_COD,"MATA020" )
                EndIf
            EndIf
        ElseIf M->A2_TIPO == "F" .Or. M->A2_TIPO == "X" //-- Fisico ou Estrangeiro
            If !Empty(M->A2_CGC)
                SA1->(dbSetOrder(3))
                If SA1->(MsSeek(xFilial("SA1") + M->A2_CGC ))
                    If RTrim(M->A2_INSCR) == RTrim(SA1->A1_INSCR)
                        M->A2_COD    := SA1->A1_COD
                    Else
                        lRet    := MATA020B(.F.,M->A2_COD,"MATA020"  )
                    EndIf
                Else
                    lRet    := MATA020B(.F.,M->A2_COD,"MATA020"  )
                EndIf
            EndIf
        EndIf

    EndIf
EndIf

RestArea(aAreaSA2)
RestArea(aAreaSA1)
Return lRet

/*/{Protheus.doc} A020cancel
Bloco de cancelamento do Modelo. Está sendo chamado pelo bloco, pois, neste momento não existe um evento específico para o cancelamento

@type function

@author José Eulálio
@since 28/08/2017
@version P12.1.17

/*/
Static Function A020cancel(oModel)
Local lIntUnqCod	:= FwHasEAI("MATA020B")

//-- EXCLUSÃO DA RESERVEID
If lIntUnqCod
	lIncluiBkp	:= INCLUI
	lAlteraBkp	:= ALTERA

	INCLUI	:= .F.
	ALTERA	:= .F.

	MATA020B(.T.,,"MATA020",.F.,.T.,.T.)

	INCLUI	:= lIncluiBkp
	ALTERA	:= lAlteraBkp
EndIf

If Type("INCLUI") == "L" .AND. INCLUI
	If Type("aFornNovo") <> "U"
		If aFornNovo[2] == aFornNovo[1] .And. __lSx8
			RollBackSx8()
		EndIf
	EndIf
EndIf

Return .T.

/*/{Protheus.doc} Mata020doc
Chamada para o banco de conhecimento

@type function

@author José Eulálio
@since 29/08/2017
@version P12.1.17

/*/
Function Mata020doc()

//VARIAVEIS ADICIONADAS DEVIDO A UTILIZAÇÃO NA FUNÇÃO MSDOCUMENT.
Private aRotina	:= MenuDef()
Private cCadastro	:= OemtoAnsi(STR0008) //"Atualização de Produtos"

MsDocument('SA2',SA2->(Recno()),4)

Return

//Funções de compatiblidade
//Excluir as funções abaixo quando for descontinuado o MATA020 e o MATA020M virar padrão
//Retirar o "Static" das funções que conterem o comentário //RETIRAR STATIC
//-----------------------------------
Function MA020WebbIc(aFields)
Return	A020WebbIc(aFields)
//-----------------------------------
Function MA020SXB()
Return A020SXB()
//-----------------------------------

/*/{Protheus.doc} ValidA2COD
Atualiza controle de alteração do código do fornecedor para controle do RollBackSX8

@type function

@author brunno.costa
@since 08/01/2018
@version P12.1.17

/*/
Static Function ValidA2COD(oFields)
Local lReturn := .T.

If Type("aFornNovo") <> "U"
	If Empty(aFornNovo[1])
		aFornNovo[1] := M->A2_COD//Conteúdo anterior
		If Empty(aFornNovo[1])
			aFornNovo[1] := oFields:GetValue("A2_COD")//Conteúdo novo
		EndIf
	EndIf
	aFornNovo[2] := oFields:GetValue("A2_COD")//Conteúdo novo
EndIf

Return lReturn

/*/{Protheus.doc} A020TDOK
Função de validação da tela após clicar em confirmar

@type function

@author brunno.costa
@since 08/01/2018
@version P12.1.17

/*/
Static Function A020TDOK(oFields)
Local lReturn 	:= .T.

IF Type("INCLUI") == "L" .AND. INCLUI//Houve alteração manual do código do fornecedor
	If Type("aFornNovo") <> "U"
		If aFornNovo[1]!=aFornNovo[2] .AND. __lSx8
			RollBackSx8()
		EndIf
		If lReturn//Limpa aFornNovo para nova inclusão
			aFornNovo := {"",""}
		EndIf
	EndIf
EndIf
Return lReturn

/*/{Protheus.doc} A020MVldBc
Funcao de validacao do botao Ok da interface de bancos

@type Static Function
@author Totvs
@since 20/02/2018
@version P12.1.17
/*/
Static Function A020MVldBc(oView)

Local oModel  := oView:GetModel()
Local oGrid   := oModel:GetModel("BANCOS")
Local nOpc    := oModel:GetOperation()
Local nX      := 0
Local nPrinc  := 0
Local nLine   := 0
Local lRet    := .T.

If nOpc == MODEL_OPERATION_INSERT .Or. nOpc == MODEL_OPERATION_UPDATE
	//-----------------------------------------------------------------------------
	// Verifica se existe uma e somente uma conta principal
	//-----------------------------------------------------------------------------
	If !oGrid:IsEmpty() .And. oGrid:Length(.T.) > 0 //Verifica se tem alguma linha nao deletada
		For nX := 1 To oGrid:Length()
			If !oGrid:IsDeleted(nX)
				If oGrid:GetValue("FIL_TIPO",nX) == "1"
					nPrinc++
					nLine := nX
				EndIf
			EndIf
		Next nX

		If nPrinc > 1
			lRet := .F.
			Help( ,, 'BANCOS',, STR0040+CRLF+STR0043, 1, 0)
		ElseIf nPrinc == 0
			lRet := .F.
			Help( ,, 'BANCOS',, STR0041+CRLF+STR0042, 1, 0)
		ElseIf nPrinc == 1 .And. nLine > 0
			If Empty(oGrid:GetValue("FIL_BANCO",nLine)) .Or. Empty(oGrid:GetValue("FIL_AGENCI",nLine)) .Or. Empty(oGrid:GetValue("FIL_CONTA ",nLine))
				lRet := .F.
			Help( ,, 'BANCOS',, STR0083, 1, 0)
			EndIf
		EndIf
	EndIf
EndIf

Return lRet

/*/{Protheus.doc} A020MSetBc
Caso o fornecedor possua bancos relacionados, seta os dados da conta principal
no model do fornecedor

@type Static Function
@author Totvs
@since 20/02/2018
@version P12.1.17
/*/
Static Function A020MSetBc(oView)

Local oModel  := oView:GetModel()
Local oGrid   := oModel:GetModel("BANCOS")
Local oField  := oModel:GetModel("SA2MASTER")
Local nOpc    := oModel:GetOperation()
Local nX      := 0

If nOpc == MODEL_OPERATION_INSERT .Or. nOpc == MODEL_OPERATION_UPDATE
	If !oGrid:IsEmpty()
		For nX:=1 to oGrid:Length()
			If !oGrid:IsDeleted(nX) .And. oGrid:GetValue("FIL_TIPO",nX) == "1" .And. !Empty(oGrid:GetValue("FIL_BANCO",nX)) .And. !Empty(oGrid:GetValue("FIL_AGENCI",nX)) .And. !Empty(oGrid:GetValue("FIL_CONTA ",nX))
				If oGrid:HasField("FIL_BANCO") .and. (cPaisLoc <> "RUS" .Or. Iif(empty(GetSx3Cache("A2_BANCO", "X3_WHEN")),.T.,&(GetSx3Cache("A2_BANCO", "X3_WHEN") )))
					oField:SetValue("A2_BANCO", oGrid:GetValue("FIL_BANCO",nX))
				EndIf
				If oGrid:HasField("FIL_AGENCI") .and. (cPaisLoc <> "RUS" .Or. Iif(empty(GetSx3Cache("A2_AGENCIA", "X3_WHEN")),.T.,&(GetSx3Cache("A2_AGENCIA", "X3_WHEN") )))
					oField:SetValue("A2_AGENCIA", oGrid:GetValue("FIL_AGENCI",nX))
				EndIf
				If oGrid:HasField("FIL_DVAGE") .and. (cPaisLoc <> "RUS" .Or. Iif(empty(GetSx3Cache("A2_DVAGE", "X3_WHEN")),.T.,&(GetSx3Cache("A2_DVAGE", "X3_WHEN") )))
					oField:SetValue("A2_DVAGE", oGrid:GetValue("FIL_DVAGE",nX))
				EndIf
				If oGrid:HasField("FIL_CONTA") .and. (cPaisLoc <> "RUS" .Or. Iif(empty(GetSx3Cache("A2_NUMCON", "X3_WHEN")),.T.,&(GetSx3Cache("A2_NUMCON", "X3_WHEN") )))
					oField:SetValue("A2_NUMCON", oGrid:GetValue("FIL_CONTA",nX))
				EndIf
				If oGrid:HasField("FIL_DVCTA") .and. (cPaisLoc <> "RUS" .Or. Iif(empty(GetSx3Cache("A2_DVCTA", "X3_WHEN")),.T.,&(GetSx3Cache("A2_DVCTA", "X3_WHEN") )))
					oField:SetValue("A2_DVCTA", oGrid:GetValue("FIL_DVCTA",nX))
				EndIf
				If oGrid:HasField("FIL_TIPCTA") .and. (cPaisLoc <> "RUS" .Or. Iif(empty(GetSx3Cache("A2_TIPCTA", "X3_WHEN")),.T.,&(GetSx3Cache("A2_TIPCTA", "X3_WHEN") )))
					oField:SetValue("A2_TIPCTA", oGrid:GetValue("FIL_TIPCTA",nX))
				EndIf
				Exit
			EndIf
		Next nX
	EndIf
EndIf

Return

/*/{Protheus.doc} A020AutoM
Função que realiza a rotina automatica para o MATA020 em MVC.

@type Function
@author Totvs
@since 26/03/2018
@version P12.1.17
/*/
Function A020AutoM(aRotAuto, nOpcAuto)
Return A020Auto(aRotAuto, nOpcAuto)

/*/{Protheus.doc} F12InitM
Função que realiza a chamada do atalho F12 da rotina.

@type Function
@author Totvs
@since 26/03/2018
@version P12.1.17
/*/
Function F12InitM()
Return F12Init()

/*/{Protheus.doc} A020TDOKM
Função de validação da tela após clicar em confirmar

@type Function
@author Totvs
@since 26/03/2018
@version P12.1.17
/*/
Function A020TDOKM(oFields)
Return A020TDOK(oFields)

/*/{Protheus.doc} A020cancM
Bloco de cancelamento do Modelo. Está sendo chamado pelo bloco, pois, neste momento não existe um evento específico para o cancelamento

@type Function
@author Totvs
@since 26/03/2018
@version P12.1.17
/*/
Function A020cancM(oModel)
Return A020cancel(oModel)

/*/{Protheus.doc} ValidA2CDM
Atualiza controle de alteração do código do fornecedor para controle do RollBackSX8

@type Function
@author Totvs
@since 26/03/2018
@version P12.1.17
/*/
Function ValidA2CDM(oFields)
Return ValidA2COD(oFields)

/*/{Protheus.doc} A020DeactM
Executado no deactivate do modelo de dados.

@type Function
@author Totvs
@since 26/03/2018
@version P12.1.17
/*/
Function A020DeactM(oFields)
Return A020Deactivate(oFields)
