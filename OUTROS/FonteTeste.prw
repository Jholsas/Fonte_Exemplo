#INCLUDE "FINA040.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "ACADEF.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "FWADAPTEREAI.CH"

Static lOpenCmc7
Static aPrefixo
Static lAltDtVc

Static nSomaGrupo := 0
Static cArqTmp		:= "" //arquivo temporario utilizado para IR. Necessario para tirar da transação quando utilizada NFE (mata103) ;
								// e não dar erro ao excluir as tabelas quando utilizado banco postgres

Static lPmsInt	:=	IsIntegTop(,.T.)
Static __lF040CMNT	:= ExistFunc("F040CMNT")
Static __lFAPodeTVA	:= ExistFunc("FAPodeTVA")
Static __lFINA040VA := ExistFunc("FINA040VA")
Static __lExisFKD := .F.

/*/
ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
³Variavel para inibir a chamada da função GeraDDINCC		  ³
³Nao gerar DDI e NCC										  ³
ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/
Static _lNoDDINCC := ExistBlock( "F040NDINC" )
Static lTravaSA1:= ExistBlock("F040TRVSA1")
Static dLastPcc  := CTOD("22/06/2015")
Static lFinImp  := FindFunction("FRaRtImp")       //Define se ha retencao de impostos PCC/IRPJ no R.A
Static lF040DELC := ExistBlock("F040DELC")
Static lReCalcmoed := .F.
Static aVAAuto		:= NIL

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³ FINA040	³ Autor ³ Wagner Xavier 	    ³ Data ³ 16/04/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de manuten‡„o no cadastro de Contas a Receber	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³PROGRAMADOR³ DATA   ³   ISSUE     ³  MOTIVO DA ALTERACAO               ³±±
±±³Jose Glez  ³23/10/17³TSSERMI01-182|Localizacion de  SA1->A1_RECIRRF    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FinA040( aRotAuto, nOpcAuto, aTitPrv, aRatSevSez, aParam, aFKF, aFKG, aVAAut )

Local nPos
Local bBlock
Local cParcela 	:= Chr(Asc(GetMV("MV_1DUP"))-1)
Local nTamPArc 	:= TAMSX3("E1_PARCELA")[1]
Local nX 		:= 0
Local lFKG 		:= aFKG <> Nil
Local lFKF 		:= aFKF <> Nil
Local aFKFLoc	:= {}
Local aFKGLoc	:= {}
Local lRet		:= .T.

__lExisFKD := TableInDic('FKD') .And. TableInDic('FKC')

SaveInter() // Salva variaveis publicas

//------------------------------------------------------------------
// Restringe o uso do programa ao Financeiro, Sigaloja e Especiais
//------------------------------------------------------------------
If !(AmIIn(5,6,11,12,14,41,97,17,44,5,49,59,72,77)) // S¢ Fat,Fin , Veiculos, Loja, Pecas, Oficina e Esp, EIC, PMS, 49-GE, 59-GAC ,PHOTO, SIGAPFS
	Return
Endif

//------------------------------------------------------------------
// Campos especificos e documentados para uso na MSMM
// disponivel no Quark e utilizados em clientes
//------------------------------------------------------------------
If SE1->(FieldPos("E1_CODOBS")) > 0
	Private aMemos := { {"E1_CODOBS", "E1_OBS" } }
Endif

Private nMaxParc	:= 0
Private lOracle		:= "ORACLE"$Upper(TCGetDB())
Private	cTitPai		:= ""

If nTamParc == 1  // TAMANHO DA PARCELA

	For nX := 1 To 63
		cParcela := Soma1( cParcela, , .F., .T. )
		If cParcela == "000000" .Or. cParcela == "*"
			Exit
		EndIf
		nMaxParc++
	Next nX

ElseIf nTamParc == 2

	nMaxParc := 99

ElseIf nTamParc == 3

	nMaxParc := 999

ElseIf nTamParc == 4

	nMaxParc := 9999

EndIf

//------------------------------------------------------------------
// Define Array contendo as Rotinas a executar do programa
// ----------- Elementos contidos por dimensao ------------
// 1. Nome a aparecer no cabecalho
// 2. Nome da Rotina associada
// 3. Usado pela rotina
// 4. Tipo de Transa‡„o a ser efetuada
//	 1 - Pesquisa e Posiciona em um Banco de Dados
//	 2 - Simplesmente Mostra os Campos
//	 3 - Inclui registros no Bancos de Dados
//	 4 - Altera o registro corrente
//	 5 - Exclui um registro cadastrado
//------------------------------------------------------------------
Private aRotina := MenuDef()

If GetNewPar("MV_ACATIVO",.F.)
	If aPrefixo == NIL
		aPrefixo := ACPrefixo()
	EndIF
Endif

Private lUsaGac		:= Upper(AllTrim(FunName())) == "ACAA690"
Private lF040Auto	:= ( aRotAuto <> NIL )
Private aRatEvEz	:= Nil

Public N // para o mvc

If lF040Auto
	If (aRatSevSez <> Nil )
		aRatEvEz:=aClone(aRatSevSez)
	Endif
	If lFKF
		aFKFLoc:=aClone(aFKF)
	Endif
	If lFKG
		aFKGLoc:=aClone(aFKG)
	Endif
	//Valores Acessórios - Rotina Automatica CR
	If (aVAAut <> Nil )
		aVAAuto := aClone(aVAAut)
	Endif
Endif


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Definicao das teclas de parametros e chamada da funcao pergunte  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

If !lF040Auto
	SetKey (VK_F12,{|a,b| AcessaPerg("FIN040",.T.)})
Endif
pergunte("FIN040",.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Define o cabecalho da tela de atualizacoes						  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE cCadastro := STR0007  // "Contas a Receber"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica o numero do Lote 											  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PRIVATE cLote,lAltera:=.f.
PRIVATE cBancoAdt		:= CriaVar("A6_COD")
PRIVATE cAgenciaAdt		:= CriaVar("A6_AGENCIA")
PRIVATE cNumCon			:= CriaVar("A6_NUMCON")
PRIVATE nMoedAdt		:= CriaVar( "A6_MOEDA" )
PRIVATE nMoeda  		:= Int(Val(GetMv("MV_MCUSTO")))
PRIVATE cMarca  		:= GetMark()
PRIVATE lHerdou		:= .F.
PRIVATE aTELA[0][0],aGETS[0]
PRIVATE lIntegracao := IF(GetMV("MV_EASY")=="S",.T.,.F.)
PRIVATE nIndexSE1 := ""
PRIVATE aDadosRet := Array(6)
PRIVATE cIndexSE1 := ""
PRIVATE nVlRetPis	:= 0
PRIVATE nVlRetCof := 0
PRIVATE nVlRetCsl	:= 0
PRIVATE nVlRetIRF := 0
PRIVATE nVlOriCof := 0
PRIVATE nVlOriCsl	:= 0
PRIVATE nVlOriPis := 0
PRIVATE aAutoCab := aRotAuto
Private aParamAuto	:= {}

//Substituicao Automatica
PRIVATE aItnTitPrv   := Iif(aTitPrv   <> Nil, aTitPrv  , {})

AFill( aDadosRet, 0 )

//Selecionar ordem 1 para Cadastro de Clientes
SA1->(dbSetOrder(1))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recupera o numero do lote contabil.								  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
LoteCont( "FIN" )

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada para pre-validar os dados a serem  ³
//³ exibidos.                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("F040BROW")
	ExecBlock("F040BROW",.f.,.f.)
Endif

aParamAuto := If(aParam <> Nil,aParam,Nil)
FI040PerAut()

If lF040Auto
	DEFAULT nOPCAUTO := 3
	//Banco Agencia e Conta para inclusão do RA
	aValidGet := {}
	IF (nT := ascan(aRotAuto,{|x| x[1]='E1_TIPO'}) ) > 0
		IF aRotAuto[nT,2] $ MVRECANT   // Se for RA
			IF (nT := ascan(aRotAuto,{|x| x[1]='CBCOAUTO'})) > 0
				Aadd(aValidGet,{'cBancoAdt' ,PAD(aRotAuto[nT,2],TamSx3("E5_BANCO")[1]),"CarregaSa6(@cBancoAdt,,,.T.)",.t.})
			Endif
			IF (nT := ascan(aRotAuto,{|x| x[1]='CAGEAUTO'}) ) > 0
				Aadd(aValidGet,{'cAgenciaAdt' ,PAD(aRotAuto[nT,2],TamSx3("E5_AGENCIA")[1]),"CarregaSa6(@cBancoAdt,@cAgenciaAdt,,.T.)",.t.})
			EndIf
		  	IF (nT := ascan(aRotAuto,{|x| x[1]='CCTAAUTO'}) ) > 0
				Aadd(aValidGet,{'cNumCon' ,PAD(aRotAuto[nT,2],TamSx3("E5_CONTA")[1]),"CarregaSa6(@cBancoAdt,@cAgenciaAdt,@cNumCon,.F.,,.T.)",.t.})
			EndIf

			If FXMultSld()
			  	If ( nT := aScan( aRotAuto, { |x| x[1] = 'MOEDAUTO' } ) ) > 0
					aAdd( aValidGet, { 'nMoedAdt', Pad( aRotAuto[nT,2], TamSx3("A6_MOEDA")[1]),"CarregaSa6(@cBancoAdt,@cAgenciaAdt,@cNumCon,.F.,,.T.,, @nMoedAdt )",.t.})
				EndIf
			EndIf
			RegToMemory("SE1",.T.,.F.)

		 	If ! SE1->(MsVldGAuto(aValidGet)) // consiste os gets
			  	lRet:= .F.
		   EndIf
		Else
			If cPaisLoc=="BRA" .and. (lFKF .or. lFKG) .and. lRet
				lRet:= F986ExAut("SE1", aFKFLoc, aFKGLoc, nOpcAuto)
			Endif
		Endif
	Endif
	IF ExistBlock("F040RAUTO")
		aAutoCab := ExecBlock("F040RAUTO",.F.,.F.,{aAutoCab})
	Endif
	If lRet
		MBrowseAuto(nOpcAuto,aAutoCab,"SE1")
	Endif
Else
	If nOpcAuto<>Nil
		Do Case
			Case nOpcAuto == 3
				INCLUI := .T.
				ALTERA := .F.
			Case nOpcAuto == 4
				INCLUI := .F.
				ALTERA := .T.
			OtherWise
				INCLUI := .F.
				ALTERA := .F.
		EndCase

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Chamada direta da funcao de Inclusao/Alteracao/Visualizacao/Exclusao³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nPos := nOpcAuto
		If ( nPos # 0 )
			bBlock := &( "{ |x,y,z,k| " + aRotina[ nPos,2 ] + "(x,y,z,k) }" )
			dbSelectArea("SE1")
			Eval( bBlock,Alias(),SE1->(Recno()),nPos)
		EndIf
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Endereca a funcao de BROWSE											  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		mBrowse( 6, 1,22,75,"SE1",,,,,, Fa040Legenda("SE1"),,,,,,,,IIf(ExistBlock("F040FILB"),ExecBlock("F040FILB",.F.,.F.),Nil))
                If GetMv("MV_CMC7FIN") == "S"
                        CMC7Fec(nHdlCMC7,GetMv("MV_CMC7PRT"))
                EndIf
		lOpenCmc7 := Nil
	EndIf
EndIf

//Valores Acessórios
If (aVAAut <> Nil )
	aSize(aVAAut,0)
	aVAAut := Nil
Endif

If (aVAAuto <> Nil )
	aSize(aVAAuto,0)
	aVAAuto := Nil
Endif

//-------------------------------------------------------------------------
// Recupera a Integridade dos dados
//-------------------------------------------------------------------------
Set Key VK_F12 To
RestInter() // Restaura variaveis publicas
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Inclu³ Autor ³ Wagner Xavier         ³ Data ³ 16/04/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa para inclusao de contas a receber				  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Inclu(ExpC1,ExpN1,ExpN2) 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo									  ³±±
±±³			 ³ ExpN1 = Numero do registro 								  ³±±
±±³			 ³ ExpN2 = Numero da opcao selecionada 						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Inclu(cAlias,nReg,nOpc,cRec1,cRec2,lSubst)
Local nOpca
Local aBut040		:= {}
Local cTudoOk 		:= ""
Local lRet 			:= .T.
Local cTipos 		:= MVPROVIS + "/" + MVABATIM
Local nIndexAtu		:= SE1->(IndexOrd())
Local oEnchoice
Local aDim 			:= {}
Local cNumTitOld	:= Alltrim(SE1->E1_NUM)
Local lF040DTMOV	:= ExistBlock("F040DTMV",.F.,.F.)
Local lDtMovFin		:= .F.
Local lFA040INC		:= ExistBlock("FA040INC")
Local lRatPrj:= .T. //indica se existira rateio de projeto
Local nN := 1
Local lRMInteg		:= IIf(FindFunction("FWHasEai"),FWHasEai("FINI150A",.T.,,.T.),.F.)
Local nI
Local aRetInteg := {}

Local lIntPFS       := SuperGetMV("MV_JURXFIN",,.F.) // Integração SIGAPFS x SIGAFIN

DEFAULT lSubst		:=.F.

PRIVATE aRatAFT	:= {}
PRIVATE bPMSDlgRC
Private nVCalIRF := 0
Private nVRetIRF := 0
Private nBCalIRF := 0
Private nVCalCSL := 0
Private nBCalCSL := 0
Private nVCalPIS := 0
Private nBCalPIS := 0
Private nVCalCOF := 0
Private nBCalCOF := 0
//Reestruturação SE5.
Private nRCalCSL := 0
Private nRCalCOF := 0
Private nRCalPIS := 0
Private nRCalIRF := 0
//
lF040Auto	:= Iif(Type("lF040Auto") != "L", .F., lF040Auto )

If !lF040Auto
	PRIVATE aCols
	PRIVATE aHeader
EndIf

PRIVATE cHistDsd	:= CRIAVAR("E1_HIST",.F.)  // Historico p/ Desdobramento
PRIVATE aParcelas	:= {}  // Array para desdobramento
PRIVATE aParcacre := {},aParcDecre := {}  // Array de Acresc/Decresc do Desdobramento
PRIVATE nIndexSE1 := ""
PRIVATE cIndexSE1 := ""
Private lDescPCC  := .F.

// Variavel de controle da retenção de IRRF de acordo com a Natureza(SED->ED_RECIRF).
PRIVATE nRecIRRF := 0

If SE1->E1_EMISSAO >= dLastPcc
	nValMinRet	:= 0
EndIf

If lFA040INC
	cTudoOk := 'IIF( M->E1_TIPO$MVRECANT , DtMovFin(M->E1_EMISSAO,,"2") .And. PcoVldLan("000001",IIF(M->E1_TIPO$MVRECANT,"02","01"),"FINA040") .And. FA040VLMV() .And. ExecBlock("FA040INC",.f.,.f.), PcoVldLan("000001",IIF(M->E1_TIPO$MVRECANT,"02","01"),"FINA040") .And. ExecBlock("FA040INC",.f.,.f.)'
Else
	cTudoOk := 'IIF( M->E1_TIPO$MVRECANT , DtMovFin(M->E1_EMISSAO,,"2") .And. PcoVldLan("000001",IIF(M->E1_TIPO$MVRECANT,"02","01"),"FINA040") .And. FA040VLMV(), PcoVldLan("000001",IIF(M->E1_TIPO$MVRECANT,"02","01"),"FINA040")'
EndIf

If lSubst
		bPMSDlgRC	:={||PmsDlgRS(4,M->E1_PREFIXO,M->E1_NUM,M->E1_PARCELA,M->E1_TIPO,M->E1_CLIENTE,M->E1_LOJA,M->E1_ORIGEM)}
Else
	bPMSDlgRC	:={||PmsDlgRC(3,M->E1_PREFIXO,M->E1_NUM,M->E1_PARCELA,M->E1_TIPO,M->E1_CLIENTE,M->E1_LOJA,M->E1_ORIGEM)}
EndIf

If !Type("lF040Auto") == "L" .or. !lF040Auto
	nVlRetPis	:= 0
	nVlRetCof	:= 0
	nVlRetCsl	:= 0
	nVlRetIRF	:= 0
	aDadosRet	:= Array(6)
	Afill(aDadosRet,0)
	nVlOriPis	:= 0
	nVlOriCof	:= 0
	nVlOriCsl	:= 0
Endif

//Ponto de entrada FA040BLQ
//Ponto de entrada utilizado para permitir ou nao o uso da rotina
//por um determinado usuario em determinada situacao
IF ExistBlock("F040BLQ")
	lRet := ExecBlock("F040BLQ",.F.,.F.)
	If !lRet
		Return .T.
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento n„o ‚ menor que data limite de ³
//³ movimentacao no financeiro    								 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lF040DTMOV
	lDtMovFin := ExecBlock( "F040DTMV", .F., .F. )
Else
	lDtMovFin := DtMovFin(,,"2")
Endif

If !lDtMovFin
   Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza integracao com o SIGAPMS                                        	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("AFT")
dbSetOrder(1)

//Botoes adicionais na EnchoiceBar

aBut040 := fa040BAR("IntePms()",bPmsDlgRC)

// integração com o PMS

If IntePms() .And. (!Type("lF040Auto") == "L" .Or. !lF040Auto)
	SetKey(VK_F10, {|| Eval(bPmsDlgRC)})
EndIf

If cPaisLoc=="BRA"  // Esta rotina esta somente para o Brasil pois Localizacoes utiliza o Recibo para incluir os cheque ( Fina087A)
   Aadd(aBut040,{'LIQCHECK',{||IIF(!Empty(M->E1_TIPO) .and. !M->E1_TIPO $ cTipos,CadCheqCR(,,,M->E1_VALOR),Help("",1,"NOCADCHREC"))},STR0051,STR0068}) //"Cadastrar cheques recebidos" //"Cheques"
EndIf

cTudoOk += ' .And. iif(m->e1_tipo $ MVABATIM .and. !Empty(m->e1_num), F040VlAbt(), .T.) '

cTudoOk += ' .And. F040VldVlr() '

// se for adiantamento, valida se o cliente e loja escolhido estao conforme pedido/documento
If !lF040Auto
	If Type("aRecnoAdt") != "U" .and. (FunName() = "MATA410" .or. FunName() = "MATA460A" .or. FunName() = "MATA460B")
		cTudoOk += ' .And. F040VlAdClLj()'
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Agroindustria  									                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If OGXUtlOrig()
   cTudoOK += ' .AND. OGX130()'
EndIf

cTudoOk += " )"
cTudoOk += ' .And. F040VlCpos()'

BEGIN TRANSACTION

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicializa a gravacao dos lancamentos do SIGAPCO          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PcoIniLan("000001")

lAltera:=.F.
dbSelectArea( cAlias )
cCadastro := STR0007  // "Contas a Receber"
If ( lF040Auto )
	RegToMemory("SE1",.T.,.F.)
	If EnchAuto(cAlias,aAutoCab,cTudoOk,nOpc)
			If len(aAutoCab) > 0
				For nN = 1 to len(aAutoCab)
					If aAutoCab[nN,1] <> NIl .And. aAutoCab[nN,2] <> NIl // vldção para não gerar error log na macro-exec
						If !Empty(aAutoCab[nN,2]) .And. IIF(AllTrim(SUBSTR(aAutoCab[nN,1],1,3)) == "E1_", Empty(M->&(aAutoCab[nN,1])), .F.)
							M->&(aAutoCab[nN,1]) := aAutoCab[nN,2]
						EndIf
					EndIf
				Next nN
			//FA040Natur()
			FA040Natur(,, .T.)
			EndIf

		If lF040Auto
				For nI:= 1 to Len(aItnTitPrv)
						If	(nPosPre := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_PREFIXO"} )) == 0 .Or.;
							(nPosNum := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_NUM"    } )) == 0 .Or.;
							(nPosPar := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_PARCELA"} )) == 0 .Or.;
							(nPosTip := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_TIPO"   } )) == 0 .Or.;
							(nPosFor := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_CLIENTE"} )) == 0 .Or.;
							(nPosLoj := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_LOJA"   } )) == 0

							Loop

						EndIf

						SE1->(DbSetOrder(2))
						If SE1->(MsSeek(xFilial("SE1") + aItnTitPrv[nI,nPosFor,2] + aItnTitPrv[nI,nPosLoj,2] + PadR(aItnTitPrv[nI,nPosPre,2],TamSX3("E1_PREFIXO")[1])  + ;
						 	aItnTitPrv[nI,nPosNum,2] + PadR(aItnTitPrv[nI,nPosPar,2],TamSX3("E1_PARCELA")[1])  + aItnTitPrv[nI,nPostip,2] ))
						Endif

						If M->E1_EMISSAO < SE1->E1_EMISSAO
        					Help( " ", 1, "DATAERR" )
							lRet := .F.
						EndIf
				Next nI
		EndIf
		If lRet
			nOpca := AxIncluiAuto(cAlias,cTudoOk,"FA040AXINC('"+cAlias+"')")
		EndIf
	EndIf
Else
	// Se estiver utilizando CMC7, abre a porta para cadastro do cheque recebido.
	If lOpenCmc7 == Nil .And. GetMv("MV_CMC7FIN") == "S"
		OpenCMC7()
		lOpenCmc7 := .T.
	Endif
	If IsPanelFin()  //Chamado pelo Gestor Financeiro - PFIN
		dbSelectArea("SE1")
		RegToMemory("SE1",.T.,,,FunName())
		oPanelDados := FinWindow:GetVisPanel()
		oPanelDados:FreeChildren()
		aDim := DLGinPANEL(oPanelDados)

		/*Projeto Grupo ABC
		If ( mv_par03 == 1 )
			CtbTranUniq()
		Endif*/

		nOpca := AxInclui(cAlias,nReg,nOpc,, "FA040INIS",,cTudoOk,,"FA040AXINC('"+cAlias+"')",aBut040,/*aParam*/,/*aAuto*/,/*lVirtual*/,/*lMaximized*/,/*cTela*/,	.T.,oPanelDados,aDim,FinWindow)
        //Controle de Cartão de Credito para o Equador...
		If nOpca == 1 .and. cPaisLoc == "EQU" .and. SE1->E1_TIPO == "CC " .and. ProcName(1) <> "FA040TIT2CC"
           //Executar dialogo para obter os dados do Cartão de Crédito e gravar arquivo de controle FRB
           aTituloCC := Fa040GetCC(.T.)
           If Len(aTituloCC) > 0
           	  Fa040GrvFRB(aTituloCC)
		   EndIf
        EndIf
	Else
		/*Projeto Grupo ABC
		If ( mv_par03 == 1 )
			CtbTranUniq()
		Endif*/
		nOpca := AxInclui(cAlias,nReg,nOpc,, "FA040INIS",,cTudoOk,,"FA040AXINC('"+cAlias+"')",aBut040)

        //Controle de Cartão de Credito para o Equador...
		If nOpca == 1 .and. cPaisLoc == "EQU" .and. SE1->E1_TIPO == "CC " .and. ProcName(1) <> "FA040TIT2CC"
           //Executar dialogo para obter os dados do Cartão de Crédito e gravar arquivo de controle FRB
           aTituloCC := Fa040GetCC(.T.)
           If Len(aTituloCC) > 0
           	  Fa040GrvFRB(aTituloCC)
		   EndIf
        EndIf
	Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	//³Integracao protheus X tin	³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	If nOpca == 1 .and. FWHasEAI("FINA040",.T.,,.T.)
		lRatPrj := PmsRatPrj("SE1",,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO)
		If !( AllTrim(SE1->E1_TIPO) $ MVRECANT .and. lRatPrj  .and. !(cPaisLoc $ "BRA|")) //nao integra PA e RA para Totvs Obras e Projetos Localizado
			If !FwIsInCallStack('FINA460') .And. !FwIsInCallStack('FINA280') .And. !GetNewPar("MV_RMCLASS", .F.) //Não executo o adapter caso a integração com o RM Classis esteja ativa
				aRetInteg := FwIntegDef( 'FINA040', , , , 'FINA040' )
				//Se der erro no envio da integração, então faz rollback e apresenta mensagem em tela para o usuário
				If ValType(aRetInteg) == "A" .AND. Len(aRetInteg) >= 2 .AND. !aRetInteg[1]
					If ! IsBlind()
						Help( ,, "FINA040INTEG",, STR0201 + AllTrim( aRetInteg[2] ), 1, 0,,,,,, {STR0202} ) //"O registro não será gravado, pois ocorreu um erro na integração: ", "Verifique se a integração está configurada corretamente."
					Endif
					DisarmTransaction()
					Return .F.
				Endif
			EndIf
		Endif
	Endif

	//Integração Protheus x RM Classis via mensagem única
	//Disparo essa mensagem para obter o "Nosso Número", gerado pelo RM Classis
	If nOpca == 1 .And. FindFunction( "GETROTINTEG" ) .And. FindFunction("FwHasEAI") .And. FWHasEAI("FINI150A",.T.,,.T.) .And. lRMInteg .And.;
		!Empty(SE1->E1_PORTADO) .And. !Empty(SE1->E1_CONTRAT) .And. !Empty(SE1->E1_CONTA) .And. !Empty(SE1->E1_AGEDEP) .And. !Empty(SE1->E1_NUMBCO)
		SetRotInteg('FINI150A')
		FINI150A()
		SetRotInteg('FINA040')
	Endif
EndIf

END TRANSACTION

If lRet

	// grava array para uso na rotina de adiantamento do pedido de venda
	If nOpcA = 1 .and. Type("aRecnoAdt") != "U" .and. (FunName() = "MATA410" .or. FunName() = "MATA460A" .or. FunName() = "MATA460B")
		aAdd(aRecnoAdt,{SE1->(RECNO()),SE1->E1_VALOR})
	Endif

	If cPaisLoc=="BRA"
		F986LimpaVar()
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a gravacao dos lancamentos do SIGAPCO            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PcoFinLan("000001")

	SE1->(dbSetOrder(nIndexAtu))

	If IntePms() .And. (!Type("lF040Auto") == "L" .Or. !lF040Auto)
		SetKey(VK_F10, Nil)
	EndIf

	// Integração com SIGAPFS
	If lIntPFS .And. nOpca == 1 .And. FindFunction("JIncTitCR") // Confirmação da inclusão -> nOpca == 1
		JIncTitCR( SE1->(Recno()), SE1->E1_EMISSAO )
	EndIf

Endif

Return nOpca

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Delet³ Autor ³ Wagner Xavier   	    ³ Data ³ 16/04/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de exclusao contas a receber					  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Delet(ExpC1,ExpN1,ExpN2) 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo									  ³±±
±±³			 ³ ExpN1 = Numero do registro 						 		  ³±±
±±³			 ³ ExpN2 = Numero da opcao selecionada 						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ DATA     ³ BOPS ³Prograd.³ALTERACAO                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³02/06/05  ³080020³Marcos  ³Os campos A1_VACUM e A1_NROCOM nao devem ser³±±
±±³          ³      ³        ³gravados qdo o modulo for o loja e o        ³±±
±±³          ³      ³        ³ cliente = cliente padrao.                  ³±±
±±³          ³      ³        ³                                            ³±±
±±³21/06/06  ³101534³Marcelo ³-Incluida uma validacao no SE1 para checar  ³±±
±±³          ³      ³        ³se o titulo esta em TELECOBRANCA            ³±±
±±³19/03/07  ³121368³Michel M³- Permitido que um titulo seja excluido do  ³±±
±±³          ³      ³        ³SE1 com o titulo no TELECOBRANCA mediante o ³±±
±±³          ³      ³        ³titulo esteja marcado como excecao de       ³±±
±±³          ³      ³        ³cobranca no SK1.                            ³±±
±±³          ³      ³        ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Delet(cAlias,nReg,nOpc)

Local aHelpEng	:= {}
Local aHelpEsp	:= {}
Local aHelpPor	:= {}
Local nOpcA		:= 0
Local nSavRec
Local cPrefixo
Local cParcela
Local nCntDele		:= 0
Local cNatureza
Local lDigita
Local cNum 	   		:= CRIAVAR ("E1_NUM")
Local cCliente
Local cLoja
Local cArquivo
Local nTotal		:= 0
Local nHdlPrv		:= 0
Local cPadrao		:= "505" // "Abandona" "Confirma"
Local aSE5 			:= {}
Local nX 			:= 0
Local lPadrao		:= .F.
Local cTipo
Local nIss
Local nIrrf
Local nInss
Local lTFa040B01	:= ExistTemplate("FA040B01")
Local lFa040B01		:= ExistBlock("FA040B01")
Local lRet 			:= .T.
Local lAtuAcum		:= .T.	// Verifica se deve alterar os campos A1_VACUM e   qdo modulo for o loja
Local oDlg
Local i
Local aTab			:= {}
Local aBut040
Local nRecnoSE1 	:= 0
Local lDesdobr 		:= .F.
Local nProxReg 		:= SE1->(RECNO())
Local lHead 		:= .F.
Local nValSaldo 	:= 0
Local lContrAbt 	:= .T.
Local cParcIRF		:= ""
Local nNextRec
Local lBxConc  		:= GetNewPar("MV_BXCONC","2") == "1"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Acrescentadas para integração com o módulo de Gestão Educacional ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local cOrigem 		:= ""
Local cNumra  		:= ""
Local cCodCur 		:= ""
Local cPerLet 		:= ""
Local cDiscip 		:= ""
Local cNrDoc  		:= ""
Local aDiscip 		:= {}
Local nParcela		:= 0
Local nDiscip 		:= 0
Local lImpComp		:= SuperGetMv("MV_IMPCMP",,"2") == "1"
Local cPrefOri		:= SE1->E1_PREFIXO
Local cNumOri 		:= SE1->E1_NUM
Local cParcOri		:= SE1->E1_PARCELA
Local lSetAuto		:= .F.
Local lSetHelp		:= .F.
Local lPanelFin 	:= (IsPanelFin())
Local lRastro	 	:= FVerRstFin()
Local lExIrrf     	:= .F.
Local lRAExc		:= .F.

Local nValMinRet 	:= GetNewPar("MV_VL10925",5000)
Local aDadRet 		:= {,,,,,,,.F.}
Local nTotGrupo		:= 0
Local nBaseAtual  	:= 0
Local nBaseAntiga 	:= 0
Local nProp			:= 0
Local nValorDDI 	:= 0
Local nValorDif		:= 0
Local cRetCli 		:= "1"
Local cModRet   	:= GetNewPar( "MV_AB10925", "0" )
Local lRecalcImp	:= .F.
Local dVencRea
Local lTemSfq 		:= .F.
Local lExcRetentor 	:= .F.
Local aDiario		:= {}
Local lRetVM		:= .T.
Local cChave		:= ""
Local cPadMon		:= "59A" //Contabilizacao do estorno da varia monetaria
//639.04 Base Impostos diferenciada
Local lBaseImp		:= F040BSIMP(2)
Local nValBase		:= 0
Local lFina460 		:= IsInCallStack("FINA460")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Parametro que permite ao usuario utilizar o desdobramento³
//³da maneira anterior ao implementado com o rastreamento.  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lNRastDSD	:= SuperGetMV("MV_NRASDSD",.T.,.F.)
Local lCalcImp		:= F040BSIMP(3)

//Exclusao chamada a partir do cancelamento de desdobramento
Local lFina250		:= IsInCallStack("FACANDSD")

Local lAchou		:= .F.
Local lEECFAT := SuperGetMv("MV_EECFAT",.F.,.F.)
Local aVlrTotMes	:= {}
//Verifica se a funcionalidade Lista de Presente esta ativa e aplicada
Local lUsaLstPre	:= SuperGetMV("MV_LJLSPRE",,.F.) .And. LjUpd78Ok()
Local lLiquid 		:= FunName() == "FINA460"
Local lEstProv := .F.   //Variavel para estornar título provisório
Local lViaAFT   := .T.
Local lViaInt   :=.F.
Local lF040CANVM := ExistBlock("F040CANVM")
Local lNoDDINCC	:= .T.
//Verifica se retem imposots do RA
Local lRaRtImp  := lFinImp .And.FRaRtImp()
Local lRatPrj	:=.T. //indica se existe rateio de projeto para o título
//Nova estrutura SE5
Local oModel
Local oSubFKA
Local oSubFK5
Local cLog := ""
Local cChaveFK7 := ""
Local cChvSE2	:= ""
Local lExcIR 	:= .T.
Local lPCCBaixa	:=  SuperGetMv("MV_BR10925",.T.,"2") == "1"
Local lCpRet	:= .F.
Local lExistFJU := FJU->(ColumnPos("FJU_RECPAI")) >0 .and. FindFunction("FinGrvEx")
Local lGrvSa1			:= .T.
Local cLstSit0 	:= FN022LSTCB(7)
Local aRetInteg := {}
Local lIrRet	:= .F.
Local cIss 		:= &(SuperGetMv("MV_ISS",,""))
Local cIRF		:= &(SuperGetMv("MV_IRF",,""))

// Integração SIGAPFS x SIGAFIN
Local lIntPFS   := SuperGetMV("MV_JURXFIN",,.F.)
Local cChvTitPFS:= SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

//Validação da Integração RM Classis
Local cProdRM		:= GETNEWPAR('MV_RMORIG', "")

Local lGestao   := FWSizeFilial() > 2	// Indica se usa Gestao Corporativa
Local lSE1Comp  := FWModeAccess("SE1",3)== "C" // Verifica se SE1 é compartilhada

Local lPendCtb := .F.

DEFAULT _lNoDDINCC := ExistBlock( "F040NDINC" )

PRIVATE aRatAFT	:= {}
PRIVATE bPMSDlgRC	:= {||PmsDlgRC(2,M->E1_PREFIXO,M->E1_NUM,M->E1_PARCELA,M->E1_TIPO,M->E1_CLIENTE,M->E1_LOJA)}

Pergunte("FIN040",.F.)
lF040Auto	:= Iif(Type("lF040Auto") != "L", .F., lF040Auto )
//Ponto de entrada FA040BLQ
//Ponto de entrada utilizado para permitir ou nao o uso da rotina
//por um determinado usuario em determinada situacao
IF ExistBlock("F040BLQ")
	lRet := ExecBlock("F040BLQ",.F.,.F.)
	If !lRet
		Return .T.
	Endif
Endif

If lTravaSA1
   	lGrvSa1:= ExecBlock("F040TRVSA1",.F.,.F.)
Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Caso titulos originados pelo SIGALOJA estejam nas carteiras :  ³
//³I = Carteira Caixa Loja                                        ³
//³J = Carteira Caixa Geral                                       ³
//³Nao permitir esta operacao, pois ele precisa ser transferido   ³
//³antes pelas rotinas do SIGALOJA.                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//SITCOB
If Upper(AllTrim(SE1->E1_SITUACA)) $ "I|J" .AND. Upper(AllTrim(SE1->E1_ORIGEM)) $ "LOJA010|FATA701|LOJA701"
	Help(" ",1,"NOUSACLJ")
	Return
Endif

//PCREQ-3782 - Bloqueio por situação de cobrança
If !F023VerBlq("1","0002",SE1->E1_SITUACA,.T.)
	Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verificar se o documento foi ajustado por diferencia ³
//³de cambio.                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc == "BRA"
	FW9->(DbSetOrder(3))
	If FW9->(DbSeek(xFilial("FW9") + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO + SE1->E1_CLIENTE + SE1->E1_LOJA))
		Help(" ",1,"INCSERASA",,STR0194 +CRLF+ STR0195+" "+FW9->FW9_LOTE,1,0)	//"Este título não poderá ser excluído pois está registrado no SERASA."###"Lote Serasa:"
		Return(.F.)
	Endif
Else
	If cPaisLoc $ "ARG|ANG|COL|MEX"
		SIX->(DbSetOrder(1))
		If SIX->(DbSeek('SFR'))
			DbSelectArea('SFR')
			DbSetOrder(1)
			If DbSeek(xFilial()+"1"+SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)
				Help( " ", 1, "FA074010",,Substr(SFR->FR_CHAVDE,Len(SE1->E1_CLIENTE+SE1->E1_LOJA)+1),5)
				Return .F.
			Endif
		Endif
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza integracao com o SIGAPMS / Ordem 1                              	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("AFT")
dbSetOrder(1)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ativa a consulta aos rateios de Projetos            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//Botoes adicionais na EnchoiceBar
aBut040 := fa040BAR('SE1->E1_PROJPMS == "1"',bPmsDlgRC)

//inclusao do botao Posicao
AADD(aBut040, {"HISTORIC", {|| Fc040Con() }, STR0139}) //"Posicao"

//inclusao do botao Rastreamento
AADD(aBut040, {"HISTORIC", {|| Fin250Rec(2) }, STR0140}) //"Rastreamento"


// integração com o PMS
If IntePms() .And. (!Type("lF040Auto") == "L" .Or. !lF040Auto)
	SetKey(VK_F10, {|| Eval(bPmsDlgRC)})
EndIf

// Não excluir um Titulo que veio da Integração com o TOP - Wilson em 15/08/2011
If lPmsInt .And. SE1->E1_ORIGEM # "WSFINA04"
	aArea     := GetArea()
	aAreaAFT  := AFT->(GetArea())
	aAreaSE1  := SE1->(GetArea())
	dbSelectArea("AFT")
	dbSetOrder(2)//AFT_FILIAL+AFT_PREFIX+AFT_NUM+AFT_PARCEL+AFT_TIPO+AFT_CLIENT+AFT_LOJA+AFT_PROJET+AFT_REVISA+AFT_TAREFA
	If MsSeek(xFilial("AFT")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)
		If lViaAFT
		   lViaINT := IIf(AFT->AFT_VIAINT == 'S',.T.,.F.)
 			If lViaINT
				If cPaisLoc $ ('BRA|')

					Help(" ",1, "HELP",, STR0126, 1, 0 ) // "Titulo Integrado pelo TOP só pode ser excluido pelo TOP"
				Else
					Help(" ",1, "HELP",, STR0149, 1, 0 ) //"Este título está bloqueado pelo Totvs Obras e Projetos. Desbloqueie o título no TOP para realizar esta operação."
				Endif
				Return .F.
			End
		End
	End
	RestArea(aAreaSE1)
	RestArea(aAreaAFT)
	RestArea(aArea)
End
//


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se existem dados no arquivo					  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If SE1->( EOF()) .or. xFilial("SE1") # SE1->E1_FILIAL
	Help(" ",1,"ARQVAZIO")
	Return .T.
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Caso tenha seja um titulo gerado pelo SigaEic nao podera ser excluido    		        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lIntegracao .and. UPPER(Alltrim(SE1->E1_ORIGEM)) $ "SIGAEIC"
	HELP(" ",1,"FAORIEIC")
	Return
Endif

//DFS - 16/03/11 - Deve-se verificar se os títulos foram gerados por módulos Trade-Easy, antes de apresentar a mensagem.
//  !!!! FAVOR MANTER A VALIDACAO SEMPRE COM SUBSTR() PARA NAO IMPACTAR EM OUTROS MODULOS !!!! (SIGA3286)
If substr(SE1->E1_ORIGEM,1,7) $ "SIGAEEC/SIGAEFF/SIGAEDC/SIGAECO" .AND. !(cModulo $ "EEC/EFF/EDC/ECO")
	HELP(" ",1,"FAORIEEC")
	Return
Endif


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Integracao com o Modulo de Transporte (SIGATMS)                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If SubStr(SE1->E1_ORIGEM, 1, 7) $ 'TMSA850' .And. !lF040Auto
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1) //Este titulo nao podera ser excluido pois foi gerado pelo modulo
	Return .F.
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Integracao com o Modulo de Plano de Saude (SIGAPLS) - BOPS 102698           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If  SubStr(SE1->E1_ORIGEM, 1, 3) $ 'PLS' .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1) //Este titulo nao podera ser excluido pois foi gerado pelo modulo
	Return .F.
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Para titulo e-Commerce nao pode ser excluido                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !LJ861ECAuto() .And. !LJ862ECAuto() .And.;
       LJ861EC01(SE1->E1_NUM, SE1->E1_PREFIXO, .F./*NaoTemQueTerPedido*/,SE1->E1_FILORIG)
	Help(" ",1,"NO_DELETE",,"SIGALOJA - e-Commerce!",3,1) //Este titulo nao podera ser excluido pois foi gerado pelo modulo
	Return .F.
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Nao permite exclusao de titulo gerado pela rotina Rec.Diversos para a Loca- ³
//³ lização BRASIL
//  Não permite a exclusão de titulos gerados por prestação de contas           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If (cPaisLoc=="BRA") .AND. (SE1->E1_ORIGEM $ 'FINA087A|FINA677') .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1) //Este titulo nao podera ser excluido pois foi gerado pelo modulo
	Return .F.
EndIf

//Titulos gerados por faturamento não podem ser excluidos no FINANCEIRO
If  SubStr(SE1->E1_ORIGEM, 1, 4) $ 'MATA' .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1) //Este titulo nao podera ser excluido pois foi gerado pelo modulo
	Return .F.
EndIf

//Titulos gerados por diferenca de imposto não podem ser excluidos
If Alltrim(SE1->E1_ORIGEM) == "APDIFIMP" .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1) //Este titulo nao podera ser excluido pois foi gerado pelo modulo
	Return .F.
EndIf

// Verifica movimentacao de AVP
If !FAVPValTit( "SE1",, SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, SE1->E1_CLIENTE, SE1->E1_LOJA, " " )
	Return .F.
EndIf

// Verifica integracao com PMS e nao permite excluir titulos que tenham solicitacoes
// de transferencias em aberto.
If !Empty(SE1->E1_NUMSOL)
	HELP(" ",1,"FIN62003")
	Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Não permite alterar titulos que foram gerados pelo Template GEM³
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistTemplate("GEMSE1LIX")
	If ExecTemplate("GEMSE1LIX",.F.,.F.)
		Help(" ",1, "HELP",, STR0086, 1, 0 )//"Este titulo não pode ser excluido, pois foi gerado através do Template GEM."
		Return
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Não permite excluir titulos que já foram conciliados           ³
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SE5")
dbSetOrder(7)
IF MsSeek(xFilial()+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)
	If !Empty(SE5->E5_RECONC) .And. !lBxConc .And. SE5->E5_RECPAG = 'R'
		Help(" ",1,"MOVRECONC")
		Return
	Endif

	//Nao permite a exclusao de RA com imposto retido em outro titulo RA
	If SE5->E5_TIPO $ MVRECANT .and. (SE5->E5_PRETPIS=='2' .or. SE5->E5_PRETCOF=='2' .or. SE5->E5_PRETCSL=='2')
		//"Essa baixa possui impostos retidos em outra baixa. E necessario cancelar primeiro a baixa responsavel pela retenção dos impostos"
		Help(" ",1,"NODELIMP",, STR0159 + CRLF + ;		//"Este adiantamento possui impostos retidos em outro adiantamento."
								STR0160 ,1,0)			//"É necessario cancelar primeiro o adiantamento responsavel pela retenção dos impostos"
		Return .F.
	Endif
EndIf

If !Empty(SE1->E1_ORIGEM) .And. Upper(Trim(SE1->E1_ORIGEM)) $ "FINA280"
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1)
	Return
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Integracao com o Modulo Gestao de Contratos (SIGAGCT)                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !Empty(SE1->E1_MDCONTR) .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)
	Help(" ",1,"NO_DELETE",,SE1->E1_ORIGEM,3,1)
	Return
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Nao permite excluir titulos do tipo RA gerados automaticamente  ³
//³ ao efetuar o recebimentos diversos - Majejo de Anticipo         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc == "MEX" .And.;
	Upper(Alltrim(SE1->E1_Origem)) $ "FINA087A" .And.;
	SE1->E1_TIPO == Substr(MVRECANT,1,3) .And.;
	X3Usado("ED_OPERADT") .And.;
	GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+SE1->E1_NATUREZ,1,"") == "1"

	Help(" ",1,"FA040VLDEXC")

	Return
Endif


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Integracao com o Controle de Exportacao (SIGAEEC)                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//Verifica se título efetivo poderá ou não ser estornado
dbselectarea("FIH")
dbsetorder(2)
If dbseek(xFilial("FIH")+"SE1"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)

	If (!Type("lF040Auto") == "L" .or. !lF040Auto)
		if msgyesno(STR0127) //"Titulo Efetivo originado de Título(s) Provisório(s), deseja excluir o Efetivo e retornar o(s) Provisório(s) para o Status 'Em aberto'?"
			lEstProv := .T.
		else
			Return .F.
		endif

	Else
		lEstProv := .T.
	EndIf

EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Limpa aGet e aTela              					³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aGets := { }
aTela := { }

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se o titulo esta em TELECOBRANCA                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
SK1->(DbSelectarea("SK1"))
SK1->(DbSetorder(1))            	// K1_FILIAL+K1_PREFIXO+K1_NUM+K1_PARCELA+K1_TIPO
If SK1->( DbSeek( xFilial("SK1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO) )
	If SK1->K1_OPERAD != "XXXXXX"
		Help(" ",1, "HELP",, STR0088, 1, 0 ) //"Este título não pode ser excluido pois se encontra em cobrança"
		Return .F.
	EndIf
Endif

If( Alltrim(SE1->E1_ORIGEM) $ cProdRM .And. !lF040Auto)

	HELP(" ",1,"ProtheusXClassis" ,,STR0208,2,0,,,,,, {STR0209})//"Título gerado pela Integração Protheus X Classis não Pode ser excluido pelo Protheus" ## "Efetue a exclusão do titulo pelo sistema RM Clasis"
	Return .F.

EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se o titulo foi gerado por outro modulo do sistema ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If (!Empty(SE1->E1_ORIGEM) .And. !(Upper(Trim(SE1->E1_ORIGEM)) $ "FINA040") .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)) .And.;
	!Upper(AllTrim(SE1->E1_ORIGEM)) $ "S|L|T"
	If GetNewPar("MV_RMBIBLI",.F.)
		If !(Upper(AllTrim(SE1->E1_ORIGEM)) $ "S") .and. !(Upper(AllTrim(SE1->E1_ORIGEM)) $ "L") //S=Gerado pelo RM Classis Net/RM Biblios
			If (SE1->E1_ORIGEM) == "WSFINA04"
				MsgAlert(STR0126) // "Titulo Integrado pelo TOP so pode ser excluido pelo TOP"
				Return .F.
			Else
				Help(" ",1,"NO_DELETE")
				Return .T.
			Endif
		Endif
	ElseIf ! GetNewPar("MV_ACATIVO", .F.) .or. ! Upper(Trim(SE1->E1_ORIGEM)) $ "ACAA070/ACAA680/ACAA681/ACAA682/WEB410/REQ410"
		If (SE1->E1_ORIGEM) == "WSFINA04"
			MsgAlert(STR0126) // "Titulo Integrado pelo TOP so pode ser excluido pelo TOP"
			Return .F.
		Else
			Help(" ",1,"NO_DELETE")
			Return .T.
		endif
	ElseIf ! GetNewPar("MV_ACATIVO", .F.) .or. ! Upper(Trim(SE1->E1_ORIGEM)) $ "ACAA070/ACAA680/ACAA681/ACAA682/WEB410/REQ410"
		Help(" ",1,"NO_DELETE")
		Return .T.
	Elseif GetNewPar("MV_ACATIVO", .F.) .and. Upper(Trim(SE1->E1_ORIGEM)) = "ACAA680"
		IF SE1->E1_PREFIXO $ aPrefixo[__MAT]+"/"+aPrefixo[__MES]+"/"+aPrefixo[__ADA]+"/"+aPrefixo[__TUT]+"/"+aPrefixo[__DEP]+"/"+aPrefixo[__DIS] .and. !Empty( SE1->E1_NRDOC )

			cNumra  := SE1->E1_NUMRA
			cCodCur := Substr(SE1->E1_NRDOC,1,TamSx3("JC7_CODCUR")[1])
			cPerLet := Substr(SE1->E1_NRDOC,TamSx3("JC7_CODCUR")[1]+1,TamSx3("JC7_PERLET")[1])
			cDiscip := Substr(SE1->E1_NRDOC,TamSx3("JC7_CODCUR")[1]+TamSx3("JC7_PERLET")[1]+1,TamSx3("JC7_DISCIP")[1])
			cNrDoc  := SE1->E1_NRDOC
		EndIf
	Elseif GetNewPar("MV_ACATIVO", .F.) .and. Upper(Trim(SE1->E1_ORIGEM)) = "ACAA070"
		JA1->(dbSetOrder(8))
		If JA1->(dbSeek(xFilial("JA1")+SE1->E1_PREFIXO+SE1->E1_NUM))
			JA6->(dbSetOrder(1))
			If JA6->(dbSeek(xFilial("JA6")+JA1->JA1_PROSEL))
			    If Empty(JA6->JA6_STATUS) .Or. JA6->JA6_STATUS == "2"
			    	Help(" ",1, "HELP",, STR0066, 1, 0 ) // "Para excluir um título de processo seletivo é necessário excluir o candidato."
					Return .T.
				Elseif JA6->JA6_STATUS == "1"
					JAP->(dbSetOrder(1))
					JAP->(dbSeek(xFilial("JAP")+JA1->JA1_CODINS))
					JAA->(dbSetOrder(1))
					JAA->(dbSeek(xFilial("JAA")+JA1->JA1_CODINS))
					If JAP->JAP_COMPAR == "1" .OR. JAA->JAA_COMPAR == "1"
						Help(" ",1, "HELP",, STR0066, 1, 0 )// "Para excluir um título de processo seletivo é necessário excluir o candidato."
						Return .T.
					Endif
				Endif
			Endif
		EndIf
	EndIf
EndIf
//Verifica se existe tratamento de rastreamento
//Verifica se o titulo foi gerador ou gerado por desdobramento
If lRastro .AND. SE1->E1_DESDOBR $ "1#S" .AND. !lNRastDSD .and. !lFina250
	Help( " ", 1, "DESDOBRAD",,STR0097+Chr(13)+; //"Não é possivel a exclusão de titutos geradores ou gerados por desdobramento. "
						STR0098,1)	//"Favor utilizar a rotina de Cancelamento de Desdobramento."
	Return .F.
Endif

nSavRec	 	:= SE1->(RecNo())
cPrefixo  	:= SE1->E1_PREFIXO
cNum		:= SE1->E1_NUM
cParcela  	:= SE1->E1_PARCELA
cCliente 	:= SE1->E1_CLIENTE
cLoja		:= SE1->E1_LOJA

If cPaisLoc == "BRA"
	cParcIRF := SE1->E1_PARCIRF
Else
	cParcIRF := ""
Endif

cNatureza 	:= SE1->E1_NATUREZ
cTipo 	 	:= SE1->E1_TIPO
nIss		:= SE1->E1_ISS
nIrrf 		:= SE1->E1_IRRF
nInss 		:= SE1->E1_INSS
nCsll		:= SE1->E1_CSLL
nCofins 	:= SE1->E1_COFINS
nPis	 	:= SE1->E1_PIS
cOrigem     := SE1->E1_ORIGEM

cTitPai		:= SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se o titulo foi baixado total ou parcialmente      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !Empty(SE1->E1_BAIXA) .and. !( SE1->E1_TIPO $ MVABATIM .and. SE1->E1_SALDO > 0 )
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Campo utilizado no Correspondente Bancario³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|TRI|URU|VEN"
		If Empty(SE1->E1_DOCTEF)
			Help(" ",1,"FA040BAIXA")
			Return
		Endif
	Else
		Help(" ",1,"FA040BAIXA")
		Return
	Endif
EndIf

//Trato a exclusao das baixas geradas pelo RM Classis quando o título vier zerado
If !Empty(SE1->E1_BAIXA) .And. SE1->E1_VALOR == 0 .And. SE1->E1_SALDO == 0 .And. AllTrim(SE1->E1_ORIGEM) $ 'S|L|T'
	Help(" ",1,"FA040BAIXA")
	Return
EndIf

If SE1->E1_VALOR != SE1->E1_SALDO
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Campo utilizado no Correspondente Bancario³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|TRI|URU|VEN"
		If Empty(SE1->E1_DOCTEF)
			Help(" ",1,"BAIXAPARC")
			Return
		Endif
	Else
		Help(" ",1,"BAIXAPARC")
		Return
	Endif
EndIf
If !lPCCBaixa
	lCpRet:= SLDRMSG(SE1->E1_EMISSAO, SE1->E1_SALDO,SE1->E1_NATUREZ,"R",SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_TIPO)
	If lCpRet
		If !MSGNoYes(STR0193)
			Return
		Else
			lIrRet	:= .T.
		Endif
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento n„o ‚ menor que data limite de ³
//³ movimentacao no financeiro    								 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !DtMovFin(,,"2")
   Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se o titulo ‚ um titulo de IR                      ³
//³   s¢ ser  deletado quando o titulo que o gerou o for  		 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If SE1->E1_TIPO $ MVIRABT+"/"+MVINABT+"/"+MVCFABT+"/"+MVCSABT+"/"+MVPIABT
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o titulo de abatimento foi gerado manualmente      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Fa040Pai()
		Help(" ",1,"NAOPRINCIP")
		Return
	Endif
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se o titulo est  em carteira, pois os que n†o      ³
//³   estiverem, n†o ser†o deletados.                    		 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//SITCOB
If !(SE1->E1_SITUACA $ cLstSit0 )
	Help(" ",1,"FA040SITU")
	Return
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se tem título de ISS no C.Pagar que já esteja      ³
//³   baixado													³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nISS != 0
	dbSelectArea("SE2")
	dbSetOrder(1)
	dbSeek(xFilial("SE2")+cPrefixo+cNum+cParcela)
	While !Eof() .And. E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA == ;
		xFilial("SE2")+cPrefixo+cNum+cParcela
		IF AllTrim(E2_NATUREZ) = Alltrim(cISS) .and. ;
			STR(SE2->E2_SALDO,17,2) <> STR(SE2->E2_VALOR,17,2)
			//"Esse título não pode ser cancelado pois
	       	//"possui ISS baixado no Contas a Pagar."
			Help(" ",1,"ISSBXCP")
			Return
		EndIf
		dbSkip()
	Enddo
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se adiantamento tem relacionamento com pedido de   ³
//³ venda.                                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc $ "BRA|MEX" .and. SE1->E1_TIPO $ MVRECANT
	FIE->(dbSetOrder(2))
	If FIE->(MsSeek(xFilial("FIE")+"R"+SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
		Help(" ",1, "HELP",, STR0107, 1, 0 ) //"Adiantamento relacionado a um pedido de venda. Primeiro é necessário excluir este relacionamento."
		Return()
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Envia para processamento dos Gets			  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SA1")
dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)

If lContrAbt
	 If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|URU|VEN"
		cRetCli := Iif(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
	Endif
Endif


nOpca := 0
dbSelectArea(cAlias)
If !SoftLock( "SE1" )
	Return
EndIf

bCampo := {|nCPO| Field(nCPO) }
FOR i := 1 TO FCount()
	M->&(EVAL(bCampo,i)) := FieldGet(i)
NEXT i
If !Type("lF040Auto") == "L" .or. !lF040Auto
	If lPanelFin  //Chamado pelo Painel Financeiro
		dbSelectArea("SE1")
		oPanelDados := FinWindow:GetVisPanel()
		oPanelDados:FreeChildren()
		aDim := DLGinPANEL(oPanelDados)

		DEFINE MSDIALOG oDlg OF oPanelDados:oWnd FROM 0, 0 TO 0, 0 PIXEL STYLE nOR( WS_VISIBLE, WS_POPUP )

		aPosEnch := {,,,}
		oEnc01:= MsMGet():New( cAlias, nReg, nOpc,,"AC",STR0010,,aPosEnch,,,,,,oDlg,,,.F.) // "Quanto … exclus„o?"
		oEnc01:oBox:Align := CONTROL_ALIGN_ALLCLIENT

		// define dimenção da dialog
		oDlg:nWidth := aDim[4]-aDim[2]

		nOpca := 2

		ACTIVATE MSDIALOG oDlg  ON INIT (FaMyBar(oDlg,{|| nOpca := 1,oDlg:End()},{|| nOpca := 2,oDlg:End()},aBut040),oDlg:Move(aDim[1],aDim[2],aDim[4]-aDim[2], aDim[3]-aDim[1]))
		FinVisual(cAlias,FinWindow,(cAlias)->(Recno()))

   Else

		nOpca := AxVisual( "SE1", SE1->( Recno() ), 2 ,,,,,aBut040)

	Endif
Else
	nOpcA := 1
EndIF

If nOpcA == 1
	If (Type("lF040Auto") == "L" .and. lF040Auto)
		lRetVM		:= .T.
	Endif

	SE5->(DbSelectarea("SE5"))
	SE5->(DbSetorder(7))
	If SE5->( DbSeek( xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO) )
		cChave := xFilial("SE5")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO
		cChvSE2 := SE1->(E1_PREFIXO + E1_NUM + E1_PARCELA)

		While cChave == SE5->(E5_FILIAL + E5_PREFIXO + E5_NUMERO + E5_PARCELA + E5_TIPO )
			If SE5->E5_TIPODOC $ "VM"
				If !lRetVM // valida somente 1 vez
					lRetVM := MsgYesNo(STR0125)
				Endif

				If lRetVM
					If lF040CANVM
						ExecBlock("F040CANVM", .F., .F.)
					Endif
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Gera o lancamento contabil para delecao da varicao  ³
					//³ monetaria					                        ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If SE5->E5_TIPODOC $ "VM"
						cPadMon :=	cPadrao
						cPadrao := "59A"
					EndIf

					IF SE5->E5_TIPODOC $ "VM"
						If !lHead
							nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
							lHead := .T.
						Endif
					  	nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
					Endif

					RodaProva(nHdlPrv,nTotal)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Indica se a tela sera aberta para digitação			  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					lDigita:=IIF(mv_par01==1 .And. !lF040Auto,.T.,.F.)

					cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,,,,,,aDiario)

					//Posiciona a FK5 para mandar a operação de alteração com base no registro posicionado da SE5
					If AllTrim( SE5->E5_TABORI ) == "FK1"
						aAreaAnt := GetArea()
						dbSelectArea( "FK1" )
						FK1->( DbSetOrder( 1 ) )
						If MsSeek( xFilial("FK1") + SE5->E5_IDORIG )
							aAreaAnt := GetArea()
							oModel :=  FWLoadModel('FINM030')//Mov. Bancario Manual
							oModel:SetOperation( 4 ) //Alteração
							oModel:Activate()
							oSubFKA := oModel:GetModel( "FKADETAIL" )
							oSubFKA:SeekLine( { {"FKA_IDORIG", SE5->E5_IDORIG } } )

							oModel:SetValue( "MASTER", "E5_GRV", .T. ) //Habilita gravação SE5
							oModel:SetValue( "MASTER", "E5_OPERACAO", 3 ) //E5_OPERACAO 3 = Deleta da SE5 e sem gerar estorno na FK5

							If oModel:VldData()
						       	oModel:CommitData()
						       	oModel:DeActivate()
						       	oModel:Destroy()
		        				oModel := NIL
							Else
								lRet := .F.
							    cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
							    cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
							    cLog += cValToChar(oModel:GetErrorMessage()[6])

						       	If (Type("lF040Auto") == "L" .and. lF040Auto)
						       		Help( ,,"M040VALID",,cLog, 1, 0 )
					       		Endif
							Endif
						Endif
					Endif

					cPadrao:= cPadMon
				Else
					Return(.F.)
				EndIf
			EndIf
			SE5->(DbSkip())
		EndDo
	Endif


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa a gravacao dos lancamentos do SIGAPCO          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PcoIniLan("000001")

	lRet := .T.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de entrada de templates para verificar        ³
	//³ informacoes antes de serem gravadas		            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lTFa040B01
		lRet := ExecTemplate( "FA040B01",.F.,.F. )
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de entrada para verificar informacoes antes   ³
	//³ de serem gravadas			                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lFa040B01
		lRet := ExecBlock( "FA040B01",.F.,.F. )
	EndIf
	aChave := {SE1->E1_FILIAL,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA}
	aPenCont := FA040PenC(aChave)

	If Len(aPenCont) > 0
		lRet := FA040MonP(aPenCont)
		lPendCtb := .T.
	EndIf

	If !lRet
		Return
	EndIF
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o titulo foi gerado por desdobramento.  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SE1->E1_DESDOBR == "1"
		lDesdobr := .T.
	Endif

	// Verifica se o titulo foi distribuido por multiplas naturezas para contabilizar o
	// cancelamento via SE1 ou SEV
	If SE1->E1_MULTNAT == "1" .and. !lDesdobr
		DbSelectArea("SEV")
		If DbSeek(RetChaveSev("SE1"))
			// Vai para o final para nao contabilizar duas vezes o LP 505
			DbGoBottom()
			DbSkip()
		Endif
		DbSelectArea("SE1")
	Endif

	/*Projeto Grupo ABC
	If ( mv_par03 == 1 ) .and. FindFunction("CtbTranUniq")
		CtbTranUniq()
	Endif*/

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicio do bloco protegido via TTS						  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	BEGIN TRANSACTION

		//....
		//   Conforme situacao do parametro abaixo, integra com o SIGAGSP
		//   MV_SIGAGSP - 0-Nao / 1-Integra
		//   Estornar o lancamento de Orcamentacao
		//   .....
		If GetNewPar("MV_SIGAGSP","0") == "1"
			// Inclusão de FindFunction pois a rotina nao foi encontrada
			// no repositorio.
			If FindFunction("GSPF230")
				GSPF230(3)
				DbSelectArea("SE1")
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualizacao dos dados do Modulo SIGAPMS    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		lRatPrj:= PmsRatPrj("SE1",,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO)
		PmsWriteRC(2,"SE1")	//Estorno
		PmsWriteRC(3,"SE1")	//Exclusao

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verificacao da Lista de Presentes - Vendas CRM³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lUsaLstPre
			Fa040LstPre()
		EndIf
		If SE1->E1_MULTNAT <> "1" .And. SE1->E1_FLUXO == 'S' .And. !GetNewPar("MV_RMCLASS", .F.)
			lAchou := .F.
			FI7->(DbSetOrder(1))
			// Se nao for o titulo gerador do desdobramento, atualiza o saldo, pois o titulo gerador nao atualiza o saldo
			// na inclusao
			lAchou := FI7->(MsSeek(xFilial("FI7")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
			If !lAchou

				If cFilAnt == SE1->E1_FILORIG
					If lGestao
						If lSE1Comp
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  		Else
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
						Endif
					Else
						If lSE1Comp
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  		Else
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
						Endif
					Endif
				Else
					If lGestao
						If lSE1Comp
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  		Else
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
						Endif
					Else
						If lSE1Comp
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  		Else
				  			AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
						Endif
					Endif
				Endif

				aGetSE1 := SE1->(GetArea())

				SE1->(DbSetOrder(28))
				FIV->(DbSetOrder(1))

				If SE1->(DbSeek(xFilial("SE1") + cTitPai))
					While !SE1->(EOF()) .And. Alltrim(SE1->E1_TITPAI) == Alltrim(cTitPai)
						If cFilAnt == SE1->E1_FILORIG
							If lGestao
								If lSE1Comp
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  				Else
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
								Endif
							Else
								If lSE1Comp
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  				Else
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
								Endif
							Endif
						Else
							If lGestao
								If lSE1Comp
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  				Else
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
								Endif
							Else
								If lSE1Comp
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILORIG)
				  				Else
				  					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),nOpc , ,0, SE1->E1_FILIAL)
								Endif
							Endif
						Endif
						SE1->(DbSkip())
					Enddo
				Endif
				RestArea(aGetSE1)
			Endif
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exclui comissao, se foi gerada 							  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ( GetMv("MV_TPCOMIS") == "O" ) .and. !lDesdobr
			Fa440DeleE("FINA040")
		EndIf
		nRecnoSE1 := SE1->(Recno())
		dbSelectArea("SA1")
		dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)
		nMoeda		:= If(SA1->A1_MOEDALC > 0, SA1->A1_MOEDALC, Val(GetMV("MV_MCUSTO")))
		dbSelectArea("SE1")
		If !(SE1->E1_TIPO $ MVPROVIS) .or. (mv_par02 == 1) .or. (SE1->E1_TIPO $ MVPROVIS .and. lDesdobr)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica se titulos foram gerados via desdobramento ³
			//³ e altera o lancamento padrao para 578.              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lDesdobr
				cPadrao:="529"  //Exclusao de titulo gerado via desdobramento
			Endif

			//Quando esta rotina for chamada do FINA460 via rotina automatica,
			//a contabilizacao neste ponto ficara desabilitada
			//A contabilizacao da exclusao neste caso sera feita no proprio FINA460
			lPadrao:=VerPadrao(cPadrao) .and. !lFina460

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Deleta os titulos de Desdobramento em aberto        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lDesdobr

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Apaga os lancamentos de desdobramento - SIGAPCO  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				PcoDetLan("000001","03","FINA040",.T.)

				If ( GetMv("MV_TPCOMIS") == "O" )
					Fa440DeleE("FINA040",.T.)
				EndIf
				nValSaldo := 0
				VALOR := 0
				lHead := .F.
				dDtEmiss := SE1->E1_EMISSAO
				nMoedSE1 := SE1->E1_MOEDA
				nOrdSE1 := IndexOrd()
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Gera o lancamento contabil para delecao de titulos  ³
				//³ gerados via desdobramento.                          ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				IF lPadrao .and. SubStr(SE1->E1_LA,1,1) == "S" .AND. !lFina250
					If !lHead
						nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
						lHead := .T.
					Endif
					nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
					nValSaldo += SE1->E1_VALOR
				Endif
				nRecnoSE1 := SE1->(Recno())
				dbSkip()
				nProxReg := SE1->(Recno())
				dbGoto(nRecnoSE1)

				If UsaSeqCor()
					aDiario := {}
					aDiario := {{"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"}}
				Else
					aDiario := {}
				EndIf

				cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
							SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
				FINDELFKs(cChaveFK7,"SE1")

				RecLock("SE1",.F.,.T.)
				dbDelete()
				MsUnlock()

				If nTotal > 0 .AND. !lFina250
					dbSelectArea ("SE1")
					dbGoBottom()
					dbSkip()
					VALOR := nValSaldo
					nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
				Endif

				IF lPadrao .and. nTotal > 0 .AND. !lFina250
					//-- Se for rotina automatica força exibir mensagens na tela, pois mesmo quando não exibe os lançametnos, a tela
					//-- sera exibida caso ocorram erros nos lançamentos padronizados
					If lF040Auto
						lSetAuto := _SetAutoMode(.F.)
						lSetHelp := HelpInDark(.F.)
						If Type('lMSHelpAuto') == 'L'
							lMSHelpAuto := !lMSHelpAuto
						EndIf
					EndIf

					RodaProva(nHdlPrv,nTotal)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Indica se a tela sera aberta para digitação			  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					lDigita:=IIF(mv_par01==1 .And. !lF040Auto,.T.,.F.)

					cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,,,,,,aDiario)

					If lF040Auto
						HelpInDark(lSetHelp)
						_SetAutoMode(lSetAuto)
						If Type('lMSHelpAuto') == 'L'
							lMSHelpAuto := !lMSHelpAuto
						EndIf
					EndIf

				Endif

			Else
				If SE1->E1_TIPO $ MVRECANT
					cPadrao:="502"
					dbSelectArea("SE5")
					dbSetOrder(7)
					If (dbSeek(xFilial()+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA))
						dbSelectArea("SA6")
						dbSeek( xFilial("SA6") + SE5->E5_BANCO+SE5->E5_AGENCIA+SE5->E5_CONTA )
					EndIf
				EndIf
				SED->(DbSetOrder(1))
				SED->(dbSeek( xFilial("SED") + SE1->E1_NATUREZ))

				//Quando esta rotina for chamada do FINA460 via rotina automatica,
				//a contabilizacao neste ponto ficara desabilitada
				//A contabilizacao da exclusao neste caso sera feita no proprio FINA460
				lPadrao:=VerPadrao(cPadrao) .and. !lFina460

				If lPadrao .and. SubStr(SE1->E1_LA,1,1)=="S"
					nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
					nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
				EndIf
				If nTotal > 0
					If lF040Auto
						lSetAuto := _SetAutoMode(.F.)
						lSetHelp := HelpInDark(.F.)
						If Type('lMSHelpAuto') == 'L'
							lMSHelpAuto := !lMSHelpAuto
						EndIf
					EndIf

					RodaProva(nHdlPrv,nTotal)
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Indica se a tela sera aberta para digitação			  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					lDigita:=IIF(mv_par01==1 .And. !lF040Auto,.T.,.F.)

					cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,,,,,,aDiario)

					If lF040Auto
						HelpInDark(lSetHelp)
						_SetAutoMode(lSetAuto)
						If Type('lMSHelpAuto') == 'L'
							lMSHelpAuto := !lMSHelpAuto
						EndIf
					EndIf
				Endif
			Endif
			If !cNatureza $ &(GetMv("MV_ISS")) .and. !cNatureza $ &(GetMv("MV_IRF")) .and. ;
				!cNatureza $ &(GetMv("MV_INSS")) .and. !SE1->E1_TIPO $ MVPROVIS .and.;
				!cNatureza $ GetMv("MV_CSLL")	.and.;
				!cNatureza $ GetMv("MV_COFINS") .and.;
				!cNatureza $ GetMv("MV_PISNAT")

				If SE1->E1_TIPO $ MVRECANT+"/"+MVABATIM+"/"+MV_CRNEG .and. FUNNAME() <> "FINA460"
					AtuSalDup("+",SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,SE1->E1_TXMOEDA,SE1->E1_EMISSAO,,,lGrvSa1)
					SE1->(dbGoTo(nRecnoSE1))
				Else
					If !(FunName() $ "FINA074|FINA460") .AND. IIf(lNRastDSD ==.F.,IIf(SE1->E1_DESDOBR $ "1|S",!Empty(SE1->E1_PARCELA),.T.),.T.)
						AtuSalDup("-",SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,SE1->E1_TXMOEDA,SE1->E1_EMISSAO,,,lGrvSa1)
					Endif
				   	SE1->(dbGoTo(nRecnoSE1))

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Nao atualizar os campos A1_VACUM e A1_NROCOM se o modulo for o loja³
					//³e o cliente = cliente padrao.                                      ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

					If nModulo == 12 .OR. nModulo == 72 // SIGALOJA //SIGAPHOTO
						If SA1->A1_COD + SA1->A1_LOJA == GetMv("MV_CLIPAD") + GetMv("MV_LOJAPAD")
   							lAtuAcum := .F.
						EndIf
					ElseIf FunName() $ "FINA074|FINA460"
						lAtuAcum := .F.
					EndIf
					If lAtuAcum .AND. !lLiquid .AND. IIf(lNRastDSD == .F.,IIf(SE1->E1_DESDOBR $ "1|S",!Empty(SE1->E1_PARCELA),.T.),.T.) .And. lGrvSa1
						RecLock("SA1")
							SA1->A1_VACUM-=Round(NoRound(xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMoeda,SE1->E1_EMISSAO,3,SE1->E1_TXMOEDA),3),2)
							SA1->A1_NROCOM--
						MsUnLock()
					EndIf

				EndIf
			EndIf
			SE1->(dbGoTo(nRecnoSE1))
		EndIf

		If SE1->E1_TIPO $ MVRECANT
			AtuSalBco( SE5->E5_BANCO, SE5->E5_AGENCIA,SE5->E5_CONTA,dDataBase,SE5->E5_VALOR,"-")
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exclui os registros do FRB - Tabela de Controle de Cartão de Credito.   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If cPaisLoc == "EQU" .and. AllTrim(SE1->E1_TIPO) == "CC" .and. Subs(ProcName(1),18) <> "FA098GRV"
       	  	Fa040DelFRB()
		EndIf
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Exclui os registros do SE5 quando deletar o SE1     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		F040GrvSE5(2,.F.,,,,,lPendCtb)

		If lExistFJU .and. !lLiquid  .and. cPaisLoc == "BRA"
			FinGrvEx("R")
		Endif

		// Se estiver utilizando multiplas naturezas por titulo
		If SE1->E1_MULTNAT == "1"
			DelMultNat("SE1",@nHdlPrv,@nTotal,@cArquivo) // Apaga as naturezas geradas para o titulo
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica se existe um cheque gerado para este TITULO			 ³
		//³pois se tiver, dever  ser cancelado                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SEF")
		SEF->( dbSetOrder(3) )
		If SEF->(dbSeek(xFilial()+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)))
			While !Eof().and.SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO)==;
				EF_PREFIXO+EF_TITULO+EF_PARCELA+EF_TIPO.AND.EF_FILIAL==xFilial("SEF")
				If (SEF->EF_FORNECE == SE1->E1_CLIENTE .Or.;
					SEF->EF_CLIENTE == SE1->E1_CLIENTE) .And. AllTrim(SEF->EF_ORIGEM) == "FINA040"
					Reclock("SEF")
					SEF->( dbDelete() )
				Endif
				SEF->( dbSkip())
			Enddo
		Endif
		SEF->( dbSetOrder(1) )
		If !lDesdobr .or. (lDesdobr .and. lRastro .and. !lNRastDSD .and. lFina250 .and. lCalcImp)
			If cRetCli == "1" .And. cModRet == "2"
				SE1->(dbGoto(nRecnoSE1))
				SFQ->(DbSetOrder(1))
				If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
					lTemSfq := .T.
					lExcRetentor := .T.
				ELSE
					SFQ->(DbSetOrder(2))
					If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
						lTemSfq := .T.
					Endif
				Endif
				If lTemSfq
					// Altera Valor dos abatimentos do titulo retentor e tambem dos titulos gerados por ele.
					nTotGrupo := F040TotGrupo(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA), Left(Dtos(SE1->E1_VENCREA),6))
					nValBase	:= If (lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR)
					nTotGrupo -= nValBase
					nBaseAtual := nTotGrupo
					nBaseAntiga := nTotGrupo+nValBase
					nProp := nBaseAtual / nBaseAntiga
					aDadRet := F040AltRet(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA),nProp,0,nTotGrupo <= nValMinRet) // Altera titulo retentor
				Endif

				If lContrAbt .and. (SA1->A1_RECPIS $ "S#P" .or. SA1->A1_RECCSLL $ "S#P" .or. SA1->A1_RECCOFI $ "S#P")
					If !aDadRet[8] // Retentor estah em aberto
						SFQ->(DbSetOrder(2)) // FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES
						If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
							lTemSfq := .T.
							If nTotGrupo <= nValMinRet
								// Exclui o relacionamento SFQ
								SE1->(DbSetOrder(1))
								If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
									aRecSE1 := FImpExcTit("SE1",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
									For nX := 1 to Len(aRecSE1)
										SE1->(MSGoto(aRecSE1[nX]))
										FaAvalSE1(4)
									Next
									If SE1->E1_EMISSAO < dLastPcc
										// Recalculo os impostos quando a base ficou menor que o valor minimo //
										aVlrTotMes := F040TotMes(SE1->E1_VENCREA,@nIndexSE1,@cIndexSE1)
										If (aVlrTotMes[1]-(IIf(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR))) <= 5000
											dVencRea := SE1->E1_VENCREA
											F040RecalcMes(dVencRea,nValMinRet, cCliente, cLoja, .T.)
										Endif
									EndIf
									//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
									//³ Exclui os registros de relacionamentos do SFQ                               ³
									//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
									FImpExcSFQ("SE1",SFQ->FQ_PREFORI,SFQ->FQ_NUMORI,SFQ->FQ_PARCORI,SFQ->FQ_TIPOORI,SFQ->FQ_CFORI,SFQ->FQ_LOJAORI)
								Endif
							Endif
							RecLock("SFQ",.F.)
							DbDelete()
							MsUnlock()
						Endif
						SFQ->(DbSetOrder(1))
						SE1->(MsGoto(nRecnoSE1))
						// Caso o total do grupo for menor ou igual ao valor minimo de acumulacao,
						// e o retentor nao estava baixado. Recalcula os impostos dos titulos do mes
						// que possivelmente foram incluidos apos a base atingir o valor minimo
						If (nTotGrupo <= nValMinRet .And. lTemSfq) .Or.;
							(lTemSfq .And. lExcRetentor)
							lRecalcImp := .T.
							dVencRea := SE1->E1_VENCREA
						Endif
					ElseIf lTemSfq
						SFQ->(DbSetOrder(2))// FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES
						If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
							RecLock("SFQ",.F.)
							DbDelete()
							MsUnlock()
						Endif

						// Gera DDI
						// Calcula valor do DDI
						nValorDif := nBaseAtual - nBaseAntiga

						//Caso a base atua seja menor que o valor minimo de retencao (MV_VL10925)
						//O DDI sera o valor total dos impostos retidos do grupo (retidos + retentor)
						//Nao retirar o -1 pois neste caso o valor da diferenca eh o valor da base antiga
						//ja que os impostos foram descontados indevidamente. (Pequim & Claudio)
						If nBaseAtual <= nValMinRet
							nValorDif := (nBaseAntiga * (-1))
						Endif

						nValorDDI := Round(nValorDif * (SED->(ED_PERCPIS+ED_PERCCSL+ED_PERCCOF)/100),TamSx3("E1_VALOR")[2])

						If nValorDDI < 0
							nValorDDI	:= Abs(nValorDDI)
							// Se ja existir um DDI gerado para o retentor, calcula a diferenca do novo DDI.
							SE1->(DbSetOrder(1))
							If SE1->(MsSeek(xFilial("SE1")+aDadRet[1]+aDadRet[2]+aDadRet[3]+"DDI"))
								If (SE1->E1_VALOR == SE1->E1_SALDO)
									nValorDDI := nValorDDI - SE1->E1_VALOR
									RecLock("SE1",.F.)
									SE1->E1_VALOR := nValorDDI
									SE1->E1_SALDO := nValorDDI
									MsUnlock()
								Endif
							Else
								/*/
								ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								³ Ponto de Entrada para nao geração de DDI e NCC			   ³
								ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/
								If ( _lNoDDINCC )
									If ( ValType( uRet := ExecBlock("F040NDINC") ) == "L" )
										lNoDDINCC := uRet
									Else
										lNoDDINCC := .T.
									EndIf
								EndIf

								If ( lNoDDINCC )
									GeraDDINCC(	aDadRet[1]		,;
											 		aDadRet[2] 		,;
													aDadRet[3] 		,;
													"DDI"		 		,;
													aDadRet[5] 		,;
													aDadRet[6] 	 	,;
													aDadRet[7] 	   ,;
													nValorDDI		,;
													dDataBase		,;
													dDataBase		,;
												 	"APDIFIMP"		,;
												 	lF040Auto )
								EndIf

							Endif
						Endif
					Endif
				Endif
			Endif

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Apaga o registro									  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("SE1")
			SE1->(dbGoTo(nRecnoSE1))

			//Limpo referencias de apuracao de impostos.
			If lContrAbt .and. (SA1->A1_RECPIS $ "S#P" .or. SA1->A1_RECCSLL $ "S#P" .or. SA1->A1_RECCOFI $ "S#P")
				aRecSE1 := FImpExcTit("SE1",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
				For nX := 1 to Len(aRecSE1)
					SE1->(MSGoto(aRecSE1[nX]))
					FaAvalSE1(4)
				Next
				If SE1->E1_EMISSAO < dLastPcc
					// Recalculo os impostos quando a base ficou menor que o valor minimo
					aVlrTotMes := F040TotMes(SE1->E1_VENCREA,@nIndexSE1,@cIndexSE1)
					If (aVlrTotMes[1]-(IIf(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR))) <= 5000
						dVencRea := SE1->E1_VENCREA
						F040RecalcMes(dVencRea,nValMinRet, cCliente, cLoja, .T., .F.)
					Endif
				EndIf
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Exclui os registros de relacionamentos do SFQ                               ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				SE1->(dbGoTo(nRecnoSE1))
				FImpExcSFQ("SE1",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
			Endif
			SE1->(dbGoTo(nRecnoSE1))

			If ( UsaSeqCor() )
					aDiario := {}
					aDiario := {{"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"}}
			Else
					aDiario := {}
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Apaga os lancamentos nas contas orcamentarias - SIGAPCO  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If SE1->E1_TIPO $ MVRECANT
				PcoDetLan("000001","02","FINA040",.T.)		// Tipo RA
			Else
				PcoDetLan("000001","01","FINA040",.T.)
			EndIf

			//Acerto valores dos impostos do titulo pai quando os mesmos forem alterados
			//por compensacao ou inclusao do AB-
			If lImpComp .and. SE1->E1_TIPO $ MVABATIM

				nPisAbt := SE1->E1_PIS
				nCofAbt := SE1->E1_COFINS

				If nPisAbt + nCofAbt > 0
					// Procura titulo que gerou o abatimento, titulo pai
					SE1->(DbSeek(xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)))
					While SE1->(!Eof()) .And.;
							SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == xFilial("SE1")+cPrefOri+cNumOri+cParcOri
						If !SE1->E1_TIPO $ MVABATIM
							lAchouPai := .T.
							nRecSE1P	:= SE1->(RECNO())
							Exit // Encontrou o titulo
						Endif
						SE1->(DbSkip())
					Enddo

					SE1->(dbGoTo(nRecnoSE1))

					If lAchouPai
						//Acerta valores dos impostos da inclusão do abatimento.
						F040ActImp(nRecSE1P,SE1->E1_VALOR,.T.,nPisAbt,nCofAbt)
					Endif

				Endif
			Endif

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Integracao Protheus X RM Classis Net (RM Sistemas)³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			if GetNewPar("MV_RMBIBLI",.F.)
				if alltrim(upper(SE1->E1_ORIGEM)) == 'L' .or. alltrim(upper(SE1->E1_ORIGEM)) == 'S' .or. SE1->E1_IDLAN > 0
				     //Replica a exclusão do titulo para as tabelas do CorporeRM
				     ClsProcExc(SE1->(Recno()),'1','FIN040')
				endif
			endif


			If lEstProv //Executa rotina para estorno de título provisório
				F040RetPR()
				Pergunte("FIN040",.F.)
			EndIF

			cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
						SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA

			//realiza a exclus?o da tabela complementar
			If cPaisLoc=="BRA"
				Fa986excl("SE1")
			EndIf

			FINDELFKs(cChaveFK7,"SE1")

			//realiza a exclus?o no TAF
			//habilitar somente quando tiver a integra‡?o TAF
			//FExpT999(SE1->(Recno()), 2, 'T154')

			RecLock("SE1" ,.F.,.T.)

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Verifica se o titulo foi gerado a partir da implementacao³
			//³de Formas de Pagamento. (Gestao Educacional)             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If GetNewPar("MV_ACATIVO", .F.) .and. Upper(AllTrim(cOrigem)) == "ACAA681"
				dbSelectArea("JIF")
				JIF->( dbSetOrder(2) ) //Ordem: JIF_FILIAL+JIF_PRFTIT+JIF_NUMTIT+JIF_PARTIT+JIF_TIPTIT
				JIF->( dbSeek(xFilial("JIF")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO) )
				RecLock("JIF", .F.)
				JIF->JIF_PRFTIT := ""
				JIF->JIF_NUMTIT := ""
				JIF->JIF_PARTIT := ""
				JIF->JIF_TIPTIT := ""
				JIF->(MsUnLock())
			Endif

			If SE1->E1_TIPO $ MVRECANT .OR. ( !FXCalImp2(SE1->E1_NATUREZ, "ED_CALCIRF")) // ( /*Cod. Natureza*/, /*Campo da SED*/ )
				lRAExc := .T.
			EndIf

			SE1->( dbDelete() )

			// Recalculo os impostos quando a base ficou menor que o valor minimo
			If lRecalcImp
				F040RecalcMes(dVencRea,nValMinRet, cCliente, cLoja)
			Endif

	   Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apaga tambem os registro de impostos-IRRF  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !(SE1->E1_TIPO $ MVABATIM)
			If nIrrf != 0 .And. cPaisLoc == "BRA"
				dbSelectArea("SE2")
				dbSetOrder(1)
				dbSeek(xFilial("SE2")+cPrefixo+cNum+cParcIRF)
				While !Eof() .And. E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA == ;
					xFilial("SE2")+cPrefixo+cNum+cParcIRF
					IF AllTrim(E2_NATUREZ) = Alltrim(cIRF) .and. ;
						STR(SE2->E2_SALDO,17,2) == STR(SE2->E2_VALOR,17,2)
						// Apaga os lancamentos de IRRF do contas a pagar SIGAPCO
						PcoDetLan("000001","12","FINA040",.T.)
						cChaveFK7 := xFilial("SE2")+"|"+SE2->E2_PREFIXO+"|"+SE2->E2_NUM+"|"+SE2->E2_PARCELA+"|"+;
									SE2->E2_TIPO+"|"+SE2->E2_FORNECE+"|"+SE2->E2_LOJA
						FINDELFKs(cChaveFK7,"SE2")

						RecLock( "SE2" ,.F.,.T.)
						dbDelete( )
						nCntDele++
					EndIf
					dbSkip()
				Enddo
			Endif

			If nISS != 0
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Apaga tambem os registro de impostos-ISS	  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea("SE2")
				dbSetOrder(1)
				dbSeek(xFilial("SE2")+cPrefixo+cNum+cParcela)
				While !Eof() .And. E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA == ;
					xFilial("SE2")+cPrefixo+cNum+cParcela
					IF AllTrim(E2_NATUREZ) = Alltrim(cISS) .and. ;
						STR(SE2->E2_SALDO,17,2) == STR(SE2->E2_VALOR,17,2)
						// Apaga os lancamentos de ISS do contas a pagar SIGAPCO
						PcoDetLan("000001","13","FINA040",.T.)
						//Reestruturação da SE5, deletando SE2 e FK7
						cChaveFK7 := xFilial("SE2")+"|"+SE2->E2_PREFIXO+"|"+SE2->E2_NUM+"|"+SE2->E2_PARCELA+"|"+;
									SE2->E2_TIPO+"|"+SE2->E2_FORNECE+"|"+SE2->E2_LOJA
						FINDELFKs(cChaveFK7,"SE2")
						If lExistFJU .and. !FWIsInCallStack("FINA040")
							FinGrvEx("P")
						Endif
						RecLock( "SE2" ,.F.,.T.)
						dbDelete( )
						nCntDele++
						lExIrrf := .T.
					EndIf
					dbSkip()
				Enddo
			EndIf

			AADD(aTab,{"nPis"		,MVPIABT,"MV_PISNAT"})
			AADD(aTab,{"nCofins"	,MVCFABT,"MV_COFINS"})
			AADD(aTab,{"nCsll"		,MVCSABT,"MV_CSLL"})
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
			//³Integracao protheus X tin	³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
			If FWHasEAI("FINA040",.T.,,.T.)
				If !( AllTrim(SE1->E1_TIPO) $ MVRECANT .and. lRatPrj  .and. !(cPaisLoc $ "BRA|")) //nao integra  RA para Totvs Obras e Projetos Localizado
					If GetNewPar("MV_RMCLASS", .F.) //Caso a integração esteja ativada, excluo somente títulos gerados pelo RM
						If Upper(AllTrim(SE1->E1_ORIGEM)) $ "S|L|T"
							aRetInteg := FwIntegDef( 'FINA040', , , , 'FINA040' )

							//Se der erro no envio da integração, então faz rollback e apresenta mensagem em tela para o usuário
							If ValType(aRetInteg) == "A" .AND. Len(aRetInteg) >= 2 .AND. !aRetInteg[1]
								If ! IsBlind()
									Help( ,, "FINA040INTEGDELRM",, STR0203 + AllTrim( aRetInteg[2] ), 1, 0,,,,,, {STR0202} ) //"O registro não será excluído, pois ocorreu um erro na integração: ", "Verifique se a integração está configurada corretamente."
								Endif
								DisarmTransaction()
								Return .F.
							Endif
						EndIf
					Else
						aRetInteg := FwIntegDef( 'FINA040', , , , 'FINA040' )

						//Se der erro no envio da integração, então faz rollback e apresenta mensagem em tela para o usuário
						If ValType(aRetInteg) == "A" .AND. Len(aRetInteg) >= 2 .AND. !aRetInteg[1]
							If ! IsBlind()
								Help( ,, "FINA040INTEGDEL",, STR0203 + AllTrim( aRetInteg[2] ), 1, 0,,,,,, {STR0202} ) //"O registro não será excluído, pois ocorreu um erro na integração: ", "Verifique se a integração está configurada corretamente."
							Endif
							DisarmTransaction()
							Return .F.
						Endif
					EndIf
				Endif
			Endif

			For i := 1 to Len(aTab)
				If &(aTab[i,1]) != 0
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Apaga tambem os registro de impostos		  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					dbSelectArea("SE1")
					dbSetOrder(1)
					dbSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+aTab[i,2])
					While !Eof() .And. E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO == ;
							xFilial("SE1")+cPrefixo+cNum+cParcela+aTab[i,2]
						IF AllTrim(E1_NATUREZ) == GetMv(aTab[i,3])
							// Apaga os lancamentos dos impostos COFINS, PIS e CSLL do SIGAPCO
							PcoDetLan("000001",StrZero(8+i,2),"FINA040",.T.)
							If SE1->E1_FLUXO == 'S'
								AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),nOpc)
							Endif
							cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
										SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
							FINDELFKs(cChaveFK7,"SE1")
							If lExistFJU
								FinGrvEx("R")
							Endif
							RecLock( "SE1" ,.F.,.T.)
							dbDelete( )
							nCntDele++
						EndIf
						dbSkip()
					Enddo
				EndIf
			Next
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apaga tambem os registros agregados-SE1 	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nCntDele:=0
		If !( SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG+"/NDC") .and. !cTipo $ MVABATIM+"/"+MVIRABT+"/"+MVINABT
			dbSelectArea("SE1")
			dbSetOrder(2)
			dbSeek(xFilial("SE1")+cCliente+cLoja+cPrefixo+cNum+cParcela)
			While !EOF() .And. E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA == ;
				xFilial("SE1")+cCliente+cLoja+cPrefixo+cNum+cParcela
				If E1_TIPO $ MVABATIM +"/"+MVIRABT+"/"+MVINABT   // AB-/IR-/IN-
					If Alltrim(cTitPai) == Alltrim(SE1->E1_TITPAI)
						If lPadrao .and. SubStr(SE1->E1_LA,1,1) == "S"
							If nHdlPrv <= 0
								nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
								lHead := .T.
							Endif
							nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
						Endif

						If SE1->E1_TIPO == MVIRABT
							PcoDetLan("000001","06","FINA040",.T.)
						ElseIf SE1->E1_TIPO == MVINABT
							PcoDetLan("000001","07","FINA040",.T.)
						ElseIf SE1->E1_TIPO == MVISABT
							PcoDetLan("000001","08","FINA040",.T.)
						EndIf
						If SE1->E1_FLUXO == 'S'
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),nOpc)
						Endif

						cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
									SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
						FINDELFKs(cChaveFK7,"SE1")
						If lExistFJU
							FinGrvEx("R")
						Endif

						RecLock("SE1" ,.F.,.T.)
						dbDelete()
						nCntDele++
						AtuSalDup("+",SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,SE1->E1_TXMOEDA,SE1->E1_EMISSAO)
						dbSelectArea( "SE1" )
						lExIrrf := .T.
					EndIf
				EndIf
				dbSkip()
			Enddo
		Endif

		If !lExIrrf .And. !lRAExc
			If !( SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG+"/NDC") .and. !cTipo $ MVABATIM+"/"+MVIRABT+"/"+MVINABT
				dbSelectArea("SE1")
				dbSetOrder(2)
				If dbSeek(xFilial("SE1")+cCliente+cLoja + cChvSE2 + "IRF")
			  		lExcIR := MsgYesNo(STR0162)
			  	EndIf
			  	dbSeek(xFilial("SE1")+cCliente+cLoja)
		  		If lExcIR .And. ( !Empty(cChvSE2) .And. !lIrRet ) // Se o Ir estiver retido em outro título, não deve excluir tal qual o Pcc
					While !EOF() .And. E1_FILIAL+E1_CLIENTE+E1_LOJA == xFilial("SE1")+cCliente+cLoja
				  		If SE1->E1_TIPO == cTipo
				    		RecLock("SE1" ,.F.,.T.)
		              	SE1->E1_IRRF := 0
		              	nCntDele++
							dbSelectArea( "SE1" )
				  		Endif
						If E1_TIPO $ MVIRABT   // AB-/IR-/IN-
							If lPadrao .and. SubStr(SE1->E1_LA,1,1) == "S"
								If nHdlPrv <= 0
									nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
									lHead := .T.
								Endif
								nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
							Endif

							If SE1->E1_TIPO == MVIRABT
								PcoDetLan("000001","06","FINA040",.T.)
							ElseIf SE1->E1_TIPO == MVINABT
								PcoDetLan("000001","07","FINA040",.T.)
							ElseIf SE1->E1_TIPO == MVISABT
								PcoDetLan("000001","08","FINA040",.T.)
							EndIf
							If SE1->E1_FLUXO == 'S'
								AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),nOpc)
							Endif
						   	If lExistFJU
								FinGrvEx("R")
							Endif

							RecLock("SE1" ,.F.,.T.)
							dbDelete()
							nCntDele++
							AtuSalDup("+",SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,SE1->E1_TXMOEDA,SE1->E1_EMISSAO)
							dbSelectArea( "SE1" )
						EndIf
						dbSkip()
					Enddo
		 	  	Endif
			Endif
	   	Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Apaga tambem os registros de Impostos do RA³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SE1->(dbGoTo(nRecnoSE1))
		If lRaRtImp .and. SE1->E1_TIPO $ MVRECANT
			dbSelectArea("SE1")
			dbSetOrder(2)
			dbSeek(xFilial("SE1")+cCliente+cLoja+cPrefixo+cNum)
			While !EOF() .And. E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM == ;
				xFilial("SE1")+cCliente+cLoja+cPrefixo+cNum
				If E1_TIPO $ "IRF/PIS/COF/CSL"
				   	If lExistFJU
						FinGrvEx("R")
					Endif
					RecLock("SE1" ,.F.,.T.)
					dbDelete()
					nCntDele++
					dbSelectArea( "SE1" )
				EndIf

				dbSkip()
			Enddo
		Endif

		If !lDesdobr
			If nTotal > 0
				If lF040Auto
					lSetAuto := _SetAutoMode(.F.)
					lSetHelp := HelpInDark(.F.)
					If Type('lMSHelpAuto') == 'L'
						lMSHelpAuto := !lMSHelpAuto
					EndIf
				EndIf

				RodaProva(nHdlPrv,nTotal)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Indica se a tela sera aberta para digitação			  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lDigita:=IIF(mv_par01==1 .And. !lF040Auto,.T.,.F.)

				cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,,,,,,aDiario)

				If lF040Auto
					HelpInDark(lSetHelp)
					_SetAutoMode(lSetAuto)
					If Type('lMSHelpAuto') == 'L'
						lMSHelpAuto := !lMSHelpAuto
					EndIf
				EndIf


			Endif
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Final do bloco protegido via TTS 						  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	END TRANSACTION

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Finaliza a gravacao dos lancamentos do SIGAPCO            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PcoFinLan("000001")

	If GetNewPar("MV_ACATIVO", .F.) .and. Upper(AllTrim(cOrigem)) = "ACAA680"
		IF ! Empty( cNumra+cCodCur+cPerLet+cDiscip )
			If Val(cPARCELA) == 0
				if GetMV("MV_1DUP") == "1"
					nParcela := ASC(cPARCELA)-55
				Else
					nParcela := ASC(cPARCELA)-64
				EndIf
			Else
				nParcela := val(cPARCELA)
			EndIf
			If cPrefixo $ aPrefixo[__MAT]+"/"+aPrefixo[__MES]+"/"+aPrefixo[__DIS]
				JBE->(dbSetOrder(3)) //ORDEM: JBE_FILIAL+JBE_ATIVO+JBE_NUMRA+JBE_CODCUR+JBE_PERLET+JBE_HABILI+JBE_TURMA
				If JBE->(dbSeek(xFilial("JBE")+"1"+cNumra+cCodCur+cPerLet)) .or. JBE->(dbSeek(xFilial("JBE")+"2"+cNumra+cCodCur+cPerLet))

					if nParcela > 0 .and. nParcela <= len(JBE->JBE_BOLETO)

						If ExistBlock("ACAtAlu1")
							U_ACAtAlu1("JBE")
						EndIf

						JBE->(RecLock("JBE",.F.))
						JBE->JBE_BOLETO := Substr(JBE->JBE_BOLETO,1,nParcela-1)+" "+Substr(JBE->JBE_BOLETO,nParcela+1)
						JBE->(MsUnLock())

						If ExistBlock("ACAtAlu2")
							U_ACAtAlu2("JBE")
						EndIf

					EndIf
				EndIf
			ElseIf cPrefixo $ aPrefixo[__ADA]+"/"+aPrefixo[__TUT]+"/"+aPrefixo[__DEP]
				If nParcela > 0
					JC7->(dbSetOrder(4))
					IF JC7->(dbSeek(xFilial("JC7")+cNumra+cCodCur+cDiscip+cPerLet)) .and. nParcela <= len(JC7->JC7_BOLETO)
						If ExistBlock("ACEXCDP")
							aDiscip := U_ACEXCDP(cNrDoc)
						Else
							Aadd(aDiscip, cDiscip)
						EndIf

						For nDiscip := 1 To Len(aDiscip)
							IF JC7->(dbSeek(xFilial("JC7")+cNumra+cCodCur+aDiscip[nDiscip]+cPerLet))
								While ! JC7->(Eof()) .and. JC7->(JC7_FILIAL+JC7_NUMRA+JC7_CODCUR+JC7->JC7_DISCIP+JC7_PERLET) == xFilial("JC7")+cNumra+cCodCur+aDiscip[nDiscip]+cPerLet
									If  (cPrefixo == aPrefixo[__ADA] .and. ! JC7->JC7_SITDIS == "001") .or.;
										(cPrefixo == aPrefixo[__DEP] .and. ! JC7->JC7_SITDIS == "002") .or. ;
										(cPrefixo == aPrefixo[__TUT] .and. ! JC7->JC7_SITDIS == "006")
										JC7->(dbSkip())
										Loop
									EndIf
									JC7->(RecLock("JC7",.F.))
									JC7->JC7_BOLETO := Substr(JC7->JC7_BOLETO,1,nParcela-1)+" "+Substr(JC7->JC7_BOLETO,nParcela+1)
									JC7->(MsUnLock())
									JC7->(dbSkip())
								EndDo
							EndIf
						Next nDiscip
					Endif
				EndIf
			EndIF
		EndIf
	EndIf
Else
	MsUnlock()
EndIf

If cPaisLoc=="BRA"
	F986LimpaVar()
EndIf
// integração com o PMS

If IntePms() .And. (!Type("lF040Auto") == "L" .Or. !lF040Auto)
	SetKey(VK_F10, Nil)
EndIf

If ExistBlock("Fa040DEL")
	ExecBlock("Fa040DEL")
EndIf

// Integração com SIGAPFS
If lIntPFS .And. FindFunction("JDelTitCR")
	JDelTitCR(cChvTitPFS)
EndIf

dbSelectArea( "SE1" )
dbGoto( nProxReg )
dbSelectArea(cAlias)

Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Natur³ Autor ³ Wagner Xavier 		  ³ Data ³ 28/04/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Calcula os impostos se a natureza assim o mandar			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Natur()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Function FA040Natur( aBases, lBaseM1,lRecalc )
Local lRetorna := .T.
Local lPode := .T.
Local nX := 0
Local nBaseIrrf  := 0
Local nAliquota  := 0

Local lIrrfSE2 := (cPaisLoc == "BRA" .And. SA1->A1_RECIRRF == "2")
Local lAplVlMin	:= .T.
Local lDesMinIR  := IIf(cPaisLoc == "BRA",SA1->A1_MINIRF == "2",.F.)
Local aHelpEng	:= {}
Local aHelpEsp	:= {}
Local aHelpPor	:= {}
//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr	:= FPccBxCr()
Local nPisBx	:= 0
Local nCofBx	:= 0
Local nCslBx	:= 0
//Controla IRPJ na baixa
Local lIrPjBxCr	:= FIrPjBxCr()
//Verifica se retem imposots do RA
Local lRaRtImp  := lFinImp .And. FRaRtImp()
//639.04 Base Impostos diferenciada
Local lBaseImp	:= F040BSIMP(1)	//Verifica a existência dos campos e o calculo de impostos
Local lCamposBase	:= F040BSIMP(2)	//Verifica a existência dos campos apenas
Local lCpoValor	:= "E1_VALOR" $ Upper(AllTrim(ReadVar()))
Local lTabISS		:= .F.
Local lVerMinISS	:= .F.
Local lFina280	:= (Type("lF040Auto") == "L" .and. lF040Auto) .And. AllTrim(Funname()) == "FINA280"
Local aPcc			:= {}

Local nVencto 	:= SuperGetMv("MV_VCPCCR",.T.,1)
Local dRef			:= dDatabase
Local cIssRat	:= SuperGetMv("MV_RTIPESP",,"0")
Local lIssRat	:= ( Left(cIssRat,1) == '0' .And. SuperGetMv("MV_RTIPFIN",,.F.) ) .Or. ;
 						Left(cIssRat,1) == '1'
Local nTamPArc 	:= TAMSX3("E1_PARCELA")[1]
Local nPsimp	:= 0
Local aArea		:= GetArea()

Default lBaseM1	:= .F.
Default lRecalc	:= .F.

lAlt040 := (INCLUI .or. ALTERA)

//Se for um titulo originado pelo Faturamento não devo permitir a alteração do vendedor ou comissão. Pois, os dados ficarão divergentes nos módulos Financeiro e Faturamento.
If !(Altera .And. Alltrim(M->E1_ORIGEM) == "MATA460") .And. !lFina280
	F040Vend()
Endif

lF040Auto	:= Iif(Type("lF040Auto") != "L", .F., lF040Auto )
lDescPCC  	:= Iif(Type("lDescPCC")  <> "L", .F., lDescPCC )
nRecIRRF	:= Iif(Type("nRecIRRF") <> "N", 0, nRecIRRF)

If lRaRtImp  .and. lPccBxCr .and. M->E1_BASEIRF > 0 .and. (!lCpoValor .Or. lRecalc) .and. M->E1_TIPO $ MVRECANT
	M->E1_VALOR		:= M->E1_BASEIRF
	M->E1_VLCRUZ	:= M->E1_BASEIRF
EndIf

If cPaisLoc == "MEX" .And. X3Usado("ED_OPERADT")
	//------------------------------------------------------------------
	// A utilizacao de natureza com operacao de adiantamento habilitada
	// fica restrita para inclusão via fatura de adiantamento
	//------------------------------------------------------------------
	If INCLUI .And. GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+M->E1_NATUREZ,1,"") == "1" .And. !("MATA467N" $ M->E1_ORIGEM)
		Help(" ",,"FA040NATUR",,I18N(STR0151,{AllTrim(RetTitle("ED_OPERADT"))}),1,0) //Não é possivel utilizar naturezas com operação de adiantamento habilitada. Verifique o campo #1[campo]# no cadastro de naturezas.
		Return .F.
	EndIf

	If ALTERA
		//---------------------------------------------------------------------------
		// Alteracao de titulos de adiantamento originados de fatura de adiantamento
		//---------------------------------------------------------------------------
		If (SE1->E1_NATUREZ != M->E1_NATUREZ .Or. SE1->E1_VALOR != M->E1_VALOR) .And. GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+SE1->E1_NATUREZ,1,"") == "1"
			Help(" ",,"FA040NATUR",,STR0152,1,0) //Não é possivel alterar a natureza ou o valor deste titulo, pois a operação de adiantamento está habilitada.
			Return .F.
		EndIf

		//---------------------------------------------------------------------------
		// Valida para nao utilizar natureza com operacao de adiantamento habilitada
		//---------------------------------------------------------------------------
		If GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+SE1->E1_NATUREZ,1,"") != GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+M->E1_NATUREZ,1,"")
			Help(" ",,"FA040NATUR",,I18N(STR0153,{AllTrim(RetTitle("ED_OPERADT"))}),1,0) //Natureza inválida. Verifique o campo #1[campo]# no cadastro de naturezas.
			Return .F.
		EndIf
	EndIf
EndIf

// O array aBases pode ser utilizado quando a base de calculo dos impostos nao for exatamente o valor do titulo
// esta rotina será usada desta forma no módulo Plano de Saúde (SIGAPLS).
If aBases == Nil

	// Base de IR nao entra na regra abaixo (M->E1_VLCRUZ) pois eh apurada a partir de todos os titulos do cliente (ver F040CalcIr).
	nBaseIrrf   := M->E1_VALOR
	nBaseCofins := If( lBaseM1, M->E1_VLCRUZ, M->E1_VALOR )
	nBaseIss    := If( lBaseM1, M->E1_VLCRUZ, M->E1_VALOR )
	nBaseCsll   := If( lBaseM1, M->E1_VLCRUZ, M->E1_VALOR )
	nBasePis    := If( lBaseM1, M->E1_VLCRUZ, M->E1_VALOR )
	nBaseInss	:= If( lBaseM1, M->E1_VLCRUZ, M->E1_VALOR )

	//639.04 Base Impostos diferenciada
	If lBaseImp

		//Para os casos onde foi alterada a natureza e a nova natureza passa a calcular impostos
		//Alimento a base de impostos
		If M->E1_BASEIRF == 0 .or. lCpoValor
			M->E1_BASEIRF :=	M->E1_VALOR
		Endif

		nBaseImp	:= Round(NoRound(xMoeda(M->E1_BASEIRF,M->E1_MOEDA,1,M->E1_EMISSAO,3,M->E1_TXMOEDA),3),2)
		nBaseIrrf   := M->E1_BASEIRF
		If lF040auto
			If nBaseImp > 0
				If F040ImpAut("E1_BASECOF", @nPsimp)
					M->E1_BASECOF := nBaseCofins := aAutoCab[nPsimp,2]
				Else
					nBaseCofins := nBaseImp
				EndIf
				If F040ImpAut("E1_BASECSL", @nPsimp)
					M->E1_BASECSL := nBaseCsll := aAutoCab[nPsimp,2]
				Else
					nBaseCsll   := nBaseImp
				EndIf
				If F040ImpAut("E1_BASEPIS", @nPsimp)
					M->E1_BASEPIS := nBasePis := aAutoCab[nPsimp,2]
				Else
					nBasePis    := nBaseImp
				EndIf
				If F040ImpAut("E1_BASEIRF", @nPsimp)
					M->E1_BASEIRF := nBaseIrrf := aAutoCab[nPsimp,2]
				Else
					nBaseIrrf    := nBaseImp
				EndIf
			EndIf
		Else
			nBaseCofins := nBaseImp
			nBaseCsll   := nBaseImp
			nBasePis    := nBaseImp
		EndIf
		nBaseIss	:= nBaseImp
		nBaseInss	:= nBaseImp
	Endif

Else
	nBaseIrrf   := aBases[1]			// Base IRRF
	nBaseCofins := aBases[2]            // Base Cofins
	nBaseIss    := aBases[3]            // Base Iss
	nBaseCsll   := aBases[4]			// Base Csll
	nBasePis    := aBases[5]            // Base Pis
	nBaseInss   := aBases[6]            // Base Inss
Endif

If M->E1_TIPO = "DDI" .Or. ; // Nao calcula impostos quando utilizar multiplas naturezas
   M->E1_TIPO $ MV_CRNEG .or.;  // Não se calcula imposto do tipo NCC
   f40IsDesdobr()
   M->E1_IRRF		:= 0
   M->E1_ISS		:= 0
   M->E1_INSS		:= 0
   M->E1_CSLL		:= 0
   M->E1_COFINS	:= 0
   M->E1_PIS		:= 0
   Return .T.
ElseIf Empty(M->e1_naturez)
	Return .T.
EndIf

//Quando rotina automatica, caso sejam enviados os valores dos impostos nao devo recalcula-los.
If lF040Auto .and. !lAltera .and. (M->E1_IRRF+M->E1_ISS+M->E1_INSS+M->E1_PIS+M->E1_CSLL+M->E1_COFINS > 0 )
	Return .T.
EndIF

If lAltera

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Nao permite alterar natureza se titulo ja sofreu baixa    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !Empty(SE1->E1_BAIXA) .And. "E1_NATUREZ" $ Upper(AllTrim(ReadVar()))
		Help(" ",1,"FA040BAIXA")
		Return .F.
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ N„o permite alterar natureza se titulo ja foi contabiliz. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ExistBlock("F040ALN")
		lPode := ExecBlock("F040ALN",.F.,.F.)
	Endif

	If !lPode .and. SE1->E1_LA == "S" .and. SED->(DbSeek(xFilial("SED")+M->E1_NATUREZ))
		For nX := 1 To SED->(FCount())
			If "_CALC" $ SED->(FieldName(nX))
				lPode := !SED->(FieldGet(nX)) $ "1S" // So permite alterar se nao calcular impostos
				If !lPode // No primeiro campo que calcula impostos, nao permite alterar
					Help(" ",1,"NOALTNAT")  //"Não é possível a alteração da natureza pois a mesma pode alterar o valor do titulo."
					Return .F.
				Endif
			Endif
		Next
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ N„o permite alterar natureza quando adiantamento para n„o ³
	//³ desbalancear o arquivo de Movimenta‡„o Banc ria (SE5).    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SE1->E1_TIPO $ MVRECANT .and. M->E1_NATUREZ != SE1->E1_NATUREZ
		Help(" ",1,"FA040NONAT")
		Return .F.
	Endif

	If M->E1_NATUREZ != SE1->E1_NATUREZ
		lAlterNat := .T.
	Endif


	If SE1->E1_TIPO $ MVABATIM
		Return .T.
	Endif

Endif

dbSelectArea("SED")
dbSetOrder(1)
//Verifico a existencia do codigo de natureza e se está bloqueado.
//RegistroOk verifica o bloqueio (LIB)
//ExistCpo() não funcionava neste caso pois nao posiciona no registro do codigo digitado,
//voltando para ultimo posicionamento do SED antes da execucao da rotina.
If !(DbSeek(xFilial("SED")+M->E1_NATUREZ)) .or. !(ExistCpo("SED",M->E1_NATUREZ))
	Help(" ",1,"E1_NATUREZ")
	lRetorna := .F.
Else

   //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Tratamento dos campos dos impostos Brasileiros E1_IRRF,	  ³
	//³ E1_INSS, etc...													     ³
	//ÀÄTransp DM Argentina Lucas e Armando 05/01/00ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If m->e1_valor > 0 .and. cPaisLoc=="BRA"

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Calcula IRRF se natureza mandar                        	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//Verifica se o IRRF nao veio no array de campos da rotina automatica
		If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_IRRF"))

			If lAltera .And. (SED->ED_CALCIRF == "S" .Or. F040ChkOldNat(SE1->E1_NATUREZ,1))
	   		   	m->e1_irrf := 0
	  		ElseIf !lAltera
	  			m->e1_irrf := 0
	  		EndIf

			If aBases == Nil
				//Se existir redutor da base do IR, calcular nova base
				If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|PAD|PAN|PAR|PER|POR|PTG|SAL|TRI|URU|VEN" .and. SED->ED_BASEIRF > 0
					nBaseIrrf := m->e1_valor * (SED->ED_BASEIRF/100)
				Endif
		   	Endif

			//Se for rotina automática e a base de IR estiver gravada, utilizo esse valor
	   		If lF040Auto .And. M->E1_BASEIRF > 0
	   			nBaseIrrf := IIF(M->E1_BASEIRF <> SE1->E1_BASEIRF .And. FwIsInCallStack("FA040Alter") .and.;
	   				 M->E1_TIPO <> "FT ",SE1->E1_BASEIRF,M->E1_BASEIRF)
	   			If nBaseIrrf == 0 .And. SE1->E1_BASEIRF == 0
	   				nBaseIrrf := M->E1_BASEIRF
	   			EndIf
	   		EndIf

			If ED_CALCIRF == "S"
				m->e1_irrf := F040CalcIr(nBaseIrrf,aBases,.T.)
			EndIf
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Calcula ISS se natureza mandar                         	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//Verifica se o ISS nao veio no array de campos da rotina automatica
		If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_ISS"))
			If !lIssRat .And. SE1->E1_DESDOBR == '1' .And. M->E1_VALOR > 0
				 If (Val(M->E1_PARCELA) == 1 .Or. M->E1_PARCELA == Iif( nTamParc > 1, StrZero(0,Len(M->E1_PARCELA)-1) + "A", "A" ) )
				 	nBaseIss := SE1->E1_VALOR
				 Else
				 	nBaseIss := 0
				 EndIf
			EndIf

  			If lAltera .And. (SED->ED_CALCISS == "S" .Or. F040ChkOldNat(SE1->E1_NATUREZ,2))
				m->e1_iss  := 0
	  		ElseIf !lAltera
				m->e1_iss  := 0
			EndIf

			If ED_CALCISS == "S".and. (SA1->A1_RECISS != "1" .Or. GetNewPar("MV_DESCISS",.F.))
				// Obtem a aliquota de ISS da tabela FIM - Multiplos Vinculos de ISS
				If cPaisLoc == "BRA"
					If !Empty( M->E1_CODISS )
						lTabISS	:= .T.
					EndIf
				EndIf

				If lTabISS
					DbSelectArea( "FIM" )
					FIM->( DbSetOrder( 1 ) )
					If FIM->( DbSeek( xFilial( "FIM" ) + M->E1_CODISS ) )
						m->e1_iss  := nBaseIss * FIM->FIM_ALQISS / 100
					EndIf
				Else
					nAliquota := GetMV("MV_ALIQISS")
					If IntTms() .And. nModulo == 43 //TMS
						//-- Verifica se foi informada a aliquota do ISS para regiao
						nAliqISS := Posicione("DUY",1,xFilial("DUY")+SA1->A1_CDRDES,"DUY_ALQISS")
						If nAliqISS > 0
							nAliquota:= nAliqISS
						EndIf
					EndIf
					m->e1_iss  := nBaseIss * nAliquota / 100
				EndIf

				//Ponto de entrada para calculo alternativo do ISS
				If ExistBlock("FA040ISS")
					M->E1_ISS := ExecBlock("FA040ISS",.F.,.F.,nBaseIss)
				Endif
			EndIf

			If lRaRtImp .and. m->e1_tipo $  MVRECANT
				M-> E1_PRISS := M->E1_ISS
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Titulos Provisorios ou Antecipados n†o geram ISS       	  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If m->e1_tipo $ MVPROVIS+"/"+MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM
				m->e1_iss := 0
			EndIf

			//Posiciono na tabela de cliente para verificar o tipo de retenção de ISS
			DbSelectArea("SA1")
			SA1->(DbSetOrder(1))
			SA1->(DbSeek(xFilial("SA1")+M->E1_CLIENTE+M->E1_LOJA))
			If SA1->A1_FRETISS == "1" //Considera valor minimo (MV_VRETISS)
				lVerMinISS := .T.
			EndIf
			//Se considera valor minimo de ISS, verifico o conteudo do parametro MV_VRETISS
			//Caso contrario, verifico a base de retencao para S. Bernardo do Campo
			//Mesmo tratamento utilizado no FINA050 (funcao FA050ISS())
			If (lVerMinISS .And. M->E1_ISS <= SuperGetMv("MV_VRETISS",.F., 0))
				M->E1_ISS := 0
			EndIf
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Calcula INSS se natureza mandar                        	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//Verifica se o INSS nao veio no array de campos da rotina automatica
		If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_INSS"))

  			If lAltera .And. (SED->ED_CALCINS == "S" .Or. F040ChkOldNat(SE1->E1_NATUREZ,3))
				m->e1_inss  := 0
	  		ElseIf !lAltera
				m->e1_inss  := 0
			EndIf

			nInss := CalcINSS(nBaseInss)
			/*

			If SED->ED_CALCINS == "S" .and. SA1->A1_RECINSS == "S"
				If !Empty(SED->ED_BASEINS)
					nBaseInss := NoRound((nBaseInss * (SED->ED_BASEINS/100)),2)
				EndIf
				m->e1_inss := (nBaseInss * (SED->ED_PERCINS / 100))
			EndIf

			If lRaRtImp .and. m->e1_tipo $  MVRECANT
				M-> E1_PRINSS := M->E1_INSS
			EndIf
			*/

			M->E1_INSS := nInss

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Titulos Provisorios ou Antecipados n†o geram INSS         ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If m->e1_tipo $ MVPROVIS+"/"+MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM
				m->e1_inss := 0
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Tratamento de Dispensa de Retencao de Inss             	  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If ( M->E1_INSS < GetNewPar("MV_VLRETIN",0) )
				M->E1_INSS := 0
			EndIf
		Endif

	    If M->E1_EMISSAO < dLastPcc
			//³ Calcula CSLL se natureza mandar                        	  ³
			If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_CSLL"))

	  			If lAltera .And. (SED->ED_CALCCSL == "S" .Or. F040ChkOldNat(SE1->E1_NATUREZ,4))
					m->e1_csll  := 0
		  		ElseIf !lAltera
					m->e1_csll  := 0
				EndIf

				If SED->ED_CALCCSL == "S" .and. SA1->A1_RECCSLL $ "S#P"
					If ! GetNewPar("MV_RNDCSL",.F.)
						m->e1_csll := NoRound((nBaseCsll * (SED->ED_PERCCSL / 100)),2)
					Else
					m->e1_csll := Round(nBaseCsll * (SED->ED_PERCCSL / 100),GetMv("MV_RNDPREC"))
					Endif
					M->E1_BASECSL := nBaseCsll
				EndIf
			Endif

			//³ Calcula COFINS se natureza mandar                      	  ³
			If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_COFINS"))

	  			If lAltera .And. (SED->ED_CALCCOF == "S" .Or. F040ChkOldNat(SE1->E1_NATUREZ,5))
					m->e1_cofins  := 0
		  		ElseIf !lAltera
					m->e1_cofins  := 0
				EndIf

				If SED->ED_CALCCOF == "S" .and. SA1->A1_RECCOFI $ "S#P"
					If ! GetNewPar("MV_RNDCOF",.F.)
						m->e1_cofins := NoRound((nBaseCofins * (Iif(SED->ED_PERCCOF>0,SED->ED_PERCCOF,GetMv("MV_TXCOFIN")) / 100)),2)
					Else
						m->e1_cofins := Round(nBaseCofins * (Iif(SED->ED_PERCCOF>0,SED->ED_PERCCOF,GetMv("MV_TXCOFIN")) / 100),GetMv("MV_RNDPREC"))
					Endif
					M->E1_BASECOF := nBaseCofins
				EndIf
			Endif

			//³ Calcula PIS se natureza mandar 	                     	  ³
			If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_PIS"))
	  			If lAltera .And. (SED->ED_CALCPIS == "S" .Or. F040ChkOldNat(SE1->E1_NATUREZ,6))
					m->e1_pis  := 0
		  		ElseIf !lAltera
					m->e1_pis  := 0
				EndIf

				If SED->ED_CALCPIS == "S" .and. SA1->A1_RECPIS $ "S#P"
					If ! GetNewPar("MV_RNDPIS",.F.)
						m->e1_pis := NoRound((nBasePis * (Iif(SED->ED_PERCPIS>0,SED->ED_PERCPIS,GetMv("MV_TXPIS")) / 100)),2)
					Else
					m->e1_pis := Round(nBasePis * (Iif(SED->ED_PERCPIS>0,SED->ED_PERCPIS,GetMv("MV_TXPIS")) / 100),GetMv("MV_RNDPREC"))
					Endif
					M->E1_BASEPIS := nBasePis
				EndIf
			Endif

		Else

			If nVencto == 2
				dRef := M->E1_VENCREA
			ElseIf nVencto == 1 .OR. EMPTY(nVencto)
				dRef := M->E1_EMISSAO
			ElseIf nVencto == 3
				dRef := M->E1_EMIS1
			Endif

			aPcc	:= newMinPcc(dRef, nBasePis,M->E1_NATUREZ,"R",SA1->A1_COD+SA1->A1_LOJA)

			If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_PIS"))
				M->E1_PIS		:= aPcc[2]
			Endif

			If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_COFINS"))
				M->E1_COFINS	:= aPcc[3]
			Endif

			If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_CSLL"))
				M->E1_CSLL		:= aPcc[4]
			Endif
		EndIf

		// Titulos Provisorios ou Antecipados não geram PCC
		If (M->E1_TIPO $ MVPROVIS+"/"+MV_CRNEG+"/"+MVABATIM) .or. (!lRartImp .and. M->E1_TIPO $ MVRECANT)
				M->E1_PIS := 0
				M->E1_COFINS := 0
				M->E1_CSLL := 0
		EndIf
		//Verificar ou nao o limite de 5000 para Pis cofins Csll
		// 1 = Verifica o valor minimo de retencao
		// 2 = Nao verifica o valor minimo de retencao
		If M->E1_APLVLMN == "2"
			lAplVlMin := .F.
		Endif

		nVlOriCof	:= 0
		nVlOriCsl	:= 0
		nVlOriPis	:= 0
		nPisBx		:= m->e1_pis
		nCofBx		:= m->e1_cofins
		nCslBx		:= m->e1_csll
		//Caso PCC abatido na emissao
		//Caso exista calculo de PCC
		//Caso se aplique valor minimo a este titulo
		//Efetua tratamento de verificacao de pendencias de abatimento
		If !lPccBxCr .and. ((m->e1_pis + m->e1_cofins + m->e1_csll > 0) .and. lAplVlMin)
			FVERABTIMP()
		ElseIf lRaRtImp .and. (lPccBxCr .or. lIRPJBxCr) .and. ((m->e1_pis + m->e1_cofins + m->e1_csll + m->e1_irrf > 0) .and. lAplVlMin)

			If  m->e1_tipo $ MVRECANT
				FVerImpRet()
				lDescPCC := (M->E1_PIS + M->E1_COFINS + M->E1_CSLL > 0)
				If lDescPCC
					M->E1_VALOR 	-= (M->E1_IRRF + M->E1_PIS + M->E1_COFINS + M->E1_CSLL + If(lRaRtImp,M->E1_PRISS + M->E1_PRINSS,0))
				Else
					M->E1_VALOR 	-= (M->E1_IRRF)
					M->E1_PIS		:= nPisBx
					M->E1_COFINS	:= nCofBx
					M->E1_CSLL		:= nCslBx

					If lRaRtImp
						M->E1_VALOR -=	(M->E1_PRISS + M->E1_PRINSS)
					EndIf
				EndIf
			EndIf
		Elseif lRaRtImp .and. m->e1_tipo $ MVRECANT
		   	M->E1_VALOR -=	(M->E1_PRISS + M->E1_PRINSS)
		Endif
	EndIf

	//639.04 Base Impostos diferenciada
	//Caso nao exista calculo de imposto, o campo base de imposto será zerado
	If !lBaseImp .and. lCamposBase .and. !(m->e1_irrf + m->e1_iss + m->e1_inss + m->e1_pis + m->e1_cofins + m->e1_csll > 0 )
	   	M->E1_BASEIRF := 0
	Endif

	If m->e1_naturez$&(GetMv("MV_IRF")) 	.or. ;
		m->e1_naturez$&(GetMv("MV_ISS")) 	.or. ;
		m->e1_naturez$&(GetMv("MV_INSS")) 	.or. ;
		m->e1_naturez$ (GetMv("MV_CSLL"))	.or. ;
		m->e1_naturez$ (GetMv("MV_COFINS")) .or. ;
		m->e1_naturez$ (GetMv("MV_PISNAT"))

		m->e1_tipo  := MVTAXA
		m->e1_tipo	:= IIF(m->e1_naturez$ (GetMv("MV_CSLL"))	,"MVCSABT", m->e1_tipo)
		m->e1_tipo	:= IIF(m->e1_naturez$ (GetMv("MV_COFINS")),"MVCFABT-", m->e1_tipo)
		m->e1_tipo	:= IIF(m->e1_naturez$ (GetMv("MV_PISNAT")),"MVPIABT", m->e1_tipo)
	EndIf
EndIf
If cPaisLoc == "BRA"
	If lRaRtImp .and. lPccBxCr .and. M->E1_BASEIRF > 0 .and. (!lCpoValor .OR. lF040Auto)
		If M->E1_MOEDA > 1 .And. M->E1_VLCRUZ > 0
			M->E1_VLCRUZ:=Round(NoRound(xMoeda(M->E1_VALOR,M->E1_MOEDA,1,M->E1_EMISSAO,3,M->E1_TXMOEDA),3),2)
		Else
			M->E1_VLCRUZ	:= M->E1_VALOR
		Endif
	EndIf
EndIf
RestArea(aArea)
Return lRetorna

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Tipo ³ Autor ³ Wagner Xavier 		  ³ Data ³ 30/04/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Checa o Tipo do titulo informado 								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Tipo() 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Tipo()
Local nOpca := 0
Local lRetorna := .T.
Local nRegistro
Local oDlg
Local nPos := 0
Local cTipo := ""
Local lInclTit	:= IIF(TYPE("INCLUI")<>"U",INCLUI,.F.)

If cPaisLoc == "BRA"
	If Type("aRecnoAdt") != "U" .and. (FunName() = "MATA410" .or. FunName() = "MATA460A" .or. FunName() = "MATA460B")
		If !M->E1_TIPO $ MVRECANT
			Aviso(STR0064,STR0108,{ "Ok" }) // "ATENCAO"#"Por tratar-se de título para processo de adiantamento, é obrigatório que o tipo do título seja 'RA', ou a correspondente a adiantamento."
			Return(.F.)
		Endif
	Endif
Endif

If ( lF040Auto ) .AND. cPaisLoc == "EQU" .and. !lInclTit //somente para equador.
	nPos := Ascan(aAutoCab,{|x| Alltrim(x[1]) == "E1_TIPO"})
	If nPos > 0
		cTipo := aAutoCab[nPos] [2]
	EndIf
	M->E1_PREFIXO 	:= SE1->E1_PREFIXO
	M->E1_NUM 		:= SE1->E1_NUM
	M->E1_TIPO 		:= cTipo
	M->E1_PARCELA 	:= SE1->E1_PARCELA
	M->E1_CLIENTE 	:= SE1->E1_CLIENTE
	M->E1_LOJA 		:= SE1->E1_LOJA
EndIF

lF040Auto	:= Iif(Type("lF040Auto") != "L", .F., lF040Auto )
nMoedAdt  := Iif( Empty(nMoedAdt), M->E1_MOEDA, nMoedAdt )

dbSelectArea("SE1")
nRegistro:=Recno()
dbSetOrder(1)

dbSelectArea("SX5")
If !dbSeek(xFilial("SX5")+"05"+m->e1_tipo)
	Help(" ",1,"E1_TIPO")
	lRetorna := .F.
ElseIf lF040Auto .and. SE1->(DbSeek(xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela+m->e1_tipo)) .and. ALTERA
	lRetorna := .T.
ElseIf m->e1_tipo $ MVRECANT
	dbSelectArea("SE5")
	dbSetOrder(7)
	If dbSeek(xFilial("SE5")+m->e1_prefixo+m->e1_num+m->e1_parcela+m->e1_tipo)
		Help(" ",1,"RA_EXISTIU")
		lRetorna := .F.
	Endif
Elseif !NewTipCart(m->e1_tipo,"1")
	Help(" ",1,"TIPOCART")
	lRetorna := .F.
Else
	dbSelectArea("SE1")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Se for abatimento, herda os dados do titulo³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If m->e1_tipo $ MVABATIM .and. !Empty(m->e1_num)
		If !(dbSeek(xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela))
			Help(" ",1,"FA040TIT")
			lRetorna:=.F.
		Else
			IF SE1->E1_SALDO = 0
				Help(" ",1,"FA040ABB")
				lRetorna:=.F.
			EndIf
		Endif
		dbGoTo(nRegistro)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Caso seja titulo de adiantamento, nao posso gerar tit.abatimento ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		IF lRetorna .and. m->e1_tipo $ MVABATIM
			dbSelectArea( "SE1" )
			lRet := .F.
			IF dbSeek(xFilial("SE1")+ m->e1_prefixo + m->e1_num + m->e1_parcela )
				While !Eof() .and. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == ;
								xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela
					If SE1->E1_TIPO $ MVABATIM+"/"+MV_CRNEG+"/"+MVRECANT
						dbSkip()
						Loop
					Else
						lRet := .T.
						nRegistro:= SE1->(Recno())
						Exit
					Endif
				Enddo
			Endif
			If !lRet
				Help(" ",1,"FA040TITAB")
				dbGoTo(nRegistro)
				lRetorna:=.F.
			Endif
		Endif
	EndIf
	If lRetorna .and. (dbSeek(xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela+m->e1_tipo))
		Help(" ",1,"FA040NUM")
		dbGoTo(nRegistro)
		lRetorna:=.F.
	Else
		dbGoTo(nRegistro)
		cTitPai:=SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)
	Endif
	If lRetorna .and. !(SE1->E1_TIPO $ MVABATIM) .and. m->e1_tipo $ MVABATIM .and. SE1->E1_SALDO > 0

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ CASO SEJA TITULO DE ADIANTAMENTO, NAO POSSO GERAR TIT.ABATIMENTO ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Fa040Herda()
		dbSelectArea("SE1")
		If (dbSeek(xFilial("SE1") + m->e1_prefixo + m->e1_num + m->e1_parcela + m->e1_tipo))
			Help(" ",1,"FA040NUM")
			m->e1_num := Space(6)
			dbGoTo(nRegistro)
			lRefresh	:= .T.
			lRetorna	:=.F.
		Endif
		dbSelectArea( "SE1" )
		lRet := .F.

		//Verifico se os dados herdados nao pertencem a um titulo de adiantamento
		dbGoTo(nRegistro)
		IF dbSeek(xFilial("SE1")+ m->e1_prefixo + m->e1_num + m->e1_parcela )
			While !Eof() .and. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == ;
							xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela
				If SE1->E1_TIPO $ MVABATIM+"/"+MV_CRNEG+"/"+MVRECANT
					dbSkip()
					Loop
				Else
					lRet := .T.
					Exit
				Endif
			Enddo
		Endif
		If !lRet
			Help(" ",1,"FA040TITAB")
			dbGoTo(nRegistro)
			lRetorna:=.F.
		Endif
	EndIf
	If lRetorna .and. (	m->e1_naturez$&(GetMv("MV_IRF"))		.or.;
								m->e1_naturez$&(GetMv("MV_ISS"))		.or.;
							 	m->e1_naturez$&(GetMv("MV_INSS"))		.or.;
								m->e1_naturez== GetMv("MV_CSLL")			.or.;
								m->e1_naturez== GetMv("MV_COFINS")		.or.;
								m->e1_naturez== GetMv("MV_PISNAT") )	.and.;
								!(m->e1_tipo $ MVTAXA)
		Help(" ",1,"E1_TIPO")
		lRetorna := .F.
	EndIf
	If m->e1_tipo $ MVPAGANT+"/"+MV_CPNEG .and. lRetorna
		Help(" ",1,"E1_TIPO")
		lRetorna := .F.
	EndIf
EndIf
If M->E1_TIPO $ MVRECANT .and. ! lF040Auto .and. lRetorna
	While .T.
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Mostra Get do Banco de Entrada								³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nOpca := 0
		DEFINE MSDIALOG oDlg FROM 100, 000 TO 250, 235 TITLE STR0012 PIXEL 	// "Local de Entrada"
		@	006, 005 	Say STR0013   Of oDlg PIXEL // "Banco : "

		If cPaisLoc == "BRA"
			@	005, 040	MSGET cBancoAdt F3 "SA6" Valid CarregaSa6( @cBancoAdt,,,,,,, @nMoedAdt ) Of oDlg HASBUTTON PIXEL
		Else
			@	005, 040	MSGET cBancoAdt F3 "SA6" Valid CarregaSa6( @cBancoAdt ) Of oDlg HASBUTTON PIXEL
		EndIf

				@	021, 005 	Say STR0014  Of  oDlg PIXEL		// "Agˆncia : "
		@	020, 040	MSGET cAgenciaAdt Valid CarregaSa6(@cBancoAdt,@cAgenciaAdt) Of oDlg PIXEL
		@	036, 005 	Say STR0015  Of  oDlg PIXEL		// "Conta : "
		@	035, 040	MSGET cNumCon Picture "@S60" Valid CarregaSa6(@cBancoAdt,@cAgenciaAdt,@cNumCon,,,.T.) SIZE 75, 10 Of oDlg PIXEL

		@	001, 001 TO 055, 120 OF oDlg PIXEL

		DEFINE SBUTTON FROM 060,092  TYPE 1 ACTION (nOpca := 1,If(!Empty(cBancoAdt).and. CarregaSa6(@cBancoAdt,@cAgenciaAdt,@cNumCon,,,.T.,, @nMoedAdt),oDlg:End(),nOpca:=0)) ENABLE OF oDlg PIXEL

		ACTIVATE MSDIALOG oDlg CENTERED

		IF nOpca != 0
			//Ajusta a modalidade de pagamento para 1 = STR. Adiantamento eh sempre STR
			If SpbInUse()
				m->e1_modspb := "1"
			Endif

			If cPaisLoc == "BRA"
				M->E1_MOEDA := nMoedAdt
			EndIf

			lRetorna := .T.
			Exit
		EndIF
	Enddo
EndIf
Return lRetorna

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Venc ³ Autor ³ Wagner Xavier 		  ³ Data ³ 29/05/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica a data de vencimento informada						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Venc() 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Venc()
Local lRetorna := .T.,nRetencao:=0,nVar
Local lF040RECIMP := ExistBlock("F040RECIMP")
Local lRecalImp	:= .F. // Padrao deve ser .F. pois levamos em conta que na nota já foi contabilizado/considerado os impostos e inclusive valores já enviados ao livros fiscais.

Static lAlt040 := .F.

If cPaisLoc == "BRA"
	F040VcRea()
Endif

// A validacao da FunName, visa atender a chamada via FINA280 na geracao de uma fatura, em que
// naquele programa ha um ponto de entrada F280DTVC em que o usuario podera informar uma data de
// vencimento menor que a data base do sistema.
If M->E1_VENCTO < M->E1_EMISSAO .And. FunName() != "FINA280"
	Help(" ",1,"NOVENCTO")
	lRetorna := .F.
Else
	If Empty(M->E1_VENCORI) .or. !lAltera
		M->E1_VENCORI := M->E1_VENCTO
	EndIf
	IF lAltera
		M->E1_VENCREA:=M->E1_VENCTO
		//SITCOB
		//Titulos em carteira
		IF FN022SITCB(SE1->E1_SITUACA)[1]
			M->E1_VENCREA := DataValida(M->E1_VENCTO,.T.)

		//Para titulos que não estejam em carteira, verifica-se a retenção bancaria
		Else
			dbSelectArea("SA6")
			dbSeek(xFilial("SA6")+SE1->E1_PORTADO+SE1->E1_AGEDEP+SE1->E1_CONTA)
			nRetencao:=SA6->A6_RETENCA

			M->E1_VENCREA := DataValida(M->E1_VENCTO,.T.)

			If nRetencao > 0
				For nVar := 1 to nRetencao
					M->E1_VENCREA := DataValida(M->E1_VENCREA+1,.T.)
				Next nVar
			Endif
		EndIF
		If lF040RECIMP
			lRecalImp := ExecBlock("F040RECIMP",.F.,.F.)
		Endif
		// Se alterou o mes/ano de vencimento, recalcula os impostos. Quando for proveniente de outro módulo, pelo fato de contabilizações,
		// apurações e valores já enviados para o livros fiscais, não podemos recalculas os impostos. Ainda podemos ter na nota produtos que não
		// calculariam certos impostos e o SIGAFIN não conseguirá entender esta diferenciação de valores, se baseando somente no valor e natureza.
		// Incluimos o ponto de entrada F040RECIMP para possibilitar o cliente a recalcular os impostos caso seja de seu desejo.
		// Consultar chamado TDXS12 caso necessario
		If Left(Dtos(M->E1_VENCREA),6) != Left(Dtos(SE1->E1_VENCREA),6) .AND. ("FIN" $ UPPER(M->E1_ORIGEM) .Or. lRecalImp )
			Fa040Natur()
		Endif
		If lAlt040
			Fa040Natur()
		Endif
	Else
		M->E1_VENCREA := DataValida(M->E1_VENCTO,.T.)
		If lAlt040
			Fa040Natur()
		Endif
	EndIF
	dbSelectArea("SE1")
EndIf

IF ExistBlock("F040VENCR")
	M->E1_VENCREA := ExecBlock("F040VENCR",.F.,.F.,{})
EndIf

Return lRetorna

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Comis³ Autor ³ Wagner Xavier 		  ³ Data ³ 24/09/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Verifica a validade da comissao digitada						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040	//Compatibilizar com SX3							     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Comis()
Local lRet:=.T.
IF (Empty(m->e1_vend1) .and. m->e1_comis1>0) .or. ;
	(Empty(m->e1_vend2) .and. m->e1_comis2>0) .or. ;
	(Empty(m->e1_vend3) .and. m->e1_comis3>0) .or. ;
	(Empty(m->e1_vend4) .and. m->e1_comis4>0) .or. ;
	(Empty(m->e1_vend5) .and. m->e1_comis5>0)
	Help(" ",1,"FALTAVEND")
	lRet:=.f.
EndIF
Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³Fa040Subst³ Autor ³ Wagner Xavier 		  ³ Data ³ 18/05/93 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Rotina para substituicao de titulos provisorios.			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Subst(ExpC1,ExpN1,ExpN2) 									  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo											  ³±±
±±³			 ³ ExpN1 = Numero do registro 										  ³±±
±±³			 ³ ExpN2 = Numero da opcao selecionada 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Subst(cAlias,nReg,nOpc)
Local nOpcA
Local cIndex	:=""
Local lInverte := .F.
Local lSubs := .F.
Local lPadrao   := .F.
Local cPadrao   := "503"
Local cArquivo  := ""
Local nHdlPrv   := 0
Local nTotal    := 0
Local lDigita
Local nRecSubs  := 0
Local oDlg,oDlg1
Local oValor  		:= 0
Local oQtdTit 		:= 0
Local aCampos		:= {}
Local nHdlLock
Local aMoedas		:= {}
Local aOutMoed		:= {STR0049,STR0050}	//"1=Nao Considera"###"2=Converte"
Local cOutMoeda	:= "1"
Local oCbx, oCbx2
Local cMoeda		:= "1"
Local cSimb
Local aButtons		:= {}
Local aChaveLbn	:= {}
Local aSize := {}
Local oPanel
Local aGravaAFT := {}
Local aArea := GetArea()
Local aAreaAFT := AFT->(GetArea())
Local aVetor     := {}

//Substituicao automatica
Local cFIHSeq	 := ""   // Armazena Sequencial gerado na baixa (SE5)
Local cPrefOri   := ""   // Armazena prefixo do titulo PR
Local cNumOri    := ""   // Armazena numero do titulo PR
Local cParcOri   := ""   // Armazena parcela do titulo PR
Local cTipoOri   := ""   // Armazena tipo do titulo PR
Local cCfOri     := ""   // Armazena cliente/fornecedor do titulo PR
Local cLojaOri   := ""   // Armazena loja do titulo PR
Local cPrefDest  := ""   // Armazena prefixo do titulo NF
Local cNumDest   := ""   // Armazena numero do titulo NF
Local cParcDest  := ""   // Armazena parcela do titulo NF
Local cTipoDest  := ""   // Armazena tipo do titulo NF
Local cCfDest    := ""   // Armazena cliente/fornecedor do titulo NF
Local cLojaDest  := ""   // Armazena loja do titulo NF
Local cFilDest	 := ""   // Armazena filial de destino do titulo NF
Local dDtEmiss   := dDatabase  // Variavel para armanzenar a data de emissao do titulo

Local nI      :=  0
Local nPosPre :=  0
Local nPosNum :=  0
Local nPosPar :=  0
Local nPosTip :=  0
Local nPosFor :=  0
Local nPosLoj :=  0
Local lF040Prov := ExistBlock("F040PROV")
Local lF40DelPr := ExistBlock("F40DELPR")
Local lDelProvis := If(lF40DelPr, ExecBlock("F40DELPR",.F.,.F.), .F.)
Local lNewAutom	 := Len(aItnTitPrv) > 0
Local nRecProv   := 0
Local nMvpar140	:= mv_par01
Local aAreaProv	:= {}
Local lRet		:= .T.
Local cSimb		:= SuperGetMv("MV_SIMB",,"")

//Validação da Integração RM Classis
Local cProdRM		:= GETNEWPAR('MV_RMORIG', "")

PRIVATE cCodigo	:=CriaVar("A1_COD",.F.)
PRIVATE cLoja		:=CriaVar("A1_LOJA")
PRIVATE nQtdTit 	:= 0
PRIVATE oMark		:= 0
PRIVATE nValorS		:= 0
PRIVATE nMoedSubs	:= 1
PRIVATE aTitulo2CC  := {}

lPadrao:=VerPadrao(cPadrao)
nOpc	:= 3

lDelProvis := If(ValType(lDelProvis) != "L",.F.,lDelProvis)


If HasTemplate("LOT") .And.;
	((SE1->(FieldPos("E1_NCONTR"))>0) .And. !(Vazio(SE1->E1_NCONTR)))

	Alert(STR0092)
	Return
EndIf
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ A ocorrencia 23 (ACS), verifica se o usuario poder  ou n„o   ³
//³ efetuar substituicao de titulos provisorios.					  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF !ChkPsw( 23 )
	Return
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Para titulo e-Commerce nao pode ser alterado ou substituido                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If  LJ861EC01(SE1->E1_NUM, SE1->E1_PREFIXO, .F./*NaoTemQueTerPedido*/, SE1->E1_FILORIG)
	Help(" ",1,"FA040TMS",," SIGALOJA - e-Commerce!",3,1) //Este titulo nao podera ser alterado pois foi gerado por outro modulo
	Return .F.
EndIf

//Se veio atraves da integracao Protheus X Classis nao Pode ser alterado
If (!Type("lF040Auto") == "L" .Or. !lF040Auto) .and.  Upper(AllTrim(SE1->E1_ORIGEM))$ cProdRM
	HELP(" ",1,"ProtheusXClassis" ,,STR0205,2,0,,,,,, {STR0207})//"Título gerado pela Integração Protheus X Classis não Pode ser alterado pelo Protheus" ## "Efetue a substituição do titulo pelo sistema RM Clasis"
	Return
Endif

If !Empty(SE1->E1_MDCONTR)
	Aviso(OemToAnsi(STR0039),OemToAnsi(STR0091),{"Ok"})//"Atencao" ### "Este titulo foi gerado pelo módulo SIGAGCT e não pode ser utilizado para substituição."
	Return
EndIf

//Ponto de entrada FA040BLQ
//Ponto de entrada utilizado para permitir ou nao o uso da rotina
//por um determinado usuario em determinada situacao
IF ExistBlock("F040BLQ")
	lRet := ExecBlock("F040BLQ",.F.,.F.)
	If !lRet
		Return .T.
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento n„o ‚ menor que data limite de ³
//³ movimentacao no financeiro    										  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !DtMovFin(,,"2")
	Return
Endif

//---------------------------------------------------------
// Nao permite a substituicao para titulos com operacao de
// adiantamento habilitada - Majejo de Anticipo
//---------------------------------------------------------
If cPaisLoc == "MEX" .And.;
	Upper(Alltrim(SE1->E1_Origem)) $ "FINA087A" .And.;
	SE1->E1_TIPO == Substr(MVRECANT,1,3) .And.;
	X3Usado("ED_OPERADT") .And.;
	GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+SE1->E1_NATUREZ,1,"") == "1"

	Help(" ",,"FA040SUBST",,I18N(STR0154,{AllTrim(RetTitle("ED_OPERADT"))}),1,0) //Processo não permitido. A natureza do titulo possui operação de adiantamento habilitada. Verifique o campo #1[campo]# no cadastro de naturezas.
	Return
EndIf

If ! lF040Auto

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa array com as moedas existentes.						  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aMoedas := FDescMoed()
	While .T.

		nOpca := 0
		cSimb := Pad(cSimb+Alltrim(STR(nMoedSubs)),4)+":"

		aSize := MSADVSIZE()

		DEFINE MSDIALOG oDlg TITLE STR0028 From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL // "Informe Fornecedor e Loja"

		oDlg:lMaximized := .T.
		oPanel := TPanel():New(0,0,'',oDlg,, .T., .T.,, ,25,25,.T.,.T.)
		oPanel:Align := CONTROL_ALIGN_TOP

		@ 003,003 Say STR0024				 										  	PIXEL OF oPanel COLOR CLR_HBLUE // "Cliente : "
		@ 003,030 MSGET cCodigo F3 "SA1" Picture "@!" SIZE 70,08			  		PIXEL OF oPanel HASBUTTON

		@ 003,110 Say STR0025 														  	PIXEL OF oPanel COLOR CLR_HBLUE // "Loja : "
		@ 003,125 MSGET cLoja Picture "@!" SIZE 20,08 						  		PIXEL OF oPanel

		@ 003,150 Say STR0047														  	PIXEL OF oPanel	//"Moeda "
		@ 003,175 MSCOMBOBOX oCbx  VAR cMoeda		ITEMS aMoedas SIZE 50, 10 		PIXEL OF oPanel ON CHANGE (nMoedSubs := Val(Substr(cMoeda,1,2)))

		@ 003,245 Say STR0048														  	PIXEL OF oPanel	//"Outras Moedas"
		@ 003,295 MSCOMBOBOX oCbx2 VAR cOutMoeda	ITEMS aOutMoed SIZE 60, 10 		PIXEL OF oPanel

		@ 015,003 Say STR0031															PIXEL Of oPanel	// "N§ T¡tulos Selecionados: "
		@ 015,120 Say oQtdTit VAR nQtdTit Picture "999"  FONT oDlg:oFont			PIXEL Of oPanel

		@ 015,180 Say STR0032+cSimb														PIXEL Of oPanel	// "Valor Total "
		@ 015,230 Say oValor VAR nValorS Picture PesqPict("SE1","E1_SALDO",14)	PIXEL Of oPanel //"@E 999,999,999.99"

		If nOpca == 0
			Aadd( aButtons, {"S4WB005N",{ || Fa040Visu() }, OemToAnsi(STR0002)+" "+OemToAnsi(STR0028), OemToAnsi(STR0002)} )
		Endif

		DEFINE SBUTTON FROM 003,420 TYPE 1 ENABLE OF oPanel ;
		ACTION If(!Empty(cCodigo+cLoja),F040SelPR(oDlg,cOutMoeda,@nValorS,@nQtdTit,cMarca,oValor,oQtdTit,nMoedSubs,oPanel),HELP(" ",1,"OBRIGAT",,SPACE(45),3,0))

		If IsPanelFin()
			ACTIVATE MSDIALOG oDlg ON INIT FaMyBar(oDlg,{|| If(f040SubOk(@nOpca,nValorS,oDlg),oDlg:End(),.T.)},{|| nOpca := 0,oDlg:End()},aButtons)
		Else
			ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| If(f040SubOk(@nOpca,nValorS,oDlg),oDlg:End(),.T.)},{|| nOpca := 0,oDlg:End()},,aButtons) CENTERED
		Endif

		If nOpca != 2
			Exit
		Endif

	EndDO
Else
	//Rotina Automatica - nova
	If lNewAutom
		lSubs := .T.
    Else
	//Rotina Automatica - antiga
		lSubs := F040FilProv( SE1->E1_CLIENTE, SE1->E1_LOJA, cOutMoeda, nMoedSubs )
	Endif
	If lSubs
		nQtdTit := 1
		nOpca 	:= 1
	Else
		nQtdTit := 0
		nOpca 	:= 2
	EndIf
Endif

// Permitir substituir títulos normais por CC/CD e controlar baixa através do Cartão de Crédito
If cPaisLoc == "EQU" .and. Len(aTitulo2CC) > 0
   Fa040Tit2CC()
   Return
EndIf



VALOR 		:= 0
VLRINSTR 	:= 0
If lSubs .or. (nQtdTit > 0 .and. nOpca == 1)

	If Select("__SUBS") == 0
		ChkFile("SE1",.F.,"__SUBS")
	Endif

	dbSelectArea( "__SUBS" )
	dbSetOrder(1)
	dbGoto(nReg)

	nOpc:=3		//Inclusao
	lSubst:=.T.
	If PmsVldTit() .AND. (FA040Inclu("SE1",nReg,nOpc,,,lSubst)==1)
		lSubst:=.F.
		nValorSe1 := E1_VALOR


		If !lDelProvis
			cPrefDest	:= SE1->E1_PREFIXO
			cNumDest	:= SE1->E1_NUM
			cParcDest	:= SE1->E1_PARCELA
			cTipoDest	:= SE1->E1_TIPO
			cCfDest		:= SE1->E1_CLIENTE
			cLojaDest	:= SE1->E1_LOJA
			cFilDest	:= SE1->E1_FILIAL
			dDtEmiss	:= SE1->E1_EMISSAO
		Endif



		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Leitura para dele‡„o dos titulos provis¢rios.             	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ( lPadrao )
			nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa a gravacao dos lancamentos do SIGAPCO          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PcoIniLan("000001")

//---------------------------------------------------------------------------
		//Rotina Automatica - nova
		If lF040Auto .and. lNewAutom

            //Titulo Destino
			nReg := SE1->(RECNO())
			aAreaProv := getArea()
			For nI:= 1 to Len(aItnTitPrv)

				If	(nPosPre := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_PREFIXO"} )) == 0 .Or.;
					(nPosNum := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_NUM"    } )) == 0 .Or.;
					(nPosPar := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_PARCELA"} )) == 0 .Or.;
					(nPosTip := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_TIPO"   } )) == 0 .Or.;
					(nPosFor := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_CLIENTE"} )) == 0 .Or.;
					(nPosLoj := aScan(aItnTitPrv[nI], {|x| AllTrim(x[1]) == "E1_LOJA"   } )) == 0

					Loop

				EndIf


				SE1->(DbSetOrder(2))
				If SE1->(MsSeek(xFilial("SE1") + aItnTitPrv[nI,nPosFor,2] + aItnTitPrv[nI,nPosLoj,2] + PadR(aItnTitPrv[nI,nPosPre,2],TamSX3("E1_PREFIXO")[1])  + ;
				 	aItnTitPrv[nI,nPosNum,2] + PadR(aItnTitPrv[nI,nPosPar,2],TamSX3("E1_PARCELA")[1])  + aItnTitPrv[nI,nPostip,2] ))

					If dDatabase < SE1->E1_EMISSAO
						HELP(" ",1,"DATAPROV" ,,STR0174,2,0)//"Não é possível selecionar um título provisório com a data superior à database."
						lRet := .F.
						Exit
					EndIf

					//Processo antigo (deletando o PR)
					If lDelProvis

						//Exclui titulo
						If lF040Prov
							ExecBlock("F040PROV",.F.,.F.)
						Endif

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Apaga o lacamento gerado para a conta orcamentaria - SIGAPCO ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						PcoDetLan("000001","01","FINA040",.T.)

						//Atualiza saldo da natureza
						If SE1->E1_FLUXO == 'S'
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),nOpc)
						Endif

						Reclock("SE1",.F.)
						SE1->(dbDelete())
						MsUnlock()

					//Processo novo (baixando o PR)
					Else

						// Titulo PR será baixado na substituicao automatica
						lMsErroAuto := .F.

						cPrefOri  := SE1->E1_PREFIXO
						cNumOri   := SE1->E1_NUM
						cParcOri  := SE1->E1_PARCELA
						cTipoOri  := SE1->E1_TIPO
						cCfOri    := SE1->E1_CLIENTE
						cLojaOri  := SE1->E1_LOJA

						//Baixa Provisorio
						aVetor 	:= {{"E1_PREFIXO"	, SE1->E1_PREFIXO 		,Nil},;
		  							{"E1_NUM"		, SE1->E1_NUM       	,Nil},;
									{"E1_PARCELA"	, SE1->E1_PARCELA  		,Nil},;
									{"E1_TIPO"	    , SE1->E1_TIPO     		,Nil},;
									{"AUTMOTBX"	    , "STP"             	,Nil},;
									{"AUTDTBAIXA"	, dDataBase				,Nil},;
									{"AUTDTCREDITO" , dDataBase				,Nil},;
									{"AUTHIST"	    , STR0128+alltrim(E1_PREFIXO)+STR0129+alltrim(SE1->E1_NUM)+STR0130+alltrim(SE1->E1_PARCELA)+STR0131+alltrim(SE1->E1_TIPO)+"."	,Nil}} //"Baixa referente a substituicao de titulo tipo Provisorio para Efetivo. Prefixo: "#", Numero: "#", Parcela: "#", Tipo: "


						MSExecAuto({|x,y| Fina070(x,y)},aVetor,3)

						Pergunte("FIN040", .F.)
						If nMvpar140 != mv_par01
							FI040PerAut()
						EndIf

						//Em caso de erro na baixa
						If lMsErroAuto
							DisarmTransaction()
							MostraErro()
							Exit
						Else

							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³		Ponto de gravação dos campos da tabela auxiliar.		³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							dbselectarea("FIH")
							cFIHSeq	 := SE5->E5_SEQ

							FCriaFIH("SE1", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
							"SE1", cPrefDest, cNumDest, cParcDest, cTipoDest, cCfDest, cLojaDest,;
							cFilDest, cFIHSeq )

						EndIf
					EndIf

				EndIf
			Next nI

			RestArea(aAreaProv)
			If !lRet
				Return .F.
			EndIF
//-------------------------------------------------------
		//Rotina Automatica - Antiga
		ElseIf lF040Auto

			/*Projeto Grupo ABC
			If ( mv_par03 == 1 ) .and. FindFunction("CtbTranUniq")
				CtbTranUniq()
			Endif*/

			BEGIN TRANSACTION
				If ( lPadrao )
					nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
				EndIf
				dbSelectArea("SE1")
				dbGoto(nReg)

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Apaga o lancamento gerado para a conta orcamentaria - SIGAPCO ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				PcoDetLan("000001","01","FINA040",.T.)

				If SE1->E1_FLUXO == 'S'
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),nOpc)
				Endif

				Reclock("SE1" ,.F.,.T.)
				dbDelete()
			END TRANSACTION


		//Rotina Manual
		ElseIf !lF040Auto

			dbSelectArea("__SUBS")
			dbGoTop()

			/*Projeto Grupo ABC
			If ( mv_par03 == 1 ) .and. FindFunction("CtbTranUniq")
				CtbTranUniq()
			Endif*/

			BEGIN TRANSACTION

			While !Eof()

				If __SUBS->E1_OK == cMarca
					nRecProv = __SUBS->(recno())

					If ( lPadrao )
						nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
					EndIf
					// Caso tenha integracao com PMS para alimentar tabela AFT
					If IntePms()
						IF PmsVerAFT()
							aGravaAFT := PmsIncAFT()
						Endif
					Endif

					//Processo antigo (deletando o PR)
					If lDelProvis

						//Exclui titulo
						If lF040Prov
							ExecBlock("F040PROV",.F.,.F.)
						Endif

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Apaga o lacamento gerado para a conta orcamentaria - SIGAPCO ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						PcoDetLan("000001","01","FINA040",.T.)

						//Atualiza saldo da natureza
						If SE1->E1_FLUXO == 'S'
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),nOpc)
						Endif

						SE1->(dbGoto(nRecProv))
						cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
									SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
						FINDELFKs(cChaveFK7,"SE1")

						Reclock("SE1",.F.)
						SE1->(dbDelete())
						MsUnlock()

					//Processo novo (baixando o PR)
					Else

						nRecSubs := __SUBS->(Recno())
						dbSelectArea("SE1")
						dbGoto(nRecSubs)

						// Titulo PR será excluido na substituicao automatica
						lMsErroAuto := .F.

						cPrefOri  := SE1->E1_PREFIXO
						cNumOri   := SE1->E1_NUM
						cParcOri  := SE1->E1_PARCELA
						cTipoOri  := SE1->E1_TIPO
						cCfOri    := SE1->E1_CLIENTE
						cLojaOri  := SE1->E1_LOJA

						//Baixa Provisorio
						aVetor 	:= {{"E1_PREFIXO"	, SE1->E1_PREFIXO 		,Nil},;
		  							{"E1_NUM"		, SE1->E1_NUM       	,Nil},;
									{"E1_PARCELA"	, SE1->E1_PARCELA  		,Nil},;
									{"E1_TIPO"	    , SE1->E1_TIPO     		,Nil},;
									{"AUTMOTBX"	    , "STP"             	,Nil},;
									{"AUTDTBAIXA"	, dDtEmiss				,Nil},;
									{"AUTDTCREDITO" , dDtEmiss				,Nil},;
									{"AUTHIST"	    , STR0128+alltrim(E1_PREFIXO)+STR0129+alltrim(SE1->E1_NUM)+STR0130+alltrim(SE1->E1_PARCELA)+STR0131+alltrim(SE1->E1_TIPO)+"."	,Nil}}  //"Baixa referente a substituicao de titulo tipo Provisorio para Efetivo. Prefixo: "#", Numero: "#", Parcela: "#", Tipo: "


						MSExecAuto({|x,y| Fina070(x,y)},aVetor,3)

						//Em caso de erro na baixa
						If lMsErroAuto
							DisarmTransaction()
							MostraErro()
						Else

							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³		Ponto de gravação dos campos da tabela auxiliar.		³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If !lDelProvis
								dbselectarea("FIH")
								cFIHSeq	 := SE5->E5_SEQ

								FCriaFIH("SE1", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
								"SE1", cPrefDest, cNumDest, cParcDest, cTipoDest, cCfDest, cLojaDest,;
								cFilDest, cFIHSeq )

							EndIf

						EndIf

						If lF040Prov
							ExecBlock("F040PROV",.F.,.F.)
						Endif

					EndIf


					//Se o registro não foi gerado através do botão de integração do PMS na tela de titulos a receber do financeiro
					//Grava o registro na AFT com os dados obtidos na rotina PMSIncAFT()
					If Len(aGravaAFT) > 0 .And. (!AFT->(dbSeek(aGravaAFT[1]+aGravaAFT[6]+aGravaAFT[7]+aGravaAFT[8]+aGravaAFT[9]+aGravaAFT[10]+aGravaAFT[11]+aGravaAFT[2]+aGravaAFT[3]+aGravaAFT[5])))
						RecLock("AFT",.T.)
						    AFT->AFT_FILIAL	:= aGravaAFT[1]
							AFT->AFT_PROJET	:= aGravaAFT[2]
							AFT->AFT_REVISA	:= aGravaAFT[3]
							AFT->AFT_EDT	:= aGravaAFT[4]
							AFT->AFT_TAREFA	:= aGravaAFT[5]
							AFT->AFT_PREFIX	:= aGravaAFT[6]
							AFT->AFT_NUM	:= aGravaAFT[7]
							AFT->AFT_PARCEL	:= aGravaAFT[8]
							AFT->AFT_TIPO	:= aGravaAFT[9]
							AFT->AFT_CLIENT	:= aGravaAFT[10]
							AFT->AFT_LOJA	:= aGravaAFT[11]
							AFT->AFT_VENREA	:= aGravaAFT[12]
							AFT->AFT_EVENTO	:= aGravaAFT[13]
							AFT->AFT_VALOR1	:= aGravaAFT[14]
							AFT->AFT_VALOR2	:= aGravaAFT[15]
							AFT->AFT_VALOR3	:= aGravaAFT[16]
							AFT->AFT_VALOR4	:= aGravaAFT[17]
							AFT->AFT_VALOR5	:= aGravaAFT[18]
						MsUnLock()
					EndIf
				Endif

				dbSelectArea("__SUBS")
				dbSkip()

			Enddo

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Finaliza a gravacao dos lancamentos do SIGAPCO          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			PcoFinLan("000001")

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Contabiliza a diferenca               			    ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("SE1")
			nRecSE1 := Recno()
			dbGoBottom()
			dbSkip()
			VALOR := (nValorS - nValorSe1)
			VLRINSTR := VALOR
			If nTotal > 0
				nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
			Endif
			dbSelectArea("SE1")
			dbGoTo(nRecSE1)
			If ( lPadrao )
				RodaProva(nHdlPrv,nTotal)
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Indica se a tela sera aberta para digitação			  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lDigita:=IIF(mv_par01==1 .And. !lF040Auto,.T.,.F.)
				If ( FindFunction( "UsaSeqCor" ) .And. UsaSeqCor() )
			 		aDiario := {}
					aDiario := {{"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"}}
				Else
					aDiario := {}
				EndIf
				cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,,,,,,aDiario)
			EndIf

			END TRANSACTION

		Endif

	EndIf
EndIf

If !Empty(aChaveLbn)
	aEval(aChaveLbn, {|e| UnLockByName(e,.T.,.F.) } ) // Libera Lock
Endif

VALOR    := 0
VLSINSTR := 0
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Restaura os indices														  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Select("__SUBS") > 0
	dbSelectArea("__SUBS")
	dbCloseArea()
	Ferase(cIndex+OrdBagExt())
Endif
dbSelectArea("SE1")

If ! lF040Auto
	RetIndex("SE1")
	dbGoto(nReg)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Apaga o sem foro                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	fclose(nHdlLock)
	Ferase("FINA040.LCK")
Endif

nValorS := Nil		// Variavel private da substituicao

RestArea(aAreaAFT)
RestArea(aArea)
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Herda³ Autor ³ Valter G. Nogueira Jr.³ Data ³ 17/02/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Herda os dados do titulo original								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Herda()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Herda()
Local cAlias := Alias()
Local nRecDtAb	:= GetNewPar("MV_RECDTAB",1)
Local i,cCampo

dbSelectArea("SE1")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recupera os dados do titulo original								  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FOR i := 1 TO FCount()
	cCampo := Field(i)
	If cCampo$"E1_PREFIXO;E1_NUM;E1_PARCELA;E1_NATUREZ;E1_CLIENTE;E1_LOJA;E1_NOMCLI" .or.;
			cCampo$"E1_EMISSAO;E1_VENCTO;E1_VENCREA;E1_HISTORICO;E1_MOEDA" .OR.;
			cCampo$"E1_VEND1;E1_VEND2;E1_VEND3;E1_VEND4;E1_VEND5"
		If cCampo$"E1_EMISSAO;E1_VENCTO;E1_VENCREA"
			If nRecDtAb == 1	// Emissao, vencimento e vencimento real do título
				m->&cCampo := FieldGet(i)
			Else				// Emissao, vencimento e vencimento real igual Database
				m->&cCampo := dDataBase
			EndIf
		Else
			m->&cCampo := FieldGet(i)
		EndIf
	EndIf
NEXT i

If Empty(M->E1_VENCORI)
	M->E1_VENCORI := M->E1_VENCTO
EndIf
lRefresh := .T.
lHerdou 	:= .T.
aTela := { }
aGets := { }
MontaArray("SE1",3)
dbSelectArea(cAlias)
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Irf	³ Autor ³ Antonio Maniero Jr.   ³ Data ³ 11/04/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Calcula Irf em Reais     											  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Fina040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Irf()
Local nBaseIrrf 	:= m->e1_valor
Local lUsaMP232	:=	F040UsaMp232()

// Carrega variavel de verificacao de consideracao de valor minimo de retencao de IR.
Local lAplMinIR := .F.

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()

If !Type("lF040Auto") == "L" .or. !lF040Auto
	m->e1_irrf := 0
Endif

//639.04 Base Impostos diferenciada
If lBaseImp .and. M->E1_BASEIRF > 0
	nBaseIrrf   := M->E1_BASEIRF
Endif

// Verifica se o CLIENTE trata o valor minimo de retencao.
// 1- Não considera 	 2- Considera o parâmetro MV_VLRETIR
If cPaisLoc == "BRA" .and. SA1->A1_MINIRF == "2"
	lAplMinIR := .T.
Endif

//Se existir redutor da base do IR, calcular nova base
If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|PAD|PAN|PAR|PER|POR|PTG|SAL|TRI|URU|VEN" .and. SED->ED_BASEIRF > 0
	nBaseIrrf := nBaseIrrf * (SED->ED_BASEIRF/100)
Endif

If SED->ED_CALCIRF == "S"
	m->e1_irrf := F040CalcIr(nBaseIrrf,,.T.)
EndIf

If !(lUsaMP232) .And. If(lAplMinIr,(M->E1_IRRF <= GetMv("MV_VLRETIR")),.F.)
	M->E1_IRRF := 0
EndIf

Return .t.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Desmarca³ Autor ³ Wagner Xavier 		  ³ Data ³ 08/05/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Limpa as marcacoes do arquivo (E1_OK)							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040blank()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function fa040DesMarca(aChaveLbn)
Local lSavTTS
Local nRec
Local cChaveLbn

lSavTTS := __TTSInUse
__TTSInUse := .F.

nRec := __SUBS->(Recno())
While __SUBS->(!Eof())
	cChaveLbn := "SUBS" + xFilial("SE1")+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	If LockByName(cChaveLbn,.T.,.F.)
		If Reclock("__SUBS")
			__SUBS->E1_OK := "  "
			__SUBS->(MsUnlock())
		Endif
		MsUnlock()
		UnLockByName(cChaveLbn,.T.,.F.) // Libera Lock
	Endif
	__SUBS->(dbSkip())
End
__SUBS->(dbGoto(nRec))
__TTSInUse := lSavTTS

Return NIL

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Exibe³ Autor ³ Pilar S. Albaladejo   ³ Data ³ 07/11/95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Exibe Totais de titulos selecionados							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Exibe()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Exibe(nValor,nQtdTit,cMarca,cChave,oValor,oQtdTit,nMoeda)

If E1_OK == cMarca
	nValor += Round(NoRound(xMoeda(E1_SALDO+E1_ACRESC-E1_DECRESC,E1_MOEDA,nMoeda,,3),3),2)
	nQtdTit++
Else
	nValor -= Round(NoRound(xMoeda(E1_SALDO+E1_ACRESC-E1_DECRESC,E1_MOEDA,nMoeda,,3),3),2)
	nQtdTit--
	nValor := Iif(nValor<0,0,nValor)
	nQtdTit:= Iif(nQtdTit<0,0,nQtdTit)
Endif
oValor:Refresh()
oQtdTit:Refresh()
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Inverte³ Autor ³ Wagner Xavier       ³ Data ³ 07/11/95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Marca e Desmarca Titulos, invertendo a marca‡†o existente  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa040Inverte()                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa040Inverte(cMarca,oValor,oQtdTit,nValor,nQtdTit,oMark,nMoeda,aChaveLbn,cChaveLbn,lTodos)
Local nReg := __SUBS->(Recno())
Local nAscan
Local lAbreDlgCC := .F.

dbSelectArea("__SUBS")
If lTodos
	dbSeek(xFilial("SE1"))
Endif
While !lTodos .Or.;
		!Eof() .and. xFilial("SE1") == E1_FILIAL
	If lTodos .Or. cChaveLbn == Nil
		cChaveLbn := "SUBS" + xFilial("SE1")+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	Endif
	If (lTodos .And. LockByName(cChaveLbn,.T.,.F.)) .Or. !lTodos
		If dDatabase < __SUBS->E1_EMISSAO
			HELP(" ",1,"DATAPROV" ,,STR0174,2,0)//"Não é possível selecionar um título provisório com a data superior à database."
			Exit
		EndIf
		RecLock("__SUBS")
		IF E1_OK == cMarca
			__SUBS->E1_OK := "  "
			nValor -= Round(NoRound(xMoeda(E1_SALDO+E1_ACRESC-E1_DECRESC,E1_MOEDA,nMoeda,,3),3),2)
			nQtdTit--
			nAscan := Ascan(aChaveLbn, cChaveLbn )
			If nAscan > 0
				UnLockByName(aChaveLbn[nAscan],.T.,.F.) // Libera Lock
			Endif
		Else
			If Ascan(aChaveLbn, cChaveLbn) == 0
				Aadd(aChaveLbn,cChaveLbn)
			Endif
			__SUBS->E1_OK := cMarca
			nValor += Round(NoRound(xMoeda(E1_SALDO+E1_ACRESC-E1_DECRESC,E1_MOEDA,nMoeda,,3),3),2)
			nQtdTit++
		Endif
		MsUnlock()
		If cPaisLoc == "EQU"
			lAbreDlgCC := .F.
			If SE1->E1_TIPO <> "CC "
				SF2->(dbSetOrder(1))
				If SF2->(dbSeek(xFilial("SF2")+SE1->E1_NUM+SE1->E1_PREFIXO+SE1->E1_CLIENTE+SE1->E1_LOJA))
					SE4->(dbSetOrder(1))
					If SE4->(dbSeek(xFilial("SE4")+SF2->F2_COND)) .and. AllTrim(SE4->E4_FORMA) == "CC"
				    	lAbreDlgCC := .T.
				    EndIf
				EndIf
			Else
				lAbreDlgCC := .T.
			EndIf
			If !Empty(__SUBS->E1_OK) .and. lAbreDlgCC
                //Executar dialogo para obter os dados do Cartão de Crédito
				Fa040GetCC(.F.)
			EndIf
	    EndIf
	EndIf
	If !lTodos
		Exit
	Endif
	dbSkip()
Enddo
__SUBS->(dbGoto(nReg))
oValor:Refresh()
oQtdTit:Refresh()
oMark:oBrowse:Refresh(.t.)
Return Nil

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040Alter³ Autor ³ Wagner Xavier 	    ³ Data ³ 22/04/92 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa para alteracao de contas a receber				  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Alter(ExpC1,ExpN1,ExpN2) 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo									  ³±±
±±³			 ³ ExpN1 = Numero do registro 								  ³±±
±±³			 ³ ExpN2 = Numero da opcao selecionada 						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Alter(cAlias,nReg,nOpc)
Local aCpos
Local k
Local aBut040 		:= {}
Local aUsers 		:= {}
Local cTudoOK 		:= ""
Local lRet 			:= .T.
Local nPisOri 		:= SE1->E1_PIS
Local nCofOri 		:= SE1->E1_COFINS
Local nCslOri 		:= SE1->E1_CSLL
Local nIrfOri		:= SE1->E1_IRRF
Local lContrAbt 	:= .T.
Local aHelpEng		:= {}
Local aHelpEsp		:= {}
Local aHelpPor		:= {}
Local cTipos 		:= MVPROVIS+"/"+MVABATIM
Local aDim 			:= {}
Local oPanelDados 	:= NIL
Local cCmd 			:= ""
//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr		:= FPccBxCr()
//Controla IRPJ na baixa
Local lIrPjBxCr		:= FIrPjBxCr()
//639.04 Base Impostos diferenciada
Local lBaseImp		:= F040BSIMP(2)
Local lEECFAT := SuperGetMv("MV_EECFAT",.F.,.F.)
Local lRatPrj	:=.T. //indica se existirá rateio de projeto
Local cChaveTit := ""
Local cChaveFK7 := ""
Local cE1NATUREZ := Alltrim(SE1->E1_NATUREZ)
Local cE1VENCTO  := DTOC(SE1->E1_VENCTO)
Local cE1VENCREA := DTOC(SE1->E1_VENCREA)
Local cE1VALOR   := Alltrim(Transform(SE1->E1_VALOR,PesqPict("SE1","E1_VALOR")))
Local cE1DECRESC := Alltrim(Transform(SE1->E1_DECRESC,PesqPict("SE1","E1_DECRESC")))
Local cE1ACRESC  := Alltrim(Transform(SE1->E1_ACRESC,PesqPict("SE1","E1_ACRESC")))
Local cE1VALJUR  := Alltrim(Transform(SE1->E1_VALJUR,PesqPict("SE1","E1_VALJUR")))
Local cE1PORCJUR := Alltrim(Transform(SE1->E1_PORCJUR,PesqPict("SE1","E1_PORCJUR")))
Local cE1DESCFIN := Alltrim(Transform(SE1->E1_DESCFIN,PesqPict("SE1","E1_DESCFIN")))
Local cE1DIADESC := Alltrim(Transform(SE1->E1_DIADESC,PesqPict("SE1","E1_DIADESC")))
Local cE1TIPODES := Alltrim(SE1->E1_TIPODES)
Local cE1HIST    := Alltrim(SE1->E1_HIST)
Local aAlt       := {}
Local lAtuPFS    := .F.
Local lIntPFS    := SuperGetMV("MV_JURXFIN",,.F.) // Integração SIGAPFS x SIGAFIN

//Parametrizacao dos Produtos utilizados pela RM
Local cProdRM		:= GETNEWPAR('MV_RMORIG', "")

PRIVATE nOldValor 	:= SE1->E1_VALOR
PRIVATE nOldIrrf  	:= SE1->E1_IRRF
PRIVATE nOldIss	:= SE1->E1_ISS
PRIVATE nOldInss  	:= SE1->E1_INSS
PRIVATE nOldCsll  	:= SE1->E1_CSLL
PRIVATE nOldPis	:= SE1->E1_PIS
PRIVATE nOldCofins	:= SE1->E1_COFINS
PRIVATE aRatAFT	:= {}
PRIVATE bPMSDlgRC	:= {||PmsDlgRC(4,M->E1_PREFIXO,M->E1_NUM,M->E1_PARCELA,M->E1_TIPO,M->E1_CLIENTE,M->E1_LOJA,M->E1_ORIGEM)}
PRIVATE nOldVlAcres:= SE1->E1_ACRESC
PRIVATE nOldVlDecres := SE1->E1_DECRESC
PRIVATE nOldSdAcres := SE1->E1_SDACRES
PRIVATE nOldSdDecres := SE1->E1_SDDECRE
PRIVATE aHeader 	:= {}, aCols := {}, aRegs := {}
PRIVATE aHeadMulNat:= {}, aColsMulNat := {}
PRIVATE nIndexSE1 	:= ""
PRIVATE cIndexSE1 	:= ""
PRIVATE lAlterNat 	:= .F.
PRIVATE nOldVencto := SE1->E1_VENCTO
PRIVATE nOldVenRea := SE1->E1_VENCREA
PRIVATE cOldNatur  := SE1->E1_NATUREZ
PRIVATE nOldVlCruz := SE1->E1_VLCRUZ
PRIVATE cHistDsd	:= CRIAVAR("E1_HIST",.F.)  // Historico p/ Desdobramento
PRIVATE aParcelas	:= {}  // Array para desdobramento
PRIVATE aParcacre 	:= {},aParcDecre := {}  // Array de Acresc/Decresc do Desdobramento
PRIVATE nOldBase 	:= If(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF,SE1->E1_VALOR)

Private lSubstFI2	:=	.T.
If Type("aItemsFI2")	<> "A"
	Private aItemsFI2	:=	{}
Endif
Private aCposAlter

If !Type("lF040Auto") == "L" .OR. !lF040Auto
	nVlRetPis	:= 0
	nVlRetCof := 0
	nVlRetCsl	:= 0
	nVlRetIRF	:= 0
	aDadosRet := Array(6)
	AFill( aDadosRet, 0 )
	cTudoOK := 'If(!Empty(SE1->E1_IDCNAB) .And. Empty(aItemsFI2) .And. MsgYesNo("'+STR0084+'","'+STR0039+'"), Fa040AltOk(), .T.)'
Endif

lAltDtVc := .F.
//Ponto de entrada FA040ALT
//Ponto de entrada utilizado para permitir validacao complementar no botao OK
IF ExistBlock("FA040ALT")
	If Empty(cTudoOk)
		cTudoOk += 'ExecBlock("FA040ALT",.f.,.f.)'
	Else
		cTudoOk += '.And. ExecBlock("FA040ALT",.f.,.f.)'
	Endif
Endif

// Acrescenta funcao para validacao de bloqueio - PCO
If Empty(cTudoOk)
	cTudoOk += "F040PcoLan()"
Else
	cTudoOk += ".And. F040PcoLan()"
Endif

cTudoOk += ' .And. iif(m->e1_tipo $ MVABATIM .and. !Empty(m->e1_num), F040VlAbt(), .T.) '
cTudoOK += ' .And. F040VldVlr() '

//Ponto de entrada FA040BLQ
//Ponto de entrada utilizado para permitir ou nao o uso da rotina
//por um determinado usuario em determinada situacao
IF ExistBlock("F040BLQ")
	lRet := ExecBlock("F040BLQ",.F.,.F.)
	If !lRet
		Return .T.
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se data do movimento n„o ‚ menor que data limite de ³
//³ movimentacao no financeiro    								 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !DtMovFin(,,"2")
   Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Caso titulos originados pelo SIGALOJA estejam nas carteiras :  ³
//³I = Carteira Caixa Loja                                        ³
//³J = Carteira Caixa Geral                                       ³
//³Nao permitir esta operacao, pois ele precisa ser transferido   ³
//³antes pelas rotinas do SIGALOJA.                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//SITCOB
If Upper(AllTrim(SE1->E1_SITUACA)) $ "I|J" .AND. Upper(AllTrim(SE1->E1_ORIGEM)) $ "LOJA010|FATA701|LOJA701"
	Help(" ",1,"NOUSACLJ")
	Return
Endif

//PCREQ-3782 - Bloqueio por situação de cobrança
If !F023VerBlq("1","0001",SE1->E1_SITUACA,.T.)
	Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se utiliza integracao com o SIGAPMS                                        	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("AFT")
dbSetOrder(1)

//Botoes adicionais na EnchoiceBar
aBut040 := fa040BAR('IntePms()',bPmsDlgRC)

//Inclusao do botao Posicao
AADD(aBut040, {"HISTORIC", {|| Fc040Con() }, STR0139}) //"Posicao"

//inclusao do botao Rastreamento
AADD(aBut040, {"HISTORIC", {|| Fin250Rec(2) }, STR0140}) //"Rastreamento"


// integração com o PMS

If IntePms() .And. (!Type("lF040Auto") == "L" .Or. !lF040Auto)
	SetKey(VK_F10, {|| Eval(bPmsDlgRC)})
EndIf

If !Empty(SE1->E1_IDCNAB)  .And. !Empty(SE1->E1_PORTADO)  // Adiciona botao para envio de instrucoes de cobranca
	Aadd(aBut040,{'BAIXATIT',{||Fa040AltOk(,,.T.)},STR0083,"Instruções"}) //"Incluir instruções de cobrança"
Endif

If SE1->( EOF()) .or. xFilial("SE1") # SE1->E1_FILIAL
	Help(" ",1,"ARQVAZIO")
	Return .T.
Endif

//Se veio atraves da integracao Protheus X Classis nao Pode ser alterado
If (!Type("lF040Auto") == "L" .Or. !lF040Auto) .and.  Upper(AllTrim(SE1->E1_ORIGEM))$ cProdRM
	HELP(" ",1,"ProtheusXClassis" ,,STR0205,2,0,,,,,,{STR0206})//"Título gerado pela Integração Protheus X Classis não Pode ser alterado pelo Protheus" ## "Efetue a alteração pelo sistema RM Classis"
	Return
Endif

//Se veio atraves da integracao Protheus X Tin nao Pode ser alterado
If (!Type("lF040Auto") == "L" .Or. !lF040Auto) .and.  Upper(AllTrim(SE1->E1_ORIGEM))=="FINI055"
	HELP(" ",1,"ProtheusXTIN" ,,STR0142,2,0)//"Título gerado pela Integração Protheus X Tin não Pode ser alterado pelo Protheus"
	Return
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Caso tenha seja um titulo gerado pelo SigaEic nao podera ser alterado               	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lIntegracao .and. UPPER(Alltrim(SE1->E1_Origem)) $ "SIGAEIC"
	HELP(" ",1,"FAORIEIC")
	Return
Endif

//DFS - 16/03/11 - Deve-se verificar se os títulos foram gerados por módulos Trade-Easy, antes de apresentar a mensagem.
//  !!!! FAVOR MANTER A VALIDACAO SEMPRE COM SUBSTR() PARA NAO IMPACTAR EM OUTROS MODULOS !!!! (SIGA3286)
If substr(SE1->E1_ORIGEM,1,7) $ "SIGAEEC/SIGAEFF/SIGAEDC/SIGAECO" .AND. !(cModulo $ "EEC/EFF/EDC/ECO")
	HELP(" ",1,"FAORIEEC")
	Return
Endif

// Verifica integracao com PMS e nao permite alteracao de itulos que tenham solicitacoes
// de transferencias em aberto.
If !Empty(SE1->E1_NUMSOL)
	HELP(" ",1,"FA62003")
	Return
Endif

//Titulos gerados por diferenca de imposto não podem ser Alterados
If Alltrim(SE1->E1_ORIGEM) == "APDIFIMP" .And. (!Type("lF040Auto") == "L" .or. !lF040Auto)
	Help(" ",1,"NO_ALTERA") //Este titulo nao podera ser alterado pois foi gerado pelo modulo
	Return .F.
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Para titulo e-Commerce nao pode ser alterado                                ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If  LJ861EC01(SE1->E1_NUM, SE1->E1_PREFIXO, .F./*NaoTemQueTerPedido*/, SE1->E1_FILORIG)
	Help(" ",1,"FA040TMS",," SIGALOJA - e-Commerce!",3,1) //Este titulo nao podera ser alterado pois foi gerado por outro modulo
	Return .F.
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Não permite alterar titulos que foram gerados pelo Template GEM³
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistTemplate("GEMSE1LIX")
	If ExecTemplate("GEMSE1LIX",.F.,.F.)
		MsgStop(STR0087 ) //"Este titulo não pode ser alterado, pois foi gerado através do Template GEM."
		Return
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Nao permite alterar titulos do tipo RA gerados automaticamente  ³
//³ ao efetuar o recebimentos diversos - Majejo de Anticipo         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc == "MEX" .And.;
	Upper(Alltrim(SE1->E1_Origem)) $ "FINA087A" .And.;
	SE1->E1_TIPO == Substr(MVRECANT,1,3) .And.;
	X3Usado("ED_OPERADT") .And.;
	GetAdvFVal("SED","ED_OPERADT",xFilial("SED")+SE1->E1_NATUREZ,1,"") == "1"

	Help(" ",1,"FA040VLDALT")

	Return
Endif


//Titulo apropriado no Totvs obras e projetos nao pode ser alterado

If F040TOPBLQ()
	MsgAlert(STR0150)//"Este título está sendo utilizado no Totvs Obras e Projetos e não pode ser alterado."
	Return .F.
endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica campos do usuario      			  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SX3")
dbSetOrder(1)
DbSeek("SE1")
While !Eof() .and. X3_ARQUIVO == "SE1"
	IF X3_PROPRI == "U"
		Aadd(aUsers,sx3->x3_campo)
	Endif
	dbSkip()
Enddo

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Aten‡„o para criar o array aCpos			  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCpos := fa040MCpo()

If ( aCpos == Nil )
	Return
EndIf
aCposAlter	:=	aClone(aCpos)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Preenche campos alter veis (usu rio)       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Len(aUsers) > 0
	FOR k:=1 TO Len(aUsers)
		Aadd(aCpos,Alltrim(aUsers[k]))
	NEXT k
EndIf

lAltera:=.T.

dbSelectArea("SA1")
DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)

IF ExistBlock("FA40Prot")
	ExecBlock("FA40Prot",.f.,.f.)
Endif

// Somente permite a alteracao de multiplas naturezas para titulo digitados

If (SE1->E1_MULTNAT == "1" .And. ( Empty(SE1->E1_ORIGEM) .Or. Upper(Trim(SE1->E1_ORIGEM)) = "FINA040") .and.;
	 SE1->E1_LA != "S" )
	Aadd(aBut040, {'S4WB013N',{ || F040ButNat(aCols,aHeader,aColsMulNat,aHeadMulNat,aRegs) },"Rateio das Naturezas do titulo"} )
Endif

If lContrAbt .and. !lPccBxCr
	//Se pendente retencao, zero os valores de Pis/Cofins/Csll para que os mesmos
	//nao aparecam em tela ja que nao foi gerado abatimento para este titulo ou abatido em outro titulo
	If SE1->E1_SABTPIS+SE1->E1_SABTCOF+SE1->E1_SABTCSL > 0
		If (SED->ED_PCCINDV = '2' .Or. Empty(SED->ED_PCCINDV))
			RECLOCK("SE1",.F.,,.T.)
			nOldCsll  := 0
			nOldPis	:= 0
			nOldCofins:= 0
			SE1->E1_PIS := 0
			SE1->E1_COFINS := 0
			SE1->E1_CSLL := 0
			MsUnlock()
		ElseIf SED->ED_PCCINDV = '1'
			RECLOCK("SE1",.F.,,.T.)

			If SE1->E1_SABTPIS > 0
				nOldPis	:= 0
				SE1->E1_PIS := 0
			Endif

			If SE1->E1_SABTCOF > 0
				nOldCofins:= 0
				SE1->E1_COFINS := 0
			Endif

			If SE1->E1_SABTCSL > 0
				nOldCsll  := 0
				SE1->E1_CSLL := 0
			Endif

			MsUnlock()
		Endif
	Endif
Endif
If lContrAbt .and. !lIrPjBxCr
	//Se pendente retencao, zero os valores de IRRF para que os mesmos
	//nao aparecam em tela ja que nao foi gerado abatimento para este titulo ou abatido em outro titulo
	If cPaisLoc == "BRA" .and. SE1->E1_SABTIRF > 0 //este campo pertence ao Brasil
		RECLOCK("SE1",.F.,,.T.)
		nOldIrrf  := 0
		SE1->E1_IRRF := 0
		MsUnlock()
	Endif
Endif

// Somo o total do grupo, pois apos a alteracao os dados tais como Vencto e Valor jah estao gravados
If !lPccBxCr .or. !lIrPjBxCr
	nSomaGrupo := F040TotGrupo(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA), Left(Dtos(SE1->E1_VENCREA), 6))
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Insere o botao de cheques na tela de alteracao            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc=="BRA"  // Esta rotina esta somente para o Brasil pois Localizacoes utiliza o Recibo para incluir os cheque ( Fina087A)
   Aadd(aBut040,{'LIQCHECK',{||IIF(!Empty(M->E1_TIPO) .and. !M->E1_TIPO $ cTipos,CadCheqCR(,,,,,3),Help("",1,"NOCADCHREC"))},STR0051,STR0068}) //"Cadastrar cheques recebidos" //"Cheques"
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Inicializa a gravacao dos lancamentos do SIGAPCO          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PcoIniLan("000001")
dbSelectArea( cAlias )
If !Type("lF040Auto") == "L" .or. !lF040Auto
	If IsPanelFin()  //Chamado pelo Gestor Financeiro
		dbSelectArea("SE1")
		RegToMemory("SE1",.F.,.F.,,FunName())
		oPanelDados := FinWindow:GetVisPanel()
		oPanelDados:FreeChildren()
		aDim := DLGinPANEL(oPanelDados)
		nOpca := AxAltera(cAlias,nReg,nOpc,,aCpos,4,SA1->A1_NOME,cTudoOk,"FA040AXALT('"+cAlias+"')",,aBut040,,,,,,.T.,oPanelDados,aDim,FinWindow)
	Else
		nOpca := AxAltera(cAlias,nReg,nOpc,,aCpos,4,SA1->A1_NOME,cTudoOk,"FA040AXALT('"+cAlias+"')",,aBut040 )
	Endif
Else
	RegToMemory("SE1",.F.,.F.)
	If EnchAuto(cAlias,aAutoCab,cTudoOk,nOpc)
		fa040natur()
		nOpcA := AxIncluiAuto(cAlias,,"FA040AXALT('"+cAlias+"')",4,SE1->(RecNo()))
	Else
		nOpca := 0
	EndIf
EndIf

If nOpca == 1

  If !(cE1NATUREZ == Alltrim(SE1->E1_NATUREZ))
       aadd( aAlt,{ STR0175,STR0176 + ' :',STR0177 + ' - '  + STR0178,STR0190 + ' - ' +  Alltrim(cE1NATUREZ) , STR0191 + ' - ' + Alltrim(SE1->E1_NATUREZ)})
  endif

  If !(cE1VENCTO == Alltrim(DTOC(SE1->E1_VENCTO)))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0179, STR0190 + ' - ' + Alltrim(cE1VENCTO) , STR0191 + ' - ' +  Alltrim(DTOC(SE1->E1_VENCTO))})
  endif

  If !(cE1VENCREA == Alltrim(DTOC(SE1->E1_VENCREA)))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0180,STR0190 + ' - '  +  Alltrim(cE1VENCREA) , STR0191 + ' - ' +  Alltrim(DTOC(SE1->E1_VENCREA))})
  endif

   If !(cE1VALOR == Alltrim(Transform(SE1->E1_VALOR,PesqPict("SE1","E1_VALOR"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0181,STR0190 + ' - '  +  Alltrim(cE1VALOR) , STR0191 + ' - ' + Alltrim(Transform(SE1->E1_VALOR,PesqPict("SE1","E1_VALOR"))) })
  endif

   If !(cE1DECRESC == Alltrim(Transform(SE1->E1_DECRESC,PesqPict("SE1","E1_DECRESC"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0182, STR0190 + ' - '  +  Alltrim(cE1DECRESC) ,STR0191 + ' - ' + Alltrim(Transform(SE1->E1_DECRESC,PesqPict("SE1","E1_DECRESC"))) })
  endif

   If !(cE1ACRESC == Alltrim(Transform(SE1->E1_ACRESC,PesqPict("SE1","E1_ACRESC"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0183, STR0190 + ' - '  +  Alltrim(cE1ACRESC) ,STR0191 + ' - ' + Alltrim(Transform(SE1->E1_ACRESC,PesqPict("SE1","E1_ACRESC"))) })
  endif

  If !(cE1VALJUR == Alltrim(Transform(SE1->E1_VALJUR,PesqPict("SE1","E1_VALJUR"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0184, STR0190 + ' - ' +  Alltrim(cE1VALJUR) , STR0191 + ' - ' +  Alltrim(Transform(SE1->E1_VALJUR,PesqPict("SE1","E1_VALJUR"))) })
  endif

  If !(cE1PORCJUR == Alltrim(Transform(SE1->E1_PORCJUR,PesqPict("SE1","E1_PORCJUR"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0185, STR0190 + ' - '  +  Alltrim(cE1PORCJUR) ,STR0191 + ' - ' +  Alltrim(Transform(SE1->E1_PORCJUR,PesqPict("SE1","E1_PORCJUR"))) })
  endif

  If !(cE1DESCFIN == Alltrim(Transform(SE1->E1_DESCFIN,PesqPict("SE1","E1_DESCFIN"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0186, STR0190 + ' - '  +  Alltrim(cE1DESCFIN) ,STR0191 + ' - ' +  Alltrim(Transform(SE1->E1_DESCFIN,PesqPict("SE1","E1_DESCFIN"))) })
  endif

  If !(cE1DIADESC == Alltrim(Transform(SE1->E1_DIADESC,PesqPict("SE1","E1_DIADESC"))))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0187, STR0190 + ' - '  +  Alltrim(cE1DIADESC) ,STR0191 + ' - ' +  Alltrim(Transform(SE1->E1_DIADESC,PesqPict("SE1","E1_DIADESC"))) })
  endif

  If !(cE1TIPODES == Alltrim(SE1->E1_TIPODES))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0188, STR0190 + ' - '  +  Alltrim(cE1TIPODES) ,STR0191 + ' - ' +  Alltrim(SE1->E1_TIPODES)})
  endif

  If !(cE1HIST == Alltrim(SE1->E1_HIST))
       aadd( aAlt,{ STR0175,STR0176 + ':',STR0177 + ' - '  + STR0189, STR0190 + ' - '  +  Alltrim(cE1HIST) ,STR0191 + ' - ' +  Alltrim(SE1->E1_HIST)})
  endif

  ///chamada da Função que cria o Histórico de Cobrança
  FinaCONC(aAlt)

endif

//.....
//    Conforme situacao do parametro abaixo, integra com o SIGAGSP
//    MV_SIGAGSP - 0-Nao / 1-Integra
//    Estornar a Inclusao e Re-lancar para a Orcamentacao
//    ......
If nOpca == 1 .And. GetNewPar("MV_SIGAGSP","0") == "1"
	// Inclusão de FindFunction pois a rotina nao foi encontrada
	// no repositorio.
	If FindFunction("GSPF230")
		GSPF230(2)
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Integracao Protheus X RM Classis Net (RM Sistemas)³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
if GetNewPar("MV_RMBIBLI",.F.) .and. nOpca == 1
	if alltrim(upper(SE1->E1_ORIGEM)) == 'L' .or. alltrim(upper(SE1->E1_ORIGEM)) == 'S' .or. SE1->E1_IDLAN > 0
		//Replica a alteracao nas tabelas do RM Biblios
		ClsProcAlt(SE1->(Recno()),'1',"FIN040")
	endif
endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ ExecBlock para valida‡Æo pos-confirma‡Æo da altera‡Æo	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("F040ALT") .and. nOpca == 1
	ExecBlock("F040ALT",.f.,.f.)
Endif

//****************************************************
// Caso seja PCC na emissao e não tenha valor retido *
//****************************************************
If !lPccBxCr .And. Empty(SE1->(E1_PIS+E1_COFINS+E1_CSLL))

	If (!lAlterNat .or. nOpca != 1)
		//*************************************************
		// Caso a rotina nao tenha recalculado a natureza *
		// ou a rotina de alteração tenha sido cancelada. *
		//*************************************************
   		If nOpca <> 3
			RecLock("SE1")
		Else
			RECLOCK("SE1",.F.,,.T.)
		Endif
		If !(SE1->E1_EMISSAO >= dLastPcc .and. nOpca == 1)
			SE1->E1_PIS := nPisOri
			SE1->E1_COFINS := nCofOri
			SE1->E1_CSLL := nCslOri
		EndIf
		MsUnlock()
	Else
		//*************************************************
		// Caso tenha a rotina tenha rodado o recalculo da*
		// natureza utiliza o valor recalculado.          *
		//*************************************************
		RecLock("SE1")
		SE1->E1_PIS := nVlRetPis
		SE1->E1_COFINS := nVlRetCof
		SE1->E1_CSLL := nVlRetCsl
		MsUnlock()
	EndIf
Endif
//****************************************************
// Caso seja IR na emissao e não tenha valor retido *
//****************************************************
If !lIrPjBxCr .And. Empty(SE1->E1_IRRF)

	If (!lAlterNat .or. nOpca != 1)
		//*************************************************
		// Caso a rotina nao tenha recalculado a natureza *
		// ou a rotina de alteração tenha sido cancelada. *
		//*************************************************
   		If nOpca <> 3
			RecLock("SE1")
		Else
			RECLOCK("SE1",.F.,,.T.)
		Endif
		If nIrfOri > 0 .and. Empty(SE1->E1_IRRF) .and. nOpca != 1
			SE1->E1_IRRF := nIrfOri
		EndIf
		MsUnlock()
	Else
		//*************************************************
		// Caso tenha a rotina tenha rodado o recalculo da*
		// natureza utiliza o valor recalculado.          *
		//*************************************************
		RecLock("SE1")
		SE1->E1_IRRF := nVlRetIrf
		MsUnlock()
	EndIf
Endif

// integração com o PMS

If IntePms() .And. (!Type("lF040Auto") == "L" .Or. !lF040Auto)
	SetKey(VK_F10, Nil)
EndIf

If cPaisLoc=="BRA"
	F986LimpaVar()
EndIf

/*
Atualiza o status do titulo no SERASA */
If cPaisLoc == "BRA" .And. nOpca == 1
	cChaveTit := xFilial("SE1", SE1->E1_FILORIG)	+ "|" +;
				SE1->E1_PREFIXO 					+ "|" +;
				SE1->E1_NUM							+ "|" +;
				SE1->E1_PARCELA 					+ "|" +;
				SE1->E1_TIPO						+ "|" +;
				SE1->E1_CLIENTE 					+ "|" +;
				SE1->E1_LOJA
	cChaveFK7 := FINGRVFK7("SE1",cChaveTit)
	F770BxRen("2","",cChaveFK7)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza a gravacao dos lancamentos do SIGAPCO            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PcoFinLan("000001")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
//³Integracao protheus X tin	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
If nOpca == 1 .And. FWHasEAI("FINA040",.T.,,.T.)
	lRatPrj:= PmsRatPrj("SE1",,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO)
	If !( AllTrim(SE1->E1_TIPO) $ MVRECANT .and. lRatPrj  .and. !(cPaisLoc $ "BRA|")) //nao integra PA e RA para Totvs Obras e Projetos Localizado
		If GetNewPar("MV_RMCLASS", .F.) //Caso a integração esteja ativada, excluo somente títulos gerados pelo RM
			If Upper(AllTrim(SE1->E1_ORIGEM)) $ "S|L|T"
				FwIntegDef( 'FINA040' )
			EndIf
		Else
			FwIntegDef( 'FINA040' )
		EndIf
	Endif
Endif

// Integração com SIGAPFS
If lIntPFS .And. nOpca == 1 .And. FindFunction("JAltTitCR") // Confirmação da alteração -> nOpca == 1
	// Caso tenha alteração nos campos abaixo
	lAtuPFS := nOldValor  <> SE1->E1_VALOR   .Or.; // Valor
	           cE1HIST    <> SE1->E1_HIST    .Or.; // Histórico
	           nOldVenRea <> SE1->E1_VENCREA .Or.; // Vencimento Real
	           cOldNatur  <> SE1->E1_NATUREZ       // Natureza

	JAltTitCR( SE1->(Recno()), SE1->E1_EMISSAO, lAtuPFS )
EndIf

Return nOPCA

/*/{Protheus.doc} FinaCsLog
Consulta do Histórico de Cobrança
@author Alexandre Felicio
@since  02/07/2015
@version 12
/*/
Function FinaCsLog()
Local cIdDoc := ''
Local cIdCV8 := ''
Local cChaveTit := ''

cChaveTit := xFilial("SE1") + "|" + SE1->E1_PREFIXO + "|" + SE1->E1_NUM + "|" + SE1->E1_PARCELA + "|" +;
			 SE1->E1_TIPO   + "|" + SE1->E1_CLIENTE + "|" + SE1->E1_LOJA

cIdDoc    := FINGRVFK7("SE1", cChaveTit)

ProcLogView( cFilAnt, cIdDoc)

Return


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040valor³ Autor ³ Wagner Xavier 		  ³ Data ³ 18/05/93 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Verifica se valor podera' ser alterado, ou se abat > valor  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa040valor() 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function fa040valor()
Local lRet:=.T.
Local cAlias:=Alias()
Local nRec
Local cMascara
Local nRecSX3
Local aImpostos := {}
Local nX := 0

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()

nRecSX3 := SX3->(Recno())
nRec := SE1->(RecNo())

If m->e1_moeda > 99
	Return .f.
Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³A moeda do abatimento e titulo devem ser as mesmas para   ³
//³compatibilizacao com multi-moedas e taxas variaveis. Isto ³
//³evita diferencas na consulta FINC060. (Localizacoes)      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If cPaisLoc <> "BRA" .And. M->E1_TIPO $ MVABATIM
	If cPaisLoc <> "EQU" .And. M->E1_MOEDA <> SE1->E1_MOEDA
		Help(" ",1,"E1MOEDIF")
		Return .f.
	ElseIf cPaisLoc == "EQU" .And. M->E1_TIPO <> "IV-" .And. M->E1_MOEDA <> SE1->E1_MOEDA
		Help(" ",1,"E1MOEDIF")
		Return .f.
	EndIf
EndIf
aImpostos := { { "E1_CSLL" 		, "MV_VRETCSL" 	, "VALORCSLL",.T.} ,;
				{ "E1_COFINS"	, "MV_VRETCOF" 	, "VALCOFINS",.T.} ,;
				{ "E1_INSS"		, "MV_VLRETIN"	, "VALORINSS",.T.} ,;
				{ "E1_IRRF"		, "MV_VLRETIR"	, "VALORIRRF",!F040UsaMp232() .And. (cPaisLoc == "BRA" .And. SA1->A1_MINIRF == "2")} ,;
				{ "E1_PIS"		, "MV_VRETPIS" 	, "VALORPIS" ,.T.} }

For nX := 1 to Len(aImpostos)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Tratamento de Dispensa de Retencao de IMPOSTOS         	  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If AllTrim(SX3->X3_CAMPO) == aImpostos[nX][1]
		If aImpostos[nX][4] .And. ( &(M->(aImpostos[nX][1])) <= GetNewPar(aImpostos[nX][2],0) .and. ;
				&(M->(aImpostos[nX][1])) > 0  )
			Help(" ",1,aImpostos[nX][3])
			lRet:=.F.
		EndIf
	Endif
Next

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se o abatimento e' maior que valor do titulo         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF !Empty( m->e1_tipo )
	IF m->e1_tipo $ MVABATIM
		dbSelectArea( "SE1" )
		IF dbSeek( xFilial("SE1") + m->e1_prefixo + m->e1_num + m->e1_parcela + m->e1_tipo )
			Do While !Eof() .and. E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO == m->e1_prefixo+m->e1_num+m->e1_parcela+m->e1_tipo
				If E1_TIPO $ MVABATIM+"/"+MV_CRNEG+"/"+MVRECANT
					dbSkip( )
					Loop
				Endif
				IF m->e1_valor > SE1->E1_SALDO
					Help(" ",1,"ABATMAIOR")
					lRet := .f.
					Exit
				Endif
				Exit
			Enddo
		Endif
	Endif
Endif

SE1 -> (dbGoto(nRec))

IF lAltera
	IF SE1->E1_LA = "S" .AND. !( Upper(AllTrim(SE1->E1_ORIGEM)) == "FINI055" )
		Help(" ",1,"NAOVALOR")
		lRet:=.F.
	Endif
	IF cPaisLoc == "BRA" .and. SE1->E1_TIPO $ MVIRABT+"/"+MVINABT+"/"+MVCFABT+"/"+MVCSABT+"/"+MVPIABT
		Help(" ",1,"NOVALORIR")
		lRet:=.F.
	Endif
	If SE1->E1_TIPO $ MVRECANT
		Help( " ",1,"FA040ADTO")
		lRet := .F.
	Endif
Endif

If lRet		// Valor alterado, deve alterar E1_VLCRUZ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa o valor em cruzeiro como sugestao										 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cMascara:=PesqPict("SE1","E1_VLCRUZ",19)

	If ( cPaisLoc == "CHI" )
		//Edu
		//M->E1_VLCRUZ:=Round( xMoeda(M->E1_VALOR,M->E1_MOEDA,1,M->E1_EMISSAO,3), MsDecimais(1) )
		M->E1_VLCRUZ:=Round( xMoeda(M->E1_VALOR,M->E1_MOEDA,1,M->E1_EMISSAO,3,M->E1_TXMOEDA), MsDecimais(1) )
	Else
		//Edu
		//M->E1_VLCRUZ:=Round(NoRound(xMoeda(M->E1_VALOR,M->E1_MOEDA,1,M->E1_EMISSAO,3),3),2)
		M->E1_VLCRUZ:=Round(NoRound(xMoeda(M->E1_VALOR,M->E1_MOEDA,1,M->E1_EMISSAO,3,M->E1_TXMOEDA),3),2)
	Endif

Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Recalcula o valor dos impostos usando como base o valor em moeda nacional (E1_VLCRUZ) ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lRet .And. cPaisLoc == "BRA" .And. M->E1_VLCRUZ > 0 .And. lReCalcmoed
	FA040Natur(,.T.)
EndIf

SE1->(dbGoto(nRec))
dbSelectArea(cAlias)
SX3->(dbGoTo(nRecSX3))

Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040Moed ³ Autor ³ Pilar S. Albaladejo   ³ Data ³ 10/03/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Verifica se a moeda existe no SX3 								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa040valor() 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Moed()

Local cAlias	:= Alias()
Local nOrder	:= IndexOrd()
Local nRec, lRet := .t.
Local cMoed		:= "1"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se a moeda existe no SX3												 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
cMoeda := Alltrim(Str(m->e1_moeda))

If(cMoed <>  Alltrim(Str(m->e1_moeda)))

	cMoed   :=  Alltrim(Str(m->e1_moeda))
	lReCalcmoed := .T.

EndIf
dbSelectArea("SX3")

nRec := Recno()
dbSetOrder(2)
If !dbSeek("M2_MOEDA"+cMoeda)
	Help ( " ", 1, "SEMMOEDA" )
	lRet := .F.
EndIf

dbGoto(nRec)
dbSelectArea(cAlias)
dbSetOrder(nOrder)
Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040Dsdobr  ³ Autor ³ Mauricio Pequim Jr  ³ Data ³ 16/07/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Faz desdobramento em parcelas, do titulo em inclusao.      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa040Dsdobr()                                        	     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040Dsdobr()
Local nOpcDsd:= 0
Local cCondPgto:= Space(3), nParceDsd:= 0, cValorDsd := "T"
Local nPerioDsd:= 0
Local nOrdSE1 := SE1->(IndexOrd())
Local oDlg, oVlDsd
aParcelas := {}
aParcacre := {}
aParcdecre:= {}
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Verifica se a campos obrigatorios foram preencidos							 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Empty(m->e1_num) 		.or. Empty(m->e1_tipo)    .or. Empty(m->e1_naturez) .or.;
	Empty(m->e1_cliente)	.or. Empty(m->e1_loja)    .or. Empty(m->e1_emissao) .or.;
	Empty(m->e1_vencto) 	.or. Empty(m->e1_vencrea) .or. Empty(m->e1_valor)   .or.;
	Empty(m->e1_vlcruz)
	Help(" " , 1 , "FA050NODSD")
	Return .F.
Endif
If m->e1_tipo $ MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM
	Help(" " , 1 , "FA050TPDSD")
	Return .F.
Endif

nOpcDsd := 0
While nOpcDsd == 0

	DEFINE MSDIALOG oDlg FROM	0,0 TO 235,280 TITLE STR0053 PIXEL //"Desdobramento"

	@ 004, 007 TO 105, 105 OF oDlg PIXEL

	@ 010, 014 SAY STR0054 SIZE 90, 7 OF oDlg PIXEL  //"Condição de Pagamento"
	@ 028, 014 SAY STR0055 SIZE 90, 7 OF oDlg PIXEL  //"Numero de Parcelas"
	@ 046, 014 SAY STR0056 SIZE 90, 7 OF oDlg PIXEL  //"Valor do Titulo (Total ou Parcela)"
	@ 064, 014 SAY STR0057 SIZE 90, 7 OF oDlg PIXEL  //"Periodo de Vencto. (em dias)"
	@ 082, 014 SAY STR0058 SIZE 90, 7 OF oDlg PIXEL  //"Historico"

	@ 018, 014 MSGET cCondPgto	F3 "SE4" Picture "!!!" SIZE 72, 08 OF oDlg PIXEL ;
													Valid (Empty (cCondPgto) .or. ExistCpo("SE4",cCondPgto)) .and. ;
													Fa290Cond(cCondPgto)
	@ 036, 014 MSGET  nParceDsd 		  	Picture "9999" When IIf(Empty(cCondPgto),.T.,.F.);
	Valid f040ValPar(nParceDsd,nMaxParc) ;
	SIZE 80, 08 OF oDlg PIXEL
	@ 054, 014 COMBOBOX oVlDsd VAR cValorDsd ITEMS {STR0059,STR0060} SIZE 80, 10 OF oDlg PIXEL ; //"TOTAL"###"PARCELA" //"TOTAL"###"PARCELA"
	When IIf(Empty(cCondPgto),.T.,.F.)
	@ 072, 014 MSGET nPerioDsd				Picture "999" When IIf(Empty(cCondPgto),.T.,.F.) ;
	Valid nPerioDsd > 0;
	SIZE 80, 08 OF oDlg PIXEL
	@ 090, 014 MSGET  cHistDsd			 	Picture "@S40";
	SIZE 80, 08 OF oDlg PIXEL

	DEFINE SBUTTON FROM 07, 110 TYPE 1 ACTION ;
	{||nOpcDsd:=1,IF(A040TudoOK(cCondPgto,nParceDsd,cValorDsd,nPerioDsd),oDlg:End(),nOpcDsd:=0)} ENABLE OF oDlg
	DEFINE SBUTTON FROM 23, 110 TYPE 2 ACTION {||nOpcDsd:=9 ,oDlg:End()} ENABLE OF oDlg

	ACTIVATE MSDIALOG oDlg CENTERED
EndDo
If nOpcDsd == 1
	nSavRec:=RecNo()
	dbSelectArea("SE1")
	nOrdSE1:= IndexOrd()
	dbSetOrder(6)
	If !dbSeek(xFilial("SE1")+m->e1_cliente+m->e1_loja+m->e1_prefixo+m->e1_num)
		Fa040Cond(cCondPgto,nParceDsd,cValorDsd,nPerioDsd,cHistDsd)
	Else
		Help(" ",1,"NO_DESDOBR")
		dbSelectArea("SE1")
		dbSetOrder(nOrdSE1)
		Return .F.
	Endif
	//Cancela Multiplas Naturezas se tiver Desdobramento
	M->E1_MULTNAT := "2"
Else
	Return .F.
Endif
dbSelectArea("SE1")
dbSetOrder(nOrdSE1)
Return .T.


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040Valpar  ³ Autor ³ Mauricio Pequim Jr  ³ Data ³ 16/07/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Faz verificacao do numero de parcelas do desdobramento.    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040ValPar()                                        	     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function F040VALPAR(nParceDsd,nMaxParc)

If nParceDsd > nMaxParc .or. nParceDsd < 2
	Help(" " , 1 , "FA050PCDSD")
	Return .F.
Endif
Return .T.

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040Cond	³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 16/07/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Faz calculos do Desdobramento parcelas automaticas 		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Cond(cCondicao)													  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Fa040Cond(cCondDsd,nParceDsd,cValorDsd,nPerioDsd)

Local nValParc		:= 0		// Valor de cada parcela
Local nValParcac	:= 0
Local nValParcde	:= 0
Local nVlTotParc	:= 0  	// Valor do somatorio das parcelas
Local nVlTotAcre	:= 0
Local nVlTotDecr	:= 0
Local nDifer		:= 0
Local nDifacre		:= 0
Local nDifdecre	:= 0
Local nCond			:= 0
Local dDtVenc		:= IIF(Empty(cCondDsd),dDataBase,m->e1_emissao)
Local nValorDSD	:= m->e1_valor
Local lPerPc1		:= .T.
Local nConda		:= 0
Local nCondd		:= 0


//Zera valor dos impostos do titulo principal
//para evitar problemas no desdobramento com calculo de imposto
m->e1_irrf		:= 0
m->e1_iss		:= 0
m->e1_inss		:= 0
m->e1_cofins	:= 0
m->e1_csll		:= 0
m->e1_pis		:= 0
m->e1_vretirf	:= 0
m->e1_vretpis	:= 0
m->e1_vretcof	:= 0
m->e1_vretcsl	:= 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de Entrada F40DTDSD                               	³
//³ Utilizado para manipulacao de data inicial para os calculos³
//³ de vencimento das parcelas do desdobramento.					³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("F40DTDSD")
	dDtVenc := ExecBlock("F40DTDSD",.F.,.F.)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de Entrada F040PRPC                                	³
//³ Utilizado para manipulacao da aplica‡ao ou nao do periodo  ³
//³ interparcela sobre a a primeira parcela, dever  retornar   ³
//³ retornar .T.(aplica)  ou .F. (nao aplica). Exemplo:		   ³
//³ Tendo como data inicial para calculo 10/02/2002, periodo   ³
//³ interparcela de 10 dias, e retorno .T., a data de vencto   ³
//³ inicial ser  20/02/2002. Caso retorno seja .F., a data     ³
//³ de vencto da primeira parcela ser  10/02/2002. Aplic vel   ³
//³ apenas quando NAO se utilizar condicao de pagamento para   ³
//³ calculo dos titulos a serem gerados.                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("F040PRPC") .and. Empty(cCondDsd)
	lPerPc1 := ExecBlock("F040PRPC",.F.,.F.)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Caso a data retornada pelo PE acima seja menor que a data  ³
//³ de emissao do titulo gerador do desdobramento, utilizo o   ³
//³ padrao de inicializacao da data inicial para calculo do    ³
//³ vencimento das parcelas.												³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If dDtVenc < m->e1_emissao
	If !Empty(cCondDsd)
		dDtVenc := m->e1_emissao
	Else
		dDtVenc := dDataBase
	Endif
Endif

If !Empty(cCondDsd)
	aParcelas := Condicao (nValorDsd	,cCondDsd,,dDtVenc)
	aParcacre := Condicao (m->e1_acresc ,cCondDsd,,dDtVenc)
	aParcdecre:= Condicao (m->e1_decresc,cCondDsd,,dDtVenc)
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Corrige possiveis diferencas entre o valor total e o    	³
	//³ apurado ap¢s a divisao das parcelas								³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	For nCond := 1 to Len (aParcelas)
		nVlTotParc += aParcelas [ nCond, 2]
	Next
	If nVlTotParc != nValorDsd
		nDifer := round(nValorDsd - nVlTotParc,2)
		aParcelas [ Len(aParcelas), 2 ] += nDifer
	Endif
	If Len(aParcacre)>0
		For nConda := 1 to Len (aParcacre)
			nVlTotAcre += aParcacre [ nConda, 2]
		Next
		If nVlTotAcre != m->e1_acresc
			nDifacre := round(m->e1_acresc - nVlTotAcre,2)
			aParcelas [ Len(aParcelas), 2 ] += nDifacre
		Endif
	Endif
	If Len(aParcdecre)>0
		For nCondd := 1 to Len (aParcdecre)
			nVlTotDecr += aParcdecre [ nCondd, 2]
		Next
		If nVlTotAcre != m->e1_decresc
			nDifdecre := round(m->e1_decresc - nVlTotDecr,2)
			aParcdecre [ Len(aParcdecre), 2 ] += nDifdecre
		Endif
	Endif
Else
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o valor do titulo que est  sendo desdobrado ‚ o³
	//³ total, e por consequencia, divide por numero de parcelas ou³
	//³ caso seja o valor da parcela, gera n parcelas do valor.    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Left(cValorDsd,1) == "T"
		nValParc 	:= Round(NoRound((nValorDsd / nParceDsd),3),2)
		nValParcAc	:= Round(NoRound((m->e1_acresc / nParceDsd),3),2)
		nValParcDe	:= Round(NoRound((m->e1_decresc / nParceDsd),3),2)
	Else
		nValParc	:= nValorDsd
		nValParcAc	:= m->e1_acresc
		nValParcDe	:= m->e1_decresc
	Endif
	For nCond := 1 To nParceDsd
		If (nCond == 1 .and. lPerPc1) .or. nCond > 1
			dDtVenc += nPerioDsd
		Endif
		dDtVencRea := DataValida(dDtVenc,.T.)
		AADD ( aParcelas, { dDtVenc , nValParc } )
		AADD ( aParcacre, { dDtVenc , nValParcAc } )
		AADD ( aParcdecre, { dDtVenc , nValParcDe } )
		nVlTotParc += aParcelas [nCond,2]
		nVlTotAcre += aParcacre [nCond,2]
		nVlTotDecr += aParcdecre [nCond,2]
	Next
	If Left(cValorDsd,1) == "T"
		nDifer		:= Round(nValorDsd - nVlTotParc,2)
		nDifacre	:= Round(m->e1_acresc - nVlTotAcre,2)
		nDifdecre	:= Round(m->e1_decrescr - nVlTotDecr,2)
		aParcelas [ Len(aParcelas), 2 ] += nDifer
		aParcacre [ Len(aParcacre), 2 ] += nDifacre
		aParcdecre [ Len(aParcdecre), 2 ] += nDifdecre
	Endif
Endif
Return .T.

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³A040TudoOK³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 16/07/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica se dados para desdobramento estao corretos.		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ A040TudoOk()															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A040TudoOk(cCondPgto,nParceDsd,cValorDsd,nPerioDsd)

If nModulo <> 11 .And. nModulo <> 14 .And. Alltrim(cCondPgto) == "A"
	Help(" " , 1 , "CONDPGTOA",,STR0103,1,0) // "Condição de Pagamento exclusiva para os ambientes Veículos (SIGAVEI) e Oficinas (SIGAOFI)"
	Return .F.
Endif

If Empty (cCondPgto)
	If nParceDsd < 2 .or. nParceDsd > nMaxParc .or. Empty(cValorDsd) .or. nPerioDsd <= 0
		Help(" " , 1 , "FA050DADOS")
		Return .F.
	Endif
Endif

If UsaSeqCor()
	If !CTBvldDiario(M->E1_DIACTB,dDataBase)
		Return(.F.)
	EndIf
EndIf

Return .T.


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040AxInc³ Autor ³ Mauricio Pequim Jr	  ³ Data ³ 04/08/99 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Fun‡Æo para complementacao da inclusao de C.Pagar			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040AxInc(ExpC1) 													  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo											  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040AxInc(cAlias)

Local lDigita
Local cPadrao:="500"
Local aFlagCTB := {}
Local lUsaFlag	:= SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
Local cArquivo
Local nTotal:=0
Local lPadrao:=.F.
Local nRecSe1 := 0
Local cCodFor :=""
Local aTam    :={}
Local nHdlPrv := 0
Local lDesDobr := .F.
Local nRecSED := SED->(Recno())
Local lAbate   := .T.
Local nTotARet  := 0
Local nSobra    := 0
Local nFatorRed := 0
Local nLoop     := 0
Local nValMinRet := GetNewPar("MV_VL10925",5000)
Local cModRet   := GetNewPar( "MV_AB10925", "0" )
Local lContrAbt := .T.
Local cRetCli   := "1"
Local lContrAbtIRF:= cPaisLoc == "BRA"
Local cModRetIRF 	:= GetNewPar("MV_IRMP232", "0" )
Local lAbatIRF  	:= cPaisLoc == "BRA"

Local cPrefOri  := SE1->E1_PREFIXO
Local cNumOri   := SE1->E1_NUM
Local cParcOri  := SE1->E1_PARCELA
Local cTipoOri  := SE1->E1_TIPO
Local cCfOri    := SE1->E1_CLIENTE
Local cLojaOri  := SE1->E1_LOJA
Local nDiferImp := 0
Local nValorTit := 0
Local nRecAtu	 := SE1->(RECNO())
Local lVerImpAut := .T.
Local cLojaImp	:= ""
Local lCdRetInd	:= .T.
Local lE1_CODRET	:= SE1->( ColumnPos( "E1_CODRET" ) ) > 0
Local lLOJRREC	:= FindFunction("LOJRREC")				// Relatorio de impressao de Recibo (OBSOLETO)
Local lULOJRREC	:= FindFunction("U_LOJRRecibo")			// Relatorio de impressao de Recibo (RDMAKE)
Local lIMPLJRE	:= SuperGetMV( "MV_IMPLJRE",.F., .F.)
Local aTitBx	:= {}	//Array contendo o título incluido para impressao do Recibo de Pagamento
Local aFormPg	:= {}	//Array contendo a forma de pagamento RA para impressao do Recibo

//1-Cria NCC/NDF referente a diferenca de impostos entre emitidos (SE2) e retidos (SE5)
//2-Nao Cria NCC/NDF, ou seja, controla a diferenca num proximo titulo
//3-Nao Controla
Local cNccRet  := SuperGetMv("MV_NCCRET",.F.,"1")

Local lRetSoIrf := .F.
Local lOriFatura  := ("FINA280" $ SE1->E1_ORIGEM)
Local lDescISS := IIF(SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.),.T.,.F.)
Local lAchouPai := .F.
Local nRecSE1P	:= 0
Local nRecAbt := 0


Local lSetAuto := .F.
Local lSetHelp := .F.
Local cBuscSe1, nValSe1, cTipSe1

//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr			:= FPccBxCr()
Local aDiario			:= {}
//Controla IRPJ na baixa
Local lIrPjBxCr		:= FIrPjBxCr()
Local lRaRtImp      := lFinImp .And.FRaRtImp()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()

Local lFINA200	 := FunName() == "FINA200" .Or. FwIsInCallStack("FINA200")
Local lCTBCNAB	 := .F.
Local lEnd		 := .F.
Local lF040FCR   := ExistBlock("F040FCR")
Local cTipoAbat  := ""
Local aColsSev:={}
Local aHeaderSev:={}
Local nTotRetPIS := 0
Local nTotRetCOF := 0
Local nTotRetCSL := 0

//Nova estrutura SE5
Local oModel
Local oSubFK1
Local oSubFKA
Local oSubFK5
Local oSubFK7
Local cLog := ""
Local aColsKco := {}
Local nOldBaseINS := 0
Local nOldBaseISS := 0

// Importacao via Mile
Local lMile   := IsInCallStack("CFG600LMdl") .Or. IsInCallStack("FWMILEIMPORT") .Or. IsInCallStack("FWMILEEXPORT")
Local cFilAux := ""
Local lFINA791 := FwIsInCallStack("FINA791")
Local lVincVA := .F.

Private aItemsFI2	:=	{} // Utilizada para gravacao de ocorrencias

Pergunte("FIN040", .F.)
FI040PerAut()
Begin Transaction

If cPaisLoc == "BRA"
	nOldBaseINS := SE1->E1_BASEINS
	nOldBaseISS := SE1->E1_BASEISS
EndIf

If Type("aCols") == "U"
	aCols:= {}
Endif

If SE1->E1_EMISSAO >= dLastPcc
	nValMinRet	:= 0
EndIf

If cModulo == "TMS" .And. FunName() == "TMSA850"
	//--> Caso a chamada seja pela função TMSA850, inicializa a variavel a de Lote.
	LoteCont( "FIN" )
EndIf

If lContrAbt
	If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|URU|VEN"
		cRetCli := Iif(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
	Endif
Endif

If lF040Auto
	cBancoAdt   := Iif(Empty(SE1->E1_PORTADO),cBancoAdt,SE1->E1_PORTADO)
	cAgenciaAdt := Iif(Empty(SE1->E1_AGEDEP),cAgenciaAdt,SE1->E1_AGEDEP)
	cNumCon     := Iif(Empty(SE1->E1_CONTA),cNumCon,SE1->E1_CONTA)
	nMoedAdt    := Iif(Empty(SE1->E1_MOEDA),nMoedAdt,SE1->E1_MOEDA)
EndIf

//Quando rotina automatica, caso sejam enviados os valores dos impostos
//nao devo recalcula-los.
If lF040Auto .and. (M->E1_IRRF+M->E1_ISS+M->E1_INSS+M->E1_PIS+M->E1_CSLL+M->E1_COFINS > 0 )
	If lOriFatura //Se a inclusao vier atraves de Rot. Aut. (Fina040) chamada do Fina280 (faturas a receber)
		lVerImpAut := .F.
	Endif
EndIF

// Trata gravacao da filial para titulos importados por Mile
If lMile .And. Type("M->E1_FILIAL") # Nil
	cFilAux := cFilAnt
	cFilAnt := M->E1_FILIAL
	RecLock("SE1")
	SE1->E1_FILIAL := cFilAnt
	SE1->(MsUnlock())
EndIf
//Caso o PCC seja abatido na emissao
//Recarrega as variaveis nVlRetPis, nVlRetCof e nVlRetCsl, com os novos valores digitados pelo usuario.
If !lPccBxCr .and. (m->e1_pis + m->e1_cofins + m->e1_csll > 0) .And. M->E1_EMISSAO < dLastPCC
	FVERABTIMP(.f.)
Endif

dbSelectArea("SA1")
DbSetOrder(1)
dbSeek(cFilial+SE1->E1_CLIENTE+SE1->E1_LOJA)
nSavRecA1 := RecNo()

IF SE1->E1_DESDOBR == "1"
	lDesdobr := .T.
	nRecSe1 := SE1->(RECNO())
	//realiza a gravacao do model do titulo desdobrado
	If cPaisLoc=="BRA"
		Fa986grava("SE1","FINA040")
	EndIf
	Processa({||GeraParcSe1(cAlias,@lEnd,@nHdlPrv,@nTotal,@cArquivo,@aDiario,nSavRecA1,nRecSe1)}) // Gera as parcelas do desdobramento
	If lEnd
		lDesdobr := .F.
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualiza dados complementares do titulo    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF SE1->E1_DESDOBR != "1"

	//639.04 Base Impostos diferenciada
	//Gravo a base dos impostos para este titulo
	If cPaisLoc == "BRA"
		If lBaseImp .and. SE1->E1_BASEIRF > 0 .AND. !lFINA791
			RecLock("SE1")
			SE1->E1_BASEINS := E1_BASEIRF
			SE1->E1_BASEISS := E1_BASEIRF
			SE1->E1_BASEPIS := Iif(lF040Auto .And. E1_BASEPIS > 0 .And. E1_BASEPIS <> E1_BASEIRF,E1_BASEPIS,E1_BASEIRF)
			SE1->E1_BASECOF := Iif(lF040Auto .And. E1_BASECOF > 0 .And. E1_BASECOF <> E1_BASEIRF,E1_BASECOF,E1_BASEIRF)
			SE1->E1_BASECSL := Iif(lF040Auto .And. E1_BASECSL > 0 .And. E1_BASECSL <> E1_BASEIRF,E1_BASECSL,E1_BASEIRF)
	        MsUnlock()
	   Endif
	Endif

	If (lContrAbt .Or. lContrAbtIRF) .and. !(E1_TIPO $ MVRECANT+"/"+MV_CRNEG) .and. lVerImpAut .And. !lFINA791
		//Caso nao seja PCC Baixa CR
		If !lPccBxCr
			If cRetCli == "1"  //Calculo do sistema
				If cModRet == "1" //Verifica apenas o titulo em questao

					//639.04 Base Impostos diferenciada
					If lBaseImp .and. SE1->E1_BASEIRF > 0
						lAbate := SE1->E1_BASEIRF > nValMinRet
					Else
						lAbate := SE1->E1_VALOR > nValMinRet
					Endif

					SE1->E1_PIS := nVlRetPis
					SE1->E1_COFINS := nVlRetCof
					SE1->E1_CSLL := nVlRetCsl
					If !lAbate	.And. !lPccBxCR
						SE1->E1_SABTPIS := nVlRetPis
						SE1->E1_SABTCOF := nVlRetCof
						SE1->E1_SABTCSL := nVlRetCof
					Endif

				ElseIf cModRet == "2" .Or. cModRetIRF=="1"	//Verifica o acumulado no mes

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verifica os titulos para o mes de referencia, para verificar se atingiu a retencao       ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

					// Estrutura de aDadosRet
					// 1-Valor dos titulos
					// 2-Valor do PIS
					// 3-Valor do COFINS
					// 4-Valor da CSLL
					// 5-Array contendo os recnos dos titulos
					// 6-Valor do IRRF

					//639.04 Base Impostos diferenciada
					If lBaseImp .and. M->E1_BASEIRF > 0
						cCond := "aDadosRet[ 1 ] + M->E1_BASEIRF"
					Else
						cCond := "aDadosRet[ 1 ] + M->E1_VALOR"
					Endif

					If &cCond  > nValMinRet

						lAbate := .T.

						nTotARet := nVlRetPIS + nVlRetCOF + nVlRetCSL + nVlRetIRF

						nValorTit := SE1->(E1_VALOR-E1_IRRF-E1_INSS-If(lDescIss,E1_ISS,0))

						nSobra := nValorTit - nTotARet

						If nSobra < 0

							nFatorRed := 1 - ( Abs( nSobra ) / nTotARet )

							//armazena o valor total calculado para o PCC para depois abater dele o valor retido
							nTotRetPIS := nVlRetPIS
							nTotRetCOF := nVlRetCOF
							nTotRetCSL := nVlRetCSL

	 						nVlRetPIS  := NoRound( nVlRetPIS * nFatorRed, 2 )
	 						nVlRetCOF  := NoRound( nVlRetCOF * nFatorRed, 2 )
	 						nVlRetIRF  := NoRound( nVlRetIRF * nFatorRed, 2 )

	 						nVlRetCSL := nValorTit - ( nVlRetPIS + nVlRetCOF + nVlRetIRF )

							nDiFerImp := nTotARet - (nVlRetPIS + nVlRetCOF + nVlRetCSL + nVlRetIRF )

							If cNccRet == "1"
								ADupCredRt(nDiferImp,"001",SE1->E1_MOEDA,.T.)
							Endif
						EndIf

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Grava os novos valores de retencao                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						RecLock("SE1")
						If lE1_CODRET
							lCdRetInd := ( SE1->E1_PIS <= 0 .Or. SE1->E1_COFINS <= 0 .Or. SE1->E1_CSLL <= 0 ) .And. M->E1_CODRET $ "5987|5960|5979"
						EndIf
						If ( SE1->E1_COFINS <= Iif(!lCdRetInd,0,SuperGetMV("MV_VRETCOF"))) // VerIfica se o Cofins pode ser retido
							SE1->E1_COFINS		:= 0							 // Valor menor que MV_VRETCOF e' dispensado de recolhimento.
							SE1->E1_SABTCOF	:= nVlRetCof
						Else
							SE1->E1_COFINS		:= nVlRetCof
							SE1->E1_SABTCOF	:= 0
						EndIf

						//Se a variável de memória veio preenchida e está vindo via ExecAuto
						//mantenho o valor do COFINS que foi informado na ExecAuto
						If lF040Auto .And. M->E1_COFINS > 0
							SE1->E1_COFINS := M->E1_COFINS
						EndIf

						If ( SE1->E1_PIS <= Iif(!lCdRetInd,0,SuperGetMV("MV_VRETPIS"))) // VerIfica se o Pis pode ser retido
							SE1->E1_PIS	:= 0							 // Valor menor que MV_VRETPIS e' dispensado de recolhimento.
							SE1->E1_SABTPIS := nVlRetPIS
						Else
							SE1->E1_PIS    := nVlRetPIS
							SE1->E1_SABTPIS := 0
						EndIf

						//Se a variável de memória veio preenchida e está vindo via ExecAuto
						//mantenho o valor do PIS que foi informado na ExecAuto
						If lF040Auto .And. M->E1_PIS > 0
							SE1->E1_PIS := M->E1_PIS
						EndIf

						If ( SE1->E1_CSLL <= Iif(!lCdRetInd,0,SuperGetMV("MV_VRETCSL"))) // VerIfica se o Csll pode ser retido
							SE1->E1_CSLL		:= 0							 // Valor menor que MV_VRETCSL e' dispensado de recolhimento.
							SE1->E1_SABTCSL	:= nVlRetCSL
						Else
							SE1->E1_CSLL		:= nVlRetCSL
							SE1->E1_SABTCSL	:= 0
						EndIf

						//Se a variável de memória veio preenchida e está vindo via ExecAuto
						//mantenho o valor do CSLL que foi informado na ExecAuto
						If lF040Auto .And. M->E1_CSLL > 0
							SE1->E1_CSLL := M->E1_CSLL
						EndIf

						If lAbatIRF .And. cModRetIRF == "1"
							SE1->E1_IRRF    := nVlRetIRF
							SE1->E1_SABTIRF := 0
						Endif
						MSUnlock()
						nSavRec := SE1->( Recno() )

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Zera os saldos a abater dos demais movimentos     ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If aDadosRet[1] > 0
							aRecnos := aClone( aDadosRet[ 5 ] )

							cPrefOri  := SE1->E1_PREFIXO
							cNumOri   := SE1->E1_NUM
							cParcOri  := SE1->E1_PARCELA
							cTipoOri  := SE1->E1_TIPO
							cCfOri    := SE1->E1_CLIENTE
							cLojaOri  := SE1->E1_LOJA

							For nLoop := 1 to Len( aRecnos )

								SE1->( dbGoto( aRecnos[ nLoop ] ) )

								If nSavRec <> aRecnos[ nLoop ]
									FImpCriaSFQ("SE1", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
													"SE1", SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, SE1->E1_CLIENTE, SE1->E1_LOJA,;
													SE1->E1_SABTPIS, SE1->E1_SABTCOF, SE1->E1_SABTCSL,;
													If( FieldPos('FQ_SABTIRF') > 0 .And. lAbatIRF .And. cModretIRF =="1", SE1->E1_SABTIRF, 0),;
													SE1->E1_FILIAL )
								Endif

								RecLock( "SE1", .F. )

								//Nao	deve zerar e sim tirar o que esta sendo absorvido
								SE1->E1_SABTPIS := 0
								SE1->E1_SABTCOF := 0
								SE1->E1_SABTCSL := 0
								If lAbatIRF .And. cModRetIRF == "1"
									SE1->E1_SABTIRF := 0
								Endif

								SE1->( MsUnlock() )

							Next nLoop
						Endif

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Retorna do ponteiro do SE1 para a parcela         ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						SE1->( MsGoto( nSavRec ) )
						Reclock( "SE1", .F. )


					ElseIf &cCond > MaTbIrfPF(0)[4] .and. ;
							cModRetIrf == "1" .and. Len(Alltrim(SM0->M0_CGC)) < 14   //P.Fisica

						lAbate := .T.
						lRetSoIrf := .T.

						RecLock("SE1")
						SE1->E1_PIS 	:= 0
						SE1->E1_COFINS := 0
						SE1->E1_CSLL 	:= 0
						SE1->E1_IRRF 	:= 0
						MsUnlock()

						If cModRetIRF == "1"
							nVlRetIRF := aDadosRet[ 6 ] + nVlRetIRF
						Else
							nVlRetIRF := 0
						Endif

						nTotARet := nVlRetIRF

						nValorTit := SE1->(E1_VALOR-E1_IRRF-E1_INSS)

						nSobra := nValorTit - nTotARet

						If nSobra < 0

							nFatorRed := 1 - ( Abs( nSobra ) / nTotARet )

	 						nVlRetIRF  := NoRound( nVlRetIRF * nFatorRed, 2 )

							nDiFerImp := nTotARet - nVlRetIRF

							If cNccRet == "1"
								ADupCredRt(nDiferImp,"001",SE1->E1_MOEDA,.T.)
							Endif
						EndIf

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Grava os novos valores de retencao                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						RecLock("SE1")
						If lAbatIRF .And. cModRetIRF == "1"
							SE1->E1_IRRF    := nVlRetIRF
							SE1->E1_SABTIRF := 0
						Endif
						MSUnlock()
						nSavRec := SE1->( Recno() )

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Zera os saldos a abater dos demais movimentos     ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						If aDadosRet[1] > 0
							aRecnos := aClone( aDadosRet[ 5 ] )

							cPrefOri  := SE1->E1_PREFIXO
							cNumOri   := SE1->E1_NUM
							cParcOri  := SE1->E1_PARCELA
							cTipoOri  := SE1->E1_TIPO
							cCfOri    := SE1->E1_CLIENTE
							cLojaOri  := SE1->E1_LOJA

							For nLoop := 1 to Len( aRecnos )

								SE1->( dbGoto( aRecnos[ nLoop ] ) )

								If nSavRec <> aRecnos[ nLoop ]
									FImpCriaSFQ("SE1", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
													"SE1", SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, SE1->E1_CLIENTE, SE1->E1_LOJA,;
													SE1->E1_SABTPIS, SE1->E1_SABTCOF, SE1->E1_SABTCSL,;
													If( FieldPos('FQ_SABTIRF') > 0 .And. lAbatIRF .And. cModretIRF =="1", SE1->E1_SABTIRF, 0),;
													SE1->E1_FILIAL )
								Endif
								RecLock( "SE1", .F. )

								//Nao	deve zerar e sim tirar o que esta sendo absorvido
								If lAbatIRF .And. cModRetIRF == "1"
									SE1->E1_SABTIRF := 0
								Endif

								SE1->( MsUnlock() )
							Next nLoop
						Endif

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Retorna do ponteiro do SE1 para a parcela         ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						SE1->( MsGoto( nSavRec ) )
						Reclock( "SE1", .F. )

					Else 	//Fica retencao pendente
						Reclock( "SE1", .F. )
						SE1->E1_PIS    := nVlRetPIS
						SE1->E1_COFINS := nVlRetCOF
						SE1->E1_CSLL   := nVlRetCSL
						SE1->E1_SABTPIS := nVlRetPis
						SE1->E1_SABTCOF := nVlRetCof
						SE1->E1_SABTCSL := nVlRetCsl
						If lAbatIRF .And. cModRetIRF == "1"
							SE1->E1_IRRF    := nVlRetIRF
							SE1->E1_SABTIRF := nVlRetIRF
						Endif
						lAbate := .F.
						MsUnlock()
					EndIf

				EndIf

			ElseIf cRetCli == "2"		//Retem sempre
				lAbate := .T.
				Reclock( "SE1", .F. )
				SE1->E1_PIS    := nVlRetPIS
				SE1->E1_COFINS := nVlRetCOF
				SE1->E1_CSLL   := nVlRetCSL
				SE1->E1_SABTPIS := 0
				SE1->E1_SABTCOF := 0
				SE1->E1_SABTCSL := 0
				MsUnlock()
			ElseIf cRetCli == "3"		//Nao Retem
				lAbate := .F.
				Reclock( "SE1", .F. )
				SE1->E1_PIS    := nVlRetPIS
				SE1->E1_COFINS := nVlRetCOF
				SE1->E1_CSLL   := nVlRetCSL
				If lPccBxCR
					SE1->E1_SABTPIS := nVlRetPis
					SE1->E1_SABTCOF := nVlRetCof
					SE1->E1_SABTCSL := nVlRetCsl
				EndIf
				If lAbatIRF
					SE1->E1_IRRF    := nVlRetIRF
					SE1->E1_SABTIRF := nVlRetIRF
				Endif
				If lIrPjBxCr
					SE1->E1_IRRF    := nVlRetIRF
					SE1->E1_SABTIRF := nVlRetIRF
				Endif
				MsUnlock()
			EndIf
		Endif
	EndIf
	// Impede retencao de ISS se a natureza nao calcular (Inclusao Manual)
	If SE1->E1_ISS > 0 .And. nOldBaseISS == 0
		If SED->ED_CALCISS != "S"
			Reclock("SE1",.F.)
			SE1->E1_ISS := 0
			SE1->(MsUnlock())
		EndIf
	EndIf

	// Impede rentecao de INSS se a natureza nao calcular (Inclusao Manual)
	If SE1->E1_INSS > 0 .And. nOldBaseINS == 0
		If SED->ED_CALCINS == "N" .Or. SED->ED_PERCINS == 0 .Or. SA1->A1_RECINSS == "N"
			Reclock("SE1",.F.)
			SE1->E1_INSS := 0
			SE1->(MsUnlock())
		EndIf
	EndIf

	A040DupRec(IIF(Empty(E1_ORIGEM),"FINA040",E1_ORIGEM),,,lAbate,,(FunName() != "FINA280"),,,.T.,,,,,,cTitpai,,Iif(cPaisLoc == "BRA",SE1->E1_CODIRRF,""))

	//Se houve retencao apenas do Irrf
	If !lPccBxCr .and. lRetSoIrf
		Reclock( "SE1", .F. )
		SE1->E1_PIS 	:= nVlRetPis
		SE1->E1_COFINS := nVlRetCof
		SE1->E1_CSLL 	:= nVlRetCsl
		SE1->E1_SABTPIS := nVlRetPis
		SE1->E1_SABTCOF := nVlRetCof
		SE1->E1_SABTCSL := nVlRetCsl
		MsUnlock()
	Endif
	If 	!lPccBxCr .and. (nTotRetPIS + nTotRetCOF + nTotRetCSL) > 0
		//Se nao reteve totalmente o valor do PCC, armazena o valor restante para posterior retenção
		Reclock( "SE1", .F. )
		SE1->E1_SABTPIS := If(nTotRetPIS>0,nTotRetPIS-nVlRetPIS, 0 )
		SE1->E1_SABTCOF := If(nTotRetCOF>0,nTotRetCOF-nVlRetCOF, 0 )
		SE1->E1_SABTCSL := If(nTotRetCSL>0,nTotRetCSL-nVlRetCSL, 0 )
		MsUnlock()
	EndIf

	//Posiciono na Natureza do titulo para contabilizacao
	SED->(dbGoTo(nRecSED))

	If SE1->E1_TIPO $ MVABATIM     // Abatimento
		AtuSalDup("-",SE1->E1_VALOR,SE1->E1_MOEDA,SE1->E1_TIPO,,SE1->E1_EMISSAO)
	EndIf
Endif

dbSelectArea("SE1")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Caso seja um recebimento antecipado, ir 		³
//³ gerar uma movimenta‡„o banc ria.				³
//³ Caso seja um desdobramento, ir  baixar o		³
//³ titulo gerador do desdobramento					³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
F040GrvSE5(1,lDesdobr,cBancoAdt,cAgenciaAdt,cNumCon,nRecSe1)

If SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Caso seja um recebimento antecipado ou Nota³
	//³ de cr‚dito, ir  subtrair do Saldo Cliente. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	AtuSalDup("-",SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,,SE1->E1_EMISSAO)
	If SE1->E1_FLUXO == 'S'
		AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "3", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),3)
	Endif
Else
	If SE1->E1_MULTNAT # "1" .And. !lDesdobr .And. SE1->E1_FLUXO == 'S' .AND. !(SE1->E1_TIPO $ MVPROVIS)
		AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM,"-","+"),,FunName(),"SE1",SE1->(Recno()),3)
	Endif
EndIf
dbSelectArea("SE1")

If !SE1->E1_TIPO $ MVABATIM .and. GETMV("MV_TPCOMIS") == "O" .and. !lDesdobr .And. FunName() <>  "FINA280" .And. !IsinCallStack("FINA280") .And. !IsInCallStack("FINA460")
	Fa440CalcE("FINA040")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ponto de entrada do F040COM,	 serve p/ tratar Comis-³
	//³sao dos titulos RA.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SE1->E1_TIPO $ MVRECANT
		IF ExistBlock("F040COM")
			ExecBlock("F040COM",.f.,.f.)
		Endif
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Grava Status do SE1											  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !lDesdobr
	Reclock("SE1")
	Replace E1_SDACRES With E1_ACRESC
	Replace E1_SDDECRE With E1_DECRESC

	If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
		Replace E1_STATUS With "A"
	Else
		Replace E1_STATUS With Iif(E1_SALDO >= 0.01,"A","B")
	EndIf

	Replace E1_ORIGEM With IIF(Empty(E1_ORIGEM),"FINA040",E1_ORIGEM)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de entrada do FA040GRV, serve p/ tratar dados ³
	//³ ap¢s estarem gravados.                              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	IF ExistBlock("FA040GRV")
		ExecBlock("FA040GRV",.f.,.f.)
	Endif
	MSUNLOCK()
	FKCOMMIT()

	// Verifica se esta utilizando multiplas naturezas
	If MV_MULNATR .And. SE1->E1_MULTNAT == "1"
		If lF040Auto .And.  !SuperGetMv("MV_RATAUTO",,.F.)	// Abre tela de rateio em rotina automatica
			If aRatEvEz <> Nil
				Multiauto(@aColsSEV,@aHeaderSEV,"SE1","SEV")
			Endif
			If !GrvSevSez(	"SE1", aColsSEV, aHeaderSEV, , Iif(mv_par04 == 1 .or. Alltrim (SE1->E1_ORIGEM)=="FINI055",0,((SE1->(E1_IRRF+E1_INSS+E1_PIS+E1_COFINS+E1_CSLL)) * -1)),,;
						"FINA040", mv_par03==1, @nHdlPrv, @nTotal, @cArquivo )
				DisarmTransaction()
				Return .F.
			Endif
		Else
			// Chama a rotina para distribuir o valor entre as naturezas
			MultNat("SE1",@nHdlPrv,@nTotal,@cArquivo,mv_par03==1,,IF(mv_par04 == 1,0,((SE1->(E1_IRRF+E1_INSS+E1_PIS+E1_COFINS+E1_CSLL)) * -1)),/*lRatImpostos*/, /*aHeaderM*/, /*aColsM*/, /*aRegs*/, /*lGrava*/, /*lMostraTela*/, /*lRotAuto*/, lUsaFlag, aFlagCTB	)
		EndIf
	Endif

	//Valores Acessórios
	If cPaisLoc == "BRA"
		lVincVA := ! Empty(mv_par05) .And. mv_par05 == 1
		If !lDesdobr .And. ( lVincVA .Or. aVAAuto != NIL ) .And. __lFAPodeTVA .And. FAPodeTVA(SE1->E1_TIPO, /*cNatureza*/,.F.,"R")
			If lF040Auto
				If (aVAAuto != NIL)
					If !Fa040VA(.T.)
						DisarmTransaction()
						Return .F.
					Endif
				Endif
			Else
				Fa040VA(.F.)
			Endif
		Endif
	Endif
Endif

//Somente gravo cheques de titulos que nao sejam abatimentos ou provisorios
If (!Type("lF040Auto") == "L" .Or. !lF040Auto) .and. !(SE1->E1_TIPO $ MVPROVIS+"/"+MVABATIM)
	GravaChqCR(,"FINA040") // Grava os cheques recebidos
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualizacao dos dados do Modulo SIGAPMS    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PmsWriteRC(1,"SE1")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Grava os lancamentos nas contas orcamentarias quando nao eh desdobramento - SIGAPCO  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !lDesdobr .And. SE1->E1_MULTNAT # "1"
	If SE1->E1_TIPO $ MVRECANT
		PcoDetLan("000001","02","FINA040")	// Tipo RA
	Else
		PcoDetLan("000001","01","FINA040")
	EndIf
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se sera' gerado lancamento contabil        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ! SE1->E1_TIPO $ MVPROVIS .or. mv_par02 == 1
	If !lDesdobr
		If SE1->E1_TIPO $ MVRECANT
			cPadrao:="501"
		EndIf
		// Se a origem for o Fina280 ou Fina740 (Faturas), descarta a contabilizacao pelo
		// LP500 e deixa para conbilizar na geração da fatura (LP595).
		lPadrao:=VerPadrao(cPadrao) .And. !(FunName() $ "FINA280#FINA460") .And. !( lF040Auto .And. FunName() == "FINA740" .And. FwIsInCallStack("Fin740280") )
		// Validação contabilização on-line pela rotina de funções contas a receber, pela rotina de Liquidação
		lPadrao := If(FunName() == "FINA740" .And. (FwIsInCallStack("Fin740460").or. FwIsInCallStack("FINA460")).And. cPadrao == "500", .F., lPadrao)
		// Validação contabilização on-line LP595 pela rotina de funções contas a receber, pela rotina de Faturas.
		lPadrao := If(FunName() == "FINA740" .And. FwIsInCallStack("FA280AUT") .And. cPadrao == "500", .F., lPadrao)

		IF lPadrao .and. mv_par03 == 1 	// On Line
			// Tratamento de CONTABILIZAÇÃO da inclusão de RECANT(RA) via RETORNO CNAB.
			If lFINA200 .And. lCabec
				nHdlPrv	:= nHdlCNAB
				lCTBCNAB := .T.
			EndIf
			If nHdlPrv <= 0
				nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
			Endif
			If nHdlPrv > 0
				If lUsaFlag  // Armazena em aFlagCTB para atualizar no modulo Contabil
					aAdd( aFlagCTB, {"E1_LA", "S", "SE1", SE1->( Recno() ), 0, 0, 0} )
				Endif

				If UsaSeqCor()
					aAdd( aDiario, {"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"})
				Else
					aDiario := {}
				EndIf

				nTotal += DetProva( nHdlPrv, cPadrao, "FINA040", cLote, /*nLinha*/, /*lExecuta*/,;
				                    /*cCriterio*/, /*lRateio*/, /*cChaveBusca*/, /*aCT5*/,;
				                    /*lPosiciona*/, @aFlagCTB, /*aTabRecOri*/, /*aDadosProva*/ )
			Endif
		Endif
	Endif
	IF (lPadrao .Or. lDesdobr) .and. mv_par03 == 1 .And. nTotal > 0 .And. !lCTBCNAB	// On Line
		//-- Se for rotina automatica força exibir mensagens na tela, pois mesmo quando não exibe os lançametnos, a tela
		//-- sera exibida caso ocorram erros nos lançamentos padronizados
		If lF040Auto
			lSetAuto := _SetAutoMode(.F.)
			lSetHelp := HelpInDark(.F.)
			If Type('lMSHelpAuto') == 'L'
				lMSHelpAuto := !lMSHelpAuto
			EndIf
		EndIf

		RodaProva(nHdlPrv,nTotal)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Indica se a tela sera aberta para digitação			  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		lDigita:=IIF(mv_par01==1 .And. !lF040Auto,.T.,.F.)
		If UsaSeqCor()
			aAdd( aDiario, {"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"})
		Else
			aDiario := {}
		EndIf

		cA100Incl( cArquivo, nHdlPrv, 3 /*nOpcx*/, cLote, lDigita, .F. /*lAglut*/,;
		           /*cOnLine*/, /*dData*/, /*dReproc*/, @aFlagCTB, /*aDadosProva*/, aDiario )
		aFlagCTB := {}  // Limpa o coteudo apos a efetivacao do lancamento

		If lF040Auto
			HelpInDark(lSetHelp)
			_SetAutoMode(lSetAuto)
			If Type('lMSHelpAuto') == 'L'
				lMSHelpAuto := !lMSHelpAuto
			EndIf
		EndIf
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Atualiza Flag de Lancamento contabil		  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF lPadrao .and. mv_par03 == 1  .and. !lDesdobr   // On Line
	If !lUsaFlag // Contabilizacao atraves do modulo contabil.
		Reclock("SE1")
		Replace E1_LA With "S"
		MsUnlock()
	Endif

	nRecSe1 := recno()
	SE2->(DbSetOrder(1))
	cCodFor := GetMv('MV_MUNIC')
	aTam    := TamSx3("E2_FORNECE")
	If (aTam[1]-len(cCodFor))<0
		cCodFor := Subs(cCodFor,1,aTam[1])
	Else
		cCodFor := cCodFor+space((aTam[1]-len(cCodFor)))
	Endif

	// Verifica se o ambiente esta configurado com Multiplos Vinculos de ISS
	If cPaisLoc == "BRA"
		If !Empty( M->E1_CODISS )
			DbSelectArea( "FIM" )
			FIM->( DbSetOrder( 1 ) )
			If FIM->( DbSeek( xFilial( "FIM" ) + M->E1_CODISS ) )
				cCodFor	:= FIM->FIM_CODMUN
			EndIf
		EndIf
	EndIf

	If SE2->(dbSeek(xFilial("SE2")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+"TX "+cCodFor+PadR("00",TamSX3("A2_LOJA")[1],"0")))
		Reclock("SE2")
		Replace E2_LA With "S"
		MsUnlock()
	EndIf
	SE1->(DbGoTo(nRecSe1))

	If SE1->E1_TIPO $ MVRECANT

		dbSelectArea( "FK5" )
		FK5->( DbSetOrder( 1 ) )//FK5_FILIAL+FK5_IDMOV
		If SE5->E5_TABORI== "FK5" .AND. MsSeek( xFilial("FK5") + SE5->E5_IDORIG )

    		If ! FWIsInCallStack( "FINI040" )
                //Necessario para o MVC
                aColsKco := AClone(aCols)
                aCols := NIL
			Endif

			oModel := FWLoadModel('FINM030')//Mov. Bancario
			oModel:SetOperation( 4 ) //Alteração
			oModel:Activate()
			oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5

			//posicionar na FKA
			oSubFKA := oModel:GetModel( "FKADETAIL" )
			oSubFKA:SeekLine( { {"FKA_IDORIG", SE5->E5_IDORIG } } )

			//Dados do movimento
			oSubFK5 := oModel:GetModel( "FK5DETAIL" )
			oSubFK5:SetValue( "FK5_LA", "S" )

			If oModel:VldData()
		       oModel:CommitData()
		       oModel:DeActivate()
		       oModel:Destroy()
		       oModel := NIL
		       oSubFKA := nil
		       oSubFK5 := nil
			Else

 				cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
				cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
    			cLog += cValToChar(oModel:GetErrorMessage()[6])

    			If (Type("lF040Auto") == "L" .and. lF040Auto)
					Help( ,,"M040VALID",,cLog, 1, 0 )
				Endif
		       oModel:DeActivate()
		       oModel:Destroy()
		       oModel := NIL
		       oSubFKA := nil
		       oSubFK5 := nil

				DisarmTransaction()
				return
			Endif
			aCols := AClone(aColsKco)
		Endif
	EndIf
EndIf

If cPaisLoc == "PAR" .And. AllTrim(SE1->E1_TIPO) $ AllTrim(MVCHEQUE)
	Reclock("SE1",.F.)
	Replace E1_NUMCHQ With E1_NUM
	MsUnlock()
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada do FA040FIN, serve p/ tratar dados ³
//³ antes de sair da rotina.                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("FA040FIN")
	ExecBlock("FA040FIN",.f.,.f.)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Apaga o arquivo da Indregua                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If lContrAbt .and. !Empty(cIndexSE1)
	FErase( cIndexSE1+OrdBagExt() )
Endif

If SE1->E1_TIPO $ MVABATIM .or. SuperGetMv("MV_IMPCMP",,"2") == "1"
	cTipoAbat := SE1->E1_TIPO
	nRecAbt   := SE1->(RECNO())
	// Procura titulo que gerou o abatimento, titulo pai
	SE1->(DbSeek(xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)))
	While SE1->(!Eof()) .And.;
			SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == xFilial("SE1")+cPrefOri+cNumOri+cParcOri
		If !SE1->E1_TIPO $ MVABATIM
			lAchouPai := .T.
			nRecSE1P	:= SE1->(RECNO())
			Exit // Encontrou o titulo
		Endif
		SE1->(DbSkip())
	End
	If lAchouPai
		// Nao trata instrucao de titulo de abatimento, somente informando o valor de abatimento/desconto no titulo principal
		If ! ( cTipoAbat $ MVABATIM )
			If !Empty(SE1->E1_IDCNAB) .And. !Empty(SE1->E1_PORTADO) .And. MsgYesNo(STR0083,STR0039) // "Deseja cadastrar instrução de cobrança para a alteração efetuada para posterior envio ao banco?"
				Fa040AltOk({Space(10) }, { "" },, .T.)
				F040GrvFI2()
			Endif
		EndIf
		//Acerta valores dos impostos na inclusão do abatimento.
		SE1->(dbGoto(nRecAbt)) //reposiciono no AB-
		F040ActImp(nRecSE1P,M->E1_VALOR,.F.,0,0)
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Tratamento para quando o título for de PCC e tenha sido    ³
//³ gerado manualmente, se busque o título retentor e grave-se ³
//³ os dados referentes aos devidos campos de impostos         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If SE1->E1_TIPO $ "PI-|CS-|CF-"
	cBuscSe1 := xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)
	nValSe1 := SE1->E1_VALOR
	nRecSe1 := 0
	cTipSe1 := SE1->E1_TIPO
	dbSelectArea("SE1")
	dbSeek(cBuscSe1)
	Do While !Eof() .And. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == cBuscSe1
		If !(SE1->E1_TIPO $ "PI-|CS-|CF-") .and. Empty(SE1->E1_TITPAI) // Achou o titulo principal
		   nRecSe1 := Recno()
		   Exit
		Endif
	    dbSkip()
	Enddo

	If nRecSe1 > 0 .And. nValSe1 > 0
		SE1->(dbGoto(nRecSe1))
		Reclock("SE1",.F.)
		If cTipSe1 == "PI-"
			SE1->E1_PIS := nValSe1
		ElseIf cTipSe1 == "CS-"
			SE1->E1_CSLL := nValSe1
		ElseIf cTipSe1 == "CF-"
			SE1->E1_COFINS := nValSe1
		Endif
	Endif
Endif
SE1->(dbGoto(nRecAtu))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Ponto de entrada do F040FCR, serve p/ tratar dados ³
//³ antes de sair da rotina e depois de calcular ABT    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF lF040FCR
	ExecBlock("F040FCR",.F.,.F.)
Endif
// Restaura filial caso a importacao MILE tenha gestao corporativa
If lMile .And. cFilAnt <> cFilAux
	cFilAnt := cFilAux
EndIf
End Transaction

If lIMPLJRE
	If lLOJRREC .Or. lULOJRREC
		If Alltrim(SE1->E1_TIPO) = "RA"
			aadd(aTitBx, {	SE1->E1_NUM				,;	//01-Nro do Titulo
			       			SE1->E1_PREFIXO			,;	//02-Prefixo
			       			SE1->E1_PARCELA			,;	//03-Parcela
			       			SE1->E1_TIPO			,;	//04-Tipo
			       			SE1->E1_CLIENTE			,;	//5-Cliente
			       			SE1->E1_LOJA			,;	//6-Loja
			       			Dtos(SE1->E1_VENCREA)	,;	//7-Emissao
			       			Dtos(SE1->E1_VENCREA)	,;	//8-Vencimento
			       			SE1->E1_VALOR			,;	//9-Valor Original
			       			SE1->E1_SALDO			,;	//10-Saldo
			       			0						,;	//11Multa
			       			0						,;	//12Juros
			       			0						,;	//13Desconto
			       			SE1->E1_VALOR			})	//14Valor Recebido

			aadd(aFormPg	,{	"RA"					,;	//Forma de Pagamento
								SE1->E1_VALOR			,;	//Valor
								Dtos(SE1->E1_VENCREA)	,;	//Data do Pagamento
								""						,;	//Numero do Cheque
								""						,;	//Banco
								""						,;	//Agencia
								""						,;	//Conta Corrente
								""						})	//Nome do Terceiro
		Endif

		If lULOJRREC
			//Fonte não será mais padrao mas sim um RDMake padrão.
			U_LOJRRecibo(SE1->E1_CLIENTE, SE1->E1_LOJA, aTitBx, aFormPg)
		Else
			LOJRREC(SE1->E1_CLIENTE, SE1->E1_LOJA, aTitBx, aFormPg)
		EndIf
	Endif
Endif

Return


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040AxAlt³ Autor ³ Mauricio Pequim Jr	  ³ Data ³ 04/08/99 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Fun‡Æo para complementacao da Alteracao  de C.Receber		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040AxAlt(ExpC1) 													  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo											  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040AxAlt(cAlias)

Local nValorInss
Local cCliente := SE1->E1_CLIENTE
Local cLoja    := SE1->E1_LOJA
Local cPrefixo := SE1->E1_PREFIXO
Local cTPTIT   := SE1->E1_TIPO
Local cVar
Local nK
Local nRegSe2
Local dVenIss
Local nValorIr
Local nRegSe1 	:= RecNo()
Local nRegSed
Local cNum		:= E1_NUM
Local cParcela := E1_PARCELA
Local dVencto 	:= E1_VENCREA
Local dEmissao := SE1->E1_EMISSAO
Local dVencRea := SE1->E1_VENCREA
Local lSpbinUse := SpbInUse()
Local cModSpb		:= "1"
Local nValorCsll
Local nValorPis
Local nValorCofins
Local dVenCSLL := dDatabase
Local dVenCOFINS := dDatabase
Local dVenPIS := dDatabase
Local nTotal	:= 0
Local nHdlPrv	:= 0
Local cArquivo	:= ""
Local aArea		:= GetArea()
Local lAbate   := .T.
Local lVldFIV	:= .F.
Local aGetSE1	:= {}
Local nTotARet  := 0
Local nSobra    := 0
Local nFatorRed := 0
Local nLoop     := 0
Local nValMinRet := GetNewPar("MV_VL10925",5000)
Local cModRet   := GetNewPar( "MV_AB10925", "0" )
Local lContrAbt :=	.T.
Local cRetCli   := "1"
Local cPrefOri  := SE1->E1_PREFIXO
Local cNumOri   := SE1->E1_NUM
Local cParcOri  := SE1->E1_PARCELA
Local cTipoOri  := SE1->E1_TIPO
Local cCfOri    := SE1->E1_CLIENTE
Local cLojaOri  := SE1->E1_LOJA
Local lZerouImp := .F.
Local lRestValImp := .F.
Local nX := 0
Local nDiferImp := 0
Local cKeySE1 := ""
Local cLojaIrf := Padr( "00", Len( SE2->E2_LOJA ), "0" )
Local cParcIRF := ""
Local cUniao	:= SuperGetMV("MV_UNIAO")
Local cMunic	:= SuperGetMV("MV_MUNIC")
Local lOkMultNat := (SE1->E1_MULTNAT != "1" .or. (SE1->E1_MULTNAT == "1" .AND. F070RTMNBL()))
Local nIssAlt := SE1->E1_ISS
Local aSavCols := {}
Local aSavHead := {}
Local nProp	:= 1
Local nTotGrupo := 0
Local lRetBaixado := .F.
Local nBaseAntiga := 0
Local nBaseAtual := 0
Local nValorDDI := 0
Local nValorDif := 0
Local nImp10925 := ChkAbtImp(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_MOEDA,"V",SE1->E1_BAIXA)
Local cNome		:= STR0036

//1-Cria NCC/NDF referente a diferenca de impostos entre emitidos (SE2) e retidos (SE5)
//2-Nao Cria NCC/NDF, ou seja, controla a diferenca num proximo titulo
//3-Nao Controla
Local cNccRet  := SuperGetMv("MV_NCCRET",.F.,"1")

Local cModRetIRF 	:= GetNewPar("MV_IRMP232", "0" )

Local lAbatIRF  	:= cPaisLoc == "BRA"

Local lImpComp := SuperGetMv("MV_IMPCMP",,"2") == "1"
Local nDia
Local nDiaUtil
Local dVencReaAux
Local aDadRet 		:= {,,,,,,,.F.}
Local aTab		:= {}
Local lTemSfq := .F.
Local lCriaSfq	:= .F.

//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr			:= FPccBxCr()
//Controla IRPJ na baixa
Local lIrPjBxCr		:= FIrPjBxCr()

//639.04 Base Impostos diferenciada
Local lBaseImp	:= F040BSIMP(IIf(Upper(FunName()) == "FINA070",Iif(ValType(lAlterImp)!="U" .And. lAlterImp,2,1),1))
Local lZerouPcc := .F.
Local nValBase	:= If(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR )
Local cLojaImp	:= PadR( "00", TamSX3("A2_LOJA")[1], "0" )
Local nSabtPis	:= 0
Local nSabtCof	:= 0
Local nSabtCsl	:= 0
Local aExclPCC := {}
Local lNoDDINCC	:= .T.
Local nVlrCalc1 := 0
Local nVlrCalc2 := 0
Local lGrvSa1  := .T.
Local lNCalcIr := .F.
/*
Utiliza o codigo do aprovador padrao para os titulos de retencao gerado no contas a pagar */
Local cCodAprov := If(SuperGetMV( "MV_FINCTAL", .T., "1" ) == "2",FA050Aprov(1)," ")
Local lAltNatur := .F.
Local aAreaSED
Local cTitPai		:= SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)
Local lIss			:= .F.
Local nDifSdAcre	:= 0

Local lGestao   := FWSizeFilial() > 2	// Indica se usa Gestao Corporativa
Local lSE1Comp  := FWModeAccess("SE1",3)== "C" // Verifica se SE1 é compartilhada

DEFAULT _lNoDDINCC := ExistBlock( "F040NDINC" )
nOldBase := If(Type("nOldBase") != "N", nOldValor, nOldBase)
lF040Auto	:= Iif(Type("lF040Auto") != "L", .F., lF040Auto )

If SE1->E1_EMISSAO >= dLastPcc
	nValMinRet	:= 0
EndIf

If cPaisLoc == "BRA"
	cMunic := IIF(!Empty(SE1->E1_FORNISS),SE1->E1_FORNISS,cMunic)
EndIf

If lContrAbt
	SA1->(DBSetOrder(1))
	SA1->(DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))
	If cPaisLoc == "BRA"
		cRetCli := Iif(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
	Endif

	//Verifica se o PCC foi zerado na alteracao
	SED->(DBSetOrder(1))
	SED->(MSSeek(xFilial("SED")+SE1->E1_NATUREZ))
	If SE1->(E1_PIS + E1_COFINS + E1_CSLL) == 0
		//Verificar se nao existe PCC retido (calculado) para este titulo. Somente neste caso zerar.
		If (nVlRetPis + nVlRetCof + nVlRetCsl) == 0
			lZerouPcc := .T.
		Endif
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³A funcao que alimenta a variavel nImp10925 que determinara     ³
//³se devera haver o recalculo dos impostos de PCC (Fa040AltImp)  ³
//³recebe apenas o valor da funcao (ChkAbtImp), que calcula       ³
//³apenas os abatimentos (no caso PCC) associados ao proprio      ³
//³titulo. Deve-se validar se este titulo teve o PCC gerado       ³
//³por outro titulo, para definir se o recalculo eh necessario.   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nImp10925 == 0 .AND. !lZerouPCC
	//Pesquisar se o titulo teve PCC gerado
	dbSelectArea("SFQ")
	SFQ->(dbSetOrder(2))
	If SFQ->(dbSeek(xFilial("SFQ") + "SE1" + SE1->(E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA)))
		//Se encontrou o SFQ, verificar se o titulo PAI gerou PCC
		ChkFile("SE1",.F.,"_SE1PCC")
		_SE1PCC->(dbSetOrder(1))
		_SE1PCC->(dbSeek(xFilial("SE1") + SFQ->FQ_PREFORI + SFQ->FQ_NUMORI + SFQ->FQ_PARCORI))
		Do While !_SE1PCC->(Eof()) .AND. _SE1PCC->(E1_FILIAL + E1_PREFIXO + E1_NUM + E1_PARCELA) == ;
			xFilial("SE1") + SFQ->FQ_PREFORI + SFQ->FQ_NUMORI + SFQ->FQ_PARCORI

			If _SE1PCC->E1_TIPO # 'AB-' .AND. _SE1PCC->E1_TIPO $ MVCSABT + "|" + MVCFABT + "|" + MVPIABT
				nImp10925 += xMoeda(_SE1PCC->E1_VALOR,_SE1PCC->E1_MOEDA,_SE1PCC->E1_MOEDA,_SE1PCC->E1_BAIXA)
			Endif
			_SE1PCC->(dbSkip())
		EndDo
		_SE1PCC->(dbCloseArea())
	Endif
Endif

SE1->(dbSetOrder(1))
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se houver alteracao de valor 	  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Reclock("SE1")
If (SE1->E1_ACRESC != nOldVlAcres)
	IF nOldVlAcres != nOldSdAcres
		nDifSdAcre := nOldVlAcres - nOldSdAcres
	EndIF
	SE1->E1_SDACRES := SE1->E1_ACRESC - nDifSdAcre
Endif
If (SE1->E1_DECRESC != nOldVlDecres)
	SE1->E1_SDDECRE := SE1->E1_DECRESC
Endif

//639.04 Base Impostos diferenciada
//Gravo a base dos impostos para este titulo
If lBaseImp .and. SE1->E1_BASEIRF > 0
	RecLock("SE1")
	SE1->E1_BASEINS := E1_BASEIRF
	SE1->E1_BASEISS := E1_BASEIRF
	SE1->E1_BASEPIS := Iif(lF040Auto .And. E1_BASEPIS > 0 .And. E1_BASEPIS <> E1_BASEIRF,E1_BASEPIS,E1_BASEIRF)
	SE1->E1_BASECOF := Iif(lF040Auto .And. E1_BASECOF > 0 .And. E1_BASECOF <> E1_BASEIRF,E1_BASECOF,E1_BASEIRF)
	SE1->E1_BASECSL := Iif(lF040Auto .And. E1_BASECSL > 0 .And. E1_BASECSL <> E1_BASEIRF,E1_BASECSL,E1_BASEIRF)
Endif

If SE1->E1_MULTNAT != "1"
	If SE1->E1_FLUXO == 'S'
		// Tiro o valor da natureza antiga
		If cFilAnt == SE1->E1_FILORIG
			If lGestao
				If lSE1Comp
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
				Else
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
				Endif
			Else
				If lSE1Comp
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
				Else
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
				Endif
			Endif
		Else
			If lGestao
				If lSE1Comp
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
				Else
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
				Endif
			Else
				If lSE1Comp
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
				Else
					AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", nOldValor, nOldVlCruz, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					// Somo o valor na nova natureza
					AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, IIf(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
				Endif
			Endif
		Endif

		aGetSE1 := SE1->(GetArea())
		cTitPai := SE1->(E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA)

		SE1->(DbSetOrder(28))
		FIV->(DbSetOrder(1))

		If SE1->(DbSeek(xFilial("SE1") + cTitPai))
			While !SE1->(EOF()) .And. Alltrim(SE1->E1_TITPAI) == Alltrim(cTitPai)
				If cFilAnt == SE1->E1_FILORIG
					lVldFIV	:= .T.
					If lGestao
						If lSE1Comp
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
						Else
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
						Endif
					Else
						If lSE1Comp
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
						Else
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
						Endif
					Endif
				Else
					lVldFIV	:= .T.
					If lGestao
						If lSE1Comp
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
						Else
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
						Endif
					Else
						If lSE1Comp
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
						Else
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "+","-"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
						Endif
					Endif
				Endif
				SE1->(DbSkip())
			Enddo
		Endif
		RestArea(aGetSE1)
	Endif
Endif

IF SE1->E1_VALOR != nOldValor
	If SE1->E1_MULTNAT == "1"
		aSavCols := AClone(aCols)
		aSavHead := AClone(aHeader)
		aCols    := AClone(aColsMulNat)
		aHeader  := AClone(aHeadMulNat)
		MultNat("SE1",@nHdlPrv,@nTotal,@cArquivo,mv_par03==1,4,IF(mv_par04 == 1,0,((SE1->(E1_IRRF+E1_INSS+E1_PIS+E1_COFINS+E1_CSLL)) * -1)),;
				.T.,aHeader, aCols, aRegs, .T., .F.) // Chama a rotina para distribuir o valor entre as naturezas
		aColsMulNat := AClone(aCols)
		aHeadMulNat := AClone(aHeader)
		aCols       := AClone(aSavCols)
		aHeader     := AClone(aSavHead)
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de entrada do SigaLoja, serve p/ atualizar os ³
	//³ valores dos t¡tulos no SEF (Cheques).               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ExistBlock("LJ040X")
		ExecBlock("LJ040X",.f.,.f.)
	EndIf

	Reclock("SE1")
	SE1->E1_SALDO := SE1->E1_VALOR
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Grava Status do SE1 										  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
		SE1->E1_STATUS := "A"
	Else
		SE1->E1_STATUS := Iif(E1_SALDO >= 0.01,"A","B")
	EndIf

	If lTravaSA1
	   	lGrvSa1:= ExecBlock("F040TRVSA1",.F.,.F.)
	Endif

	dbSelectArea("SA1")
	SA1->(DBSetOrder(1))
	DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)
	nMoeda		:= If(SA1->A1_MOEDALC > 0, SA1->A1_MOEDALC, Val(SuperGetMV("MV_MCUSTO")))
	nValForte := ConvMoeda(E1_EMISSAO,E1_VENCTO,Moeda(E1_VALOR,1,"R"),AllTrim(STR(nMoeda)))
	If !(SE1->E1_TIPO $ MVPROVIS)
		If !(SE1->E1_TIPO $ MVABATIM+"/"+MVRECANT+"/"+MV_CRNEG )
			AtuSalDup("+",SE1->E1_SALDO-nOldValor,SE1->E1_MOEDA,SE1->E1_TIPO,,SE1->E1_EMISSAO,,,lGrvSa1)
			nVlrCalc1 := Round(NoRound(xMoeda(nOldValor,SE1->E1_MOEDA,nMoeda,SE1->E1_EMISSAO,3,SE1->E1_TXMOEDA),3),2)
			nVlrCalc2 := Round(NoRound(xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMoeda,SE1->E1_EMISSAO,3,,SE1->E1_TXMOEDA),3),2)
			If lGrvSa1
				RecLock("SA1")
				SA1->A1_VACUM  -= nVlrCalc1
				SA1->A1_VACUM  += nVlrCalc2
				MsUnLock()
			EndIf
		Else
			AtuSalDup("+",nOldValor-SE1->E1_SALDO,SE1->E1_MOEDA,SE1->E1_TIPO,,SE1->E1_EMISSAO,,,lGrvSa1)
		Endif

		If nValForte > A1_MAIDUPL
			If lGrvSa1
				RecLock("SA1",.F.)
				Replace A1_MAIDUPL With nValForte
				MsUnLock()
			EndIf
		EndIf
	Endif
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Efetua a atualizacao dos arquivos do SIGAPMS        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
PmsWriteRC(2,"SE1")	//Estorno
PmsWriteRC(4,"SE1") //Alteracao

If lSpbInUse
	cModSpb := IIf(Empty(SE1->E1_MODSPB),"1",SE1->E1_MODSPB)
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se houve alteracao de Irrf		  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If !SE1->E1_TIPO $ MVABATIM
	nSavRec := SE1->( Recno() )
	//Se não há retenção de IR, deleta o titulo
	// ou se a retenção passou do cliente para o emissor
	// ou do emissor para o cliente.
	If ( ;
				( ( cOldNatur != SE1->E1_NATUREZ ) .AND. ( SE1->E1_IRRF = 0 ) );	//Se alterou natureza e não ha mais retencão de IR
		.OR. 	( ( cOldNatur != SE1->E1_NATUREZ ) .AND. ( SE1->E1_IRRF != 0 ) );	//Se alterou a natureza mas será recriado o titulo de IR
		)

	 	nRegSe1 := SE1->(RecNo())	//Quardo recno titulo SE1 posicionado
		aAreaSED := SED->(GetArea())
		lNCalcIr := SED->ED_CALCIRF == 'N'
		SED->(DBSetOrder(1))
		If SED->(DbSeek(xFilial("SED")+cOldNatur))
			//Deleta o titulo de IR gerado para o emissor
			If ( cPaisLoc == "BRA" .AND. SED->(FieldPos("ED_RECIRRF")) > 0 .AND. SED->ED_RECIRRF == "2" );
				.OR. ((cPaisLoc == "BRA" .AND. SA1->A1_RECIRRF == "2") .AND. (cPaisLoc == "BRA" .AND. SED->(FieldPos("ED_RECIRRF")) > 0 .AND. (SED->ED_RECIRRF == "3" .OR. SED->ED_RECIRRF == " ") ) )
				DbSelectArea("SE2")
				nRegSe2  := RecNo()
				If DbSeek(xFilial("SE2")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCIRF)+MVTAXA+cUniao+Space(TamSX3("A2_COD")[1]-Len(cUniao))+cLojaIRF)
					PcoDetLan("000001","12","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de IRRF
					Reclock("SE2",.F.,.T.)
					dbDelete()
					MsUnlock()
					dbGoto(nRegSe2)
				EndIf
			//Deleta o titulo de IR gerado para o cliente
			Else
				dbSelectArea("SE1")
				If (DbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+MVIRABT)) .AND.  lNCalcIr
					PcoDetLan("000001","06","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de IRRF
					Reclock("SE1",.F.,.T.)
					dbDelete()
					MsUnlock()
				EndIf
			EndIf
		EndIf

		dbGoto(nRegSe1)	//Restaura titulo posicionado
		RestArea(aAreaSED)

	//Se alterou o valor mas não alterou a natureza
	ElseIf ( ( SE1->E1_IRRF != nOldIrrf .And. nOldIrrf != 0 );
			.OR. ( cOldNatur = SE1->E1_NATUREZ ) );
			.And. lOkMultNat

		nRegSe1 := SE1->(RecNo())
		nValorIr:= SE1->E1_IRRF
		If cPaisLoc == "BRA"
			If ( SED->(FieldPos("ED_RECIRRF")) > 0 .AND. SED->ED_RECIRRF == "2" );
					.OR. ( SA1->A1_RECIRRF == "2" .AND. ( SED->(FieldPos("ED_RECIRRF")) > 0 .AND. (SED->ED_RECIRRF == "3" .OR. SED->ED_RECIRRF == " ") ) )

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Cria o Fornecedor, caso nao exista 		   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea("SA2")
				SA2->(DBSetOrder(1))
				If ! DbSeek(xFilial("SA2")+cUniao+Space(TamSX3("A2_COD")[1]-Len(cUniao))+cLojaIRF)
					Reclock("SA2",.T.)
					SA2->A2_FILIAL  := xFilial("SA2")
					SA2->A2_COD 	:= cUniao
					SA2->A2_LOJA	:= cLojaIRF
					SA2->A2_NOME	:= "UNIAO"
					SA2->A2_NREDUZ := "UNIAO"
					SA2->A2_BAIRRO := "."
					SA2->A2_MUN 	:= "."
					SA2->A2_EST 	:= SuperGetMv("MV_ESTADO")
					SA2->A2_End 	:= "."
					SA2->A2_TIPO	:= "J"
					MsUnlock()
				EndIf

				DbSelectArea("SE2")
				nRegSe2  := RecNo()
				If DbSeek(xFilial("SE2")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCIRF)+MVTAXA+cUniao+Space(TamSX3("A2_COD")[1]-Len(cUniao))+cLojaIRF)
					If SE1->E1_IRRF != 0
						//Só efeuta a alteração no caso de valores diferentes
						If SE2->E2_VALOR <> SE1->E1_IRRF
							Reclock("SE2")
							//Baixa do título de imposto, parcial ou total
							If SE2->E2_SALDO <> SE2->E2_VALOR
								If SE2->E2_VALOR < SE1->E1_IRRF
									SE2->E2_SALDO += SE1->E1_IRRF - SE2->E2_VALOR
								EndIf
							Else
								SE2->E2_SALDO := SE1->E1_IRRF
							EndIf
							SE2->E2_VALOR := SE1->E1_IRRF
							PcoDetLan("000001","12","FINA040")		// Altera lançamento no PCO ref. a retencao de IRRF
						EndIf
					Else
						PcoDetLan("000001","12","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de IRRF

							cChaveFK7 := xFilial("SE2")+"|"+SE2->E2_PREFIXO+"|"+SE2->E2_NUM+"|"+SE2->E2_PARCELA+"|"+;
										SE2->E2_TIPO+"|"+SE2->E2_FORNECE+"|"+SE2->E2_LOJA
							FINDELFKs(cChaveFK7,"SE2")

						Reclock("SE2",.F.,.T.)
						dbDelete()
					Endif
					Msunlock()
				Else
					nOldIss := 0
				Endif
				dbGoto(nRegSe2)
			EndIf
		Else
			dbSelectArea("SE1")
			If (DbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+MVIRABT))
				If nValorIr != 0
					Reclock("SE1")
					SE1->E1_VALOR := nValorIr
					SE1->E1_SALDO := nValorIr
					If ( cPaisLoc == "CHI" )
						SE1->E1_VLCRUZ:= Round( nValorIr, MsDecimais(1) )
					Else
						SE1->E1_VLCRUZ:= nValorIr
					Endif
					PcoDetLan("000001","06","FINA040")	// Altera lançamento no PCO ref. a retencao de IRRF
				Else
					PcoDetLan("000001","06","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de IRRF

					cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
								SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
					FINDELFKs(cChaveFK7,"SE1")

					Reclock("SE1",.F.,.T.)
					dbDelete()
				Endif
				Msunlock()
			Else
				nOldIrrf := 0
			Endif
		Endif
		dbGoto(nRegSe1)
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se informado IRRf sem existir	  ³
	//³ anteriormente.									  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//Se há retencao de IR, cria o titulo
	If nOldIrrf = 0 .And. SE1->E1_IRRF != 0 .And. lOkMultNat

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria a natureza IRF caso nao exista		  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aAreaSED := SED->(GetArea())
		dbSelectArea("SED")
		SED->(DBSetOrder(1))
		cVar := Alltrim(&(SuperGetMv("MV_IRF")))
		cVar := cVar + Space(10-Len(cVar))
		If !(DbSeek(xFilial("SED")+cVar))
			RecLock("SED",.T.)
			SED->ED_FILIAL  := xFilial()
			SED->ED_CODIGO  := cVar
			SED->ED_CALCIRF := "N"
			SED->ED_CALCISS := "N"
			SED->ED_CALCINS := "N"
			SED->ED_CALCCSL := "N"
			SED->ED_CALCCOF := "N"
			SED->ED_CALCPIS := "N"
			SED->ED_DESCRIC := STR0035  // "IMPOSTO RENDA RETIDO NA FONTE"
			SED->ED_TIPO	:= "2"
			Msunlock()
			FKCommit()
		Endif
		RestArea(aAreaSED)

		nValorIr := SE1->E1_IRRF
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gera titulo de IRRF								  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//If cPaisLoc == "BRA" .And. SA1->A1_RECIRRF=="2" .And. !lIrPjBxCr
		If ( ( SED->(FieldPos("ED_RECIRRF")) > 0 .AND. SED->ED_RECIRRF == "2" );
				.OR. ( SA1->A1_RECIRRF == "2" .AND. ( SED->(FieldPos("ED_RECIRRF")) > 0 .AND. (SED->ED_RECIRRF == "3" .OR. SED->ED_RECIRRF == " ") ) ) .And. !lIrPjBxCr )
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Cria o Fornecedor, caso nao exista 		  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			DbSelectArea("SA2")
			SA2->(DBSetOrder(1))
			DbSeek(xFilial("SA2")+cUniao+Space(Len(A2_COD)-Len(cUniao))+cLojaIRF)
			If ( EOF() )
				Reclock("SA2",.T.)
				SA2->A2_FILIAL  := xFilial("SA2")
				SA2->A2_COD 	:= cUniao
				SA2->A2_LOJA	:= cLojaIRF
				SA2->A2_NOME	:= "UNIAO"
				SA2->A2_NREDUZ := "UNIAO"
				SA2->A2_BAIRRO := "."
				SA2->A2_MUN 	:= "."
				SA2->A2_EST 	:= SuperGetMv("MV_ESTADO")
				SA2->A2_End 	:= "."
				SA2->A2_TIPO	:= "J"
				MsUnlock()
			EndIf
			cParcIRF := ParcImposto(cPrefixo,cNum,MVTAXA)

			dVencReaAux := dVencRea
			dVencRea	:= F050vImp("IRRF",dEmissao,dDataBase,dVencrea)

			RecLock("SE2",.T.)
			SE2->E2_FILIAL	:= xFilial("SE2")
			SE2->E2_PREFIXO	:= cPrefixo
			SE2->E2_NUM		:= cNum
			SE2->E2_PARCELA	:= cParcIRF
			SE2->E2_TIPO	:= MVTAXA
			SE2->E2_EMISSAO	:= dEmissao
			SE2->E2_VALOR	:= nValorIr
			SE2->E2_VENCREA	:= dVencrea
			SE2->E2_SALDO	:= nValorIr
			SE2->E2_VENCTO	:= dVencRea
			SE2->E2_VENCORI	:= dVencRea
			SE2->E2_MOEDA	:= 1
			SE2->E2_EMIS1	:= dDataBase
			SE2->E2_FORNECE	:= cUniao
			SE2->E2_VLCRUZ	:= Round(nValorIr, MsDecimais(1) )
			SE2->E2_LOJA	:= SA2->A2_LOJA
			SE2->E2_NOMFOR	:= SA2->A2_NREDUZ
			SE2->E2_NATUREZ	:= &(SuperGetMv("MV_IRF"))
			SE2->E2_CODAPRO	:= cCodAprov
			MsUnLock()
			//GRAVAR A PARCELA DO IRRF NO TITULO PRINCIPAL NO SE1
			DbSelectArea("SE1")
			If cPaisLoc == "BRA"
				DbGoTo(nRegSE1)
				RecLock("SE1",.F.)
				SE1->E1_PARCIRF	:= cParcIRF
				MsUnLock()
			Endif
			PcoDetLan("000001","12","FINA040")	// Gera lançamento no PCO ref. a retencao de IRRF
			dVencRea := dVencReaAux

		Elseif !lIrPjBxCr
			RecLock("SE1",.T.)
			SE1->E1_FILIAL  := xFilial("SE1")
			SE1->E1_PREFIXO := cPrefixo
			SE1->E1_NUM	    := cNum
			SE1->E1_PARCELA := cParcela
			SE1->E1_NATUREZ := &(SuperGetMv("MV_IRF"))
			SE1->E1_TIPO	 := MVIRABT
			SE1->E1_EMISSAO := dEmissao
			SE1->E1_VALOR   := nValorIr
			SE1->E1_VENCREA := dVencrea
			SE1->E1_SALDO   := nValorIr
			SE1->E1_VENCTO  := dVencRea
			SE1->E1_VENCORI := dVencRea
			SE1->E1_EMIS1   := dDataBase
			SE1->E1_CLIENTE := cCliente		// Grava o cliente do proprio titulo
			SE1->E1_LOJA	 := cLoja			// Grava a loja do proprio titulo
			SE1->E1_NOMCLI  := SA1->A1_NREDUZ
			SE1->E1_MOEDA   := 1
			If ( cPaisLoc == "CHI" )
				SE1->E1_VLCRUZ  := Round( nValorIr, MsDecimais(1) )
			Else
				SE1->E1_VLCRUZ  := nValorIr
			Endif
			If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
				SE1->E1_STATUS := "A"
			Else
				SE1->E1_STATUS := Iif(E1_SALDO >= 0.01,"A","B")
			EndIf

			SE1->E1_SITUACA := "0"
			SE1->E1_OCORREN := "04"
			SE1->E1_TITPAI  := cTitPai
			Msunlock()
			PcoDetLan("000001","06","FINA040")	// Gera lançamento no PCO ref. a retencao de IRRF
		Endif
	Endif

	dbSelectArea("SE1")
	dbGoto(nRegSe1)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se houve alteracao de INSS		  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SE1->E1_INSS != nOldInss .and. nOldInss != 0 .And. lOkMultNat
		nRegSe1 := RecNo()
		nValorInss:= SE1->E1_INSS
		dbSelectArea("SE1")
		If (DbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+MVINABT))
			If nValorInss != 0
				Reclock("SE1")
				SE1->E1_VALOR := nValorInss
				SE1->E1_SALDO := nValorInss
				If ( cPaisLoc == "CHI" )
					SE1->E1_VLCRUZ:= Round( nValorInss, MsDecimais(1) )
				Else
					SE1->E1_VLCRUZ:= nValorInss
				Endif
				PcoDetLan("000001","07","FINA040")	// Altera lançamento no PCO ref. a retencao de INSS
			Else
				PcoDetLan("000001","07","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de INSS
				cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
							SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
				FINDELFKs(cChaveFK7,"SE1")

				Reclock("SE1",.F.,.T.)
				dbDelete()
			Endif
			Msunlock()
		Else
			nOldInss := 0
		Endif
		dbGoto(nRegSe1)
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se informado INSS sem existir	  ³
	//³ anteriormente.									  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nOldInss = 0 .And. SE1->E1_INSS != 0 .And. lOkMultNat
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria a natureza INSS caso nao exista		  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SED")
		SED->(DBSetOrder(1))
		cVar := Alltrim(&(SuperGetMv("MV_INSS")))
		cVar := cVar + Space(10-Len(cVar))
		If !(DbSeek(xFilial("SED")+cVar))
			RecLock("SED",.T.)
			SED->ED_FILIAL  := xFilial()
			SED->ED_CODIGO  := cVar
			SED->ED_CALCIRF := "N"
			SED->ED_CALCISS := "N"
			SED->ED_CALCINS := "N"
			SED->ED_CALCCSL := "N"
			SED->ED_CALCCOF := "N"
			SED->ED_CALCPIS := "N"
			SED->ED_DESCRIC := STR0052 //"RETENCAO P/ SEGURIDADE SOCIAL"
			SED->ED_TIPO	:= "2"
			Msunlock()
			FKCommit()
		Endif
		nValorInss := SE1->E1_INSS
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gera titulo de INSS								  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		SED->( dbSetOrder(1) ) //ED_FILIAL+ED_CODIGO
		SED->( dbSeek(xFilial("SED") + SE1->E1_NATUREZ) )
		If (SED->ED_CALCINS == "S" .and. ED_PERCINS > 0) .and. (SA1->A1_RECINSS ==  "S")
			RecLock("SE1",.T.)
			SE1->E1_FILIAL  := xFilial("SE1")
			SE1->E1_PREFIXO := cPrefixo
			SE1->E1_NUM	    := cNum
			SE1->E1_PARCELA := cParcela
			SE1->E1_NATUREZ := &(SuperGetMv("MV_INSS"))
			SE1->E1_TIPO	 := MVINABT
			SE1->E1_EMISSAO := dEmissao
			SE1->E1_VALOR   := nValorInss
			SE1->E1_VENCREA := dVencrea
			SE1->E1_SALDO   := nValorInss
			SE1->E1_VENCTO  := dVencRea
			SE1->E1_VENCORI := dVencRea
			SE1->E1_EMIS1   := dDataBase
			SE1->E1_CLIENTE := cCliente		// Grava o cliente do proprio titulo
			SE1->E1_LOJA	 := cLoja			// Grava a loja do proprio titulo
			SE1->E1_NOMCLI  := SA1->A1_NREDUZ
			SE1->E1_MOEDA   := 1
			If ( cPaisLoc == "CHI" )
				SE1->E1_VLCRUZ  := Round( nValorInss, MsDecimais(1) )
			Else
				SE1->E1_VLCRUZ  := nValorInss
			Endif
			If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
				SE1->E1_STATUS := "A"
			Else
				SE1->E1_STATUS := Iif(E1_SALDO >= 0.01,"A","B")
			EndIf
			SE1->E1_SITUACA := "0"
			SE1->E1_OCORREN := "04"
			SE1->E1_TITPAI  := cTitPai
			Msunlock()
			PcoDetLan("000001","07","FINA040")	// Gera lançamento no PCO ref. a retencao de INSS
		EndIf
	Endif
	dbSelectArea("SE1")
	dbGoto(nRegSe1)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se houver alteracao de Iss		  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
 	If nIssAlt != nOldIss .And. lOkMultNat .And. !(SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.)) //SE1->E1_ISS onde nIssAlt

		If cPaisLoc == "BRA"
			If !Empty( M->E1_CODISS )
				DbSelectArea( "FIM" )
				FIM->( DbSetOrder( 1 ) )
				If FIM->( DbSeek( xFilial( "FIM" ) + M->E1_CODISS ) )
					cMunic		:= FIM->FIM_CODFOR
					cLojaImp	:= FIM->FIM_FORLOJ
					cNome	+= "-" + FIM->FIM_MUN
				EndIf
			EndIf
			// Cria o fornecedor, caso nao exista

			cMunic := IIF(!Empty(SE1->E1_FORNISS),SE1->E1_FORNISS,cMunic)
		EndIf
		dbSelectArea("SA2")
		SA2->(DBSetOrder(1))
		If !(DbSeek(xFilial("SA2")+cMunic))
			Reclock("SA2",.T.)
			Replace A2_FILIAL With xFilial("SA2")
			Replace A2_COD	 With cMunic
			Replace A2_LOJA   With cLojaImp
			Replace A2_NOME   With cNome 	// "MUNICIPIO"
			Replace A2_NREDUZ With cNome 	// "MUNICIPIO"
			Replace A2_BAIRRO With "."
			Replace A2_MUN	  With "."
			Replace A2_EST	  With SuperGetMv("MV_ESTADO")
			Replace A2_END	  With "."
			Msunlock()
			FKCommit()
		Endif

		dbSelectArea("SE2")
		nRegSe2  := RecNo()
		If DbSeek(xFilial("SE2")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)+MVTAXA+cMunic+Space(TamSX3("A2_COD")[1]-Len(cMunic))+cLojaImp)
			If nIssAlt != 0 //SE1->E1_ISS onde nIssAlt
				Reclock("SE2")
				SE2->E2_VALOR := nIssAlt //SE1->E1_ISS onde nIssAlt
				SE2->E2_SALDO := nIssAlt //SE1->E1_ISS onde nIssAlt
				PcoDetLan("000001","13","FINA040")	// Gera lançamento no PCO ref. a retencao de ISS
			Else
				PcoDetLan("000001","13","FINA040",.T.)	// Gera lançamento no PCO ref. a retencao de ISS
				cChaveFK7 := xFilial("SE2")+"|"+SE2->E2_PREFIXO+"|"+SE2->E2_NUM+"|"+SE2->E2_PARCELA+"|"+;
							SE2->E2_TIPO+"|"+SE2->E2_FORNECE+"|"+SE2->E2_LOJA
				FINDELFKs(cChaveFK7,"SE2")

				Reclock("SE2",.F.,.T.)
				dbDelete()
			Endif
			Msunlock()
		Else
			nOldIss := 0
		Endif
		dbGoto(nRegSe2)
	Endif

	dbSelectArea("SE1")
	dbGoto(nRegSe1)
	//Localizo o titulo de abatimento para alterar o valor
	If SE1->(MsSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+MVISABT)) .And.;
		!(SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.))
		If nIssAlt != 0
			Reclock("SE1",.F.)
			SE1->E1_VALOR	 := nIssAlt
			SE1->E1_SALDO	 := nIssAlt
			MsUnlock()
			PcoDetLan("000001","08","FINA040")	// Altera lançamento no PCO ref. a retencao de ISS
		Else
			PcoDetLan("000001","08","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de INSS
			cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
						SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
			FINDELFKs(cChaveFK7,"SE1")

			Reclock("SE1",.F.,.T.)
			dbDelete()
		Endif
		Msunlock()
	Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se informado ISS sem existir 	  ³
	//³ anteriormente.									  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nValorIss := nIssAlt//SE1->E1_ISS
	//Cliente nao retem o ISS (Gera Contas a Pagar)
	If nOldIss = 0 .And. nIssAlt != 0 .And. SED->ED_CALCISS == "S" .And. lOkMultNat .And.;
	 	!(SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.)) //SE1->E1_ISS onde nIssAlt
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gera titulo de ISS 								  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria o fornecedor, caso nao exista			  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SA2")
		SA2->(DBSetOrder(1))
		If !(DbSeek(xFilial("SA2")+cMunic))
			Reclock("SA2",.T.)
			Replace A2_FILIAL With xFilial("SA2")
			Replace A2_COD	 With cMunic
			Replace A2_LOJA   With cLojaImp
			Replace A2_NOME   With STR0036 	// "MUNICIPIO"
			Replace A2_NREDUZ With STR0036 	// "MUNICIPIO"
			Replace A2_BAIRRO With "."
			Replace A2_MUN	  With "."
			Replace A2_EST	  With SuperGetMv("MV_ESTADO")
			Replace A2_END	  With "."
			Msunlock()
			FKCommit()
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria a natureza ISS caso nao exista		  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SED")
		SED->(DBSetOrder(1))
		cVar := Alltrim(&(SuperGetMv("MV_ISS")))
		cVar := cVar + Space(10-Len(cVar))
		If !(DbSeek(xFilial("SED")+cVar))
			RecLock("SED",.T.)
			SED->ED_FILIAL  := xFilial("SED")
			SED->ED_CODIGO  := cVar
			SED->ED_CALCIRF := "N"
			SED->ED_CALCISS := "N"
			SED->ED_CALCINS := "N"
			SED->ED_CALCCSL := "N"
			SED->ED_CALCCOF := "N"
			SED->ED_CALCPIS := "N"
			SED->ED_DESCRIC := STR0037  // "IMPOSTO SOBRE SERVICOS"
			SED->ED_TIPO	:= "2"
			Msunlock()
			FKCommit()
		Endif
		// Calcula vencimento do ISS
		Do Case
			Case GetNewPar("MV_VENCISS","E")=="E"
				dVenISS := dEmissao
				dVenISS += 28
				If ( Month(dVenISS) == Month(dEmissao) )
					dVenISS := dVenISS+28
				EndIf
				nTamData := Iif(Len(Dtoc(dVenISS)) == 10, 7, 5)
				dVenISS	:= Ctod(StrZero(SuperGetMv("MV_DIAISS"),2)+"/"+Subs(Dtoc(dVenISS),4,nTamData))
			Case GetNewPar("MV_VENCISS","E")=="Q" //Ultimo dia util da quinzena subsequente a dEmissao
				If Day(dEmissao) <= 15
					dVenISS	:= LastDay(dEmissao)
					dVenISS := DataValida(dVenISS,.F.)
				Else
					dVenISS := DataValida((LastDay(dEmissao)+1)+14,.F.)
				EndIf
			Case GetNewPar("MV_VENCISS","E")=="U" //Ultimo dia util do mes subsequente da dEmissao
				dVenISS := DataValida(LastDay(LastDay(dEmissao)+1),.F.)
			Case GetNewPar("MV_VENCISS","E")=="D"
				dVenISS := (LastDay(dEmissao)+1)
				nDiaUtil:= SuperGetMv("MV_DIAISS")
				For nDia := 1 To nDiaUtil-1
					If !(dVenISS == DataValida(dVenISS,.T.))
						nDia-=1
					EndIf
					dVenISS+=1
				Next nDia
			Case GetNewPar("MV_VENCISS","E")=="F" //Qtd de dia do parametro MV_DIAISS apos o fechamento da quinzena.
				If Day(dEmissao) <= 15
					dVenISS := CtoD("15"+SUBSTR(DtoC(dEmissao),3,Len(DtoC(dEmissao))))+SuperGetMv("MV_DIAISS")
				Else
					dVenISS := LastDay(dEmissao)+SuperGetMv("MV_DIAISS")
				EndIf
			OtherWise
				dVenISS := dVencto
				dVenISS += 28
				If ( Month(dVenISS) == Month(dEmissao) )
					dVenISS := dVenISS+28
				EndIf
				nTamData := Iif(Len(Dtoc(dVenISS)) == 10, 7, 5)
				dVenISS	:= Ctod(StrZero(SuperGetMv("MV_DIAISS"),2)+"/"+Subs(Dtoc(dVenISS),4,nTamData))
		EndCase
		dVencRea := DataValida(dVenISS,.T.)
		SE2->(DbSetOrder(1))
		If SE2->(!DbSeek(xFilial("SE2")+cPrefixo+cNum+cParcela+MVTAXA+cMunic+Space(TamSX3("A2_COD")[1]-Len(cMunic))+cLojaImp))
			RecLock("SE2",.T.)
		Else
			RecLock("SE2",.F.)
		Endif
		SE2->E2_FILIAL  := xFilial("SE2")
		SE2->E2_PREFIXO := cPrefixo
		SE2->E2_NUM	  := cNum
		SE2->E2_PARCELA := cParcela
		SE2->E2_NATUREZ := &(SuperGetMv("MV_ISS"))
		SE2->E2_TIPO	  := MVTAXA
		SE2->E2_EMISSAO := dEmissao
		SE2->E2_VALOR   := nValorIss
		SE2->E2_VENCTO  := dVenISS
		SE2->E2_SALDO   := nValorIss
		SE2->E2_VENCREA := dVencRea
		SE2->E2_VENCORI := dVenISS
		SE2->E2_FORNECE := cMunic
		SE2->E2_LOJA    := cLojaImp
		SE2->E2_NOMFOR  := SA2->A2_NREDUZ
		SE2->E2_MOEDA   := 1
		SE2->E2_CODAPRO	:= cCodAprov
		If ( cPaisLoc == "CHI" )
			SE2->E2_VLCRUZ  := Round( nValorIss, MsDecimais(1) )
		Else
			SE2->E2_VLCRUZ  := nValorIss
		Endif
		If lSpbInUse
			Replace	SE2->E2_MODSPB with cModSpb
		Endif
		Msunlock()
		PcoDetLan("000001","13","FINA040")	// Gera lançamento no PCO ref. a retencao de ISS

	//O Cliente retem o ISS (gera abatimento no SE1)
	ElseIf nIssAlt != nOldIss .And. SED->ED_CALCISS = "S" .And. lOkMultNat .And. (SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.)) //SE1->E1_ISS onde nIssAlt
		// Localiza o titulo de abatimento para alterar o valor
		If SE1->(MsSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+MVISABT))
			If nValorIss != 0
				Reclock("SE1",.F.)
				SE1->E1_VALOR	 := nValorIss
				SE1->E1_SALDO	 := nValorIss
				MsUnlock()
				PcoDetLan("000001","08","FINA040")	// Altera lançamento no PCO ref. a retencao de ISS
			Else
				PcoDetLan("000001","08","FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de INSS
				cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
							SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
				FINDELFKs(cChaveFK7,"SE1")

				Reclock("SE1",.F.,.T.)
				dbDelete()
			Endif
			Msunlock()
			lIss	:= .T.
		Else
			nOldIss := 0
		Endif
		dbGoto(nRegSe1)

		If nOldIss = 0 .And. nIssAlt != 0 .And. lOkMultNat //SE1->E1_ISS onde nIssAlt
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Cria a natureza INSS caso nao exista		  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("SED")
			SED->(DBSetOrder(1))
			cVar := Alltrim(&(SuperGetMv("MV_ISS")))
			cVar := cVar + Space(10-Len(cVar))
			If !(DbSeek(xFilial("SED")+cVar))
				RecLock("SED",.T.)
				SED->ED_FILIAL  := xFilial()
				SED->ED_CODIGO  := cVar
				SED->ED_CALCIRF := "N"
				SED->ED_CALCISS := "N"
				SED->ED_CALCINS := "N"
				SED->ED_CALCCSL := "N"
				SED->ED_CALCCOF := "N"
				SED->ED_CALCPIS := "N"
				SED->ED_DESCRIC := STR0052 //"RETENCAO P/ SEGURIDADE SOCIAL"
				SED->ED_TIPO	:= "2"
				Msunlock()
				FKCommit()
			Endif
			nValorIss := nIssAlt //SE1->E1_ISS onde nIssAlt
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Gera titulo de INSS								  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If !lIss
				RecLock("SE1",.T.)
				SE1->E1_FILIAL  := xFilial("SE1")
				SE1->E1_PREFIXO := cPrefixo
				SE1->E1_NUM	    := cNum
				SE1->E1_PARCELA := cParcela
				cNatureza:= &(SuperGetMV("MV_ISS"))
				SE1->E1_NATUREZ := cNatureza
				SE1->E1_TIPO	 := MVISABT
				SE1->E1_EMISSAO := dEmissao
				SE1->E1_VALOR   := nValorIss
				SE1->E1_VENCREA := dVencrea
				SE1->E1_SALDO   := nValorIss
				SE1->E1_VENCTO  := dVencRea
				SE1->E1_VENCORI := dVencRea
				SE1->E1_EMIS1   := dDataBase
				SE1->E1_CLIENTE := cCliente		// Grava o cliente do proprio titulo
				SE1->E1_LOJA	 := cLoja			// Grava a loja do proprio titulo
				SE1->E1_NOMCLI  := SA1->A1_NREDUZ
				SE1->E1_MOEDA   := 1
				If ( cPaisLoc == "CHI" )
					SE1->E1_VLCRUZ  := Round( nValorIss, MsDecimais(1) )
				Else
					SE1->E1_VLCRUZ  := nValorIss
				Endif
				If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
					SE1->E1_STATUS := "A"
				Else
					SE1->E1_STATUS := Iif(E1_SALDO >= 0.01,"A","B")
				EndIf

				SE1->E1_SITUACA := "0"
				SE1->E1_OCORREN := "04"
				SE1->E1_TITPAI  := cTitPai
				Msunlock()
				PcoDetLan("000001","08","FINA040")	// Altera lançamento no PCO ref. a retencao de ISS
			EndIf
		Endif
	Endif
	dbSelectArea("SE1")
	dbGoto(nRegSe1)

	//Tratamento de Retencao para Pis/Cofins/Csll
	//Se nao for PCC Baixa CR
	If !lPccBxCr
		If lContrAbt .and. !(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG) .and. lAlterNat .And. lOkMultNat .and. !lZerouPCC
			If cRetCli == "1"  //Calculo do sistema
				If cModRet == "1" //Verifica apenas o titulo em questao
					lAbate := SE1->E1_VALOR > nValMinRet
					RecLock("SE1")
					SE1->E1_PIS := nVlRetPis
					SE1->E1_COFINS := nVlRetCof
					SE1->E1_CSLL := nVlRetCsl
					If !lAbate
						SE1->E1_SABTPIS := nVlRetPis
						SE1->E1_SABTCOF := nVlRetCof
						SE1->E1_SABTCSL := nVlRetCsl
		        	Endif
					Msunlock()
				ElseIf cModRet == "2"	//Verifica o acumulado no mes

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Verifica os titulos para o mes de referencia, para verificar se atingiu a retencao       ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

					// Estrutura de aDadosRet
					// 1-Valor dos titulos
					// 2-Valor do PIS
					// 3-Valor do COFINS
					// 4-Valor da CSLL
					// 5-Array contendo os recnos dos titulos

					If aDadosRet[ 1 ] - If(Left(Dtos(SE1->E1_VENCREA),6) != LEft(Dtos(nOldVenRea),6),0,nOldBase) + nValBase > nValMinRet

						lAbate := .T.
						If !lAltera
							nVlRetPIS := aDadosRet[ 2 ] + nVlRetPis - nVlOriPis
							nVlRetCOF := aDadosRet[ 3 ] + nVlRetCOF - nVlOriCof
							nVlRetCSL := aDadosRet[ 4 ] + nVlRetCSL - nVlOriCsl
						Else

							If nVlRetPIS # nVlOriPis
								IF (aDadosRet[ 2 ] + nVlRetPis - nVlOriPis) > SuperGetMV("MV_VRETPIS")
									nVlRetPIS := aDadosRet[ 2 ] + nVlRetPis - nVlOriPis
								Else
									nSabtPis	:= aDadosRet[ 2 ] + nVlRetPis - nVlOriPis
									nVlRetPIS := 0
								Endif
							Else
								If (nVlRetPIS > SuperGetMV("MV_VRETPIS")) .Or.(M->E1_PIS> SuperGetMV("MV_VRETPIS"))
									If lAltera //.and. Month(SE1->E1_VENCREA) <> Month(M->E1_VENCREA)
										nVlRetPIS 	:= nVlRetPis + aDadosRet[2]
									Else
										nVlRetPIS 	:= nVlRetPis
									Endif
								Else
									nSabtPis	:= nVlRetPIS
									nVlRetPIS := 0
								Endif
							Endif

							If nVlRetCOF # nVlOriCof
								IF (aDadosRet[ 3 ] + nVlRetCOF - nVlOriCof) > SuperGetMV("MV_VRETCOF")
									nVlRetCOF := aDadosRet[ 3 ] + nVlRetCOF - nVlOriCof
								Else
									nSabtCof	:= aDadosRet[ 3 ] + nVlRetCOF - nVlOriCof
									nVlRetCOF := 0
								Endif
							Else
								If (nVlRetCOF > SuperGetMV("MV_VRETCOF")) .Or. ( M->E1_COFINS > SuperGetMV("MV_VRETCOF"))
									If lAltera //.and. Month(SE1->E1_VENCREA) <> Month(M->E1_VENCREA)
										nVlRetCOF 	:= nVlRetCOF + aDadosRet[3]
									Else
										nVlRetCOF := nVlRetCOF
									Endif
								Else
									nSabtCof	:= nVlRetCOF
									nVlRetCOF := 0
								Endif
							Endif

							If nVlRetCSL # nVlOriCsl
								IF (aDadosRet[ 4 ] + nVlRetCSL - nVlOriCsl) > SuperGetMV("MV_VRETCSL")
									nVlRetCSL := aDadosRet[ 4 ] + nVlRetCSL - nVlOriCsl
								Else
									nSabtCsl	:= aDadosRet[ 4 ] + nVlRetCSL - nVlOriCsl
									nVlRetCSL := 0
								Endif
							Else
								If (nVlRetCSL > SuperGetMV("MV_VRETCSL")) .Or. (M->E1_CSLL > SuperGetMV("MV_VRETCSL"))
									If lAltera //.and. Month(SE1->E1_VENCREA) <> Month(M->E1_VENCREA)
										nVlRetCSL 	:= nVlRetCSL + aDadosRet[4]
									Else
										nVlRetCSL := nVlRetCSL
									Endif
								Else
									nSabtCsl	:= nVlRetCSL
									nVlRetCSL := 0
								Endif
							Endif
						Endif

						nTotARet := nVlRetPIS + nVlRetCOF + nVlRetCSL

						nSobra := SE1->E1_VALOR - nTotARet

						If nSobra < 0

							nFatorRed := 1 - ( Abs( nSobra ) / nTotARet )

							nVlRetPIS  := NoRound( nVlRetPIS * nFatorRed, 2 )
		 					nVlRetCOF  := NoRound( nVlRetCOF * nFatorRed, 2 )

		 					nVlRetCSL := SE1->E1_VALOR - ( nVlRetPIS + nVlRetCOF )

							nDiFerImp := nTotARet - (nVlRetPIS + nVlRetCOF + nVlRetCSL)
							If cNCCRet == "1"
								ADupCredRt(nDiferImp,"001",SE1->E1_MOEDA,.T.)
							Endif

						EndIf

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Grava os novos valores de retencao                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						Reclock( "SE1", .F. )
						SE1->E1_PIS    := nVlRetPIS
						SE1->E1_COFINS := nVlRetCOF
						SE1->E1_CSLL   := nVlRetCSL
						SE1->E1_SABTPIS := nSabtPis
						SE1->E1_SABTCOF := nSabtCof
						SE1->E1_SABTCSL := nSabtCsl
						MsUnLock()
						nSavRec := SE1->( Recno() )
						lCriaSfq := .T.

						///****  Verifica se devemos excluir algum Abatimento TX caso apos a alteração, este nao deva mais existir pois nao alcançou valor minimo (MV_VRETXXX) ****//
						AADD(aExclPCC,{ nSabtPis , MVPIABT, "MV_PISNAT"})
						AADD(aExclPCC,{ nSabtCof	, MVCFABT, "MV_COFINS"})
						AADD(aExclPCC,{ nSabtCsl , MVCSABT, "MV_CSLL"})
						For nLoop := 1 to Len(aExclPCC)
							If aExclPCC[nLoop,1] != 0
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³ Apaga tambem os registro de impostos		  ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								SE1->(dbSetOrder(1))
								// Procura o abatimento do imposto do titulo e exclui
								If (MsSeek(xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)+aExclPCC[nLoop,2])) .And.;
									AllTrim(SE1->E1_NATUREZ) == GetMv(aExclPCC[nLoop,3])
									RecLock( "SE1" ,.F.,.T.)
									dbDelete( )
									SE1->(MsUnlock())
								EndIf
								SE1->(dbGoTo(nSavRec))
							EndIf
						Next
					////***** ---------------------------------------------------------- *****//

					ElseIf aDadosRet[ 1 ] + M->E1_VALOR > MaTbIrfPF(0)[4] .and. ;
							 cModRetIrf == "1" .and. Len(Alltrim(SM0->M0_CGC)) < 14   //P.Fisica


							lAbate := .T.
							lRetSoIrf := .T.

							RecLock("SE1")
							SE1->E1_PIS 	:= 0
							SE1->E1_COFINS := 0
							SE1->E1_CSLL 	:= 0
							SE1->E1_IRRF 	:= 0
							MsUnlock()

							If cModRetIRF == "1"
								nVlRetIRF := aDadosRet[ 6 ] + nVlRetIRF
							Else
								nVlRetIRF := 0
							Endif

							nTotARet := nVlRetIRF

							nValorTit := SE1->(E1_VALOR-E1_IRRF-E1_INSS)

							nSobra := nValorTit - nTotARet

							If nSobra < 0

								nFatorRed := 1 - ( Abs( nSobra ) / nTotARet )

		 						nVlRetIRF  := NoRound( nVlRetIRF * nFatorRed, 2 )

								nDiFerImp := nTotARet - nVlRetIRF

							If cNccRet == "1"
								ADupCredRt(nDiferImp,"001",SE1->E1_MOEDA,.T.)
							Endif
						EndIf

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Grava os novos valores de retencao                ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
						RecLock("SE1")
						If lAbatIRF .And. cModRetIRF == "1"
							SE1->E1_IRRF    := nVlRetIRF
							SE1->E1_SABTIRF := 0
						Endif
						MSUnlock()
						nSavRec := SE1->( Recno() )
						lCriaSfq := .T.

					Else 	//Fica retencao pendente
						If M->E1_EMISSAO < dLastPcc
							Reclock( "SE1", .F. )
							SE1->E1_SABTPIS := nVlRetPis
							SE1->E1_SABTCOF := nVlRetCof
							SE1->E1_SABTCSL := nVlRetCsl
							MsUnlock()
							lAbate := .F.
							lRestValImp := .T.
						EndIf
					EndIf

				EndIf

			ElseIf cRetCli == "2"		//Retem sempre
				lAbate := .T.
				Reclock( "SE1", .F. )
				SE1->E1_PIS    := nVlRetPIS
				SE1->E1_COFINS := nVlRetCOF
				SE1->E1_CSLL   := nVlRetCSL
				SE1->E1_SABTPIS := 0
				SE1->E1_SABTCOF := 0
				SE1->E1_SABTCSL := 0
				MsUnlock()
			ElseIf cRetCli == "3"		//Nao Retem
				lAbate := .F.
				lRestValImp := .F.
				Reclock( "SE1", .F. )
				SE1->E1_SABTPIS := nVlRetPis
				SE1->E1_SABTCOF := nVlRetCof
				SE1->E1_SABTCSL := nVlRetCsl
				MsUnlock()
			EndIf
		EndIf

		// Prepara o recalculo do total do grupo, caso os imposto sejam calculados pelo sistema e pelo total no mes
		If cRetCli == "1" .And. cModRet == "2"
			nTotGrupo := (RetTotGrupo() + (nValbase - nOldBase) - If(Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6),nOldBase,0))
			nBaseAtual := nTotGrupo
			nBaseAntiga := nTotGrupo+nOldBase-nValbase + If(Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6),nOldBase,0)
			nProp := nBaseAtual / nBaseAntiga
		Endif

		dbSelectArea("SE1")
		dbGoto(nRegSe1)

		dVencto := SE1->E1_VENCTO
		dVencRea := SE1->E1_VENCREA

		SED->( dbSetOrder(1) ) //ED_FILIAL+ED_CODIGO
		SED->( dbSeek(xFilial("SED") + SE1->E1_NATUREZ) )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se houver alteracao de COFINS	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ((SE1->E1_COFINS != nOldCofins .and. nOldCofins != 0) .Or. Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6)) .And. lOkMultNat .And. nImp10925 > 0
			F040AltImp(2,SE1->E1_COFINS,@lZerouImp, nProp, @nOldCofins, @lRetBaixado, nTotGrupo, nValMinRet,aDadRet, cRetCli, cModRet)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se informado COFINS sem existir   ³
		//³ anteriormente.									  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (nOldCofins = 0 .Or. nImp10925 == 0) .And. SE1->E1_COFINS != 0 .And. lOkMultNat .and. lAbate;
			.and.(SED->ED_CALCCOF == "S" .and. SED->ED_PERCCOF > 0) .and. (SA1->A1_RECCOFI == "S")
		   F040CriaImp(2, SE1->E1_COFINS, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM,cTPTIT)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se houver alteracao de PIS		  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (SE1->E1_PIS != nOldPis .Or. Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6) ) .And. lOkMultNat .And. nImp10925 > 0
			F040AltImp(1,SE1->E1_PIS,@lZerouImp, nProp, @nOldPis, @lRetBaixado, nTotGrupo, nValMinRet,aDadRet,cRetCli, cModRet)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se informado PIS sem existir 	  ³
		//³ anteriormente.									  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (nOldPis = 0 .Or. nImp10925 == 0) .And. SE1->E1_PIS != 0 .And. lOkMultNat  .and. lAbate;
			.and.(SED->ED_CALCCSL == "S" .and. SED->ED_PERCCSL > 0) .and. (SA1->A1_RECCSLL == "S")
			F040CriaImp(1, SE1->E1_PIS, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM,cTPTIT)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se houver alteracao de CSLL		  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (SE1->E1_CSLL != nOldCSLL .Or. Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6)) .And. lOkMultNat .And. nImp10925 > 0
			F040AltImp(3,SE1->E1_CSLL,@lZerouImp, nProp, @nOldCSLL, @lRetBaixado, nTotGrupo, nValMinRet,aDadRet,cRetCli, cModRet)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se informado CSLL sem existir 	  ³
		//³ anteriormente.									  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (nOldCSLL = 0 .Or. nImp10925 == 0) .And. SE1->E1_CSLL != 0 .And. lOkMultNat .and. lAbate;
			.and.(SED->ED_CALCPIS == "S" .and. SED->ED_PERCPIS > 0) .and. (SA1->A1_RECPIS == "S")
			F040CriaImp(3, SE1->E1_CSLL, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM,cTPTIT)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se houver alteracao de IRRF	  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ((SE1->E1_IRRF != nOldIrrf .and. nOldIrrf != 0) .Or. Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6)) .And. lOkMultNat .And. nImp10925 > 0
			F040AltImp(4,SE1->E1_IRRF,@lZerouImp, nProp, @nOldCofins, @lRetBaixado, nTotGrupo, nValMinRet,aDadRet, cRetCli, cModRet)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica se informado IRRF sem existir   ³
		//³ anteriormente.									  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (nOldIrrf = 0 .Or. nImp10925 == 0) .And. SE1->E1_IRRF != 0 .And. lOkMultNat .and. lAbate;
			.and.(SED->ED_CALCCOF == "S" .and. SED->ED_PERCCOF > 0) .and. (SA1->A1_RECCOFI == "S")
		   F040CriaImp(4, SE1->E1_IRRF, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM,cTPTIT)
		Endif

		// Recalculo os imposto estes sejam calculados pelo sistema e pelo total no mes
		If cRetCli == "1" .And. cModRet == "2"
			// Calcula valor do DDI
			nValorDif := nBaseAtual - nBaseAntiga

			//Caso a base atua seja menor que o valor minimo de retencao (MV_VL10925)
			//O DDI sera o valor total dos impostos retidos do grupo (retidos + retentor)
			If nBaseAtual <= nValMinRet
				nValorDif := nBaseAntiga
			Endif

			nValorDDI := Round(nValorDif * (SED->(ED_PERCPIS+ED_PERCCSL+ED_PERCCOF)/100),TamSx3("E1_VALOR")[2])

			SE1->(DbSetOrder(1))
			// Se o titulo retentor estiver baixado, gera titulo DDI
			If lRetBaixado
				If nValorDDI < 0
					Reclock( "SE1", .F. )
					// Ao gerar DDI e a base ficou menor que o valor minimo e o titulo estiver baixado, o titulo nao deve ficar pendente
					SE1->E1_SABTPIS := 0
					SE1->E1_SABTCOF := 0
					SE1->E1_SABTCSL := 0
					MsUnlock()
					nValorDDI := Abs(nValorDDI)
					// Se ja existir um DDI gerado para o retentor, calcula a diferenca do novo DDI.
					SE1->(DbSetOrder(1))
					If SE1->(MsSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+"DDI")) .Or.;
						SE1->(MsSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+"NCC"))
						If SE1->E1_VALOR == SE1->E1_SALDO
							nValorDDI := nValorDDI - SE1->E1_VALOR
							RecLock("SE1",.F.)
							SE1->E1_VALOR := nValorDDI
							SE1->E1_SALDO := nValorDDI
							If Empty(SE1->E1_VALOR)
								DbDelete()
							Endif
							MsUnlock()
						Endif
					Else
						SE1->(MsGoto(nRegSe1))
						/*/
						ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						³ Ponto de Entrada para nao geração de DDI e NCC			   ³
						ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/
						If ( _lNoDDINCC )
							If ( ValType( uRet := ExecBlock("F040NDINC") ) == "L" )
								lNoDDINCC := uRet
							Else
								lNoDDINCC := .T.
							EndIf
						EndIf

						If ( lNoDDINCC )
							GeraDDINCC(	SE1->E1_PREFIXO,;
									 		SE1->E1_NUM		,;
											SE1->E1_PARCELA,;
											"DDI"		 		,;
											SE1->E1_CLIENTE,;
											SE1->E1_LOJA	,;
											SE1->E1_NATUREZ,;
											nValorDDI,;
											dDataBase,;
											dDataBase	,;
										 	"APDIFIMP"	,;
										 	lF040Auto )
						EndIf
					Endif
				ElseIf nValorDDI >= 0
					// Exclui os impostos, caso eles ja existam
					AADD(aTab,{"nOldPis"		,MVPIABT,"MV_PISNAT"})
					AADD(aTab,{"nOldCofins"	,MVCFABT,"MV_COFINS"})
					AADD(aTab,{"nOldCsll"	,MVCSABT,"MV_CSLL"})

					For nX := 1 to Len(aTab)
						If &(aTab[nX,1]) != 0
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Apaga tambem os registro de impostos		  ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							dbSelectArea("SE1")
							dbSetOrder(1)
							dbSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+aTab[nX,2])
							While !Eof() .And. E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO == ;
									xFilial("SE1")+cPrefixo+cNum+cParcela+aTab[nX,2]
								IF AllTrim(E1_NATUREZ) == GetMv(aTab[nX,3])
									// Apaga os lancamentos dos impostos COFINS, PIS e CSLL do SIGAPCO
									PcoDetLan("000001",StrZero(8+nX,2),"FINA040",.T.)
									RecLock( "SE1" ,.F.,.T.)
									dbDelete( )
								EndIf
								dbSkip()
							Enddo
						EndIf
					Next
					SE1->(MsGoto(nRegSe1))
					SE1->(DbSetOrder(1))
					// Se existir o titulo DDI e a diferenca de imposto for positiva, excluir o titulo DDI
					If SE1->(MsSeek(xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)+"DDI"))
						// Se o titulo DDI ainda nao foi pago pelo cliente, exclui
						If SE1->E1_SALDO == SE1->E1_VALOR
						cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
									SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
						FINDELFKs(cChaveFK7,"SE1")

							RecLock("SE1",.F.)
							DbDelete()
							MsUnlock()
						Endif
					Else
						SE1->(MsGoto(nRegSe1))
						// Gera DEBITO dos Impostos calculados a menor
						If nValorDDI > 0
							// Cria os impostos
							nValorPis	 := Round(nValorDif * (SED->ED_PERCPIS/100),TamSx3("E1_VALOR")[2])
							nValorCofins := Round(nValorDif * (SED->ED_PERCCOF/100),TamSx3("E1_VALOR")[2])
							nValorCsll 	 := Round(nValorDif * (SED->ED_PERCCSL/100),TamSx3("E1_VALOR")[2])
		               /*
							F040CriaImp(1, nValorPis, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM)
							F040CriaImp(2, nValorCofins, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM)
							F040CriaImp(3, nValorCsll, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, SA1->A1_NREDUZ, E1_ORIGEM)
							*/
							/*/
							ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							³ Ponto de Entrada para nao geração de DDI e NCC			   ³
							ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ/*/
							If ( _lNoDDINCC )
								If ( ValType( uRet := ExecBlock("F040NDINC") ) == "L" )
									lNoDDINCC := uRet
								Else
									lNoDDINCC := .T.
								EndIf
							EndIf

							If ( lNoDDINCC )
								GeraDDINCC(	SE1->E1_PREFIXO,;
										 		SE1->E1_NUM		,;
												SE1->E1_PARCELA,;
												"DDI"		 		,;
												SE1->E1_CLIENTE,;
												SE1->E1_LOJA	,;
												SE1->E1_NATUREZ,;
												nValorPis+nValorCofins+nValorCsll,;
												dDataBase,;
												dDataBase	,;
											 	"APDIFIMP"	,;
											 	lF040Auto )
							EndIf
						Endif
					Endif
				Endif
			Else
				If lContrAbt .And. lZerouImp .And. nTotGrupo <= nValMinRet
					// Exclui o relacionamento SFQ
					SFQ->(DbSetOrder(2))
					If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
						lTemSfq := .T.
						SE1->(DbSetOrder(1))
						If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
							cPrefixo	:= SE1->E1_PREFIXO
							cNum		:= SE1->E1_NUM
							cParcela	:= SE1->E1_PARCELA
							cTipo		:= SE1->E1_TIPO
							cCliente	:= SE1->E1_CLIENTE
							cLoja		:= SE1->E1_LOJA

							aRecSE1 := FImpExcTit("SE1",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
							For nX := 1 to Len(aRecSE1)
								If nSavRec <> aRecSE1[nX]
									SE1->(MSGoto(aRecSE1[nX]))
									FaAvalSE1(4)
								Endif
							Next
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Exclui os registros de relacionamentos do SFQ                               ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							FImpExcSFQ("SE1",cPrefixo,cNum,cParcela,cTipo,cCliente,cLoja)
						Endif
						SE1->(MsGoto(nRegSe1))
					Else
						SFQ->(DbSetOrder(1))
						If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
							lTemSfq := .T.
						Endif
					Endif
					SFQ->(DbSetOrder(1))
				Endif
				// Caso o total do grupo for menor ou igual ao valor minimo de acumulacao,
				// e o retentor nao estava baixado. Recalcula os impostos dos titulos do mes
				// que possivelmente foram incluidos apos a base atingir o valor minimo
				If nTotGrupo <= nValMinRet .And. lTemSfq
					F040RecalcMes(nOldVenRea,nValMinRet,SE1->E1_CLIENTE, SE1->E1_LOJA)
				Endif
			Endif
		Endif
		RestArea(aArea)
		dbSelectArea("SE1")
		dbGoto(nRegSe1)


		If lContrAbt .and. lZerouImp
			aRecSE1 := FImpExcTit("SE1",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
			For nX := 1 to Len(aRecSE1)
				SE1->(MSGoto(aRecSE1[nX]))
				FaAvalSE1(4)
			Next

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Exclui os registros de relacionamentos do SFQ                               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SE1->(dbGoTo(nRegSE1))
			FImpExcSFQ("SE1",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
		Endif

		If lContrAbt .and. lRestValImp
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Restaura os valores originais de PIS / COFINS / CSLL  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			RecLock( "SE1", .F. )
			SE1->E1_PIS    := nVlRetPIS
			SE1->E1_COFINS := nVlRetCOF
			SE1->E1_CSLL   := nVlRetCSL
			MsUnlock()
		EndIf

		//Se a data do titulo principal, os venctos dos abatimentos devem ser alterados
		If nOldVencto != SE1->E1_VENCTO .OR. nOldVenRea != SE1->E1_VENCREA
			dbSelectArea("SE1")
			dbSetOrder(1)
			dbGoto(nRegSe1)
			dVencto := SE1->E1_VENCTO
			dVencRea := SE1->E1_VENCREA
			cKeySe1 := E1_PREFIXO+E1_NUM+E1_PARCELA
			If DbSeek(xFilial("SE1")+cKeySE1)
				While !Eof() .and. cKeySe1 == SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)
					If SE1->E1_TIPO $ MVABATIM
						If SE1->E1_FLUXO == 'S'
							// Tiro o valor da natureza antiga
							AtuSldNat(cOldNatur, nOldVenRea, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),4)
						Endif

						RecLock( "SE1", .F. )
						SE1->E1_VENCTO := dVencto
						SE1->E1_VENCREA := dVencRea
						MsUnlock()

						If SE1->E1_FLUXO == 'S'
							// Somo o valor na nova natureza
							AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),4)
						Endif
					Endif
					dbSkip()
				Enddo
			Endif
		Endif

		If lCriaSfq .And. aDadosRet[1] > 0
			aRecnos := aClone( aDadosRet[ 5 ] )

			SE1->( MsGoto( nSavRec ) )
			cPrefOri  := SE1->E1_PREFIXO
			cNumOri   := SE1->E1_NUM
			cParcOri  := SE1->E1_PARCELA
			cTipoOri  := SE1->E1_TIPO
			cCfOri    := SE1->E1_CLIENTE
			cLojaOri  := SE1->E1_LOJA

			For nLoop := 1 to Len( aRecnos )

				SE1->( dbGoto( aRecnos[ nLoop ] ) )
				If nSavRec <> aRecnos[ nLoop ]
					FImpCriaSFQ("SE1", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
									"SE1", SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, SE1->E1_CLIENTE, SE1->E1_LOJA,;
									SE1->E1_SABTPIS, SE1->E1_SABTCOF, SE1->E1_SABTCSL,;
									If( FieldPos('FQ_SABTIRF') > 0 .And. lAbatIRF .And. cModretIRF =="1", SE1->E1_SABTIRF, 0),;
									SE1->E1_FILIAL )

					RecLock( "SE1", .F. )
					SE1->E1_SABTPIS := 0
					SE1->E1_SABTCOF := 0
					SE1->E1_SABTCSL := 0
					//Nao	deve zerar e sim tirar o que esta sendo absorvido
					If lAbatIRF .And. cModRetIRF == "1"
						SE1->E1_SABTIRF := 0
					Endif
		         MsUnlock()

				ELSE
					RecLock( "SE1", .F. )
					SE1->E1_SABTPIS := nSabtPis
					SE1->E1_SABTCOF := nSabtCof
					SE1->E1_SABTCSL := nSabtCsl
					//Nao	deve zerar e sim tirar o que esta sendo absorvido
					If lAbatIRF .And. cModRetIRF == "1"
						SE1->E1_SABTIRF := 0
					Endif
		         MsUnlock()
		   	Endif
			Next nLoop
		Endif
	Endif

	dbSelectArea("SE1")
	dbGoto(nRegSe1)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Grava o lancamento do titulo a receber efetivo no SIGAPCO  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SE1->E1_MULTNAT # "1"
		If SE1->E1_TIPO $ MVRECANT
			PcoDetLan("000001","02","FINA040")	// Tipo RA
		Else
			PcoDetLan("000001","01","FINA040")
		EndIf
	EndIf

	// Se o titulo ja foi enviado ao banco e for uma alteracao para re-envio ao CNAB,
	// grava no arquivo de instrucoes
	If !Empty(SE1->E1_IDCNAB) .And. !Empty(SE1->E1_PORTADO)
		FinGrvFI2()
	Endif
Endif

dbSelectArea("SE1")
dbGoto(nRegSe1)
//Acerto valores dos impostos do titulo pai quando os mesmos forem alterados
//por compensacao ou inclusao do AB-
If !lPccBxCr .and. lImpComp .and. SE1->E1_TIPO $ MVABATIM .and. SE1->E1_VALOR != nOldValor

	nPisAbtOld := SE1->E1_PIS
	nCofAbtOld := SE1->E1_COFINS

	nProporcao := SE1->E1_VALOR / nOldValor

	nPisAbt := (SE1->E1_PIS * nProporcao) - nPisAbtOld
	nCofAbt := (SE1->E1_COFINS * nProporcao) - nCofAbtOld

	If ABS(nPisAbt + nCofAbt) > 0
		// Procura titulo que gerou o abatimento, titulo pai
		SE1->(DbSeek(xFilial("SE1")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA)))
		While SE1->(!Eof()) .And.;
				SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == xFilial("SE1")+cPrefOri+cNumOri+cParcOri
			If !SE1->E1_TIPO $ MVABATIM
				lAchouPai := .T.
				nRecSE1P	:= SE1->(RECNO())
				Exit // Encontrou o titulo
			Endif
			SE1->(DbSkip())
		Enddo

		dbSelectArea("SE1")
		dbGoto(nRegSe1)

		If lAchouPai
			//Acerta valores dos impostos da inclusão do abatimento.
			F040ActImp(nRecSE1P,SE1->E1_VALOR,.F.,nPisAbt,nCofAbt)
		Endif

		//Acerto valores de impostos no AB-
		dbSelectArea("SE1")
		dbGoto(nRegSe1)
		RecLock("SE1")
		SE1->E1_PIS += nPisAbt
		SE1->E1_COFINS += nCofAbt
		MsUnlock()

	Endif
Endif

If lVldFIV
	aGetSE1 := SE1->(GetArea())

	SE1->(DbSetOrder(28))
	FIV->(DbSetOrder(1))

	If SE1->(DbSeek(xFilial("SE1") + cTitPai))
		While !SE1->(EOF()) .And. Alltrim(SE1->E1_TITPAI) == Alltrim(cTitPai)
			If cFilAnt == SE1->E1_FILORIG
				If lGestao
					If lSE1Comp
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					Else
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					Endif
				Else
					If lSE1Comp
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					Else
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					Endif
				Endif
			Else
				lVldFIV	:= .T.
				If lGestao
					If lSE1Comp
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					Else
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					Endif
				Else
					If lSE1Comp
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILORIG)
					Else
						AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, Iif(SE1->E1_TIPO $ MVRECANT+"/"+MV_CRNEG,"3","2"), "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, Iif(SE1->E1_TIPO $ MVABATIM, "-","+"),,FunName(),"SE1",SE1->(Recno()),4 , ,0, SE1->E1_FILIAL)
					Endif
				Endif
			Endif
			SE1->(DbSkip())
		Enddo
	Endif
	RestArea(aGetSE1)
Endif

//realiza a gravacao do model
If cPaisLoc=="BRA"
	Fa986grava("SE1","FINA040")
EndIf

//realiza a integracao online do titulo para o TAF
//If FindFunction("TAFExstInt") .And. TAFExstInt()
	//FinExpTAF(SE1->(Recno()),2,,,,, )
//EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Grava as alteracoes realizadas na tela de inclusao de cheques      	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
GravaChqCR(,"FINA040")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ ExecBlock pos-confirma‡Æo da altera‡Æo e antes de sair do AxAltera	³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("F040ALTR")
	ExecBlock("F040ALTR",.f.,.f.)
Endif

Return .T.


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040Inss ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 28/01/99 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Zera valor do INSS caso cliente n„o recolha e Natureza sim  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa040Inss()  															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Inss()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()
Local nBaseImp := m->e1_valor

//639.04 Base Impostos diferenciada
If lBaseImp .and. M->E1_BASEIRF > 0
	nBaseImp   := M->E1_BASEIRF
Endif

If SA1->A1_RECINSS <> "S" .and. m->e1_inss > 0
	m->e1_inss := 0
Endif

If SED->ED_CALCINS == "S" .and. SA1->A1_RECINSS == "S" .And. m->e1_multnat != "1"
	m->e1_inss := (nBaseImp * (SED->ED_PERCINS / 100))
Endif

If ( M->E1_INSS <= GetNewPar("MV_VLRETIN",0) )
	M->E1_INSS := 0
EndIf

Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040CSSL ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 07/02/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Zera valor do CSLL caso cliente n„o recolha e Natureza sim  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa040CSLL()  															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040CSLL()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()
Local nBaseImp := m->e1_valor

//639.04 Base Impostos diferenciada
If lBaseImp .and. M->E1_BASEIRF > 0
	nBaseImp   := M->E1_BASEIRF
Endif

If !(SA1->A1_RECCSLL $ "S#P") .and. m->e1_csll > 0
	m->e1_csll := 0
Endif

If SED->ED_CALCCSL == "S" .and. SA1->A1_RECCSLL $ "S#P" .And. m->e1_multnat != "1"
	m->e1_csll := (nBaseImp * (SED->ED_PERCCSL / 100))
Endif

If M->E1_CSLL <= GetNewPar("MV_VRETCSL",0)
	M->E1_CSLL := 0
EndIf

Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040COFI ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 07/02/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Zera valor do COFINS caso cliente n„o recolha e Natureza sim³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa040Cofins()  															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Cofi()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()
Local nBaseImp := m->e1_valor

//639.04 Base Impostos diferenciada
If lBaseImp .and. M->E1_BASEIRF > 0
	nBaseImp   := M->E1_BASEIRF
Endif

If !(SA1->A1_RECCOFI $ "S#P") .and. m->e1_cofins > 0
	m->e1_cofins := 0
Endif

If SED->ED_CALCCOF == "S" .and. SA1->A1_RECCOFI $ "S#P" .And. m->e1_multnat != "1"
	m->e1_cofins := (nBaseImp * (Iif(SED->ED_PERCCOF>0,SED->ED_PERCCOF,GetMv("MV_TXCOFIN")) / 100))
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Titulos Provisorios ou Antecipados n†o geram COFINS       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If m->e1_tipo $ MVPROVIS+"/"+MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM
	m->e1_cofins := 0
EndIf

Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³fa040PIS  ³ Autor ³ Mauricio Pequim Jr.   ³ Data ³ 07/02/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Zera valor do PIS caso cliente n„o recolha e Natureza sim   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³fa040Pis()   															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040Pis()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()
Local nBaseImp := m->e1_valor

//639.04 Base Impostos diferenciada
If lBaseImp .and. M->E1_BASEIRF > 0
	nBaseImp   := M->E1_BASEIRF
Endif

If !(SA1->A1_RECPIS $ "S#P") .and. m->e1_pis > 0
	m->e1_pis := 0
Endif

If SED->ED_CALCPIS == "S" .and. SA1->A1_RECPIS $ "S#P" .And. m->e1_multnat != "1"
	m->e1_pis := (nBaseImp * (Iif(SED->ED_PERCPIS>0,SED->ED_PERCPIS,GetMv("MV_TXPIS")) / 100))
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Titulos Provisorios ou Antecipados n†o geram PIS          ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If m->e1_tipo $ MVPROVIS+"/"+MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM
	m->e1_pis := 0
EndIf

Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³FA040MCPO ³ Autor ³ Fernando A. Bernardes ³ Data ³ 10/05/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Monta array com campos a ser alterado                      ³±±
±±³          ³ Criado para compatibilizacao com rotinas automaticas       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function fa040MCpo( )
Local aCpos
Local lSpbInUse := SpbInUse()
Local lPode := .F.
Local nX
Local lTpDesc :=	.T.
Local lNumPro :=	.T.
Local lCodIRRF :=	cPaisLoc == "BRA"

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP(2)

lUsaGac	:= Upper(AllTrim(FunName())) == "ACAA690"

If !Empty(SE1->E1_BAIXA) .Or. "S" $ SE1->E1_LA .or. "LOJA" $ Upper(Trim(SE1->E1_ORIGEM)) .OR. ;
	"FINA460" $ Upper(Trim(SE1->E1_ORIGEM)) .Or.;
	alltrim(SE1->E1_FATURA) == "NOTFAT" .OR.;// Nao permite alterar alguns campos da fatura.
	SE1->E1_TIPO $ MVRECANT .OR.; // Se for Adiantamento.
	(FinTemSFQ(,.T.)) // Se titulo teve retencao de PCC

	If SE1->E1_SALDO = 0
		Help(" ",1,"FA040BAIXA")
		Return
	Endif
	aCpos := {}
	Aadd(aCpos,"E1_VENCTO")
	Aadd(aCpos,"E1_VENCREA")
	Aadd(aCpos,"E1_HIST")
	Aadd(aCpos,"E1_INDICE")
	Aadd(aCpos,"E1_OP")
	Aadd(aCpos,"E1_OCORREN")
	Aadd(aCpos,"E1_INSTR1")
	Aadd(aCpos,"E1_INSTR2")
	Aadd(aCpos,"E1_NUMBCO")
	Aadd(aCpos,"E1_FLUXO")
	Aadd(aCpos,"E1_ACRESC")
	Aadd(aCpos,"E1_DECRESC")
	Aadd(aCpos,"E1_DIADESC")
	Aadd(aCpos,"E1_DESCFIN")
	AADD(aCpos,"E1_VALJUR")
	AADD(aCpos,"E1_PORCJUR")
	If lSpbInUse
		Aadd(aCpos,"E1_MODSPB")
	Endif
	//Integracao SIGAGE/SIGAGAC
	If lUsaGac
		Aadd(aCpos,"E1_VLBOLSA")
		Aadd(aCpos,"E1_NUMCRD")
		Aadd(aCpos,"E1_VLFIES")
		Aadd(aCpos,"E1_DESCON1")
		Aadd(aCpos,"E1_DESCON2")
		Aadd(aCpos,"E1_DESCON3")
		Aadd(aCpos,"E1_VLMULTA")
		Aadd(aCpos,"E1_DESCON3")
		Aadd(aCpos,"E1_MOTNEG")
		Aadd(aCpos,"E1_FORNISS")
		Aadd(aCpos,"E1_DTDESC1")
		Aadd(aCpos,"E1_DTDESC2")
		Aadd(aCpos,"E1_DTDESC3")
	Endif
	// So permite alterar a natureza, depois de contabilizado o titulo, se ela nao estiver
	// preenchida
	If SED->(DbSeek(xFilial("SED")+SE1->E1_NATUREZ))
		For nX := 1 To SED->(FCount())
			If "_CALC" $ SED->(FieldName(nX))
				lPode := !SED->(FieldGet(nX)) $ "1S" // So permite alterar se nao calcular impostos
				If !lPode // No primeiro campo que calcula impostos, nao permite alterar
					Exit
				Endif
			Endif
		Next
	Endif

	If ExistBlock("F040ALN")
		lPode := .T.
	Endif

	// So permite alterar a natureza, depois de contabilizado o titulo, se ela nao estiver
	// preenchida
	If Empty(SE1->E1_NATUREZ) .Or. lPode
		Aadd(aCpos,"E1_NATUREZ")
	Endif
Else
	aCpos := {}
	Aadd(aCpos,"E1_NATUREZ")
	Aadd(aCpos,"E1_VENCTO")
	Aadd(aCpos,"E1_VENCREA")
	Aadd(aCpos,"E1_HIST")
	Aadd(aCpos,"E1_INDICE")
	Aadd(aCpos,"E1_OP")
	Aadd(aCpos,"E1_VALJUR")
	Aadd(aCpos,"E1_PORCJUR")
	Aadd(aCpos,"E1_VALOR")
	Aadd(aCpos,"E1_VALCOM1")
	Aadd(aCpos,"E1_VALCOM2")
	Aadd(aCpos,"E1_VALCOM3")
	Aadd(aCpos,"E1_VALCOM4")
	Aadd(aCpos,"E1_VALCOM5")
	Aadd(aCpos,"E1_OCORREN")
	Aadd(aCpos,"E1_INSTR1")
	Aadd(aCpos,"E1_INSTR2")
	Aadd(aCpos,"E1_NUMBCO")
	Aadd(aCpos,"E1_IRRF")
	Aadd(aCpos,"E1_ISS")
	Aadd(aCpos,"E1_FLUXO")
	Aadd(aCpos,"E1_INSS")
	Aadd(aCpos,"E1_PIS")
	Aadd(aCpos,"E1_COFINS")
	Aadd(aCpos,"E1_CSLL")
	Aadd(aCpos,"E1_ACRESC")
	Aadd(aCpos,"E1_DECRESC")
	Aadd(aCpos,"E1_DIADESC")
	Aadd(aCpos,"E1_DESCFIN")
	If lSpbInUse
		Aadd(aCpos,"E1_MODSPB")
	Endif

	//639.04 Base Impostos diferenciada
	If lBaseImp
		Aadd(aCpos,"E1_BASEIRF")
	Endif

	//Integracao SIGAGE/SIGAGAC
	If lUsaGac
		Aadd(aCpos,"E1_VLBOLSA")
		Aadd(aCpos,"E1_NUMCRD")
		Aadd(aCpos,"E1_VLFIES")
		Aadd(aCpos,"E1_DESCON1")
		Aadd(aCpos,"E1_DESCON2")
		Aadd(aCpos,"E1_DESCON3")
		Aadd(aCpos,"E1_VLMULTA")
		Aadd(aCpos,"E1_DESCON3")
		Aadd(aCpos,"E1_MOTNEG")
		Aadd(aCpos,"E1_FORNISS")
		Aadd(aCpos,"E1_DTDESC1")
		Aadd(aCpos,"E1_DTDESC2")
		Aadd(aCpos,"E1_DTDESC3")
	Endif
Endif

If cPaisLoc == "BRA"
	If lNumPro
		Aadd(aCpos,"E1_NUMPRO")
		Aadd(aCpos,"E1_INDPRO")
	Endif
	If lTpDesc
		Aadd(aCpos,"E1_TPDESC")
	Endif
	IF lCodIRRF
		Aadd(aCpos,"E1_CODIRRF")
	EndIF
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ ExecBlock para tratamento dos campos a serem alterados  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
IF ExistBlock("F040CPO")
	aCpos := ExecBlock("F040CPO",.f.,.f.,aCpos)
Endif

Return aCpos


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³FA040MULTNAT³ Autor ³ Claudio Donizete    ³ Data ³ 21/09/01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Funcao para zerar valores de impostos quando utilizar-se   ³±±
±±³          ³ multinatureza.                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
FUNCTION Fa040MultNat
Local lRet := .T.
//Retirada a funcionalidade desta função com objetivo de manter compatibilidade com o SX3.

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³FA040IniS ³ Autor ³ Wagner Mobile Costa   ³ Data ³ 21/09/01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Funcao para inicializacao dos campos de memoria para rotina³±±
±±³          ³ de substituicao                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³                                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function fa040IniS( )
Local aIniCpos := {}, nInd
Local lFa040S := ExistBlock("FA040S")
Local lFa040SUB := ExistBlock("FA040SUB")
Local nRegAtu
Local aArea := GetArea()

If Type("nValorS") # "U" .And. nValorS # Nil
	dbSelectArea("SA1")
	dbSetOrder(1)
	dbSeek(xFilial()+cCodigo+cLoja)

	M->E1_VALOR 	:= nValorS
	If ( cPaisLoc == "CHI" )
		M->E1_VLCRUZ	:= Round( xMoeda(nValorS,nMoedSubs,1,,3), MsDecimais(1) )
	Else
		M->E1_VLCRUZ	:= Round(NoRound(xMoeda(nValorS,nMoedSubs,1,,3),3),2)

		If Select("SE1") > 0
			If SE1->E1_TXMOEDA > 0 .And. SE1->E1_MOEDA > 1
				M->E1_VLCRUZ  := nValorS * SE1->E1_TXMOEDA
				M->E1_TXMOEDA := SE1->E1_TXMOEDA
			EndIf
		EndIf
	Endif
	M->E1_CLIENTE	:= cCodigo
	M->E1_LOJA		:= cLoja
	M->E1_NOMCLI	:= SA1->A1_NREDUZ
	M->E1_MOEDA		:= nMoedSubs

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Executa um poss¡vel ponto de entrada, neste caso grava o dese³
	//³ jado no inicializador padr„o.                    		        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lFa040S
		Execblock("FA040S",.f.,.f.)
	Endif
	If lFa040SUB
		aIniCpos := ExecBlock("FA040SUB",.f.,.f.)    // array com nome de campos a serem inicializados
	Else
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Verifica campos do usuario      			  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SX3")
		dbSeek("SE1")
		While !Eof() .and. X3_ARQUIVO == "SE1"
			IF (X3_PROPRI == "U" .AND. X3_CONTEXT!="V" )
				Aadd(aIniCpos,sx3->x3_campo)
			Endif
			dbSkip()
		Enddo
	Endif

	If Len(aIniCpos) > 0
		dbSelectArea("__SUBS")
		nRegAtu := Recno()
		While !Eof()
			If E1_OK == cMarca
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Inicializa array com dados do 1o. registro selecionado p/  ³
				//³ substituicao.                                              ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				For nInd:= 1 to Len(aIniCpos)
					cCampo := "__SUBS->"+Alltrim(aIniCpos[nInd])
					&("M->"+aIniCpos[nInd]) := &cCampo
				Next
				Exit
			Endif
			dbSkip()
		EndDo
		dbSelectArea("__SUBS")
		dbGoto(nRegAtu)
		RestArea(aArea)
	Endif
Endif

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³F040ConVal ³Autor  ³Mauricio Pequim Jr    ³ Data ³ 16/04/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Desc.     ³Converte o valor dos campos para a moeda escolhida para     ³±±
±±³          ³apresentacao no MSSelect()                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Substitucao de Titulos                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040ConVal(nMoeda)
Local nValorCpo := Round(NoRound(xMoeda(E1_SALDO+E1_ACRESC-E1_DECRESC,E1_MOEDA,nMoeda,,3),3),2)
Return nValorCpo

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³WTxMoe		 ³Autor  ³Claudio D. de Souza   ³ Data ³ 24/04/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Desc.     ³Permite ou nao a digitacao da taxa contratada quando a moeda³±±
±±³          ³for maior que 1                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Fina040/Fina050                                             ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function WTxMoe(nMoeda)
Return cPaisLoc != "BRA" .Or. nMoeda > 1

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³GeraParcSe1³Autor  ³Claudio D. de Souza   ³ Data ³ 14/10/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Desc.     ³Gera parcelas no SE1, baseado nas condicoes de pagamento ou ³±±
±±³          ³na quantidade definidade pelo usuario                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³Fina040                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function GeraParcSe1(cAlias,lEnd,nHdlPrv,nTotal,cArquivo,nSavRecA1,nRecSe1,aDiario)
Local nTamParc  	:= TamSx3("E1_PARCELA")[1]
Local cHistSE1 		:= Iif(!Empty(cHistDsd),cHistDsd,SE1->E1_HIST)

//Alimentando a parcela inicial com o que foi definido no campo E1_PARCELA ou com o conteudo inicial do parametro MV_1DUP
//Formatando o valor da parcela do titulo originador com o tamanho definido no SX3
Local cTipoPar		:= IIf(SuperGetMV("MV_1DUP")$"0123456789" .OR. (!Empty(SE1->E1_PARCELA) .AND.;
							!Upper(AllTrim(SE1->E1_PARCELA)) $ "ABCDEFGHIJKLMNOPQRSTUVXWYZ"),"N","C")
Local cParcSE1 		:= IIf(cTipoPar == "N",;
					   		IIf(Empty(SE1->E1_PARCELA),StrZero(Val(SuperGetMV("MV_1DUP")),nTamParc),SE1->E1_PARCELA),;
					   		IIf(Empty(SE1->E1_PARCELA),SuperGetMV("MV_1DUP"),SE1->E1_PARCELA))

Local nMoedSe1 		:= SE1->E1_MOEDA
Local aCampos 		:= {}
Local nX			:= 0
Local a040Desd 		:= {}
Local lSpbinUse 	:= SpbInUse()
Local cModSpb		:= ""
Local lAcresc		:=lDecresc := .f.
Local lFa040Par 	:= ExistBlock("FA040PAR")
Local i				:= 1
Local cPrefixo		:= ""
Local cNum			:= ""
Local cTipo			:= ""
Local cPadrao		:= ""
Local lPadrao		:= .F.
Local nValSaldo 	:= 0
Local cNomeCli		:= SA1->A1_NREDUZ
Local lAtuAcum    	:= .T.	// Verifica se deve alterar os campos A1_VACUM e A1_NROCOM qdo modulo for o loja

//Rastreamento
Local lRastro		:= FVerRstFin()
Local cParcela		:= ""
Local cCliente		:= ""
Local cLoja			:= ""
Local aRastroOri	:= {}
Local aRastroDes	:= {}
Local nValForte		:= 0
Local nValTot		:= 0
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Parametro que permite ao usuario utilizar o desdobramento³
//³da maneira anterior ao implementado com o rastreamento.  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lNRastDSD		:= SuperGetMV("MV_NRASDSD",.T.,.F.)

//Desdobramento com Imposto
Local nRecOrig 		:= SE1->(RECNO())
Local lCalcImp		:= F040BSIMP(3)
Local dDtEmiss 		:= SE1->E1_EMISSAO
Local lF040DTDES	:= Existblock("F040DTDES")
Local nVlrTit 		:= 0
Local lGrvSA1 		:= .T.
Local aFKF 			:= {}
Local cTPCOMIS 		:= SuperGetMv("MV_TPCOMIS",,"")

dbSelectArea(cAlias)

PRIVATE lMsErroAuto := .F.

Default aDiario 	:= {}
Default nRecSE1		:= SE1->(Recno())

ProcRegua(Len(aParcelas))
// Carrega em aCampos o conteudo dos campos do SE1
For nX := 1 To fCount()
	Aadd(aCampos, {FieldName(nX), FieldGet(nX)})
Next
VALOR := 0
If lSpbInUse
	cModSpb := SE1->E1_MODSPB
Endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Baixa registro que originou o desdobramento         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
a040Desd := {}
If ExistBlock( "F040DESD" )
   a040Desd := ExecBlock( "F040DESD" )
Endif

If lNRastDSD .AND. lRastro
	//Desativar o rastreamento ja que o titulo original deixara de existir, o que impossibilitara o rastreamento entre o original e os desdobramentos
	lRastro := .F.
Endif

//Caso nao seja base TOP, mantem o processo antigo
If !lRastro
	cChaveFK7 := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
				SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
	FINDELFKs(cChaveFK7,"SE1")

	Reclock("SE1",.F.,.T.)
	dbDelete()
Else
	Reclock("SE1")
	Replace E1_SDACRES With E1_ACRESC
	Replace E1_SDDECRE With E1_DECRESC
	If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
		Replace E1_STATUS With "A"
	Else
		Replace E1_STATUS With Iif(E1_SALDO >= 0.01,"A","B")
	EndIf

	Replace E1_ORIGEM With IIF(Empty(E1_ORIGEM),"FINA040",E1_ORIGEM)
	MsUnlock()
Endif

dbSelectArea("SE1")

lAcresc := lDecresc := .F.
If Len(aParcelas)== Len(aParcAcre)
   lAcresc := .T.
Endif
If Len(aParcelas)== Len(aParcDecre)
   lDecresc := .T.
Endif

//Dados do titulo principal
cPrefixo 	:= aCampos[Ascan(aCampos,{|e| e[1] == "E1_PREFIXO"})][1]
cNum		:= aCampos[Ascan(aCampos,{|e| e[1] == "E1_NUM"})][1]
cTipo		:= aCampos[Ascan(aCampos,{|e| e[1] == "E1_TIPO"})][1]
cCliente	:= aCampos[Ascan(aCampos,{|e| e[1] == "E1_CLIENTE"})][1]
cLoja		:= aCampos[Ascan(aCampos,{|e| e[1] == "E1_LOJA"})][1]

//Preenche com os dados da FKF posicionada do titulo original
If cPaisLoc == "BRA" .and. AliasInDic("FKF")
	aFKF := { 	{ "FKF_CPRB"  , FKF->FKF_CPRB     , NIL },;
            { "FKF_CNAE"  , FKF->FKF_CNAE     , NIL },;
            { "FKF_TPREPA", FKF->FKF_TPREPA   , NIL },;
            { "FKF_TPSERV", FKF->FKF_TPSERV   , NIL },;
            { "FKF_INDDEC", FKF->FKF_INDDEC   , NIL },;
            { "FKF_INDSUS", FKF->FKF_INDSUS   , NIL }}
EndIf
//Rastreamento
If lRastro
	aAdd(aRastroOri,{	E1_FILIAL,;
							E1_PREFIXO,;
							E1_NUM,;
							E1_PARCELA,;
							E1_TIPO,;
							E1_CLIENTE,;
							E1_LOJA,;
							E1_VALOR })
Endif

If !lNRastDSD
	//Verificacao de conflito de parcela independente da gravacao, para evitar interrupcao na gravacao do desdobramento no meio do processo.
	//Correcao da baixa indevida do titulo, caso o usuario opte pelo cancelamento do desdobramento
	For  i := 1 to Len(aParcelas)
		If (cAlias)->(dbSeek(xFilial("SE1") + &cPrefixo + &cNum + cParcSE1 + &cTipo))
			If IW_MsgBox(STR0062 + cParcSe1 + STR0063,STR0064, "YESNO",2) //"Parcela "###" já está cadastrada. Abandona Desdobramento?"###"Atenção"
				lEnd := .T.
			Endif
			Exit
		Endif
	Next i
Endif

If lEnd
	//Voltando o titulo como aberto, ja que o desdobramento foi cancelado
	dbSelectArea(cAlias)
	RecLock(cAlias,.F.)
	Replace E1_SALDO	With E1_VALOR
	Replace E1_BAIXA	With CtoD("//")
	Replace E1_VALLIQ	With 0
	Replace E1_STATUS	With "A"
	Replace E1_FILORIG	With xFilial(cAlias)
	Replace E1_DESDOBR	With "2"
	MsUnlock()
	Return
Else

	If lNRastDSD
		Do While (cAlias)->(dbSeek(xFilial("SE1") + &cPrefixo + &cNum + cParcSE1 + &cTipo))
			cParcSE1 := F040RetParc( cParcSE1, cTipoPar, nTamParc )
		EndDo
	EndIf

	For  i := 1 to Len(aParcelas)
		If (cAlias)->(dbSeek(xFilial("SE1") + &cPrefixo + &cNum + cParcSE1 + &cTipo))
			cParcSE1 := F040RetParc( cParcSE1, cTipoPar, nTamParc )
		Else
			cParcSE1 := Right("000" + cParcSE1,nTamParc)
		Endif
		IncProc(STR0061 + cParcSE1) //"Gerando parcela "
		nValSaldo += aParcelas[i,2]

		//Desdobramento em método novo com rotina Automatica
		If !lF040Auto .and. lRastro .and. !lNRastDSD .and. lCalcImp

			dbGoto(nRecOrig)
			_aTit := {}
			AADD(_aTit , {"E1_PREFIXO",SE1->E1_PREFIXO                ,NIL})
			AADD(_aTit , {"E1_NUM"    ,SE1->E1_NUM		               ,NIL})
			AADD(_aTit , {"E1_PARCELA",cParcSE1                      ,NIL})
			AADD(_aTit , {"E1_TIPO"   ,SE1->E1_TIPO                    ,NIL})
			AADD(_aTit , {"E1_NATUREZ",SE1->E1_NATUREZ		                 ,NIL})
			AADD(_aTit , {"E1_CLIENTE",SE1->E1_CLIENTE                 ,NIL})
			AADD(_aTit , {"E1_LOJA"   ,SE1->E1_LOJA                     ,NIL})
			AADD(_aTit , {"E1_EMISSAO",SE1->E1_EMISSAO                        ,NIL})
			AADD(_aTit , {"E1_VENCTO" ,aParcelas[i,1]         ,NIL})
			AADD(_aTit , {"E1_VENCREA",DataValida(aParcelas[i,1],.T.)       ,NIL})
			AADD(_aTit , {"E1_VENCORI",aParcelas[i,1]      ,NIL})
			AADD(_aTit , {"E1_EMIS1"  ,IIf(Type("dDataEmis1") # "U", IIf(!Empty(dDataEmis1),dDataEmis1,dDataBase),dDataBase)                        ,NIL})
			AADD(_aTit , {"E1_MOEDA"  ,SE1->E1_MOEDA                  ,NIL})
			AADD(_aTit , {"E1_VALOR"  ,aParcelas[i,2]                         ,NIL})
			AADD(_aTit , {"E1_VLCRUZ" ,Iif( cPaisLoc=="CHI" , Round(xMoeda(aParcelas[i,2],nMoedSE1,1,dDataBase,3),MsDecimais(1)) , Round(NoRound(xMoeda(aParcelas[i,2],nMoedSE1,1,dDataBase,3),3),2) ),NIL})
			AADD(_aTit , {"E1_ORIGEM" ,"FINA040"                 ,NIL})
			AADD(_aTit , {"E1_HIST"   ,cHistSE1                 ,NIL})
			If lAcresc
				AADD(_aTit , {"E1_ACRESC" ,aParcAcre[i,2], NIL})
				AADD(_aTit , {"E1_SDACRES",aParcAcre[i,2], NIL})
			Endif
			If lDecresc
				AADD(_aTit , {"E1_DECRESC",aParcDecre[i,2], NIL})
				AADD(_aTit , {"E1_SDDECRE",aParcDecre[i,2], NIL})
			Endif
			If lSpbInUse
				AADD(_aTit , {"E1_MODSPB",cModSpb, NIL})
			Endif

			//Chamada da rotina automatica
			//3 = inclusao
			MSExecAuto({|a,b, c, d,e, f| FINA040(a,b, c, d,e, f)}, _aTit, 3,,,,aFKF)

			If lMsErroAuto
				MOSTRAERRO()
			Endif

			//Gravacoes complementares
			RecLock(cAlias,.F.)
			SE1->E1_DESDOBR := "1"
			MsUnlock()

		Else

			RecLock(cAlias,.T.)
			// Descarrega aCampos no SE1 para que todos os campos preenchidos no titulo principal
			// sejam replicados aos titulos gerados no desdobramento.
			For nX := 1 To fCount()
				If !Empty(aCampos[nX][2])
					FieldPut(nX,aCampos[nX][2])
				Endif
			Next

			If lF040DTDES
				dDtEmiss := Execblock("F040DTDES",.F.,.F.)
			Endif

			// Grava o restante dos campos que variam conforme a parcela
			Replace	E1_VENCTO 	With aParcelas[i,1]  , 	;
						E1_VALOR		With aParcelas[i,2]  , 	;
						E1_PARCELA 	With cParcSE1        ,	;
						E1_HIST    	With cHistSE1        ,	;
						E1_DESDOBR 	With "1"             ,	;
						E1_EMISSAO 	With dDtEmiss		   , 	;
						E1_VENCORI	With aParcelas[i,1]	, 	;
						E1_SALDO	With aParcelas[i,2]  , 	;
						E1_ORIGEM  	With "FINA040"			,	;
						E1_VENCREA 	With DataValida(aParcelas[i,1],.T.) ,;
						E1_VLCRUZ	With Iif( cPaisLoc=="CHI" , Round(xMoeda(aParcelas[i,2],nMoedSE1,1,dDataBase,3),MsDecimais(1)) , Round(NoRound(xMoeda(aParcelas[i,2],nMoedSE1,1,dDataBase,3),3),2) ),;
						E1_IRRF		With 0,;
						E1_INSS		With 0,;
						E1_ISS		With 0,;
						E1_COFINS	With 0,;
						E1_PIS		With 0,;
						E1_CSLL		With 0,;
						E1_BAIXA	With Ctod("//"),;
						E1_SITUACA  With "0",;
						E1_NOMCLI	With cNomeCli,;
						E1_EMIS1	With dDataBase,;
						E1_FILORIG	With cFilAnt,;
						E1_STATUS 	With IIf(AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0,"A",Iif(SE1->E1_SALDO>0.01,"A","B"))

			If lAcresc
				Replace	E1_ACRESC  with aParcAcre[i,2],;
							E1_SDACRES With aParcAcre[i,2]
			Endif
			If lDecresc
				Replace	E1_DECRESC with aParcDecre[i,2],;
							E1_SDDECRE With aParcDecre[i,2]
		    Endif
	    	If lSpbInUse
				Replace	E1_MODSPB with cModSpb
			Endif

			If SE1->E1_FLUXO == 'S'
				AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, If(SE1->E1_TIPO $ MVABATIM,"-","+"),,FunName(),"SE1",SE1->(Recno()),3)
			Endif

		Endif

		IF lfa040Par
			ExecBlock("FA040PAR",.f.,.f., a040Desd)
		Endif

		MsUnlock()

		//Rastreamento
		If lRastro
			aAdd(aRastroDes,{	E1_FILIAL,;
									E1_PREFIXO,;
									E1_NUM,;
									E1_PARCELA,;
									E1_TIPO,;
									E1_CLIENTE,;
									E1_LOJA,;
									E1_VALOR } )
		Endif

		If !SE1->E1_TIPO $ MVABATIM .and. cTPCOMIS == "O"
			Fa440CalcE("FINA040",,,,.T.)
		Endif

		nMCusto := Val(SuperGetMV("MV_MCUSTO"))
		nMCusto	:= If(SA1->A1_MOEDALC > 0,SA1->A1_MOEDALC, nMCusto)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Atualiza Acumulado de Clientes				  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !( SE1->E1_TIPO $ MVRECANT + "/"+MV_CRNEG)
			dbSelectArea("SA1")

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Nao atualizar os campos A1_VACUM e A1_NROCOM se o modulo for o loja³
			//³e o cliente = cliente padrao.                                      ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

			If nModulo == 12 .OR. nModulo == 72 // SIGALOJA //SIGAPHOTO
				If SA1->A1_COD + SA1->A1_LOJA == GetMv("MV_CLIPAD") + GetMv("MV_LOJAPAD")
	 				lAtuAcum := .F.
				EndIf
			EndIf

			If lTravaSA1
	   			lGrvSa1:= ExecBlock("F040TRVSA1",.F.,.F.)
			Endif

			If lAtuAcum
				dbSelectArea("SA1")
				dbSetOrder(1)
				dbseek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA)
				nVlrTit := Round(NoRound(xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMCusto,SE1->E1_EMISSAO,3),3),2)
			  	If lGrvSa1
					Reclock("SA1",.F.)
					SA1->A1_PRICOM  := Iif(SE1->E1_EMISSAO<SA1->A1_PRICOM .Or. Empty(SA1->A1_PRICOM),SE1->E1_EMISSAO,SA1->A1_PRICOM)
					SA1->A1_ULTCOM  := Iif(SA1->A1_ULTCOM<SE1->E1_EMISSAO,SE1->E1_EMISSAO,SA1->A1_ULTCOM)
					SA1->A1_NROCOM  := SA1->A1_NROCOM + 1
					SA1->A1_VACUM	  := SA1->A1_VACUM + nVlrTit
					nValForte := Round(NoRound(xMoeda(SE1->E1_VALOR,SE1->E1_MOEDA,nMCusto,SE1->E1_EMISSAO,3),3),2)
	                nValTot += nValForte
              EndIf
				If ( nValForte > SA1->A1_MAIDUPL )
					SA1->A1_MAIDUPL := nValForte
				EndIf

				MsUnlock()
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Rotina de contabiliza‡„o do titulo de desdobramento ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea(cAlias)
		IF !E1_TIPO $ MVPROVIS .or. mv_par02 == 1
			cPadrao:="504"  //Inclusao de C.Receber via desdobramento
			lPadrao:=VerPadrao(cPadrao)
			If lPadrao .and. mv_par03 == 1 // Contabiliza On-Line
				If nHdlPrv <= 0
					nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
				Endif
				If nHdlPrv > 0
					SA1->( DbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA) )
					nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
					If UsaSeqCor()
						aAdd( aDiario, {"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"})
					Else
						aDiario := {}
					EndIf
				Endif
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Atualiza flag de Lan‡amento Cont bil		  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If nTotal > 0
					Reclock("SE1")
					Replace E1_LA With "S"
					MsUnlock()
				Endif
			Endif
		Endif
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Grava os lancamentos de desdobramento - SIGAPCO ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		PcoDetLan("000001","03","FINA040")

		cParcSE1 := Soma1(cParcSE1,nTamParc,.F.)

		If GetMv("MV_1DUP") == "A"
			Do While cParcSE1 <> Upper(cParcSE1) .And. SE1->( MsSeek( xFilial("SE1") + &cPrefixo + &cNum + Upper(cParcSE1) + &cTipo ) )
				cParcSE1 := Soma1( cParcSE1, nTamParc, .T. )
			EndDo
		EndIf
	Next i
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Faz a atualizacao dos saldos do cliente no SA1. ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

AtuSalDup("+",nValSaldo,SE1->E1_MOEDA,SE1->E1_TIPO,,SE1->E1_EMISSAO)

Reclock("SA1",.F.)
	If (nValTot > SA1->A1_MCOMPRA)
		SA1->A1_MCOMPRA := nValTot
	EndIf

	SA1->A1_MSALDO := Iif(SA1->A1_SALDUPM>SA1->A1_MSALDO,SA1->A1_SALDUPM,SA1->A1_MSALDO)
MsUnlock()

If lPadrao .and. nTotal > 0
	StrlCtPad := SE1->E1_NUM
	nRecSE1	 := SE1->(RECNO())
	dbSelectArea ("SE1")
	dbGoBottom()
	dbSkip()
	VALOR := nValSaldo
	If nHdlPrv <= 0
		nHdlPrv:=HeadProva(cLote,"FINA040",Substr(cUsuario,7,6),@cArquivo)
	Endif
	If nHdlPrv > 0
		nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
	Endif
	VALOR := 0
	//Reposiciono o SE1 para garantir que o mesmo nao esteja mais em EOF()
	SE1->(MsGoTo(nRecSe1))
Endif

//Gravacao do rastreamento
If lRastro
	FINRSTGRV(1,"SE1",aRastroOri,aRastroDes,aRastroOri[1,8])
Endif

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³FA040Pes  ³ Autor ³ Rafael Rodrigues      ³ Data ³ 04/09/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Cria uma pesquisa personalizada para usar campos virtuais.  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³Gestao Educacional                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Pes(cAlias, nReg, nOpc)
Local nOpcA
Local oDlg, oOrdem, oChave, oBtOk, oBtCan, oBtPar
Local cOrdem
Local cExpChave := ""
Local cChave	:= Space(255)
Local aOrdens	:= {}
Local aBlocks	:= {}
Local nOrder	:= 1

SIX->( dbSetOrder(1) )
SIX->( dbSeek(cAlias) )

while SIX->( !eof() .and. INDICE == cAlias )

	aAdd( aOrdens, Capital( SIXDescricao() ) )
	aAdd( aBlocks, &("{ || "+cAlias+"->(dbSetOrder("+Str(nOrder,2,0)+")), "+cAlias+"->(dbSeek(xFilial('"+cAlias+"')+Rtrim(cChave))) }") )

	nOrder++

	SIX->( dbSkip() )
end

aAdd( aOrdens, Capital( STR0067 ) )	// "Nome do Aluno"
aAdd( aBlocks, &("{ || "+cAlias+"->(dbSetOrder(2)), "+cAlias+"->(dbSeek(xFilial('"+cAlias+"')+Posicione('JA2',3,xFilial('JA2')+Rtrim(cChave),'JA2_CLIENT')))}") )

define msDialog oDlg title STR0001 from 00,00 TO 100,500 pixel

@ 005, 005 combobox oOrdem var cOrdem items aOrdens size 210,08 of oDlg pixel
@ 020, 005 msget oChave var cChave size 210,08 of oDlg pixel

define sButton oBtOk  from 05,218 type 1 action (nOpcA := 1, oDlg:End()) enable of oDlg pixel
define sButton oBtCan from 20,218 type 2 action (nOpcA := 0, oDlg:End()) enable of oDlg pixel
define sButton oBtPar from 35,218 type 5 when .F. of oDlg pixel

activate msdialog oDlg center

if nOpcA == 1
	Set SoftSeek On
	for nOrder := 1 to len(aOrdens)
		if aOrdens[ nOrder ] == cOrdem
			cExpChave := (cAlias)->(IndexKey(nOrder))
			if "DTOS" $ cExpChave .Or. "DTOC" $ cExpChave
				cChave := ConvData( cExpChave, cChave )
			endif
			Eval( aBlocks[ nOrder ] )
		endif
	next i
	Set SoftSeek Off
endif

Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³Fa040Bar  ³ Autor ³Mauricio Pequim Jr     ³ Data ³15.09.2003³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Enchoice bar especifica da inclusao de titulos a pagar      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ xValid: 	Validacao do PMS para acrescentar botao           ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FA040Bar(cValidPMS,bPmsDlgRC)

Local aButtons := {}
Local aUsButtons

If &(cValidPMS)		// Se usa PMS integrado com o ERP
	AADD(aButtons,{'PROJETPMS', {||Eval(bPmsDlgRC)},STR0045 + " - <F10>", STR0089}) //"Gerenciamento de Projetos"###"Projetos"
Endif

If cPaisLoc=="BRA"
	aAdd(aButtons, {'CONTAINER'   ,{|| FINA986 ("SE1") },STR0211,STR0211} ) // Complemento do titulo
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Adiciona botoes do usuario na EnchoiceBar                              ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock( "F040BUT" )
	aUsButtons := ExecBlock( "F040BUT", .F., .F. )
	AEval( aUsButtons, { |x| AAdd( aButtons, x ) } )
EndIf

Return (aButtons)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³Fa040Pai	³ Autor ³ Nilton Pereira        ³ Data ³ 06/08/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Procura se titulo de ISS ou TX tem pai							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³Fa050Pai()																  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³Generico																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
FuncTion Fa040Pai()

Local nRegSE1
Local lAchou:= .F.
Local cPrefixo := SE1->E1_PREFIXO
Local cNum		:= SE1->E1_NUM
Local cTipoPai	:= SE1->E1_TIPO

dbSelectArea("SE1")
dbSetOrder(1)
nRegSE1:= Recno()
If dbSeek(xFilial("SE1")+cPrefixo+cNum)
	While !Eof() .and. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM) == xFilial("SE1")+cPrefixo+cNum
		If !(SE1->E1_TIPO $ MVIRABT+"/"+MVINABT+"/"+MVCFABT+"/"+MVCSABT+"/"+MVPIABT)
			If cTipoPai $ MVIRABT
				If SE1->E1_IRRF != 0
					lAchou := .T.
				Endif
			ElseIf cTipoPai $ MVINABT
				If SE1->E1_INSS != 0
					lAchou := .T.
				Endif
			ElseIf cTipoPai $ MVCFABT
				If SE1->E1_COFINS != 0
					lAchou := .T.
				Endif
			ElseIf cTipoPai $ MVCSABT
				If SE1->E1_CSLL != 0
					lAchou := .T.
				Endif
			ElseIf cTipoPai $ MVPIABT
				If SE1->E1_PIS != 0
					lAchou := .T.
				Endif
			Endif
		Endif
		If lAchou
			Exit
		Endif
		DbSkip()
	Enddo
EndIf

dbSelectArea("SE1")
dbGoto(nRegSE1)
Return lAchou

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³F040TotMes³ Autor ³Mauricio Pequim Jr     ³ Data ³05/08/2004³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Efetua o calculo do valor de titulos financeiros que        ³±±
±±³          ³calcularam a retencao do PIS / COFINS / CSLL e nao          ³±±
±±³          ³criaram os titulos de abatimento                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ExpA1 := F040TotMes( ExpD1 )                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ExpA1 -> Array com os seguintes elementos                   ³±±
±±³          ³       1 - Valor dos titulos                                ³±±
±±³          ³       2 - Valor do PIS                                     ³±±
±±³          ³       3 - Valor do COFINS                                  ³±±
±±³          ³       4 - Valor da CSLL                                    ³±±
±±³          ³       5 - Array contendo os recnos dos registos processados³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpD1 - Data de referencia                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function F040TotMes( dReferencia,nIndexSE1,cIndexSE1 )

Local aAreaSE1  := SE1->( GetArea() )
Local aDadosRef := Array( 6 )
Local aRecnos   := {}
Local dIniMes   := FirstDay( dReferencia )
Local dFimMes   := LastDay( dReferencia )
Local cModTot   := GetNewPar( "MV_MT10925", "1" )
Local lAbatIRF  := cPaisLoc == "BRA"
Local nVlDevolv := 0
Local cChaveOri	:=	M->E1_PREFIXO+M->E1_NUM+M->E1_PARCELA+M->E1_TIPO+M->E1_CLIENTE+M->E1_LOJA
Local aRets			:=	{0,0,0,0}
Local lTodasFil	:= ExistBlock("F040FRT")
Local aFil10925	:= {}
Local cFilAtu	:= FWGETCODFILIAL
Local lVerCliLj	:= ExistBlock("F040LOJA")
Local aCli10925	:= {}
Local nFil 			:= 0
Local lLojaAtu  := ( GetNewPar( "MV_LJ10925", "1" ) == "1" )
Local nLoop     := 0
Local lRaRtImp	:= lFinImp .And.FRaRtImp()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()
Local nLiquidado := 0
Local aBaixasTit := 0

Local aStruct   := {}
Local aCampos   := {}
Local cQuery    := ""
Local	cCliente  := M->E1_CLIENTE
Local cLoja     := M->E1_LOJA
Local cAliasQry := ""
Local cSepNeg   := If("|"$MV_CRNEG,"|",",")
Local cSepProv  := If("|"$MVPROVIS,"|",",")
Local cSepRec   := If("|"$MVRECANT,"|",",")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Parametro que permite ao usuario utilizar o desdobramento³
//³da maneira anterior ao implementado com o rastreamento.  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lNRastDSD	:= SuperGetMV("MV_NRASDSD",.T.,.F.)
Local nDesdobrad	:= 0
Local lRastro	 	:= FVerRstFin()
//--- Tratamento Gestao Corporativa
Local lGestao   := FWSizeFilial() > 2	// Indica se usa Gestao Corporativa
Local lSE1Comp  := FWModeAccess("SE1",3)== "C" // Verifica se SE1 é compartilhada
Local aFilAux	  := {}

If Type("lAltera") <> "L" .And. IsIncallStack("MATA521A")
	lAltera	:= .F.
EndIf

AFill( aDadosRef, 0 )

If lTodasFil
	aFil10925 := ExecBlock( "F040FRT", .F., .F. )
Else
	aFil10925 := { cFilAnt }
Endif

If lVerCliLj
	aCli10925 := ExecBlock("F040LOJA",.F.,.F.)
Endif
For nFil := 1 to Len(aFil10925)

	dbSelectArea("SE1")
	cFilAnt := aFil10925[nFil]

	//Se SE1 for compartilhada e ja passou pela mesma Empresa e Unidade, pula para a proxima filial
	If lGestao .and. lSE1Comp .and. Ascan(aFilAux, {|x| x == xFilial("SE1")}) > 0
		Loop
	EndIf


	aCampos := { "E1_VALOR","E1_PIS","E1_COFINS","E1_CSLL","E1_IRF","E1_SABTPIS","E1_SABTCOF","E1_SABTCSL","E1_SABTIRF","E1_MOEDA","E1_VENCREA"}
	aStruct := SE1->( dbStruct() )

	SE1->( dbCommit() )

  	cAliasQry := GetNextAlias()

	cQuery	:= "SELECT E1_VALOR,E1_PIS,E1_COFINS,E1_CSLL,E1_IRRF,E1_SABTPIS,E1_SABTCOF,E1_SABTCSL, E1_DESDOBR, "
	cQuery	+=	"E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_CLIENTE,E1_LOJA,E1_NATUREZ,E1_MOEDA,E1_FATURA,E1_VENCREA, E1_BAIXA ,"

	If lAbatIrf
		cQuery 	+= 	"E1_SABTIRF , "
	Endif

	//639.04 Base Impostos diferenciada
	If lBaseImp
		cQuery 	+= 	"E1_BASEPIS , "
	Endif

	cQuery += "	R_E_C_N_O_ RECNO FROM "
	cQuery += RetSqlName( "SE1" ) + " SE1 "
	cQuery += "WHERE "
	cQuery += "E1_FILIAL='"    + xFilial("SE1")       + "' AND "

	If Len(aCli10925) > 0	//Verifico quais clientes e loja considerar (raiz do CNPJ)
		cQuery += "("
		For nLoop := 1 to Len(aCli10925)
			cQuery += "(E1_CLIENTE='"   + aCli10925[nLoop,1]  + "' AND "
			cQuery += "E1_LOJA='"      + aCli10925[nLoop,2]  + "') OR  "
		Next
		//Retiro o ultimo OR
		cQuery := Left( cQuery, Len( cQuery ) - 4 )
		cQuery += ") AND "
	Else
		//Considero apenas o cliente atual
		cQuery += "E1_CLIENTE='"   + cCliente             + "' AND "
		If lLojaAtu  //Considero apenas a loja atual
			cQuery += "E1_LOJA='"      + cLoja             + "' AND "
		Endif
	Endif
	cQuery += "E1_VENCREA>= '" + DToS( dIniMes )      + "' AND "
	cQuery += "E1_VENCREA<= '" + DToS( dFimMes )      + "' AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepNeg)  + " AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv) + " AND "
	If !lRaRtImp
		cQuery += "E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRec)  + " AND "
	EndIf
	cQuery += "(E1_FATURA = '"+Space(Len(E1_FATURA))+"' OR "
	cQuery += "E1_FATURA = 'NOTFAT') AND "

	//-- Tratamento para titulos baixados por Cancelamento de Fatura
	//-- Aplicavel somente em TOP para o modulo de Gestao Advocaticia (SIGAGAV)
	//-- ou Pré Faturamento de Serviços (SIGAPFS)
	If nModulo == 65 .Or. nModulo = 77
		cQuery += " NOT EXISTS (SELECT E5_FILIAL "
		cQuery += "					FROM " + RetSqlName("SE5") + " SE5 "
		cQuery += "					WHERE SE5.E5_FILIAL = '" + xFilial("SE5") + "' "
		cQuery += "					AND SE5.E5_TIPO     = SE1.E1_TIPO "
		cQuery += "					AND SE5.E5_PREFIXO  = SE1.E1_PREFIXO "
		cQuery += "					AND SE5.E5_NUMERO   = SE1.E1_NUM "
		cQuery += "					AND SE5.E5_PARCELA  = SE1.E1_PARCELA  "
		cQuery += "					AND SE5.E5_CLIFOR   = SE1.E1_CLIENTE "
		cQuery += "					AND SE5.E5_LOJA     = SE1.E1_LOJA "
		cQuery += "					AND SE5.E5_MOTBX    = 'CNF' "
		cQuery += "					AND SE5.D_E_L_E_T_  = ' ') AND "
	EndIf

	//Verificar ou nao o limite de 5000 para Pis cofins Csll
	// 1 = Verifica o valor minimo de retencao
	// 2 = Nao verifica o valor minimo de retencao
	cQuery += "E1_APLVLMN <> '2' AND "
	cQuery += "D_E_L_E_T_=' '"

	cQuery := ChangeQuery( cQuery )

	dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), cAliasQry, .F., .T. )

	For nLoop := 1 To Len( aStruct )
		If !Empty( AScan( aCampos, AllTrim( aStruct[nLoop,1] ) ) )
			TcSetField( cAliasQry, aStruct[nLoop,1], aStruct[nLoop,2],aStruct[nLoop,3],aStruct[nLoop,4])
		EndIf
	Next nLop

	( cAliasQRY )->(DBGOTOP())

	While !( cAliasQRY )->( Eof())
		aRets	:=	{0,0,0,0}
		//Todos os titulos
		If cModTot == "1"
			//Obtenho o valor das devolucoes efetuadas para o titulo dentro do periodo
			If !Empty((cAliasQRY)->E1_BAIXA)
				aBaixasTit := Baixas((cAliasQRY)->E1_NATUREZ,(cAliasQRY)->E1_PREFIXO,(cAliasQRY)->E1_NUM, ;
										(cAliasQRY)->E1_PARCELA,(cAliasQRY)->E1_TIPO,(cAliasQRY)->E1_MOEDA,"R",;
										(cAliasQRY)->E1_CLIENTE,,(cAliasQRY)->E1_LOJA,,  ;
										 dIniMes,dFimMes)
  			Else
				aBaixasTit := {0,0,0,0,0,0,0,0," ",0,0,0,0,0,0,0,0,0,0,0}
			Endif

			nVlDevolv := aBaixasTit[13]

			If Len(aBaixasTit) > 18
				nLiquidado := aBaixasTit[19]
			Endif

			//639.04 Base Impostos diferenciada
			If lBaseImp .and. ( cAliasQRY )->E1_BASEPIS > 0
				adadosref[1] += ( cAliasQRY )->E1_BASEPIS  - nVlDevolv - nLiquidado
			Else
				aDadosRef[1] += ( cAliasQRY )->E1_VALOR - nVlDevolv - nLiquidado
			Endif

			If lAltera
				aRets	:=	GetAbtOrig(cChaveOri,(cAliasQry)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA))
			Endif
			// Se ha pendencia de retencao, retorno os valores pendentes
			If ( (!Empty( ( cAliasQRY )->E1_SABTPIS+aRets[1] ) ;
				.Or. !Empty( ( cAliasQry )->E1_SABTCOF+aRets[2] ) ;
				.Or. !Empty( ( cAliasQry )->E1_SABTCSL+aRets[3] ) ))

				aDadosRef[2] += ( cAliasQRY )->E1_SABTPIS+aRets[1]
				aDadosRef[3] += ( cAliasQRY )->E1_SABTCOF+aRets[2]
				aDadosRef[4] += ( cAliasQRY )->E1_SABTCSL+aRets[3]
				AAdd( aRecnos, ( cAliasQRY )->RECNO )
			EndIf
			If	lAbatIRF .And. !Empty( (cAliasQRY)->E1_IRRF) .And. !Empty( (cAliasQRY)->E1_SABTIRF+aRets[4] )
				aDadosRef[6] += (cAliasQRY)->E1_IRRF
				If Len(aRecnos)==0 .Or.aRecnos[Len(aRecnos)] <>  (cAliasQRY)->RECNO
					AAdd( aRecnos, (cAliasQRY)->RECNO )
				Endif
			Endif
		Else
	        //Apenas titulos que tiveram Pis Cofins ou Csll
			If ( !Empty( ( cAliasQRY )->(E1_PIS+E1_COFINS + E1_CSLL+E1_IRRF) ) ) .or. ( cAliasQRY )->(E1_SABTPIS+SE1->E1_SABTCOF+SE1->E1_SABTCSL+E1_SABTIRF) > 0
				//Obtenho o valor das devolucoes efetuadas para o titulo dentro do periodo
				aBaixasTit := Baixas((cAliasQRY)->E1_NATUREZ,(cAliasQRY)->E1_PREFIXO,(cAliasQRY)->E1_NUM, ;
											(cAliasQRY)->E1_PARCELA,(cAliasQRY)->E1_TIPO,(cAliasQRY)->E1_MOEDA,"R",;
											(cAliasQRY)->E1_CLIENTE,,(cAliasQRY)->E1_LOJA,,  ;
											 dIniMes,dFimMes)
					nVlDevolv := aBaixasTit[13]

				If Len(aBaixasTit) > 18
					nLiquidado := aBaixasTit[19]
				Endif
				//Desconsidero o titulo gerador do desdobramento com rastro
				If Len(aBaixasTit) > 19 .and. lRastro  .and. !lNRastDSD
					nDesdobrad := aBaixasTit[20]
				Endif

				//639.04 Base Impostos diferenciada
				If lBaseImp .and. ( cAliasQRY )->E1_BASEPIS > 0
					adadosref[1] += ( cAliasQRY )->E1_BASEPIS  - nVlDevolv - nLiquidado - nDesdobrad
				Else
					aDadosRef[1] += ( cAliasQRY )->E1_VALOR - nVlDevolv - nLiquidado - nDesdobrad
				Endif

				If lAltera
					aRets	:=	GetAbtOrig(cChaveOri,(cAliasQry)->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA))
				Endif

				If !Empty( ( cAliasQRY )->E1_SABTPIS+aRets[1] ) .And.;
				 	!Empty( ( cAliasQry )->E1_SABTCOF+aRets[2] ) .And. ;
					!Empty( ( cAliasQry )->E1_SABTCSL+aRets[3] )

					aDadosRef[2] += ( cAliasQRY )->E1_SABTPIS
					aDadosRef[3] += ( cAliasQRY )->E1_SABTCOF
					aDadosRef[4] += ( cAliasQRY )->E1_SABTCSL
					AAdd( aRecnos, ( cAliasQRY )->RECNO )
				EndIf
				If	lAbatIRF .And. !Empty( (cAliasQRY)->E1_SABTIRF+aRets[4] )
					aDadosRef[6] += (cAliasQRY)->E1_IRRF
					If Len(aRecnos)==0 .Or. aRecnos[Len(aRecnos)] <>  (cAliasQRY)->RECNO
						AAdd( aRecnos, (cAliasQRY)->RECNO )
					Endif
				Endif
			Endif
		Endif
		( cAliasQRY )->( dbSkip())

	EndDo

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Fecha a area de trabalho da query                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	( cAliasQRY )->( dbCloseArea() )
	dbSelectArea( "SE1" )

	//Se Filial for totalmente compartilhada, faz somente 1 vez
	If Empty(xFilial("SE1"))
		Exit
	ElseIf lGestao .and. lSE1Comp
		AAdd(aFilAux, xFilial("SE1"))
	EndIf

Next

cFilAnt := cFilAtu

aDadosRef[ 5 ] := AClone( aRecnos )

SE1->( RestArea( aAreaSE1 ) )

Return( aDadosRef )


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FVerAbtImp³ Autor ³ Mauricio PEquim Jr.   ³ Data ³ 30/08/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica o valor minimo de retencao dos impostos IR, PIS   ³±±
±±³          ³ COFINS, CSLL                                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FVerAbtImp() 											              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FVerAbtImp(lVerRet)
Local nVlMinImp := GetNewPar("MV_VL10925",5000)
Local cModRet   := GetNewPar( "MV_AB10925", "0" )
Local lContrAbt := .T.
Local lContrAbtIRF:= cPaisLoc == "BRA"
Local cModRetIRF := GetNewPar("MV_IRMP232", "0" )
Local cRetCli   := "1"
Local nVlMinIrf := 0
Local aSomaImp	  := {0,0,0}
Local aAreaSfq :=  SFQ->(GetArea())
Local aAreaSe1 :=  SE1->(GetArea())
Local lMenor := .F.
Local lRetBaixado := .F.
Local cCond := ""

//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr			:= FPccBxCr()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()
Local aPcc		:= {}
Local lEmpPub := SuperGetMv("MV_ISPPUBL" ,.T.,"2") == "1"
Local dRef		:= dDatabase
Local nVencto 	:= SuperGetMv("MV_VCPCCR",.T.,1)

Default lVerRet := .T.

lF040Auto	:= Iif(Type("lF040Auto") != "L", .F., lF040Auto )

If M->E1_EMISSAO >= dLastPcc
	nVlMinImp	:= 0
EndIf

//Os abatimentos de impostos somente sofrerao acao desta funcao
//Caso o PCC CR seja pela emissao
//Protegido para chamadas externas
If !lPccBxCr
	If lContrAbt .Or. lContrAbtIRF
		If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|URU|VEN"
			cRetCli := Iif(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
		Endif
	Endif
	If lAltera
		lAlterNat := .T.
	Endif
	If M->E1_EMISSAO >= dLastPcc
		SED->( dbSetOrder(1) ) //ED_FILIAL+ED_CODIGO
		SED->( dbSeek(xFilial("SED") + M->E1_NATUREZ) )
		If nVencto == 2
			dRef := M->E1_VENCREA
		ElseIf nVencto == 1 .OR. EMPTY(nVencto)
			dRef := M->E1_EMISSAO
		ElseIf nVencto == 3
			dRef := M->E1_EMIS1
		Endif
		aPcc	:= newMinPcc(dRef,Iif(M->E1_MOEDA>1,M->E1_VLCRUZ,Iif(lF040Auto .And. nBasePis <> M->E1_VALOR, nBasePis, M->E1_VALOR)),SED->ED_CODIGO,"R",SA1->A1_COD+SA1->A1_LOJA)

		If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_PIS"))
			M->E1_PIS		:= aPcc[2]
		Endif

		If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_COFINS"))
			M->E1_COFINS	:= aPcc[3]
		Endif

		If !lF040Auto .or. (lF040Auto .and. !F040ImpAut("E1_CSLL"))
			M->E1_CSLL		:= aPcc[4]
		Endif

		nVlRetPis := M->E1_PIS
		nVlRetCof := M->E1_COFINS
		nVlRetCsl := M->E1_CSLL
		nVlRetIRF := M->E1_IRRF
	Else

		If (lContrAbtIRF .Or. lContrAbt) .And. (cModRet != "0" .Or. cModRetIRF != "0")
		   //Nao retem Pis,Cofins,CSLL
			If cRetCli == "3"  //Nao retem PIS
				If cModRet !="0"
					nVlRetPis := M->E1_PIS
					nVlRetCof := M->E1_COFINS
					nVlRetCsl := M->E1_CSLL
					M->E1_PIS := 0
					M->E1_COFINS := 0
					M->E1_CSLL := 0
				Endif
				If cModRetIRF !="0"
					nVlRetIRF := M->E1_IRRF
					M->E1_IRRF := 0
				Endif
			Endif

			If cRetCli<>"3" .and. (SA1->A1_RECPIS $ "S#P" .or. SA1->A1_RECCSLL $ "S#P" .or. SA1->A1_RECCOFI $ "S#P")
				If lVerRet
					aDadosRet := F040TotMes(M->E1_VENCREA,@nIndexSE1,@cIndexSE1)
				Endif
				IF cRetCli == "1"		//Calculo do Sistema
					If cModRet == "1"  //Verifica apenas este titulo

						//639.04 Base Impostos diferenciada
						If lBaseImp .and. M->E1_BASEIRF > 0
							cCond := "M->E1_BASEIRF"
						Else
							cCond := "M->E1_VALOR"
						Endif

						AFill( aDadosRet, 0 )
					ElseIf cModRet == "2"  //Verifica o total acumulado no mes/ano

						//639.04 Base Impostos diferenciada
						If lBaseImp .and. M->E1_BASEIRF > 0
							If lAltera
								// caso o mes seja o mesmo, quer dizer que este titulo ja foi contado para o valor mensal da base
								If month(SE1->E1_VENCREA) == month(M->E1_VENCREA)
									cCond := "aDadosRet[1]+M->E1_BASEIRF-SE1->E1_BASEIRF"
								Else
									cCond := "aDadosRet[1]+M->E1_BASEIRF"
								Endif
							Else
								cCond := "aDadosRet[1]+M->E1_BASEIRF"
							Endif
						Else
							If lAltera
								cCond := "aDadosRet[1]+M->E1_VALOR-SE1->E1_VALOR"
							Else
								cCond := "aDadosRet[1]+M->E1_VALOR"
							Endif
						Endif

					Endif

					If cModRetIrf == "1" 	//Empresa se enquadra na MP232
		            If Len(Alltrim(SM0->M0_CGC)) < 14   //P.Fisica
							nVlMinIrf := MaTbIrfPF(0)[4]
						Else
							nVlMinIrf := nVlMinImp
						Endif

						//Se for menor que o valor minimo para retencao de IRRF P Fisica
						If &cCond <= nVlMinIrf
							nVlRetIRF := M->E1_IRRF
							M->E1_IRRF 		:= 0
						Endif
		   		Endif

					//Se for menor que o valor minimo para retencao de IRRF P Fisica mas
					//Se for maior que o valor minimo para retencao de Pis, Cofins e Csll
					If &cCond <= nVlMinImp
						nVlRetPis := M->E1_PIS
						nVlRetCof := M->E1_COFINS
						nVlRetCsl := M->E1_CSLL
						M->E1_PIS 		:= 0
						M->E1_COFINS 	:= 0
						M->E1_CSLL 		:= 0
						lMenor := .T.
					ElseIf lAltera
						nVlOriPis := M->E1_SABTPIS
						nVlOriCof := M->E1_SABTCOF
						nVlOriCsl := M->E1_SABTCSL
					Endif
				Endif

				If M->E1_PIS+M->E1_COFINS+M->E1_CSLL+M->E1_IRRF > 0 .Or. lAltera

					If	M->E1_PIS+M->E1_COFINS+M->E1_CSLL > 0 .Or. lAltera

						IF M->E1_PIS > 0 .And. (M->E1_PIS != nVlOriPis .Or. lAltera)
							nVlRetPis := M->E1_PIS
						Endif

						IF M->E1_COFINS > 0 .And. (M->E1_COFINS != nVlOriCof .Or. lAltera)
							nVlRetCof := M->E1_COFINS
						Endif

						IF M->E1_CSLL > 0 .And. (M->E1_CSLL != nVlOriCsl .Or. lAltera)
							nVlRetCsl := M->E1_CSLL
						Endif

						If lAltera .And. cRetCli == "1" .And. cModRet == "2"
							// Verifica se nao ha pendencia de retencao, verifica qual o imposto deste titulo.
							SFQ->(DbSetOrder(1))
							SE1->(DbSetOrder(1))
							If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+M->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
								While SFQ->(!Eof()) .And.;
										SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI) == xFilial("SFQ")+"SE1"+M->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)
									// Soma os impostos dos filhos
									If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES))) .And.;
										Left(Dtos(SE1->E1_VENCREA),6) == Left(Dtos(M->E1_VENCREA),6)
										aSomaImp[1] += SE1->E1_PIS
										aSomaImp[2] += SE1->E1_COFINS
										aSomaImp[3] += SE1->E1_CSLL
									Endif
									SFQ->(DbSkip())
								End
	/*							aDadosRet[2] += aSomaImp[1]
								aDadosRet[3] += aSomaImp[2]
								aDadosRet[4] += aSomaImp[3]*/
							Else
								SFQ->(DbSetOrder(2))
								If SFQ->(MsSeek(xFilial("SFQ")+"SE1"+M->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
									SE1->(DbSetOrder(1))
									If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
										If !(SE1->E1_SALDO == SE1->E1_VALOR)
											lRetBaixado := .T.
										Endif
									Endif
								Endif
							Endif
							SFQ->(RestArea(aAreaSfq))
							SE1->(RestArea(aAreaSe1))
						Endif
						//Caso o usuario tenha alterado os valores de pis, cofins e csll, antes da cofirmacao
						//respeito o que foi informado descartando o valor canculado.
						If lVerRet
							If !lMenor .Or. lRetBaixado
								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³Alterar apenas quando o valor do imposto for diferente do   ³
								//³calculado (o que caracteriza alteração manual). A alteracao ³
								//³sem esta validacao faz com que os valores do PCC sejam      ³
								//³calculados erroneamente, jah que eh abatido de seu valor o  ³
								//³PCC do proprio titulo.                                      ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								If nVlRetPis # nVlOriPis
									M->E1_PIS 	:= nVlRetPis + aDadosRet[2] - nVlOriPis
								Else
									If lAltera .and. ReadVar() $ "M->E1_VENCTO|M->E1_VENCREA"
										M->E1_PIS 	:= nVlRetPis + aDadosRet[2]
									Else
										M->E1_PIS 	:= nVlRetPis
									Endif
								Endif

								If nVlRetCof # nVlOriCof
									M->E1_COFINS := nVlRetCof + aDadosRet[3] - nVlOriCof
								Else
									If lAltera .and. ReadVar() $ "M->E1_VENCTO|M->E1_VENCREA"
										M->E1_COFINS := nVlRetCof + aDadosRet[3]
									Else
										M->E1_COFINS := nVlRetCof
									Endif
								Endif

								If nVlRetCsl # nVlOriCsl
									M->E1_CSLL 	:= nVlRetCsl + aDadosRet[4] - nVlOriCsl
								Else
									If lAltera .and. ReadVar() $ "M->E1_VENCTO|M->E1_VENCREA"
										M->E1_CSLL 	:= nVlRetCsl + aDadosRet[4]
									Else
										M->E1_CSLL 	:= nVlRetCsl
									Endif
								Endif
							Endif
						Endif
					Endif

					If M->E1_IRRF > 0	 .and. cModRetIrf == "1"
						nVlRetIRF := M->E1_IRRF
						//Caso o usuario tenha alterado os valores de pis, cofins e csll, antes da cofirmacao
						//respeito o que foi informado descartando o valor canculado.
						If lVerRet
							M->E1_IRRF 	:= nVlRetIRF+ aDadosRet[6]
						Endif
					Endif

					If lVerRet
						f040VerVlr()
					Endif

				Else
					//Natureza nao calculou Pis/Cofins/Csll
					AFill( aDadosRet, 0 )
				Endif
			Endif
		Endif
	EndIf
Endif
Return

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³F040VerVlr³ Autor ³ Mauricio Pequim Jr    ³ Data ³29/19/2004 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Verifica se valor será menor que zero                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Financeiro                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function	f040VerVlr()

Local nTotARet := 0
Local nSobra := 0
Local nFatorRed := 0
Local lDescISS := IIF(SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.),.T.,.F.)
Local nValorTit := m->e1_valor - m->e1_irrf - m->e1_inss - m->e1_pis - m->e1_cofins - m->e1_csll - If(lDescIss,m->e1_iss,0)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Guarda os valores originais                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If nValorTit < 0
	nValorTit += m->e1_pis + m->e1_cofins + m->e1_csll

	nTotARet := m->e1_pis+m->e1_cofins+m->e1_csll

	nVlRetPIS := M->E1_PIS
	nVlRetCOF := M->E1_COFINS
	nVlRetCSL := M->E1_CSLL

	nSobra := nValorTit - nTotARet

	If nSobra < 0

		nFatorRed := 1 - ( Abs( nSobra ) / nTotARet )

		m->e1_pis  := NoRound( m->e1_pis * nFatorRed, 2 )
		m->e1_cofins := NoRound( m->e1_cofins * nFatorRed, 2 )
		m->e1_csll := nValorTit - ( m->e1_pis + m->e1_cofins )

		nVlOriCof	:= m->e1_cofins
		nVlOriCsl	:= m->e1_csll
		nVlOriPis	:= m->e1_pis
	Endif
EndIf

Return


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FA040VcRea³ Autor ³ Mauricio Pequim Jr    ³ Data ³ 30/09/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica a data de vencimento informada						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FA040Vcrea() 															  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040VcRea()

Local lContrAbt := .T.
Local lAltPiCoCs := .F.

If lAltera .and. !lAltDtVc
	If cPaisLoc == "BRA"
		//Verifico se o titulo ja abateu o Pis/Cofins/Csll
		If lContrAbt .and. SE1->E1_PIS + SE1->E1_COFINS + SE1->E1_CSLL > 0
			If SE1->E1_SABTPIS + SE1->E1_SABTCOF + SE1->E1_SABTCSL == 0	//Titulo ja abateu os impostos nao posso alterar
				lAltPiCoCs := .T.															//os valores de Pis/Cofins/Csll
			Endif
		Endif

		If lAltPiCocs  //Se a alteracao for num titulo retentor de imposto
			lAltDtVc := .T.
			//MsgInfo(STR0070,STR0064) //"Este título gerou retenção dos impostos Pis, Cofins e Csll. Caso se altere a data de vencimento deste título e venha a ser alterado o período de apuração, os impostos não serão recalculados."###"Atenção"
		Endif
	Endif
Endif
Return .T.
/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³GetAbtOrig³ Autor ³ Bruno Sobieski        ³ Data ³ 03/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Pega o valor de ABATIMENTOS de impostos utilizado por este ³±±
±±³          ³ titulo.                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ GetAbtOrig(cChaveDest,cChaveOri)  								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function GetAbtOrig(cChaveOri,cChaveDest)
Local aRet	:=	{0,0,0,0}
Local aAreaSfq := SFQ->(GetArea())
Local aArea := GetArea()

SFQ->(dbSeTOrder(2))
SFQ->(MsSeek(xFilial()+"SE1"+cChaveDest))
While !SFQ->(Eof()) .And.xFilial('SFQ')+"SE1"+cChaveDest ==;
		SFQ->(FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES)
	If xFilial('SFQ')+"SE1"+cChaveOri==SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)
		aRet[1]	+=	SFQ->FQ_SABTPIS
		aRet[2]	+=	SFQ->FQ_SABTCOF
		aRet[3]	+=	SFQ->FQ_SABTCSL
		If SFQ->(FieldPos('FQ_SABTIRF')) > 0
			aRet[4]	+=	SFQ->FQ_SABTIRF
		Endif
	Endif
	SFQ->(Dbskip())
Enddo
SFQ->(RestArea(aAreaSfq))
RestArea(aArea)

Return aRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040UsaMP232³Autor  ³ Bruno Sobieski      ³ Data ³ 03/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica se para o cliente posicionado se aplica a MP232.  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040UsaMP232						  						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function F040UsaMp232()
Local lContrAbtIRF	:= cPaisLoc == "BRA"
Local cModRetIRF 	:= GetNewPar("MV_IRMP232", "0" )
Local cRetCli  		:= "2"
If lContrAbtIRF
	If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|URU|VEN"
		cRetCli := Iif(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
	Endif
Endif

Return (cRetCli=="1" .And. cModRetIRF=="1")


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o	 ³Fa040Visu ³ Autor ³ Cristiano Denardi     ³ Data ³22.02.05  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Visualiza Titulo a partir da tela de Bordero				  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA060	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function Fa040Visu()

Local 	aArea 		:= GetArea()
Private cCadastro 	:= OemToAnsi( STR0028 )

If Select("__SUBS") > 0
	DbSelectArea("SE1")
	DbSetOrder(1)
	If DbSeek( __SUBS->E1_FILIAL + __SUBS->E1_PREFIXO + __SUBS->E1_NUM + __SUBS->E1_PARCELA + __SUBS->E1_TIPO )
		AxVisual( "SE1", SE1->( Recno() ), 2 )
	Endif
Endif
RestArea( aArea )
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040AltOk   ³Autor  ³ Bruno Sobieski      ³ Data ³ 03/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida a modificacao de um titulo para saber informar as   ³±±
±±³          ³ ocorrencias CNAB em caso de necessidade.                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040AltOk:                                                 ³±±
±±³          ³    aCpos  : nomes dos campos que serao avaliados           ³±±
±±³          ³    aDados : dados dos campos de acpos                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040						            							  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040AltOk(aCpos,aDados,lButton,lAbatim,lProtesto,lCancProt)
Local aHead		:=	{}
Local lRet		:=	.T.
Local nMaxLenAnt	:=	10
Local nMaxLenAtu	:=	10
Local oSubst
Local aDefaults	:=	Nil
Local lPanelFin := IsPanelFin()

lSubstFI2	:=	.T.
If Type("aItemsFI2") != "A"
	aItemsFI2	:=	{}
Endif

Default lAbatim := .F.
Default lProtesto := .F.
Default lCancProt := .F.
Default aCPos	:=	aClone(aCposAlter)
Default lButton := .F.

If (!Empty(SE1->E1_IDCNAB) .And. Empty(aItemsFI2))
	aItemsFI2	:=	CarregaFI2(aCpos,aDados, lAbatim, lProtesto, lCancProt)
Endif
If lButton .Or. Len(aItemsFI2) > 0
	If lButton .Or. Ascan(aItemsFI2,{|x| Empty(x[1])}) > 0 // Pesquisa ocorrencias em branco
		aHead	:=	{}
		aAdd(aHead, {STR0071,"OCORR" ,"",Len(SEB->EB_REFBAN),0,"Vazio().Or.ExistCpo('SEB',SE1->E1_PORTADO+Pad(M->OCORR,Len(SEB->EB_REFBAN))+'E')",Nil,	"C","SEB",,,,,,,,}) // "Ocorrencia"
		If Len(aItemsFI2) > 0
			AAdd(aHead, {STR0072,"CAMPO" ,"",10,0,,Nil,"C",,,,,".F.",,,,}) // "Campo     "
		Else
			AAdd(aHead, {STR0073,"CAMPO" ,"",30,0,,Nil,"C",,,,,".F.",,,,}) // "Desc. Ocorrência"
		Endif
		AAdd(aHead, {STR0074,"VALANT","",nMaxLenAnt,0,,Nil,"C",,,,,".F.",,,,}) // "Valor Anterior"
		AAdd(aHead, {STR0075,"VALATU","",nMaxLenAtu,0,,Nil,"C",,,,,".F.",,,,}) // "Valor Atual"
		AAdd(aHead, {STR0076,"NOMCPO","",10,0,,Nil,"C",,,,,".F.",,,,}) // "Nome Campo "
		AAdd(aHead, {STR0077,"TIPCPO","",1 ,0,,Nil,"C",,,,,".F.",,,,}) // "Tipo Campo "
		AAdd(aHead, {" ","A","",1,0,,Nil,"C",,,,,".F.",,,,})//Dummy
		DEFINE FONT oBold NAME "Arial" SIZE 0, -13 BOLD

		DEFINE MSDIALOG oDlg FROM 88 ,22  TO 450,620 TITLE STR0078 Of oMainWnd PIXEL // "Cadastro de ocorrências CNAB"

		oPanel1:= TPanel():New(0,0,'',oDlg,, .T., .T.,, ,25,25,.T.,.T. )
		oPanel1:Align := CONTROL_ALIGN_TOP

		@ 001 ,002   TO 024 ,300 LABEL '' OF oPanel1 PIXEL
		@ 003 ,005   SAY STR0079 Of oPanel1 PIXEL SIZE 280 ,30 FONT oBold COLOR CLR_BLUE // "Informe a ocorrencia CNAB para cada modificao, deixe em branco para nao gerar CNAB para a alteracao."

		oGetDados := MsNewGetDados():New(45,3,120,296,GD_UPDATE,,,,,,Len(aItemsFI2),,,,oDlg,aHead,aItemsFI2)
		oGetDados:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

		oPanel2:= TPanel():New(0,0,'',oDlg,, .T., .T.,, ,13,13,.f.,.f. )
		IF !lPanelFin
			oPanel2:Align := CONTROL_ALIGN_BOTTOM
		Endif

		@ 001,008   CHECKBOX oSubst VAR lSubstFI2 PROMPT STR0080 Of oPanel2 PIXEL SIZE 200 ,10 FONT oBold COLOR CLR_BLUE // "Substitui ocorrencias iguais não enviadas?"

		If lPanelFin
			ACTIVATE MSDIALOG oDlg ON INIT (FaMyBar(oDlg,;
										{|| IIf(lRet	:=	MsgYesNo(STR0081,STR0082),(aItemsFI2:=aClone(oGetDados:aCols),oDlg:End()),Nil)},; // "Confirma ocorrências?"##"Confirmação"
										{||oDlg:End()} ),	oPanel2:Align := CONTROL_ALIGN_BOTTOM) CENTERED
		Else
			ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,;
										{|| IIf(lRet	:=	MsgYesNo(STR0081,STR0082),(aItemsFI2:=aClone(oGetDados:aCols),oDlg:End()),Nil)},; // "Confirma ocorrências?"##"Confirmação"
										{||oDlg:End()} )  CENTERED
		Endif
	Else
		lRet	:=	.T.
	Endif
Endif

Return lRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040GrvFI2  ³Autor  ³ Bruno Sobieski      ³ Data ³ 03/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Grava a tabela FI2 com as ocorrencias CNAB                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040GrvFI2: O SE1 deve estar poscionado, os dados que serao³±±
±±³          ³    gravados devem estar na variavel publica aItemsFI2.     ³±±
±±³          ³    aItemsFI2[x][1]: Ocorrencia                             ³±±
±±³          ³    aItemsFI2[x][2]: Titulo do campo (nao utilizado)        ³±±
±±³          ³    aItemsFI2[x][3]: Valor anterior                         ³±±
±±³          ³    aItemsFI2[x][4]: Novo valor                             ³±±
±±³          ³    aItemsFI2[x][5]: Nome do campo                          ³±±
±±³          ³    aItemsFI2[x][6]: Tipo do campo                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040						            							  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040GrvFI2()
Local nX	:=	1
Local aArea := GetArea()
Local lF040GRCOM  := ExistBlock("F040GRCOM")

lSubstFI2	:=	IIf(Type("lSubstFI2")=="L",lSubstFI2,.T.)


FI2->(DbSetOrder(1))
If Type('aItemsFI2') == "A" .And. !Empty(aItemsFI2)
	For nX:=1 To Len(aItemsFI2)
		If !Empty(aItemsFI2[nX][1])
			cChave	:=	xFilial("FI2")+"1"+SE1->(E1_NUMBOR+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)+aItemsFI2[nX][1]+"2"
			// Pesquisa pela ocorrencia nao gerada (FI2_GERADO = 2 - Ja esta na chave)
			If lSubstFI2 .And. FI2->(DbSeek(cChave))
				RecLock('FI2',.F.)
			Else
				RecLock('FI2',.T.)
			Endif
			Replace FI2_FILIAL 	WITH xFilial("FI2")
			Replace FI2_CARTEI 	WITH "1"
			Replace FI2_OCORR   	WITH aItemsFI2[nX][1]
			Replace FI2_GERADO  	WITH "2"
			Replace FI2_NUMBOR 	WITH SE1->E1_NUMBOR
			Replace FI2_PREFIX	WITH SE1->E1_PREFIXO
			Replace FI2_TITULO	WITH SE1->E1_NUM
			Replace FI2_PARCEL	WITH SE1->E1_PARCELA
			Replace FI2_TIPO  	WITH SE1->E1_TIPO
			Replace FI2_CODCLI	WITH SE1->E1_CLIENTE
			Replace FI2_LOJCLI	WITH SE1->E1_LOJA
			Replace FI2_DTOCOR	WITH dDataBase
			Replace FI2_DESCOC 	WITH Posicione('SEB',1,xFilial('SEB')+SE1->E1_PORTADO+Pad(FI2->FI2_OCORR,Len(SEB->EB_REFBAN))+"E","SEB->EB_DESCRI")

			Replace FI2_VALANT	WITH aItemsFI2[nX][3]
			Replace FI2_VALNOV	WITH aItemsFI2[nX][4]
			Replace FI2_CAMPO 	WITH aItemsFI2[nX][5]
			Replace FI2_TIPCPO	WITH aItemsFI2[nX][6]

			MsUnLock()

			IF lF040GRCOM
				ExecBlock( "F040GRCOM", .f., .f., { aItemsFI2 } )
		    Endif

		Endif
	Next nX
Endif
RestArea(aArea)


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³GetDadoFI2  ³Autor  ³ Bruno Sobieski      ³ Data ³ 03/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Le os conteudos  anterior e atual de uma linha do FI2, con-³±±
±±³          ³ vertendo-os para o tipo original.                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040						            							  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function GetDadoFI2()
Local xRet	:=	{Nil,Nil}

Do Case
Case  FI_TIPCPO	==	"C"
	xRet	:=	{FI2->FI2_VALANT,FI2->FI2_VALNOV}
Case  cTipo == "D"
	xRet	:=	{Ctod(Alltrim(FI2->FI2_VALANT)),Ctod(Alltrim(FI2->FI2_VALNOV))}
Case  cTipo == "N"
	xRet	:=	{Val(Alltrim(FI2->FI2_VALANT)),Val(Alltrim(FI2->FI2_VALNOV))}
EndCase

Return xRet
/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³CarregaFI2  ³Autor  ³ Bruno Sobieski      ³ Data ³ 03/02/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Retorna os dados do array aItemsFI2, colocando o tipo de   ³±±
±±³          ³ ocorrencia CNAB padrao para cada mudanza, definidos pelo   ³±±
±±³          ³ PE DEFFI2.                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ CarregaFI2:                                                ³±±
±±³          ³    aCpos  : nomes dos campos que serao avaliados           ³±±
±±³          ³    aDados : dados dos campos de acpos                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040/FINA060/TMS 		            							  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function CarregaFI2(aCpos,aDados, lAbatim, lProtesto, lCancProt)
Local lDefFI2		:=	ExistBLock('DEFFI2')
Local aItems 	:= {}
Local cOCORR
Local nMaxLenAnt	:=	10
Local nMaxLenAtu	:=	10
Local nX	:=	0
Local cDadoAnt	:=	""
Local cDadoAtu	:=	""
Local xValAnt	:=	""
Local cTipo
Local aDefaults
Local nPosDef	:=	0

Default lAbatim := .F.
Default lProtesto := .F.
Default lCancProt := .F.

If lDefFI2
	aDefaults := ExecBLock('DEFFI2',.F.,.F.,{"R", aCpos, aDados, lAbatim, lProtesto, lCancProt})
Endif
//Monta Interface para incluir as ocorrencias
For nX := 1 To Len(aCpos)
	If aDados	==	Nil
		xValAnt	:=	&("M->"+aCpos[nX])
	Else
		xValAnt	:=	aDados[nX]
	Endif
	If xValAnt <> SE1->(FieldGet(FieldPos(aCpos[nX]))) .Or. lAbatim  .Or. lProtesto .Or. lCancProt
		//SITCOB
		If aCpos[nX] == "E1_SITUACA"
			cDadoAnt	:=	SE1->(FieldGet(FieldPos(aCpos[nX])))
			cDadoAtu	:=	xValAnt
			If cDadoAtu == "0"
				cOCORR	:=	"02"
			Else
				cOCORR	:=	"01"
			Endif
			cTipo		:=	"C"
			Aadd(aItems,{cOCORR,RetTitle(aCpos[nX]),cDadoAnt,cDadoAtu,aCpos[nX],cTipo,' ',.F.})
		Else
			//Se foram definidos os defaults, verificar o valor para cada um
			If aDefaults <> Nil .And. (nPosDef	:=	Ascan(aDefaults,{|x| x[1] == aCpos[nX] })) > 0
				cOCORR	:=	Eval(aDefaults[nPosDef][2])
			Else
				cOCORR	:=	"  "
			Endif
			//Se foram definidos os defaults, e o campo nao tem default ou a condicao retorna falso,
			// nem inclui no array de ocorrencias
			If aDefaults == Nil .Or. (nPosDef > 0 .And. Eval(aDefaults[nPosDef][3]))
				If !lAbatim .And. !lProtesto .and. !lCancProt
					cTipo	:=	ValType(SE1->(FieldGet(FieldPos(aCpos[nX]))))
					Do Case
					Case  cTipo == "L"
						cDadoAnt	:=	AlltoChar(SE1->(FieldGet(FieldPos(aCpos[nX]))))
						cDadoAtu	:=	AlltoChar(xValAnt)
					Case  cTipo == "D"
						cDadoAnt	:=	DtoC(SE1->(FieldGet(FieldPos(aCpos[nX]))))
						cDadoAtu	:=	DtoC(xValAnt)
					Case  cTipo == "N"
						cDadoAnt	:=	TransForm(SE1->(FieldGet(FieldPos(aCpos[nX]))),PesqPict('SE1',aCpos[nX]))
						cDadoAtu	:=	TransForm(xValAnt,PesqPict('SE1',aCpos[nX]))
					OtherWise
						cDadoAnt	:=	SE1->(FieldGet(FieldPos(aCpos[nX])))
						cDadoAtu	:=	xValAnt
					EndCase
					Aadd(aItems,{cOCORR,RetTitle(aCpos[nX]),cDadoAnt,cDadoAtu,aCpos[nX],cTipo,' ',.F.})
				Else
					Aadd(aItems,{cOCORR,"","","","","",' ',.F.})
				Endif
			Endif
			nMaxLenAnt	:=	Max(nMaxLenAnt,Len(cDadoAnt))
			nMaxLenAtu	:=	Max(nMaxLenAtu,Len(cDadoAtu))
		Endif
	Endif
Next

Return aItems

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040CalcIr³ Autor ³ Claudio D. de Souza   ³ Data ³ 18/11/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Calculo do IRRF                 		 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040CalcIr(nBaseIrrf)										  		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040CalcIr(nBaseIrrf,aBases,lFinanceiro,nValor,lIrfRetAnt)

Local aArea			:= GetArea()
Local nTotTit		:= 0
Local nTotIrrf		:= 0
Local nTotRtIr		:= 0
Local lVRetIrf		:= .T.	//Controle de retencao de valores pendentes (<
Local lAplMinIr		:= .F.
Local cAglImPJ		:= SuperGetMv("MV_AGLIMPJ",.T.,"1")
Local aFilial		:= {}
Local aCliFor		:= {}
Local cQuery		:= ""
Local nLoop			:= 0
Local lPLS		    := FunName() $ "PLSA627,PLSA628"
Local xMinRetIR 	:= 0
//Controla IRPJ na baixa
Local lIrPjBxCr		:= FIrPjBxCr()
Local lRaRtImp      := lFinImp .And.FRaRtImp()
//639.04 Base Impostos diferenciada
Local lBaseImp	 	:= F040BSIMP(2)

//--- Tratamento Gestao Corporativa
Local cFilFwSA1 := FwFilial("SA1")
Local cFilFwSE1 := FwFilial("SE1")
Local cFilFwSED := FwFilial("SED")

Local cAcmIrrf 	:= SuperGetMv("MV_ACMIRCR",.T.,"1")  //1 = Acumula 2= Não acumula o imposto IRRF.
Local nMinIrrf   := SuperGetMV("MV_VLRETIR", .F., 10)

Local lDelTrbIR	:= .T.
Local cMotBxPLS := SuperGetMv("MV_PLMOTBC",.T.,"CAN")
Local cSepNeg   := If("|"$MV_CRNEG,"|",",")
Local cSepProv  := If("|"$MVPROVIS,"|",",")
Local cSepRec   := If("|"$MVRECANT,"|",",")
Local cArqTmp	:= ""
Local cDbMs		:= UPPER(TcGetDb())

Local nAliqIRRF	:= 0

DEFAULT nValor := 0
DEFAULT lFinanceiro := .F.   //Indica que o calculo foi chamado pelo modulo Financeiro
DEFAULT lIrfRetAnt := .F.	//Controle de retencao anterior no mesmo periodo

nRecIRRF	:= 0

// Verifica se o CLIENTE trata o valor minimo de retencao.
// 1- Não considera 	 2- Considera o parâmetro MV_VLRETIR
If cPaisLoc == "BRA" .and. SA1->A1_MINIRF == "2"
	lAplMinIR := .T.
Endif

If !lFinanceiro
	RegToMemory("SE1",.F.,.F.)
	If lVRetIrf
		RecLock("SE1")
		Replace SE1->E1_VRETIRF With SE1->E1_IRRF
		MsUnlock()
		SE1->(dbCommit())
	Endif
Endif

// Prioridade de Acesso à alíquota de IRRF:
// 1 - Cadastro Cliente;
// 2 - Cadastro da Natureza Associada ao título;
// 3 - Parâmetro do Sistema MV_ALIQIRF
If		!Empty( nAliqIRRF := Posicione('SA1',1,XFilial('SA1') + M->E1_CLIENTE + M->E1_LOJA,'A1_ALIQIR') )
ElseIf	!Empty( nAliqIRRF := SED->ED_PERCIRF )
Else
		nAliqIRRF := GetMV("MV_ALIQIRF")
EndIf

IF (!lPLS .And. lFinanceiro .and. (SA1->A1_PESSOA != "J" .Or. (aBases != NIL))) .Or.;
   (lPLS .And. lFinanceiro .and. SA1->A1_PESSOA != "J")
	If ! GetNewPar("MV_RNDIRRF",.F.)
		nValor := NoRound(((nBaseIrrf*Iif(AllTrim(Str(m->e1_moeda,2))$"01",1,IIF(M->E1_TXMOEDA <= 0, RecMoeda(m->e1_emissao,m->e1_moeda),M->E1_TXMOEDA))) * (nAliqIRRF/100)),2)
	Else
		nValor := Round(((nBaseIrrf*Iif(AllTrim(Str(m->e1_moeda,2))$"01",1,IIF(M->E1_TXMOEDA <= 0, RecMoeda(m->e1_emissao,m->e1_moeda),M->E1_TXMOEDA))) * (nAliqIRRF/100)),2)
	Endif
	nVCalIRF := nValor
	nBCalIRF := nBaseIrrf
Else
	// Pessoa juridica totaliza os titulos emitidos no dia para calculo do imposto
	If lVRetIrf
		//Verifico a combinacao de filiais (SM0) e lojas de fornecedores a serem considerados
		//na montagem da base do IRRF
		If cAglImPJ != "1"
			aRet := FLOJASIRRF("1")
			aFilial := aClone(aRet[1])
			aCliFor := aClone(aRet[2])
			cArqTMP := aRet[3]
		Endif

		cQuery := "SELECT DISTINCT E1_VALOR TotTit, E1_VRETIRF VRetIrf, E1_IRRF TotIrrf, "
		cQuery += "E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_CLIENTE,E1_LOJA, "
		cQuery += "E1_EMISSAO,E1_NATUREZ "

	Else
		cQuery := "SELECT DISTINCT E1_VALOR TotTit,E1_IRRF TotIrrf,"
		cQuery += "E1_FILIAL,E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_CLIENTE,E1_LOJA, "
		cQuery += "E1_EMISSAO,E1_NATUREZ "
	Endif

	//639.04 Base Impostos diferenciada
	IF lBaseImp
		cQuery += ",E1_BASEIRF TotBaseIrf "
	Endif

	If cPaisLoc == "BRA"
		//SED->ED_RECIRRF - Natureza (Indica como será feito o recolhimento do IRRF)
		cQuery += ",SED.ED_RECIRRF RECIRRF "
	EndIf

	cQuery += "FROM " + RetSQLname("SE1") + " SE1, "
	cQuery +=                    RetSQLname("SED") + " SED "
	cQuery += " WHERE "

	If lVretIrf
		//Se verifica base apenas na filial corrente e fornecedor corrente
		If cAglImPJ == "1" .Or. Empty( cFilFwSE1 )
			cQuery += "SE1.E1_FILIAL = '" + xFilial("SE1") + "' AND "

			If cAglImPJ == "1" 				//Verificar apenas fornecedor corrente
				cQuery += "SE1.E1_CLIENTE = '"+ SA1->A1_COD +"' AND "
				cQuery += "SE1.E1_LOJA = '"+ SA1->A1_LOJA +"' AND "
			Else									//Verificar determinados fornecedores (raiz do CNPJ)
				If "MSSQL" $ cDbMs
					cQuery += " (E1_CLIENTE+E1_LOJA IN (SELECT CODIGO+LOJA FROM "+cArqTMP+")) AND "
				Else
					cQuery += " (E1_CLIENTE||E1_LOJA IN (SELECT CODIGO||LOJA FROM "+cArqTMP+")) AND "
				Endif

			Endif

		ElseIf Len(aFilial) > 0  //Mais de uma filial SM0

			If Empty( cFilFwSA1 )  //Se cadastro de Clientes compartilhado
				cQuery += "SE1.E1_FILIAL IN ( "
				For nLoop := 1 to Len(aFilial)
					cQuery += "'"   + aFilial[nLoop] + "',"
				Next
				//Retiro a ultima virgula
				cQuery := Left( cQuery, Len( cQuery ) - 1 )
				cQuery += ") AND "

				//Verificar determinados fornecedores (raiz do CNPJ)
				If "MSSQL" $ cDbMs
					cQuery += " (E1_CLIENTE+E1_LOJA IN (SELECT CODIGO+LOJA FROM "+cArqTMP+")) AND "
				Else
					cQuery += " (E1_CLIENTE||E1_LOJA IN (SELECT CODIGO||LOJA FROM "+cArqTMP+")) AND "
				Endif
			Else							//Se cadastro de Clientes EXCLUSIVO
				If "MSSQL" $ cDbMs
					cQuery += " (E1_FILIAL+E1_CLIENTE+E1_LOJA IN (SELECT FILIALX+CODIGO+LOJA FROM "+cArqTMP+")) AND "
				Else
					cQuery += " (E1_FILIAL||E1_CLIENTE||E1_LOJA IN (SELECT FILIALX||CODIGO||LOJA FROM "+cArqTMP+")) AND "
				Endif
			Endif
		Endif
	Else
		cQuery += "SE1.E1_FILIAL = '"+ xFilial("SE1") + "' AND "
		cQuery += "SE1.E1_CLIENTE = '"+ SA1->A1_COD +"' AND "
		cQuery += "SE1.E1_LOJA = '"+ SA1->A1_LOJA +"' AND "
	Endif
	cQuery += "SE1.E1_EMISSAO  = '" + Dtos(M->E1_EMISSAO) + "' AND " // De acordo com JIRA, dispensa e cumulatividade de IR PJ deverá ser ao dia e nao ao mes.
	cQuery += "SE1.E1_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " AND "
	cQuery += "SE1.E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepNeg)  + " AND "
	cQuery += "SE1.E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv) + " AND "
	If !lRaRtImp
		cQuery += "SE1.E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRec)  + " AND "
	EndIf
	cQuery += "SE1.D_E_L_E_T_ = ' ' AND "

	//Verifico a filial do SED
	If cAglImPJ == "1" .Or. Empty( cFilFwSED ) .Or. !lVRetIrf
		cQuery += "SED.ED_FILIAL = '"+ xFilial("SED") + "' AND "
	ElseIf Len(aFilial) > 0
		cQuery += "SED.ED_FILIAL IN ( "
		For nLoop := 1 to Len(aFilial)
			cQuery += "'"  + aFilial[nLoop] + "',"
		Next
		//Retiro a ultima virgula
		cQuery := Left( cQuery, Len( cQuery ) - 1 )
		cQuery += ") AND "

	Endif
	cQuery += "SE1.E1_NATUREZ = SED.ED_CODIGO AND "
	cQuery += "SED.ED_CALCIRF = 'S' AND "

	//TRATAMENTO PARA TITULOS BAIXADOS POR CANCELAMENTO DE FATURA
	//APLICAVEL SOMENTE EM TOP PARA O MODULO DE GESTAO ADVOCATICIA (SIGAGAV)
	//OU MODULO GESTÃO DE PLANOS DE SAUDE (SIGAPLS)
	//OU PRÉ FATURAMENTO DE SERVIÇOS (SIGAPFS)
	If nModulo == 65 .or. lPls .Or. nModulo = 77
		cQuery += "NOT EXISTS (SELECT E5_FILIAL "
		cQuery += "					FROM " + RetSqlName("SE5") + " SE5 "
		cQuery += "					WHERE SE5.E5_FILIAL = '" + xFilial("SE5") + "' "
		cQuery += "					AND SE5.E5_TIPO = SE1.E1_TIPO "
		cQuery += "					AND SE5.E5_PREFIXO = SE1.E1_PREFIXO "
		cQuery += "					AND SE5.E5_NUMERO = SE1.E1_NUM "
		cQuery += "					AND SE5.E5_PARCELA = SE1.E1_PARCELA  "
		cQuery += "					AND SE5.E5_CLIFOR = SE1.E1_CLIENTE "
		cQuery += "					AND SE5.E5_LOJA = SE1.E1_LOJA "
		If lPls
			cQuery += "					AND SE5.E5_MOTBX IN ('"+Alltrim(cMotBxPLS)+"','CNF') "
		Else
			cQuery += "					AND SE5.E5_MOTBX = 'CNF' "
		EndIf
		cQuery += "					AND SE5.D_E_L_E_T_ = ' ') AND "
	Endif
	//FIM DO TRATAMENTO PARA TITULOS BAIXADOS POR CANCELAMENTO DE FATURA
	cQuery += "SED.D_E_L_E_T_ = ' ' "
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRBIRF", .F., .T.)
	TCSetField('TRBIRF', "TOTTIT", "N",17,2)
	TCSetField('TRBIRF', "TOTIRRF", "N",17,2)
	If lVRetIrf
		TCSetField('TRBIRF', "VRETIRF", "N",17,2)
	Endif

	//639.04 Base Impostos diferenciada
	IF lBaseImp
		TCSetField('TRBIRF', "TOTBASEIRF", "N",17,2)
	Endif

	dbSelectArea("TRBIRF")
	While !(TRBIRF->(Eof()))

		// Se alteracao e a chave do titulo em memoria eh a mesma da query, desconsidera o titulo para evitar duplicidade na base de irrf
		If 	lFinanceiro .And. ALTERA .And. ;
			xFilial("SE1") + M->( E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA ) == ;
			TRBIRF->( E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA )

			TRBIRF->( dbSkip() )
			Loop

		EndIf

		//639.04 Base Impostos diferenciada
		IF lBaseImp .and. TRBIRF->TOTBASEIRF > 0
			nTotTit	+= TRBIRF->TOTBASEIRF
		Else
			nTotTit	+= TRBIRF->TotTit
		Endif

		nTotIrrf	+= If(lIrPjBxCr,TRBIRF->VRETIRF,TRBIRF->TotIrrf)

		If !lPls
			//639.04 Base Impostos diferenciada
			IF lBaseImp .and. m->e1_baseirf > 0
				nBaseIrrf := m->e1_baseirf
			Else
				If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|PAD|PAN|PAR|PER|POR|PTG|SAL|TRI|URU|VEN" .and. SED->ED_BASEIRF > 0
					nBaseIrrf := m->e1_valor * (SED->ED_BASEIRF/100)
				ElseIf cPaisLoc $ "BRA" .and. lFinanceiro .and. m->e1_baseirf > 0
					nBaseIrrf := m->e1_valor
				EndIf
			Endif
		EndIf

		nBCalIRF := nBaseIrrf

		If lVRetIrf
			nTotRtIr += TRBIRF->VRetIrf
			If cPaisLoc == "BRA" .And. TRBIRF->RECIRRF == "2"
				nRecIRRF += TRBIRF->VRetIrf
			EndIf
		Else
			nBaseIrrf += nTotTit
		Endif

		dbSkip()
	Enddo

	dbCloseArea()

	//Fecha arquivo temporario e exclui do banco
	If lVRetIrf .and. cAglImPJ != "1" .and. lDelTrbIR .and. (UPPER(Alltrim(TCGetDb()))!="POSTGRES")
		If InTransact()
			StartJob( "DELTRBIR" , GetEnvServer() , .T. , SM0->M0_CODIGO, FWGETCODFILIAL ,.T.,ThreadID(),cArqTmp)
		Else
			DELTRBIR(SM0->M0_CODIGO, FWGETCODFILIAL ,.F.,0,cArqTmp)
		Endif
	Endif

	dbSelectArea("SE1")

	M->E1_BASEIRF := nBaseIrrf
	nBCalIRF 		:= M->E1_BASEIRF

	//Calculo o IRRF devido
	If ! GetNewPar("MV_RNDIRRF",.F.)
		//Edu
		//nValor := NoRound(((nBaseIrrf*Iif(AllTrim(Str(m->e1_moeda,2))$"01",1,RecMoeda(m->e1_emissao,m->e1_moeda))) * IIF(SED->ED_PERCIRF>0,SED->ED_PERCIRF,GetMV("MV_ALIQIRF"))/100),2)
		nValor := NoRound(xMoeda(M->E1_BASEIRF,M->E1_MOEDA,1,M->E1_EMISSAO,3,M->E1_TXMOEDA) * (nAliqIRRF/100),2)
	Else
		//Edu
		//nValor := Round(((nBaseIrrf*Iif(AllTrim(Str(m->e1_moeda,2))$"01",1,RecMoeda(m->e1_emissao,m->e1_moeda))) * IIF(SED->ED_PERCIRF>0,SED->ED_PERCIRF,GetMV("MV_ALIQIRF"))/100),2)
		nValor := Round(xMoeda(M->E1_BASEIRF,M->E1_MOEDA,1,M->E1_EMISSAO,3,M->E1_TXMOEDA) * (nAliqIRRF/100),2)
	Endif

	nVCalIRF := nValor
	//Recolhimento do IRRF - Emitente
	If cPaisLoc == "BRA" .And. ( SED->ED_RECIRRF == "2" .OR. ( SA1->A1_RECIRRF == "2" .AND. (SED->ED_RECIRRF == "3" .OR. SED->ED_RECIRRF == " ") ) )
		nRecIRRF += nValor
	EndIf

	RestArea(aArea)

	//Se verifico a retencao atraves de campo
	//Guardo o valor que deveria ser retido
	//Atualizo o valor pendente de retencao mais o IRRF do titulo
	If lVRetIrf
		If lFinanceiro
			M->E1_VRETIRF	:= nValor
		Else
			RecLock("SE1", .F.)
				SE1->E1_VRETIRF := nValor
			MsUnlock()
		Endif
		If 	cAcmIrrf ==	"1"
			nValor += nTotRtIr - nTotIrrf
		EndIf
	Else
		If 	cAcmIrrf ==	"1"
			nValor -= nTotIrrf  //Diminuo do valor calculado, o IRRF já retido
		EndIf
	Endif

	//Controle de retencao anterior no mesmo periodo
	lIrfRetAnt := IIF(nTotIrrf > GetMv("MV_VLRETIR"), .T., .F.)

	//Ponto de entrada para tratamento do valor minimo para IRRF.
	If ExistBlock("F040MIRF")
		xMinRetIR := 0
		xMinRetIR := Execblock("F040MIRF",.F.,.F.,{SA2->A2_COD,SA2->A2_LOJA})
		nMinIrrf  := If(ValType(xMinRetIR)=="N",xMinRetIR,nMinIrrf )
	EndIf

	If (!F040UsaMp232() .and. lAplMinIr .And. (nValor <= nMinIrrf .and. !lIrfRetAnt).AND. !lIrPjBxCr) .OR. nValor < 0
		nValor := 0
		nRecIRRF := 0
	Endif

	If cAcmIrrf == "2" .And. lAplMinIr .And. nValor <= nMinIrrf
		nValor := 0
		nRecIRRF := 0
		M->E1_VRETIRF := 0
	EndIf

Endif

// Titulos Provisorios ou Antecipados nao geram IR
If m->e1_tipo $ MVPROVIS+"/"+MVRECANT+"/"+MV_CRNEG+"/"+MVABATIM
	If !(lRaRtImp .and. lIrPjBxCr .and. m->e1_tipo == MVRECANT)
		nValor := 0
		nRecIRRF := 0
		M->E1_VRETIRF	:= 0
	EndIf
EndIf

nVRetIRF := nValor

RestArea(aArea)

Return (nValor)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³F040ActImp  ³ Autor ³Mauricio Pequim Jr.. ³ Data ³ 11.11.05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Acerta valores dos impostos na compensacao CR com NCC.     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA040                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Function F040ActImp(nRecSE1P,nValorReal,lExclusao,nValPis,nValCof,nValCsl)

Local cKeySe1 := ""
Local aArea  := GetArea()
Local lImpComp := SuperGetMv("MV_IMPCMP",,"2") == "1"
Local nProporcao := 0
Local lInclusao := .F.

Default lExclusao := .F.
Default nValPis := 0
Default nValCof := 0
Default nValCsl := 0

If lImpComp
	DbSelectArea("SE1")
	dbSetOrder(2)
	dbGoto(nRecSe1P)  //posiciono no titulo pai no SE1

	nProporcao := nValorReal / (SE1->E1_SALDO)

	cKeySE1 := SE1->(E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA)
	If nProporcao != 1

 		If !lExclusao .and. nValPis + nValCof == 0  //inclusao
			nValPis := (SE1->E1_PIS * nProporcao)
			nValCof := (SE1->E1_COFINS * nProporcao)
			nValCsl := (SE1->E1_CSLL * nProporcao)
			lInclusao := .T.
		Endif

		If ABS(nValPis+nValCof+nValCsl) > 0
			//Acerto o valor dos impostos no titulo principal
			RecLock("SE1")
			If lExclusao
				SE1->E1_PIS += nValPis
				SE1->E1_COFINS += nValCof
				SE1->E1_CSLL += nValCsl
			Else
				SE1->E1_PIS -= nValPis
				SE1->E1_COFINS -= nValCof
				SE1->E1_CSLL -= nValCsl
			Endif
			MsUnLock()

			//Acerto os valores dos titulos de impostos
			//Pis
			If MsSeek(xFilial("SE1")+cKeySE1+MVPIABT)
				If lExclusao
					RecLock("SE1")
					SE1->E1_VALOR += nValPis
					SE1->E1_SALDO := SE1->E1_VALOR
					SE1->E1_VLCRUZ :=SE1->E1_VALOR
					MsUnlock()
				Else
					RecLock("SE1")
					SE1->E1_VALOR -= nValPis
					SE1->E1_SALDO := SE1->E1_VALOR
					SE1->E1_VLCRUZ := SE1->E1_VALOR
					MsUnlock()
				Endif
			Endif

			//Cofins
			If MsSeek(xFilial("SE1")+cKeySE1+MVCFABT)
				If lExclusao
					RecLock("SE1")
					SE1->E1_VALOR += nValCof
					SE1->E1_SALDO := SE1->E1_VALOR
					SE1->E1_VLCRUZ :=SE1->E1_VALOR
					MsUnlock()
				Else
					RecLock("SE1")
					SE1->E1_VALOR -= nValCof
					SE1->E1_SALDO := SE1->E1_VALOR
					SE1->E1_VLCRUZ := SE1->E1_VALOR
					MsUnlock()
				Endif
			Endif

			//CSLL
			If MsSeek(xFilial("SE1")+cKeySE1+MVCSABT)
				If lExclusao
					RecLock("SE1")
					SE1->E1_VALOR += nValCsl
					SE1->E1_SALDO := SE1->E1_VALOR
					SE1->E1_VLCRUZ :=SE1->E1_VALOR
					MsUnlock()
				Else
					RecLock("SE1")
					SE1->E1_VALOR -= nValCsl
					SE1->E1_SALDO := SE1->E1_VALOR
					SE1->E1_VLCRUZ := SE1->E1_VALOR
					MsUnlock()
				Endif
			Endif

		Endif
	Endif
Endif
RestArea(aArea)

If SE1->E1_TIPO $ MVABATIM
	RecLock("SE1")
	SE1->E1_PIS := nValPis
	SE1->E1_COFINS := nValCof
	SE1->E1_CSLL := nValCsl
	MsUnlock()
Endif

Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³Fa050bAval³ Autor ³ Claudio Donizete      ³ Data ³ 27.03.06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Avalia se o titulo pode ser seleciona na substituicao de    ³±±
±±³          ³titulos provisorios                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³             		    												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA050           													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040bAval(cMarca,oValor,oQtdtit,nValorS,nQtdTit,oMark,nMoedSubs,aChaveLbn)
Local lRet 		:= .T.
Local cChaveLbn

cChaveLbn := "SUBS" + xFilial("SE1")+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
// Verifica se o registro nao esta sendo utilizado em outro terminal
//-- Parametros da Funcao LockByName() :
//   1o - Nome da Trava
//   2o - usa informacoes da Empresa na chave
//   3o - usa informacoes da Filial na chave
If LockByName(cChaveLbn,.T.,.F.)
	Fa040Inverte(cMarca,oValor,oQtdtit,@nValorS,@nQtdTit,@oMark,nMoedSubs,aChaveLbn,cChaveLbn,.F.) // Marca o registro e trava
	lRet := .T.
Else
	IW_MsgBox(STR0085,STR0064,"STOP") // "Este titulo está sendo utilizado em outro terminal, não pode ser utilizado para substituição" ## Atenção
	lRet := .F.
Endif
oMark:oBrowse:Refresh(.t.)
Return lRet


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao	 ³F040PcoLan³ Autor ³ Gustavo Henrique      ³ Data ³ 09.10.06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³Executa validacaso de saldos do PCO                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040PcoLan()		    									  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040           										  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040PcoLan()
Local lRet	:=	.T.
If !PcoVldLan("000001",IIF(M->E1_TIPO$MVRECANT,"02","01"),"FINA040")
	lRet	:=	.F.
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Grava os lancamentos nas contas orcamentarias SIGAPCO    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SE1->E1_TIPO $ MVRECANT
		PcoDetLan("000001","02","FINA040")
	Else
		PcoDetLan("000001","01","FINA040")
	EndIf
Endif

Return lRet


/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³MenuDef   ³ Autor ³ Ana Paula N. Silva     ³ Data ³17/11/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Utilizacao de menu Funcional                               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Array com opcoes da rotina.                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Parametros do array a Rotina:                               ³±±
±±³          ³1. Nome a aparecer no cabecalho                             ³±±
±±³          ³2. Nome da Rotina associada                                 ³±±
±±³          ³3. Reservado                                                ³±±
±±³          ³4. Tipo de Transa‡„o a ser efetuada:                        ³±±
±±³          ³		1 - Pesquisa e Posiciona em um Banco de Dados       	  ³±±
±±³          ³    2 - Simplesmente Mostra os Campos                       ³±±
±±³          ³    3 - Inclui registros no Bancos de Dados                 ³±±
±±³          ³    4 - Altera o registro corrente                          ³±±
±±³          ³    5 - Remove o registro corrente do Banco de Dados        ³±±
±±³          ³5. Nivel de acesso                                          ³±±
±±³          ³6. Habilita Menu Funcional                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/

Static Function MenuDef()
Local aRotina := {}
Local aRotinaNew
Local lRastro	:= .F.
Local lIntPFS    := SuperGetMV("MV_JURXFIN",,.F.) //Integração SIGAPFS

//Processo de rastreamento financeiro
//disponivel apenas para ambiente TOTVSDBACCESS / TOPCONNECT
lRastro := .T.

aAdd( aRotina,	{ STR0001, "AxPesqui" , 0 , 1,,.F. }) //"Pesquisar"

If Alltrim(Upper(Funname())) == "ACAA690"
	aAdd( aRotina,	{ STR0002 ,"FA280Visua", 0 , 2}) // "Visualizar"
	aAdd( aRotina,	{ STR0004 ,"FA040Alter", 0 , 4}) // "Alterar"
	aAdd( aRotina,	{ STR0005 ,"FA040Delet", 0 , 5}) // "Excluir"
	aAdd( aRotina,	{ STR0006 ,"FA040Subst", 0 , 3}) // "Substituir"
	aAdd( aRotina,	{ STR0065 ,"AC520BRW"  , 0 , 6})  // "Posicao Financeira"
	aAdd( aRotina,	{ STR0141 ,"MSDOCUMENT"  , 0 , 4}) //"Conhecimento"
	aAdd( aRotina,	{ STR0155 ,"CTBC662"  , 0 , 7}) //"Tracker Contábil"
	aAdd( aRotina,	{ STR0046 ,"FA040Legenda", 0 , 6, ,.F.})// "Legenda"
	aAdd( aRotina,	{ STR0192 ,"FinaCsLog", 0 , 8}) // "Histórico do Título"
Else
	aAdd( aRotina,	{ STR0002 ,"FA280Visua", 0 , 2}) // "Visualizar"
	aAdd( aRotina,	{ STR0003 ,"FA040Inclu", 0 , 3}) // "Incluir"
	aAdd( aRotina,	{ STR0004 ,"FA040Alter", 0 , 4}) // "Alterar"
	aAdd( aRotina,	{ STR0005 ,"FA040Delet", 0 , 5}) // "Excluir"
	aAdd( aRotina,	{ STR0006 ,"FA040Subst", 0 , 6}) // "Substituir"
	If lRastro
		aAdd( aRotina,	{ STR0105 ,"FaCanDsd", 0 , 5})	//"Canc.Desdobr."
	Endif
	aAdd( aRotina,	{ STR0141 ,"MSDOCUMENT"  , 0 , 4}) //"Conhecimento"
	aAdd( aRotina,	{ STR0155 ,"CTBC662"  , 0 , 7}) //"Tracker Contábil"
	aAdd( aRotina,	{ STR0046 ,"FA040Legenda", 0 , 6, ,.F.})// "Legenda"
	aAdd( aRotina,	{ STR0192 ,"FinaCsLog", 0 , 8}) // "Histórico do Título"
		//Rateio Multinatureza
	If __lF040CMNT .and. MV_MULNATR
		aAdd( aRotina,	{ STR0210 ,"F040CMNT()", 0 , 2})	//"Consulta Rateio Multi Naturezas - Emissão"
	Endif

EndIf

If lIntPFS
	If ExistFunc("JurDocVinc")
		aAdd( aRotina, { STR0212, "JurDocVinc()"  , 0, 2} )    // "Docs Relacionados - Fatura SIGAPFS"
	EndIf

	If ExistFunc("JurBoleto") .And. ExistFunc("JurBolFat") .And. ExistFunc("U_FINX999")
		aAdd( aRotina,	{ STR0217 ,"JurBolFat(SE1->(Recno()))", 0 , 6}) // "Boleto - Fatura SIGAPFS"
	EndIf
EndIf

If __lFINA040VA .And. __lExisFKD
	aAdd( aRotina, { STR0199, "FINA040VA", 0, 4 } ) //"Valores Acessórios"
EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Ponto de entrada para inclusão de novos itens no menu aRotina³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If ExistBlock("FI040ROT")
	aRotinaNew := ExecBlock("FI040ROT",.F.,.F.,aRotina)
	If (ValType(aRotinaNew) == "A")
		aRotina := aClone(aRotinaNew)
	EndIf
EndIf

Return(aRotina)

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³F040SelPR  ³ Autor ³ Mauricio Pequim Jr   ³ Data ³ 04.04.08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Markbrowse da Substituição							              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040SelPR(oDlg,cOutMoeda,nValorS,nQtdTit,cMarca,			  ³±±
±±³			 ³					 oValor,oQtdTit,nMoedSubs)							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 = Objeto onde se encaixara a MarkBrowse				  ³±±
±±³			 ³ ExpC1 = Tratamento aplicado a outras moedas (<>1)			  ³±±
±±³			 ³ ExpN1 = Valor dos titulos selecionados							  ³±±
±±³			 ³ ExpN2 = Quantidade de titulos selecionados					  ³±±
±±³			 ³ ExpC2 = Marca (GetMark())				 							  ³±±
±±³			 ³ ExpO2 = Objeto Valor dos titulos selecionados p/ refresh	  ³±±
±±³			 ³ ExpO3 = Objeto Quantidade de titulos selecionados p/refresh³±±
±±³			 ³ ExpN3 = Moeda da Substituicao             					  ³±±
±±³			 ³ ExpO4 = Objeto Painel superior a ser desabilitado			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA040                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040SelPR(oDlg,cOutMoeda,nValorS,nQtdTit,cMarca,oValor,oQtdTit,nMoedSubs,oPanel)

Local aChaveLbn	:= {}
Local aSize := {}
Local lRet := .T.
Local lInverte := .F.

lRet := F040FilProv( cCodigo, cLoja, cOutMoeda, nMoedSubs )

If lRet
	fa040DesMarca(aChaveLbn)
	aCampos := {}
	AADD(aCampos,{"E1_OK","","  ",""})
	dbSelectArea("SX3")
	dbSetOrder(1)
	dbSeek ("SE1")
	While !EOF() .And. (x3_arquivo == "SE1")
		IF  (X3USO(x3_usado)  .AND. cNivel >= x3_nivel .and. SX3->X3_context # "V") .Or.;
			(X3_PROPRI == "U" .AND. X3_CONTEXT!="V" .AND. X3_TIPO<>'M')
			AADD(aCampos,{X3_CAMPO,"",X3Titulo(),X3_PICTURE})
		Endif
		dbSkip()
	Enddo
	AADD(aCampos,{{ || F040ConVal(nMoedSubs)},"",STR0032,"@E 999,999,999.99"})
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Mostra a tela de Titulos Provisorios - WINDOWS					  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	dbSelectArea("__SUBS")
	dbGoTop()
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Faz o calculo automatico de dimensoes de objetos     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	oMark:=MsSelect():New("__SUBS","E1_OK","!E1_SALDO",aCampos,@lInverte,@cMarca,{35,oDlg:nLeft,oDlg:nBottom,oDlg:nRight})
	oMark:oBrowse:lhasMark := .t.
	oMark:oBrowse:lCanAllmark := .t.
	oMark:oBrowse:bAllMark := { || FA040Inverte(cMarca,oValor,oQtdtit,@nValorS,@nQtdTit,@oMark,nMoedSubs,aChaveLbn,,.T.) }
	oMark:bMark := {||Fa040Exibe(@nValorS,@nQtdTit,cMarca,&(IndexKey()),oValor,oQtdTit,nMoedSubs)}
	oMark:bAval	:= {||Fa040bAval(cMarca,oValor,oQtdtit,@nValorS,@nQtdTit,@oMark,nMoedSubs,aChaveLbn)}
	oMark:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT

	CursorArrow()

	oPanel:Disable()
Endif

Return lRet


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³F040SubOk  ³ Autor ³ Mauricio Pequim Jr   ³ Data ³ 04.04.08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Validacao do botao OK na tela de substituição              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040SubOk(ExpN1,ExpN2,ExpO1)	 									  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpN1 = Controle de opcao do usuario							  ³±±
±±³			 ³ ExpN2 = Valor dos titulos selecionados							  ³±±
±±³			 ³ ExpO1 = Objeto onde esta o botao		 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA040                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040SubOk(nOpca,nValorS,oDlg)
Local lRet := .F.

If nValorS > 0
	nOpca := 1
	oDlg:End()
	lRet := .T.
Else
	nOpca := 2
Endif

Return lRet


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³FinA040T   ³ Autor ³ Marcelo Celi Marques ³ Data ³ 04.04.08 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada semi-automatica utilizado pelo gestor financeiro   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ FINA040                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FinA040T(aParam)

	ReCreateBrow("SE1",FinWindow)
	cRotinaExec := "FINA040"
	FinA040(,aParam[1])
	ReCreateBrow("SE1", FinWindow, , .T.)

	dbSelectArea("SE1")

	INCLUI := .F.
	ALTERA := .F.

Return .T.

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040GrvSE5³ Autor ³ Mauricio Pequim Jr	  ³ Data ³ 20/04/09 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Gravacao de registros do SE5 na inclusao C.Receber			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040GrvSE5()		 													  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpN1 = Controle de operacao										  ³±±
±±³			 ³ ExpL2 = Controle de desdobramento								  ³±±
±±³			 ³ ExpC3 = Banco para movimento de inclusao do RA				  ³±±
±±³			 ³ ExpC4 = Agencia para movimento de inclusao do RA			  ³±±
±±³			 ³ ExpC5 = Conta Corrente para movimento de inclusao do RA	  ³±±
±±³			 ³ ExpN6 = Recno do Registro											  ³±±
±±³			 ³ ExpL7 = Controle de Pendencia Contabil                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040GrvSE5(nOpc,lDesdobr,cBcoAdt,cAgeAdt,cCtaAdt,nRecSE1,lPendCtb)

Local nNextRec		:= 0
Local aAreaGrv		:= GetArea()
Local nX			:= 0
Local lRastro		:= FVerRstFin()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Parametro que permite ao usuario utilizar o desdobramento³
//³da maneira anterior ao implementado com o rastreamento.  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Local lNRastDSD		:= SuperGetMV("MV_NRASDSD",.T.,.F.)
//Salvo o Recno do SE1
Local nSalvRec		:= SE1->(Recno())
Local nTamSeq		:= TamSX3("E5_SEQ")[1]
Local cSequencia 	:= Replicate("0",nTamSeq)
//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr		:= FPccBxCr()
//Controla IRPJ na baixa
Local lIrPjBxCr		:= FIrPjBxCr()
//Verifica se retem imposots do RA
Local lRaRtImp      := lFinImp .And.FRaRtImp()
Local nRecSE5		:= 0
Local nRecSFQ		:= 0
Local ni 			:= 0
Local lTemSfq 		:= .F.
Local lExcRetentor 	:= .F.
Local nValMinRet 	:= GetNewPar("MV_VL10925",5000)

//Nova estrutura SE5
Local oModel
Local oSubFK1
Local oSubFK5
Local oSubFKA
Local oSubFK3
Local oSubFK4
Local cLog := ""
Local cOrig:=Funname()
Local cIdDoc:= ""
Local cIdMov:= FWUUIDV4()
Local cIdFK4:= ""
Local cCamposE5:=""
Local aImpostos:= {}
Local nPisRet := 0
Local nCofRet := 0
Local nCslRet := 0
Local cChaveTit:= ""
Local aRarTimp		:= Array(6)
Local n040Pis		:= 0
Local n040Cof		:= 0
Local n040Csl		:= 0
Local lRetPCC		:= .F.
Local lEstPenCtb	:= .F.

DEFAULT lDesdobr	:= .F.
DEFAULT cBcoAdt	:= ""
DEFAULT cAgeAdt	:= ""
DEFAULT cCtaAdt	:= ""
DEFAULT lPendCtb := .F.

nVCalIRF     := If(Type("nVRetIRF") != "N",0,nVCalIRF)
nVRetIRF     := If(Type("nVRetIRF") != "N",0,nVRetIRF)

aFill(aRarTimp,0)

If SE1->E1_EMISSAO >= dLastPcc
	nValMinRet	:= 0
EndIf

If nOpc == 1  //Inclusao

	If (SE1->E1_TIPO $ MVRECANT .and. !Empty(cBcoAdt) .and. !Empty(cAgeAdt) .and. !Empty(cCtaAdt)) .OR. ;
		(lDesdobr .AND. lRastro .AND. !lNRastDSD)

		//Em caso de rastreamento, posiciono no registro do titulo gerador do desdobramento
		If lDesdobr .AND. lRastro .AND. !lNRastDSD
			SE1->(dbGoto(nRecSE1))
		Endif

		nSalvRec := SE1->(Recno())

		cChaveTit:= xFilial("SE1") + "|" + SE1->E1_PREFIXO + "|" + SE1->E1_NUM + "|" + SE1->E1_PARCELA + "|" + ;
                    SE1->E1_TIPO   + "|" + SE1->E1_CLIENTE + "|" + SE1->E1_LOJA

		If !lDesdobr //inclusão de RA
			oModel :=  FWLoadModel('FINM030')//Movimentos Bancarios
			oModel:SetOperation(3) // Inclusao
			oModel:Activate()
			oModel:SetValue( "MASTER", "E5_GRV", .T. )
			oModel:SetValue( "MASTER", "NOVOPROC", .T. )
     		oSubFK5 := oModel:GetModel("FK5DETAIL")
			oSubFKA := oModel:GetModel("FKADETAIL")

			oSubFK3 := oModel:GetModel("FK3DETAIL")
			oSubFK4 := oModel:GetModel("FK4DETAIL")

			cCamposE5:="{"
			cCamposE5+= "{'E5_TIPO'     , '"+SE1->E1_TIPO+"'  }"
			cCamposE5+= ",{'E5_HISTOR'  , '"+SE1->E1_HIST+"' }"
			cCamposE5+= ",{'E5_PREFIXO' , '"+SE1->E1_PREFIXO+"' }"
			cCamposE5+= ",{'E5_NUMERO'  , '"+SE1->E1_NUM+"' }"
			cCamposE5+= ",{'E5_PARCELA' , '"+SE1->E1_PARCELA+"' }"
			cCamposE5+= ",{'E5_CLIFOR'  , '"+SE1->E1_CLIENTE+"' }"
			cCamposE5+= ",{'E5_CLIENTE' , '"+SE1->E1_CLIENTE+"' }"
			cCamposE5+= ",{'E5_LOJA'    , '"+SE1->E1_LOJA+"' }"
			cCamposE5+= ",{'E5_DTDIGIT' , dDataBase }"
			cCamposE5+= ",{'E5_BENEF'   , '"+ StrTran(SE1->E1_NOMCLI,"'","")+"' }"
			cCamposE5+= ",{'E5_MOTBX'   , 'NOR'}"

			//---------------------------------------------
			// Grava ID do titulo
			//---------------------------------------------
			cIdDoc	:= FINGRVFK7("SE1", cChaveTit)

			oSubFKA:SetValue( "FKA_IDORIG", cIdMov )
			oSubFKA:SetValue( "FKA_TABORI", "FK5" )

			//---------------------------------------------
			// Grava Mov. Bancário
			//---------------------------------------------
			oSubFK5:SetValue( "FK5_DATA"  , SE1->E1_EMISSAO )
			oSubFK5:SetValue( "FK5_NATURE", SE1->E1_NATUREZ )
			oSubFK5:SetValue( "FK5_BANCO" , cBancoAdt )
			oSubFK5:SetValue( "FK5_AGENCI", cAgenciaAdt)
			oSubFK5:SetValue( "FK5_CONTA" , cNumCon )
			oSubFK5:SetValue( "FK5_RECPAG", "R" )
			oSubFK5:SetValue( "FK5_HISTOR", SubStr(SE1->E1_HIST,1,TamSX3("FK5_HISTOR")[1]) )
			oSubFK5:SetValue( "FK5_DTDISP", SE1->E1_EMISSAO )
			oSubFK5:SetValue( "FK5_LA"    , "S")
			oSubFK5:SetValue( "FK5_FILORI", SE1->E1_FILORIG )
			oSubFK5:SetValue( "FK5_ORIGEM", cOrig )
			oSubFK5:SetValue( "FK5_TPDOC" , "RA" )
			oSubFK5:SetValue( "FK5_CCUSTO", SE1->E1_CCUSTO)
			oSubFK5:SetValue( "FK5_TXMOED", SE1->E1_TXMOEDA)
			oSubFK5:SetValue( "FK5_IDDOC" , cIdDoc )

			SA6->(DbSetOrder(1))
			SA6->(DbSeek(xFilial()+cBancoAdt+cAgenciaAdt+cNumCon))
			If Max(SA6->A6_MOEDA,1) == 1
				oSubFK5:SetValue( "FK5_MOEDA" , "01" )
				oSubFK5:SetValue( "FK5_VALOR" , SE1->E1_VLCRUZ)
				oSubFK5:SetValue( "FK5_VLMOE2", SE1->E1_VALOR)
			Else

				oSubFK5:SetValue( "FK5_MOEDA" , Strzero(SA6->A6_MOEDA,2) )
				oSubFK5:SetValue( "FK5_VALOR" , SE1->E1_VALOR )
				oSubFK5:SetValue( "FK5_VLMOE2", SE1->E1_VLCRUZ)
			EndIf

			IF SPBInUse()
				oSubFK5:SetValue( "FK5_MODSPB", "1")
			Endif

			If lRaRtImp

				If cPaisLoc == "BRA" .and. (lPCCBxCR .OR.lIrPjBxCr)  .AND. SA6->A6_MOEDA <= 1
					//---------------------------------------------
					// Grava Imposto calculado
					//---------------------------------------------
					If lPCCBxCR
						cCamposE5+= ",{'E5_VRETPIS', "+cValToChar(SE1->E1_PIS)+" }"
						cCamposE5+= ",{'E5_VRETCOF', "+cValToChar(SE1->E1_COFINS)+" }"
						cCamposE5+= ",{'E5_VRETCSL', "+cValToChar(SE1->E1_CSLL)+"}"

						If Type("lDescPCC") == "L" .and. !lDescPCC
							cCamposE5+= ",{'E5_PRETPIS','1'}"
							cCamposE5+= ",{'E5_PRETCOF','1'}"
							cCamposE5+= ",{'E5_PRETCSL','1'}"
						Endif

						nPisRet := If (lDescPCC,SE1->E1_PIS,0)
						nCofRet := If (lDescPCC,SE1->E1_COFINS,0)
						nCslRet	:= If (lDescPCC,SE1->E1_CSLL,0)

						aadd(aImpostos,{"PIS",nVCalPIS,SuperGetMV("MV_PISNAT"),"", nPisRet ,nBCalPIS, nRCalPIS + SE1->E1_BASEPIS})
						aadd(aImpostos,{"COF",nVCalCOF,SuperGetMV("MV_COFINS"),"", nCofRet ,nBCalCOF, nRCalCOF + SE1->E1_BASECOF})
						aadd(aImpostos,{"CSL",nVCalCSL,SuperGetMV("MV_CSLL")  ,"", nCslRet ,nBCalCSL, nRCalCSL + SE1->E1_BASECSL})
					Endif
					If lIrPjBxCr

						If SE1->E1_IRRF>0
							cCamposE5+= ",{'E5_VRETIRF',"+ cValToChar(SE1->E1_IRRF) + "}"
							cCamposE5+= ",{'E5_BASEIRF',"+ cValToChar(SE1->E1_BASEIRF) + "}"
							aadd(aImpostos,{"IRF",nVCalIRF,&(SuperGetMV("MV_IRF")),"", nVRetIRF, nBCalIRF , SE1->E1_BASEIRF})
						Endif
					Endif

					//Grava FK3 E/OU FK4
					For nX := 1 to Len(aImpostos)

						//Gravar FK4 se os valores de PCC forem maiores que zero
						If aImpostos[nX][2] > 0
							If !oSubFK3:IsEmpty()
								//Inclui a quantidade de linhas necessárias
								oSubFK3:AddLine()
								//Vai para linha criada
								oSubFK3:GoLine( oSubFK3:Length() )
							Endif

							//---------------------------------------------
							// Grava Imposto calculado
							//---------------------------------------------
							oSubFK3:SetValue( "FK3_IDFK3" , GetSx8Num('FK3', 'FK3_IDFK3'))
							oSubFK3:SetValue( "FK3_DATA"  , SE1->E1_EMISSAO )
							oSubFK3:SetValue( "FK3_ORIGEM", cOrig )
							oSubFK3:SetValue( "FK3_IMPOS" , aImpostos[nX][1] )
							oSubFK3:SetValue( "FK3_RECPAG", "R" )
							oSubFK3:SetValue( "FK3_MOEDA" , "01" )
							oSubFK3:SetValue( "FK3_VALOR" , aImpostos[nX][2] )
							oSubFK3:LoadValue( "FK3_NATURE", aImpostos[nX][3] )	//verificar
							oSubFK3:SetValue( "FK3_FILORI", SE1->E1_FILORIG )
							oSubFK3:SetValue( "FK3_BASIMP", aImpostos[nX][6] )//buscar a base de calculo
							oSubFK3:SetValue( "FK3_IDORIG", cIdMov )
							oSubFK3:SetValue( "FK3_TABORI", "FK5")


							If aImpostos[nX][5] > 0 //(Type("lDescPCC") == "L" .and. lDescPCC) .OR.  aImpostos[nX][1]=="IRF"
								//---------------------------------------------
								// Grava Imposto Retido
								//---------------------------------------------
								If !oSubFK4:IsEmpty()
									//Inclui a quantidade de linhas necessárias
									oSubFK4:AddLine()
									//Vai para linha criada
									oSubFK4:GoLine( oSubFK4:Length() )
								Endif
								cIdFK4:= GetSx8Num('FK4', 'FK4_IDFK4')
								aImpostos[nX,4] := cIdFK4
								oSubFK4:SetValue( "FK4_IDFK4" , cIdFK4)
								oSubFK4:SetValue( "FK4_DATA"  , SE1->E1_EMISSAO )
								oSubFK4:SetValue( "FK4_ORIGEM", cOrig )
								oSubFK4:SetValue( "FK4_IMPOS" , aImpostos[nX][1]  )
								oSubFK4:SetValue( "FK4_RECPAG", "R" )
								oSubFK4:SetValue( "FK4_MOEDA" , "01" )
								oSubFK4:SetValue( "FK4_VALOR" , aImpostos[nX][5] )
								oSubFK4:LoadValue( "FK4_NATURE", aImpostos[nX][3])
								oSubFK4:SetValue( "FK4_FILORI", SE1->E1_FILORIG )
								oSubFK4:SetValue( "FK4_BASIMP", aImpostos[nX][7] )

								oSubFK3:SetValue( "FK3_IDRET" , cIdFK4 )

							Endif
						Endif
					Next

				Endif

			Endif
			cCamposE5+="}"
			oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 )
			If oModel:VldData()
		       oModel:CommitData()
		       oModel:DeActivate()
		       oModel:Destroy()
		       oModel := NIL
			Else

				cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
				cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
    			cLog += cValToChar(oModel:GetErrorMessage()[6])

    			If (Type("lF040Auto") == "L" .and. !lF040Auto)
					Help( ,,"M040VALID",,cLog, 1, 0 )
				Endif
    			Return
			Endif

		Else //baixa de desdobramento

			oModel :=  FWLoadModel('FINM010')//baixa
			oModel:SetOperation(3) // Inclusao
			oModel:Activate()
			oModel:SetValue( "MASTER", "E5_GRV", .T. )
			oModel:SetValue( "MASTER", "NOVOPROC", .T. )
			oSubFKA := oModel:GetModel("FKADETAIL")
			oSubFK1 := oModel:GetModel("FK1DETAIL")

			cIdDoc	:= FINGRVFK7("SE1", cChaveTit)

			cCamposE5:="{"
			cCamposE5+= "{'E5_TIPO', SE1->E1_TIPO  } "
			cCamposE5+= ",{'E5_HISTOR', SE1->E1_HIST }"
			cCamposE5+= ",{'E5_PREFIXO', SE1->E1_PREFIXO }"
			cCamposE5+= ",{'E5_NUMERO', SE1->E1_NUM }"
			cCamposE5+= ",{'E5_PARCELA', SE1->E1_PARCELA }"
			cCamposE5+= ",{'E5_CLIFOR', SE1->E1_CLIENTE }"
			cCamposE5+= ",{'E5_CLIENTE', SE1->E1_CLIENTE }"
			cCamposE5+= ",{'E5_LOJA',SE1->E1_LOJA }"
			cCamposE5+= ",{'E5_DTDIGIT',dDataBase }"
			cCamposE5+= ",{'E5_DTDISPO',dDataBase }"
			cCamposE5+= ",{'E5_BENEF',SE1->E1_NOMCLI }"
			cCamposE5+= ",{'E5_MOTBX','DSD'}"

			//---------------------------------------------
			// Grava Baixa do titulo
			//---------------------------------------------
			oSubFKA:SetValue( "FKA_IDORIG", cIdMov )
			oSubFKA:SetValue( "FKA_TABORI", "FK1" )

			oSubFK1:SetValue( "FK1_DATA"  , SE1->E1_EMISSAO )
			oSubFK1:SetValue( "FK1_NATURE", SE1->E1_NATUREZ )
			oSubFK1:SetValue( "FK1_VENCTO", SE1->E1_VENCREA )
			oSubFK1:SetValue( "FK1_RECPAG", "R" )
			oSubFK1:SetValue( "FK1_TPDOC" , "BA" )
			oSubFK1:SetValue( "FK1_HISTOR", SE1->E1_HIST)
			oSubFK1:SetValue( "FK1_MOTBX" , "DSD")
			oSubFK1:SetValue( "FK1_FILORI", SE1->E1_FILORIG )
			oSubFK1:SetValue( "FK1_TXMOED", SE1->E1_TXMOEDA )
			oSubFK1:SetValue( "FK1_CCUSTO", SE1->E1_CCUSTO )
			oSubFK1:SetValue( "FK1_ORIGEM", cOrig )
			oSubFK1:SetValue( "FK1_LA"    , "S")
			oSubFK1:SetValue( "FK1_IDDOC" , cIdDoc)

			SA6->(DbSetOrder(1))
			SA6->(DbSeek(xFilial()+cBancoAdt+cAgenciaAdt+cNumCon))
			If Max(SA6->A6_MOEDA,1) == 1

				oSubFK1:SetValue( "FK1_MOEDA" , "01" )
				oSubFK1:SetValue( "FK1_VALOR" , SE1->E1_VLCRUZ)
				oSubFK1:SetValue( "FK1_VLMOE2", SE1->E1_VALOR)
			Else

				oSubFK1:SetValue( "FK1_MOEDA" , Strzero(SA6->A6_MOEDA,2) )
				oSubFK1:SetValue( "FK1_VALOR" , SE1->E1_VALOR )
				oSubFK1:SetValue( "FK1_VLMOE2", SE1->E1_VLCRUZ)
			EndIf

			cCamposE5+="}"
			oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 )

			If oModel:VldData()
				oModel:CommitData()

	    		nRecSE5 := oModel:GetValue("MASTER","E5_RECNO")
				SE5->(dbGoTo(nRecSE5))

				oModel:DeActivate()
				oModel:Destroy()
		        oModel := NIL
			Else

				cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
				cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
    			cLog += cValToChar(oModel:GetErrorMessage()[6])

    			If (Type("lF040Auto") == "L" .and. !lF040Auto)
					  Help( ,,"M010VALID",,cLog, 1, 0 )
				Endif
				oModel:DeActivate()
				oModel:Destroy()
		        oModel := NIL
				DisarmTransaction()
				Return
			Endif

		Endif

		// Grava os campos necessarios para Localizacao do banco no SA6 na contabilizacao
		// off-line do LP 501, pois o usuario podera utilizar a conta contabil configurada
		// no SA6 para contabilizar o LP 501. E como o SE5 jah eh marcado com E5_LA=S, para
		// nao duplicar a contabilizacao do LP 520, no TOP este registro do SE5 fica fora do
		// processamento impossibilitando a pesquisa no SA6 atraves do SE5.
		If lRaRtImp

			If SE1->E1_TIPO $ MVRECANT
				If SE1->E1_EMISSAO < dLastPcc
					aRarTimp := F040TotMes(SE1->E1_EMISSAO)
					If aRarTimp[1] > nValMinRet
						n040Pis := SE1->E1_PIS
						n040Cof := SE1->E1_COFINS
						n040Csl := SE1->E1_CSLL
					Endif
				Else
					n040Pis := SE1->E1_PIS
					n040Cof := SE1->E1_COFINS
					n040Csl := SE1->E1_CSLL
				EndIf
				If cPaisLoc == "BRA" .and. lPCCBxCR
					If FindFunction( "FXMultSld" ) .AND. FXMultSld()
						If SA6->A6_MOEDA <= 1
							FGrvPccRec(n040Pis,n040Cof,n040Csl,nSalvRec,.F.,.T.,cSequencia,"FINA040",SE1->E1_MOEDA)
							lRetPCC := .T.
						EndIf
				    Else
						FGrvPccRec(n040Pis,n040Cof,n040Csl,nSalvRec,.F.,.T.,cSequencia,"FINA040",SE1->E1_MOEDA)
						lRetPCC := .T.
				    EndIf
				Endif
			Else
				//Gravo os titulos de impostos Pis Cofins Csll quando controlados pela baixa
				// Os titulos de impostos devem ser desconsiderados quando C/C cuja moeda seja diferente da moda corrente
				If cPaisLoc == "BRA" .and. lPCCBxCR .and. lDescPCC // .and. lRetParc
					If FXMultSld()
						If SA6->A6_MOEDA <= 1
							FGrvPccRec(SE1->E1_PIS,SE1->E1_COFINS,SE1->E1_CSLL,nSalvRec,.F.,.T.,cSequencia,"FINA040",SE1->E1_MOEDA)
						EndIf
				    Else
						FGrvPccRec(SE1->E1_PIS,SE1->E1_COFINS,SE1->E1_CSLL,nSalvRec,.F.,.T.,cSequencia,"FINA040",SE1->E1_MOEDA)
				    EndIf
				Endif
			Endif
			SE1->(dbGoTo(nSalvRec))
			If Type("lDescPCC") == "L" .and. !lDescPCC .and. (SE1->E1_TIPO $ MVRECANT) .and. lRetPCC
				If (SE1->E1_EMISSAO >= dLastPcc .And. SE5->(E5_VRETPIS+E5_VRETCOF+E5_VRETCSL) > 0 ) .Or.;
					 aRarTimp[1] > nValMinRet
					// RA ja foi retido nele mesmo
					dbSelectArea( "FK3" )
					FK3->( DbSetOrder( 2 ) )//FK3_FILIAL+FK3_TABORIG+FK3_IDORIG
					If MsSeek( xFilial("FK3") + SE5->E5_TABORI+ SE5->E5_IDORIG )

						oModel :=  FWLoadModel('FINM030')//Mov. Bancarios
						oModel:SetOperation( 4 ) //Alteração
						oModel:Activate()
						oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5

					   //Atualizar o status de retencao de impostos
						oSubFK3:= oModel:GetModel( "FK3DETAIL" )
						For nX := 1 to Len(aImpostos)
							If oSubFK3:SeekLine({{"FK3_IMPOS",aImpostos[nX,1]}})//Nome do imposto
								oSubFK3:SetValue( "FK3_IDRET", aImpostos[nX,4] )	//cIdFk4
							Endif
						Next

						cCamposE5:= "{{'E5_PRETPIS',' ' } "
						cCamposE5+= ",{'E5_PRETCOF', ' ' }"
						cCamposE5+= ",{'E5_PRETCSL', ' ' }}"

						oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 )
						If oModel:VldData()
					       oModel:CommitData()
					       oModel:DeActivate()
					       oModel:Destroy()
		        		   oModel := NIL
						Else

							cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
							cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
			    			cLog += cValToChar(oModel:GetErrorMessage()[6])
			    		EndIf
			    	EndIf
				Endif
			Endif
			If cPaisLoc == "BRA" .and. lIrPjBxCr// .and. lRetParc
				If FXMultSld()
					If SA6->A6_MOEDA <= 1
						FGrvIrRec(SE1->E1_IRRF,nSalvRec,.T.,cSequencia,"FINA040",SE1->E1_MOEDA)
					EndIf
			    Else
					FGrvIrRec(SE1->E1_IRRF,nSalvRec,.T.,cSequencia,"FINA040",SE1->E1_MOEDA)
			    EndIf
			Endif
			SE1->(dbGoTo(nSalvRec))
			// Atualiza os titulos que acumularam o PCC
			nRecSE5 := SE5->(Recno())
			If cPaisLoc == "BRA" .and. lPCCBxCR .and. Type("lDescPCC") == "L" .and. lDescPCC
				If aDadosRet[1] <= nValMinRet
					If Valtype(aDadosRet[5]) == "A" .And. Len(aDadosRet[5]) > 0
						cPrefOri  := SE5->E5_PREFIXO
						cNumOri   := SE5->E5_NUMERO
						cParcOri  := SE5->E5_PARCELA
						cTipoOri  := SE5->E5_TIPO
						cCfOri    := SE5->E5_CLIFOR
						cLojaOri  := SE5->E5_LOJA
						For ni:=1 to Len(aDadosRet[5])
							SE5->(dbGoTo(aDadosRet[5][ni]))

							dbSelectArea( "FK3" )
							FK3->( DbSetOrder( 2 ) )//FK3_FILIAL+FK3_TABORIG+FK3_IDORIG
							If MsSeek( xFilial("FK3") + SE5->E5_TABORI+ SE5->E5_IDORIG )

								oModel :=  FWLoadModel('FINM030')//Mov. Bancarios
								oModel:SetOperation( 4 ) //Alteração
								oModel:Activate()
								oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5

							   //Atualizar o status de retencao de impostos
	    						oSubFK3:= oModel:GetModel( "FK3DETAIL" )
	    						For nX := 1 to Len(aImpostos)
									If oSubFK3:SeekLine({{"FK3_IMPOS",aImpostos[nX,1]}})//Nome do imposto
										oSubFK3:SetValue( "FK3_IDRET", aImpostos[nX,4] )	//cIdFk4
									Endif
								Next

								cCamposE5:= "{{'E5_PRETPIS','2' } "
								cCamposE5+= ",{'E5_PRETCOF', '2' }"
								cCamposE5+= ",{'E5_PRETCSL', '2' }}"

								oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 )
								If oModel:VldData()
							       oModel:CommitData()
							       oModel:DeActivate()
							       oModel:Destroy()
		        				   oModel := NIL
								Else

									cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
									cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
					    			cLog += cValToChar(oModel:GetErrorMessage()[6])

					    			If (Type("lF040Auto") == "L" .and. lF040Auto)
					    				Help( ,,"M010VALID",,cLog, 1, 0 )
					    			Endif
							   	    Return
								Endif
							Endif
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Grava SFQ                                         ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If nRecSE5 <> aDadosRet[5][ni]
								FImpCriaSFQ("E1B", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
											"E1B", SE5->E5_PREFIXO, SE5->E5_NUMERO, SE5->E5_PARCELA, SE5->E5_TIPO, SE5->E5_CLIFOR, SE5->E5_LOJA,;
											SE5->E5_VRETPIS, SE5->E5_VRETCOF, SE5->E5_VRETCSL,;
											 0,;
											SE5->E5_FILIAL )
							Endif
						Next
					EndIf
				EndIf
			EndIf
			SE5->(dbGoTo(nRecSE5))

    	EndIf

		Reclock( "SE1", .F. )
		If lDesdobr
			nSE1Rec := Recno()
			SE1->E1_BAIXA		:= dDatabase
			SE1->E1_MOVIMEN	:= dDatabase
			SE1->E1_DESCONT	:= SE1->E1_SDDECRE
			SE1->E1_JUROS		:= SE1->E1_SDACRES
			SE1->E1_VALLIQ		:= SE1->(E1_VLCRUZ+E1_SDACRES-E1_SDDECRE)
			SE1->E1_SALDO		:= 0
			SE1->E1_SDACRES	:= 0
			SE1->E1_SDDECRE	:= 0
			SE1->E1_STATUS		:= "B"
			SE1->E1_LA			:= "S"
			MsUnlock()
	   Else
			SE1->E1_PORTADO		:= SE5->E5_BANCO
			SE1->E1_AGEDEP		:= SE5->E5_AGENCIA
			SE1->E1_CONTA		:= SE5->E5_CONTA
			MsUnlock()
			//Ponto de entrada F040MOV
			//Utilizado para gravação complementar na geracao do RA
			IF ExistBlock("F040MOV")
				ExecBlock("F040MOV",.f.,.f.)
			Endif
			AtuSalBco( cBcoAdt, cAgeAdt, cCtaAdt, SE5->E5_DTDISPO, SE5->E5_VALOR, "+" )
		Endif
	EndIf

ElseIf nOpc == 2  //Exclusao de titulo

	dbSelectArea("SE5")
	dbSetOrder(7)
	If (dbSeek(xFilial()+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA))
		nRecSE5 := SE5->(Recno())
		While !Eof() .and. SE5->E5_PREFIXO+SE5->E5_NUMERO+SE5->E5_PARCELA+SE5->E5_TIPO+SE5->E5_CLIFOR+SE5->E5_LOJA == ;
			SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA .AND. ;
			xFilial("SE5") == SE5->E5_FILIAL

			SE5->(dbSkip())
			nNextRec := SE5->(recno())
			SE5->(dbSkip(-1))

			//Reestruturacao SE5
			lEstPenCtb := AllTrim(SE5->E5_LA) == "N" .and. SE5->E5_TIPODOC == "ES" .And. lPendCtb
			If SE5->E5_TIPODOC $ "RA"
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Obtem os dados do registro tipo RA para gerar um	³
				//³ registro de estorno 								³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				cCamposE5:="{"
				cCamposE5+="{'E5_KEY',E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIENTE+E5_LOJA } "
				cCamposE5+= ",{'E5_PREFIXO', '' }"
				cCamposE5+= ",{'E5_NUMERO', '' }"
				cCamposE5+= ",{'E5_PARCELA', '' }"
				cCamposE5+= ",{'E5_TIPO', '' }"
				cCamposE5+="}"

				oModel :=  FWLoadModel('FINM030')//adiantamento (RA)
				oModel:SetOperation( 4 ) //Alteração
				oModel:Activate()
				oSubFKA := oModel:GetModel( "FKADETAIL" )
				oSubFKA:SeekLine( 	{ {"FKA_IDORIG", SE5->E5_IDORIG } } )

				oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5
				oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 ) //Informa os campos da SE5 que serão gravados indepentes de FK5
				oModel:SetValue( "MASTER", "E5_OPERACAO", 2 ) //E5_OPERACAO 2 = Altera E5_TIPODOC da SE5 para 'ES' e gera estorno na FK5
				oModel:SetValue( "MASTER", "HISTMOV", OemToAnsi(STR0040)) //"Exclusao de Titulo RA"

				//Dados do movimento
				oSubFK5 := oModel:GetModel( "FK5DETAIL" )
				oSubFK5:SetValue( "FK5_LA", "S" )

				If oModel:VldData()
			       oModel:CommitData()
			       oModel:DeActivate()
			       oModel:Destroy()
		           oModel := NIL
				Else
					cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
					cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
	    			cLog += cValToChar(oModel:GetErrorMessage()[6])

	    			Help( ,,"M040VALID",,cLog, 1, 0 )
			   	    return
				Endif

				FKCOMMIT()

				IF ExistBlock("F040ERA")
					ExecBlock("F040ERA",.F.,.F.)
				Endif
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Deleta o movimento no SE5 exceto quando ja foi contabilizado ou	³
			//³ quando o titulo pertencia a um bordero descontado e teve sua		³
			//³ transferencia estornada. O movimento deve permanecer por fins  	³
			//³ de extrato bancario.															³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			//Registro de compensacao com estorno cancelados
			ElseIf (SE5->E5_RECPAG == "R" .And. SE5->E5_MOTBX == "CMP" .AND. TemBxCanc(SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ),.T.))

				dbSelectArea( "FK1" )
				FK1->( DbSetOrder( 1 ) )//FK1_FILIAL+FK1_IDMOV
				If SE5->E5_TABORI== "FK1" .AND. MsSeek( xFilial("FK1") + SE5->E5_IDORIG )

					cCamposE5:= "{{'E5_KEY',E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIENTE+E5_LOJA } "
					cCamposE5+= ",{'E5_PREFIXO', '' }"
					cCamposE5+= ",{'E5_NUMERO', '' }"
					cCamposE5+= ",{'E5_PARCELA', '' }"
					cCamposE5+= ",{'E5_TIPO', '' }}"

					oModel :=  FWLoadModel('FINM010')//Baixa por compensação
					oModel:SetOperation( 4 ) //Alteração
					oModel:Activate()
					oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5
					oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 ) //Informa os campos da SE5 que serão gravados indepentes de FK5
					oSubFKA := oModel:GetModel( "FKADETAIL" )
					If oSubFKA:SeekLine({ {"FKA_IDORIG", SE5->E5_IDORIG } } )

						//Dados do movimento
						oSubFK1 := oModel:GetModel( "FK1DETAIL" )
						oSubFK1:SetValue( "FK1_LA", "S" )

						If oModel:VldData()
					       oModel:CommitData()
					       oModel:DeActivate()
					       oModel:Destroy()
		        		   oModel := NIL
						Else

							cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
							cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
			    			cLog += cValToChar(oModel:GetErrorMessage()[6])

			    			If (Type("lF040Auto") == "L" .and. lF040Auto)
						   		Help( ,,"M010VALID",,cLog, 1, 0 )
						   	Endif
					   	    return
						Endif
					Else
						oModel:DeActivate()
						oModel:Destroy()
		        		oModel := NIL
					EndIf
				EndIf

				FKCOMMIT()
			ElseIf (SE5->E5_TIPODOC == "ES" .AND. !Empty(SE5->E5_LOTE) .And. (SE5->E5_MOTBX != "CMP" .Or.(SE5->E5_RECPAG == "P" .And. SE5->E5_MOTBX == "CMP"  )))
				dbSelectArea( "FK1" )//limpando dados de estorno
				FK1->( DbSetOrder( 1 ) )//FK1_FILIAL+FK1_IDMOV
				If SE5->E5_TABORI== "FK1" .AND. MsSeek( xFilial("FK1") + SE5->E5_IDORIG )

					cCamposE5:= "{{'E5_KEY',E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIENTE+E5_LOJA } "
					cCamposE5+= ",{'E5_PREFIXO', '' }"
					cCamposE5+= ",{'E5_NUMERO', '' }"
					cCamposE5+= ",{'E5_PARCELA', '' }"
					cCamposE5+= ",{'E5_TIPO', '' }}"

					oModel :=  FWLoadModel('FINM010')//Baixa por compensação
					oModel:SetOperation( 4 ) //Alteração
					oModel:Activate()
					oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5
					oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 ) //Informa os campos da SE5 que serão gravados indepentes de FK5
					oSubFKA := oModel:GetModel( "FKADETAIL" )
					If oSubFKA:SeekLine({ {"FKA_IDORIG", SE5->E5_IDORIG } } )

						//Dados do movimento
						oSubFK1 := oModel:GetModel( "FK1DETAIL" )
						oSubFK1:SetValue( "FK1_LA", "S" )

						If oModel:VldData()
					       oModel:CommitData()
					       oModel:DeActivate()
					       oModel:Destroy()
		        		   oModel := NIL
						Else

							cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
							cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
			    			cLog += cValToChar(oModel:GetErrorMessage()[6])

			    			If (Type("lF040Auto") == "L" .and. lF040Auto)
						   		Help( ,,"M010VALID",,cLog, 1, 0 )
						   	Endif
					   	    return
						Endif
					Else
						oModel:DeActivate()
						oModel:Destroy()
		        		oModel := NIL
					EndIf

				EndIf
				FKCOMMIT()
			ElseIf (SE5->E5_TIPODOC == "DB") // Despesa bancaria
				dbSelectArea( "FK5" )//limpando dados de estorno
				FK5->( DbSetOrder( 1 ) )//FK1_FILIAL+FK1_IDMOV
				If SE5->E5_TABORI== "FK5" .AND. MsSeek( xFilial("FK5") + SE5->E5_IDORIG )

					cCamposE5:= "{{'E5_KEY',E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIENTE+E5_LOJA } "
					cCamposE5+= ",{'E5_PREFIXO', '' }"
					cCamposE5+= ",{'E5_NUMERO', '' }"
					cCamposE5+= ",{'E5_PARCELA', '' }"
					cCamposE5+= ",{'E5_TIPO', '' }}"

					oModel :=  FWLoadModel('FINM030')//Baixa por compensação
					oModel:SetOperation( 4 ) //Alteração
					oModel:Activate()
					oModel:SetValue( "MASTER", "E5_GRV", .T. ) //habilita gravação de SE5
					oModel:SetValue( "MASTER", "E5_CAMPOS", cCamposE5 ) //Informa os campos da SE5 que serão gravados indepentes de FK5
					oSubFKA := oModel:GetModel( "FKADETAIL" )
					If oSubFKA:SeekLine({ {"FKA_IDORIG", SE5->E5_IDORIG } } )

						If oModel:VldData()
					       oModel:CommitData()
					       oModel:DeActivate()
					       oModel:Destroy()
		        		   oModel := NIL
						Else

							cLog := cValToChar(oModel:GetErrorMessage()[4]) + ' - '
							cLog += cValToChar(oModel:GetErrorMessage()[5]) + ' - '
			    			cLog += cValToChar(oModel:GetErrorMessage()[6])

			    			If (Type("lF040Auto") == "L" .and. lF040Auto)
						   		Help( ,,"M010VALID",,cLog, 1, 0 )
						   	Endif
					   	    return
						Endif
					Else
						oModel:DeActivate()
						oModel:Destroy()
		        		oModel := NIL
					EndIf

				EndIf
				FKCOMMIT()
			ElseIf Substr(SE5->E5_LA,1,1) <> "S" .and. SE5->E5_TIPODOC <> "E2" .and.;
				!(SE5->E5_TIPODOC == "ES" .AND. !Empty(SE5->E5_LOTE)) .and. !(FunName() = "FINA460" .And. lF040DELC) .And. !lEstPenCtb //deletando processo de cobrança descontada
				//REESTRUTURACAO SE5
				//Neste ponto a rotina apenas seta os valores de pendencias de retencao de impostos no SE5
				//Foi mantida dasta forma antiga pois, na atualização das FKs (Model) ja foram feitas as atualizacoes
				//nas novas tabelas
				//Este trecho sera retirado em fase posterior (final da SE5)
				Reclock("SE5")
				dbDelete()
				MsUnlock()

			ElseIf SE5->E5_TIPODOC == "ES" .AND. SE5->E5_RECPAG == "P" .AND. SE5->E5_TIPO $ MVRECANT .And. SE5->E5_MOTBX == "CMP" // Estorno de compensacao
				//REESTRUTURACAO SE5
				//Neste ponto a rotina apenas seta os valores de pendencias de retencao de impostos no SE5
				//Foi mantida dasta forma antiga pois, na atualização das FKs (Model) ja foram feitas as atualizacoes
				//nas novas tabelas
				//Este trecho sera retirado em fase posterior (final da SE5)
				Reclock("SE5")
				dbDelete()
				MsUnlock()

			Endif
			If lRaRtImp
				SFQ->(DbSetOrder(1))
				If SFQ->(MsSeek(xFilial("SFQ")+"E1B"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
					lTemSfq := .T.
					lExcRetentor := .T.
				ELSE
					SFQ->(DbSetOrder(2))
					If SFQ->(MsSeek(xFilial("SFQ")+"E1B"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
						lTemSfq := .T.
					Endif
				Endif
				nRecSFQ := SFQ->(Recno())
				If lExcRetentor
					While !eof() .and. SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA) == SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)
						SE5->(dbSetOrder(7) )
						If SE5->(dbSeek(xFilial("SE5")+SFQ->FQ_PREFDES+SFQ->FQ_NUMDES+SFQ->FQ_PARCDES+SFQ->FQ_TIPODES+SFQ->FQ_CFDES+SFQ->FQ_LOJADES))
							//REESTRUTURACAO SE5
							//Neste ponto a rotina apenas seta os valores de pendencias de retencao de impostos no SE5
							//Foi mantida dasta forma antiga pois, na atualização das FKs (Model) eh que ocorrera
							// - A exclusao da retenção na FK4
							// - A exclusao do calculo de impostos da baixa que esta sendo canelada
							// - A limpeza do IDs de retencao dos demais titulos que compuseram a retencao mas continuam baixados
							//Este trecho sera retirado em fase posterior (final da SE5)
							RecLock("SE5",.f.)
								SE5->E5_PRETPIS	:= "1"
								SE5->E5_PRETCOF	:= "1"
								SE5->E5_PRETCSL	:= "1"
							MsUnLock()
						EndIf
						SFQ->(dbSkip())
					EndDo
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Exclui os registros de relacionamentos do SFQ                               ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					FImpExcSFQ("E1B",SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
				ElseIf lTemSfq
					// Altera Valor dos abatimentos do titulo retentor e tambem dos titulos gerados por ele.
					cChaveSfq := SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)
					nTotGrupo := 0

					SFQ->(DbSetOrder(1)) // FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI
					SE1->(DbSetOrder(1)) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
					If SFQ->(MsSeek(cChaveSfq))
						If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
							nTotGrupo += If(SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
						Endif
						SE1->(DbSetOrder(1))
						While SFQ->(!Eof()) .And.;
							SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI) == cChaveSfq
							If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES)))
								nTotGrupo += If(SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
							Endif
							SFQ->(DbSkip())
						End
					EndIf
                	SE1->(dbGoTo(nSalvRec))
					SFQ->(DbGoTo(nRecSFQ))
					nValBase	:= If (SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR)
					nTotGrupo -= nValBase
					nBaseAtual := nTotGrupo
					nBaseAntiga := nTotGrupo+nValBase
					nProp := nBaseAtual / nBaseAntiga
                    If nBaseAtual <= nValMinRet
						cChaveSfq := SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)
						SFQ->(DbSetOrder(1)) // FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI
						SE1->(DbSetOrder(1)) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						SE5->(dbSetOrder(7))
						If SFQ->(MsSeek(cChaveSfq))
							If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
								While SE1->(!eof()) .and. SFQ->(FQ_PREFORI+FQ_NUMORI) == SE1->(E1_PREFIXO+E1_NUM)
									If SE1->E1_TIPO $ "PIS/COF/CSL/"
										RecLock("SE1",.f.)
											SE1->(dbDelete())
										MsUnLock()
									EndIf
									SE1->(dbSkip())
								EndDo
			   	             	SE1->(dbGoTo(nSalvRec))
							Endif
							SE5->(dbSetOrder(7) )
							If SE5->(dbSeek(xFilial("SE5")+SFQ->FQ_PREFORI+SFQ->FQ_NUMORI+SFQ->FQ_PARCORI+SFQ->FQ_TIPOORI+SFQ->FQ_CFORI+SFQ->FQ_LOJAORI))
								While !eof() .and. SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)

									//REESTRUTURACAO SE5
									//Neste ponto a rotina apenas seta os valores de pendencias de retencao de impostos no SE5
									//Foi mantida dasta forma antiga pois, na atualização das FKs (Model) eh que ocorrera:
									// - A exclusao da retenção na FK4
									// - A exclusao do calculo de impostos da baixa que esta sendo canelada
									// - A limpeza do IDs de retencao dos demais titulos que compuseram a retencao mas continuam baixados
									//Este trecho sera retirado em fase posterior (final da SE5)
									RecLock("SE5",.f.)
										SE5->E5_PRETPIS	:= "1"
										SE5->E5_PRETCOF	:= "1"
										SE5->E5_PRETCSL	:= "1"
									MsUnLock()

									SE5->(dbSkip())
								EndDo
							EndIf
							SE5->(dbGoto(nRecSE5))
							SE1->(DbSetOrder(1))

							While SFQ->(!Eof()) .And.;
								SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI) == cChaveSfq
								RecLock("SFQ",.f.)
									SFQ->(dbDelete())
								MsUnLock()
								SFQ->(DbSkip())
							End
						EndIf
	   	             	SE1->(dbGoTo(nSalvRec))
	   	 			Else
						cChaveSfq := SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)
						SFQ->(DbSetOrder(1)) // FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI
						SE1->(DbSetOrder(1)) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
						SE5->(dbSetOrder(7))
						If SFQ->(MsSeek(cChaveSfq))
							If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
								While SE1->(!eof()) .and. SFQ->(FQ_PREFORI+FQ_NUMORI) == SE1->(E1_PREFIXO+E1_NUM)
									If SE1->E1_PIS+SE1->E1_COFINS+SE1->E1_CSLL > 0
										RecLock("SE1",.f.)
											SE1->E1_PIS 	:= SE1->E1_PIS * nProp
											SE1->E1_COFINS 	:= SE1->E1_COFINS * nProp
											SE1->E1_CSLL	:= SE1->E1_CSLL * nProp
										MsUnLock()
									EndIf
									If SE1->E1_TIPO $ "PIS/COF/CSL/"
										RecLock("SE1",.f.)
											SE1->E1_VALOR 	:= SE1->E1_VALOR * nProp
											SE1->E1_VLCRUZ 	:= SE1->E1_VLCRUZ * nProp
										MsUnLock()
									EndIf
									SE1->(dbSkip())
								EndDo
			   	             	SE1->(dbGoTo(nSalvRec))
							Endif
							SE5->(dbSetOrder(7) )
							If SE5->(dbSeek(xFilial("SE5")+SFQ->FQ_PREFORI+SFQ->FQ_NUMORI+SFQ->FQ_PARCORI+SFQ->FQ_TIPOORI+SFQ->FQ_CFORI+SFQ->FQ_LOJAORI))
								While !eof() .and. SE5->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA) == SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)

									//REESTRUTURACAO SE5
									//Neste ponto a rotina apenas seta os valores de pendencias de retencao de impostos no SE5
									//Foi mantida dasta forma antiga pois, na atualização das FKs (Model) eh que ocorrera
									// - A exclusao da retenção na FK4
									// - A exclusao do calculo de impostos da baixa que esta sendo canelada
									// - A limpeza do IDs de retencao dos demais titulos que compuseram a retencao mas continuam baixados
									//Este trecho sera retirado em fase posterior (final da SE5)
									RecLock("SE5",.f.)
										SE5->E5_VRETPIS	:= SE5->E5_VRETPIS * nProp
										SE5->E5_VRETCOF	:= SE5->E5_VRETCOF * nProp
										SE5->E5_VRETCSL	:= SE5->E5_VRETCSL * nProp
									MsUnLock()
									SE5->(dbSkip())

								EndDo
							EndIf
							SE5->(dbGoto(nRecSE5))
							SE1->(DbSetOrder(1))

							While SFQ->(!Eof()) .And.;
								SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI) == cChaveSfq
								If SFQ->FQ_PREFDES+SFQ->FQ_NUMDES+SFQ->FQ_PARCDES+SFQ->FQ_TIPODES+SFQ->FQ_CFDES+SFQ->FQ_LOJADES ==;
								   SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA
									RecLock("SFQ",.f.)
										SFQ->(dbDelete())
									MsUnLock()
								EndIf
								SFQ->(DbSkip())
							EndDo
						EndIf
	   	             	SE1->(dbGoTo(nSalvRec))
   	  				EndIf
				EndIf
			EndIf
			SE5->(dbSetOrder(7) )
			SE5->(DbGoTo(nNextRec))
		Enddo
	Endif
Endif

RestArea(aAreaGrv)

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ F040ButNat º Autor ³ Gustavo Henrique   º Data ³ 16/06/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Salva ambiente para chamada da rotina de rateio multiplas  º±±
±±º          ³ naturezas.                                                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ EXPA1 - aCols jah declarado e utilizado para cheques       º±±
±±º          ³ EXPA2 - aHeader jah declarado e utilizado para cheques     º±±
±±º          ³ EXPA3 - aCols para multiplas naturezas                     º±±
±±º          ³ EXPA4 - aHeader para multiplas naturezas                   º±±
±±º          ³ EXPA5 - Vetor com os recnos do rateio multiplas naturezas  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040ButNat( aCols, aHeader, aColsMulNat, aHeadMulNat, aRegs )

Local aSavHeader := {}
Local aSavCols	 := {}

oTela := GetWndDefault()
oTela:CommitControls()

aSavHeader	:= AClone(aHeader)
aSavCols	:= AClone(aCols)
aCols   	:= AClone(aColsMulNat)
aHeader 	:= AClone(aHeadMulNat)

MultNat( "SE1",0,M->E1_VALOR,"",.F.,If(SE1->E1_LA != "S", 4, 2),;
			IF(mv_par04 == 1,0,((SE1->(E1_IRRF+E1_INSS+E1_PIS+E1_COFINS+E1_CSLL)) * -1)),;
			.T.,,, aRegs )

aColsMulNat	:= AClone(aCols)
aHeadMulNat	:= AClone(aHeader)
aCols   	:= AClone(aSavCols)
aHeader 	:= AClone(aSavHeader)

Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040AltRet  º Autor ³ Claudio Donizete   º Data ³ 10/08/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Altera o valor dos impostos do titulo atual e do retentor  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ cExp1 - Chave de relacionamento SFQ                        º±±
±±º          ³ nExp1 - Proporcao do imposto a ser alterado no retentor    º±±
±±º          ³ nExp2 - Identificacao do imposto (1=Pis,2=Cofins,3=Csll    º±±
±±º          ³ lExp1 - Identifica se o impostos sera excluidos            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040AltRet(cChaveSfq, nProp, nIdImposto,lExcluiImp)
Local aAreaSfq :=  SFQ->(GetArea())
Local aAreaSe1 :=  SE1->(GetArea())
Local aArea 	:= GetArea()
Local aRet		:= {,,,,,,,.F.}
Local nBaseImp := 0

//639.04 Base Impostos diferenciada
Local lBaseImp	 	:= F040BSIMP(2)	//Verifica a existência dos campos e o calculo de impostos

If lBaseImp .and. SE1->E1_BASEIRF == 0
	lBaseImp := .F.
Endif

Default lExcluiImp := .F.

SFQ->(DbSetOrder(2)) // FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES
// Verifica se este eh um titulo retido. Localizando pela chave 2 do SFQ e este titulo for encontrado, indica que ele eh um retido
If SFQ->(MsSeek(cChaveSfq)) // Altera titulo retentor
	// Pesquisa o titulo retentor do titulo retido para alterar os impostos nele tambem
	SE1->(DbSetOrder(1)) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI)))
		aRet := { SFQ->FQ_PREFORI, SFQ->FQ_NUMORI, SFQ->FQ_PARCORI, SFQ->FQ_TIPOORI, SFQ->FQ_CFORI, SFQ->FQ_LOJAORI, SE1->E1_NATUREZ, .F.}
		If SE1->E1_SALDO > 0 // Altera titulo retentor
			If lExcluiImp
				nBaseImp := IIF(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
				RecLock("SE1",.F.)
				// Gravo valor do imposto apenas do titulo atual
				If nIdImposto == 1 .Or. nIdImposto == 0
					SE1->E1_PIS		:= If(!GetNewPar("MV_RNDPIS",.F.), NoRound((nBaseImp * (Iif(SED->ED_PERCPIS>0,SED->ED_PERCPIS,GetMv("MV_TXPIS")) / 100)),2), (nBaseImp  * (Iif(SED->ED_PERCPIS>0,SED->ED_PERCPIS,GetMv("MV_TXPIS")) / 100)) )
					SE1->E1_SABTPIS:= SE1->E1_PIS
				Endif
				If nIdImposto == 2 .Or. nIdImposto == 0
					SE1->E1_COFINS := If(!GetNewPar("MV_RNDCOF",.F.), NoRound((nBaseImp * (Iif(SED->ED_PERCCOF>0,SED->ED_PERCCOF,GetMv("MV_TXCOFIN")) / 100)),2),(nBaseImp  * (Iif(SED->ED_PERCCOF>0,SED->ED_PERCCOF,GetMv("MV_TXCOFIN")) / 100)) )
					SE1->E1_SABTCOF:= SE1->E1_COFINS
				Endif
				If nIdImposto == 3 .Or. nIdImposto == 0
					SE1->E1_CSLL	:= If(!GetNewPar("MV_RNDCSL",.F.), NoRound((nBaseImp * (SED->ED_PERCCSL / 100)),2), (nBaseImp  * (SED->ED_PERCCSL / 100)))
					SE1->E1_SABTCSL:= SE1->E1_CSLL
				Endif
				MsUnlock()
			Else
				RecLock("SE1",.F.)
				If nIdImposto == 1 .Or. nIdImposto == 0
					SE1->E1_PIS		*= nProp
				Endif
				If nIdImposto == 2 .Or. nIdImposto == 0
					SE1->E1_COFINS *= nProp
				Endif
				If nIdImposto == 3 .Or. nIdImposto == 0
					SE1->E1_CSLL	*= nProp
				Endif
				MsUnlock()
			Endif
			// Altera valor do abatimento referente ao Pis
			If (nIdImposto == 1 .Or. nIdImposto == 0) .And. SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI)+MVPIABT))
				RecLock("SE1",.F.)
				If lExcluiImp
					DbDelete()
				Else
					SE1->E1_VALOR		*= nProp
					SE1->E1_SALDO		:= SE1->E1_VALOR
					If ( cPaisLoc == "CHI" )
						SE1->E1_VLCRUZ:= Round( SE1->E1_VALOR, MsDecimais(1) )
					Else
						SE1->E1_VLCRUZ:= SE1->E1_VALOR
					Endif
				Endif
				MsUnlock()
			Endif
			// Altera valor do abatimento referente ao Cofins
			If (nIdImposto == 2 .Or. nIdImposto == 0) .And. SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI)+MVCFABT))
				RecLock("SE1",.F.)
				If lExcluiImp
					DbDelete()
				Else
					SE1->E1_VALOR		*= nProp
					SE1->E1_SALDO		:= SE1->E1_VALOR
					If ( cPaisLoc == "CHI" )
						SE1->E1_VLCRUZ := Round( SE1->E1_VALOR, MsDecimais(1) )
					Else
						SE1->E1_VLCRUZ := SE1->E1_VALOR
					Endif
				Endif
				MsUnlock()
			Endif
			// Altera valor do abatimento referente ao Csll
			If (nIdImposto == 3 .Or. nIdImposto == 0) .And. SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI)+MVCSABT))
				RecLock("SE1",.F.)
				If lExcluiImp
					DbDelete()
				Else
					SE1->E1_VALOR		*= nProp
					SE1->E1_SALDO		:= SE1->E1_VALOR
					If ( cPaisLoc == "CHI" )
						SE1->E1_VLCRUZ := Round( SE1->E1_VALOR, MsDecimais(1) )
					Else
						SE1->E1_VLCRUZ := SE1->E1_VALOR
					Endif
				Endif
				MsUnlock()
			Endif
		Else
			aRet[8] := .T.
		Endif
	Endif
Endif

// Restaura o ambiente
SFQ->(RestArea(aAreaSfq))
SE1->(RestArea(aAreaSe1))
RestArea(aArea)

Return aRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040TotGrupoº Autor ³ Claudio Donizete   º Data ³ 03/08/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Totaliza os valores dos titulos que fazem parte do grupo   º±±
±±º          ³ de titulo que tiveram retencao de PCC                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ cExp1 - Chave de relacionamento com SFQ                    º±±
±±º          ³ nExp1 - Mes do periodo                                     º±±
±±º          ³ nExp2 - Ano do periodo                                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040TotGrupo(cChaveSfq, cAnoMes)
Local aAreaSfq :=  SFQ->(GetArea())
Local aAreaSe1 :=  SE1->(GetArea())
Local aArea 	:= GetArea()
Local nRet 		:= 0
//639.04 Base Impostos diferenciada
Local lBaseImp	 	:= F040BSIMP(2)	//Verifica a existência dos campos e o calculo de impostos

If lBaseImp .AND. (SE1->E1_BASEIRF + SE1->E1_BASEPIS + SE1->E1_BASECOF + SE1->E1_BASECSL) == 0
	lBaseImp := .F.
Endif

SFQ->(DbSetOrder(1)) // FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI
SE1->(DbSetOrder(1)) // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
If SFQ->(MsSeek(cChaveSfq)) // Se chavar pela ordem 1, indica que eh o titulo retentor
	// Soma os titulos da origem
	nRet += If(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
	SE1->(DbSetOrder(1))
	While SFQ->(!Eof()) .And.;
			SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI) == cChaveSfq
		If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES))) .And. ;
			Left(Dtos(SE1->E1_VENCREA),6) == cAnoMes

			nRet += If(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
		Endif
		SFQ->(DbSkip())
	End
Else
	SFQ->(DbSetOrder(2)) // FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES
	If SFQ->(MsSeek(cChaveSfq)) // Se chavar pela ordem 2, indica que eh o titulo retido
	    cChaveSfq := SFQ->(FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES)
		nRet += If(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
		SFQ->(DbSetOrder(1)) // FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI
		cChaveSfq := SFQ->(FQ_FILIAL+FQ_ENTORI+FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI+FQ_CFORI+FQ_LOJAORI)

		If SFQ->(MsSeek(cChaveSfq))
			If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFORI+FQ_NUMORI+FQ_PARCORI+FQ_TIPOORI))) .And. ;
				Left(Dtos(SE1->E1_VENCREA),6) == cAnoMes

				nRet += If(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
			Endif
			While SFQ->(!Eof()) .And.;
		  		SFQ->(FQ_FILIAL+FQ_ENTDES+FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES+FQ_CFDES+FQ_LOJADES) == cChaveSfq
				If SE1->(MsSeek(xFilial("SE1")+SFQ->(FQ_PREFDES+FQ_NUMDES+FQ_PARCDES+FQ_TIPODES))) .And. ;
					Left(Dtos(SE1->E1_VENCREA),6) == cAnoMes

					nRet += If(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR)
				Endif
				SFQ->(DbSkip())
			End
		Endif
	Else
		nRet += If(lBaseImp .AND. SE1->E1_BASEIRF > 0,SE1->E1_BASEIRF,SE1->E1_VALOR) // Se nao tiver amarracao com SFQ, o total do grupo serah o valor do proprio titulo
	Endif
Endif
// Restaura o ambiente
SFQ->(RestArea(aAreaSfq))
SE1->(RestArea(aAreaSe1))
RestArea(aArea)

Return nRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³GeraDDINCC  º Autor ³ Claudio Donizete   º Data ³ 10/08/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Gera titulo DDI (diferenca de imposto)                     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ cExp1 - Prefixo do titulo a ser gerado                     º±±
±±º          ³ cExp2 - Numero do titulo a ser gerado                      º±±
±±º          ³ cExp3 - Parcela do titulo a ser gerado                     º±±
±±º          ³ cExp4 - Tipo do titulo ser gerado                          º±±
±±º          ³ cExp5 - Codigo do cliente do titulo a ser gerado           º±±
±±º          ³ cExp6 - Codigo da loja do titulo a ser gerado              º±±
±±º          ³ cExp7 - Natureza do titulo a ser gerado                    º±±
±±º          ³ nExp1 - Valor do titulo a ser gerado                       º±±
±±º          ³ dExp1 - Emissao do titulo a ser gerado                     º±±
±±º          ³ dExp2 - Vencimento do titulo a ser gerado                  º±±
±±º          ³ cExp8 - Origem do titulo a ser gerado                      º±±
±±º          ³ lExp1 - Parcel do titulo a ser gerado                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function GeraDDINCC(	cPrefixo, cNum, cParcela, cTipo, cCliente, cLoja, cNaturez, nValorDDI, dEmissao, dVencto, cOrigem, lRotAuto )
Local aTitulo
Local aAreaSe1	:= SE1->(GetArea())
Local aArea 	:= GetArea()
Local lRet		:= .T.

Default lRotAuto := .F.

	SaveInter()
	aTitulo := {	{"E1_PREFIXO"	, cPrefixo	, nil },;
						{"E1_NUM"		, cNum		, nil },;
						{"E1_PARCELA"	, cParcela	, nil },;
						{"E1_TIPO"		, cTipo		, nil },;
						{"E1_NATUREZ"	, cNaturez	, nil },;
						{"E1_CLIENTE"	, cCliente	, nil },;
						{"E1_LOJA"		, cLoja		, nil },;
						{"E1_EMISSAO"	, dEmissao	, nil },;
						{"E1_VENCTO"	, dVencto	, nil },;
						{"E1_VALOR"		, nValorDDI	, nil },;
						{"E1_SALDO"		, nValorDDI	, nil },;
						{"E1_ORIGEM"	, cOrigem	, nil } }

	lMsErroAuto := .F.
	MSExecAuto({|x,y| FINA040(x,y)},aTitulo,3)

	If lMsErroAuto
		If !lRotAuto
			Aviso("FINA040",STR0101+ " (" + cTipo +"). " + STR0102,{"Ok"}) // "Erro na inclusão do titulo de diferença de imposto"##"Maiores detalhes serão exibidos em seguida"
		Endif
		MostraErro()
		lRet := .F.
		If SE1->(InTransact())
			DisarmTransaction()
		Endif
	Endif

	RestInter()

	SE1->(RestArea(aAreaSe1))
	RestArea(aArea)

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040AltImp  º Autor ³ Claudio Donizete   º Data ³ 10/08/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Altera o valor dos impostos do titulo atual e do retentor  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ nExp1 - Identificacao do imposto (1=Pis,2=Cofins,3=Csll    º±±
±±º          ³ nExp2 - Valor do imposto                                   º±±
±±º          ³ lExp1 - Identifica se zerou os impostos (referencia)       º±±
±±º          ³ nExp3 - Proporcao do imposto a ser alterado no retentor    º±±
±±º          ³ nExp4 - Valor antigo do imposto (referencia)               º±±
±±º          ³ lExp2 - Identifica se o retentor esta baixado (referencia) º±±
±±º          ³ nExp5 - Valor total do grupo de titulos que fazem parte do º±±
±±º          ³ 		  do retentor                                        º±±
±±º          ³ nExp6 - Valor minimo para retencao								  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040AltImp(nIdImp,nValorImp,lZerouImp, nProp, nOldImp, lRetBaixado, nTotGrupo, nValMinRet, aDadRet, cRetCli, cModRet)
Local cAbtImp
Local aAreaSfq := SFQ->(GetArea())
Local aAreaSe1 := SE1->(GetArea())
Local nRegSe1 := SE1->(Recno())
Local lBaseImp	:= F040BSIMP(2)
Local cNatOri	:= SE1->E1_NATUREZ

	Do Case
	Case nIdImp == 1
		cIdPco	:= "10"
		cAbtImp	:= MVPIABT
	Case nIdImp == 2
		cIdPco := "09"
		cAbtImp	:= MVCFABT
	Case nIdImp == 3
		cIdPco := "11"
		cAbtImp	:= MVCSABT
	Case nIdImp == 4
		cIdPco := "12"
		cAbtImp	:= MVIRABT
	EndCase

	SE1->(DbSetOrder(1))

	If SE1->(DbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+cAbtImp))
		If nValorImp != 0
			If SE1->E1_FLUXO == 'S'
				AtuSldNat(cNatOri, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),4)
			Endif
			Reclock("SE1")
			SE1->E1_VALOR := nValorImp
			SE1->E1_SALDO := nValorImp
			SE1->E1_SALDO := nValorImp
			If SE1->E1_FLUXO == 'S'
				// Movimenta o valor do imposto na natureza do titulo principal
				AtuSldNat(cNatOri, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),4)
			Endif
			If ( cPaisLoc == "CHI" )
				SE1->E1_VLCRUZ:= Round( nValorImp, MsDecimais(1) )
			Else
				SE1->E1_VLCRUZ:= nValorImp
			Endif
			PcoDetLan("000001",cIdPco,"FINA040")	// Altera lançamento no PCO ref. a retencao de COFINS
		Else
			PcoDetLan("000001",cIdPco,"FINA040",.T.)	// Apaga lançamento no PCO ref. a retencao de COFINS
			If  SE1->E1_FLUXO == 'S'
				AtuSldNat(cNatOri, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),4)
			Endif
			Reclock("SE1",.F.,.T.)
			dbDelete()
			lZerouImp := .T.
		Endif
		Msunlock()
	Else
		If cRetCli == "1" .And. cModRet == "2"
			SE1->(dbGoto(nRegSe1))
			cCondImp := If(lBaseImp .and. SE1->E1_BASEIRF > 0, "nOldBase != SE1->E1_BASEIRF","nOldValor != SE1->E1_VALOR")

			If &cCondImp .Or. Left(Dtos(SE1->E1_VENCREA),6) != Left(Dtos(nOldVenRea),6)
				SFQ->(DbSetOrder(1))
				If ! SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
					SFQ->(DbSetOrder(2))
					If ! SFQ->(MsSeek(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA)))
						nOldImp := 0
					Else
						// Altera Valor dos abatimentos do titulo retentor e tambem dos titulos gerados por ele.
						aDadRet := F040AltRet(xFilial("SFQ")+"SE1"+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA),nProp,nIdImp,nTotGrupo <= nValMinRet) // Altera titulo retentor
						lRetBaixado := aDadRet[8]
						If !lRetBaixado
							If nTotGrupo <= nValMinRet
								lZerouImp := .T.
								nOldImp := 0
							Endif
						Endif
					Endif
				Endif
			Endif
		Endif
	Endif

	SFQ->(RestArea(aAreaSfq))
	SE1->(RestArea(aAreaSe1))

Return Nil

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040CriaImp º Autor ³ Claudio Donizete   º Data ³ 12/08/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Cria os titulos de abatimento dos impostos                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ nExp1 - Identificacao do imposto (1=Pis,2=Cofins,3=Csll)   º±±
±±º          ³ nExp2 - Valor do imposto                                   º±±
±±º          ³ dExp1 - Data de emissao do imposto                         º±±
±±º          ³ dExp2 - Data de vencimento original do imposto			     º±±
±±º          ³ cExp1 - Prefixo do titulo a ser criado                     º±±
±±º          ³ cExp2 - Numero do titulo a ser criado                      º±±
±±º          ³ cExp3 - Parcela do titulo a ser criado                     º±±
±±º          ³ cExp4 - Codigo do cliente do titulo a ser criado           º±±
±±º          ³ cExp5 - Codigo da loja do titulo a ser criado              º±±
±±º          ³ cExp6 - Nome reduzido do cliente                           º±±
±±º          ³ cExp7 - Origem do titulo (opcional)                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040CriaImp(nIdImp, nValorImp, dEmissao, dVencto, cPrefixo, cNum, cParcela, cCliente, cLoja, cNomeReduz, cOrigem,cTPTIT)
Local cNatureza
Local dVencImp
Local dVencRea
Local cDescNat
Local aAreaSe1 := SE1->(GetArea())
Local aAreaSeD := SED->(GetArea())
Local cNatOri	:= SE1->E1_NATUREZ


Default cOrigem := ""
Default cTPTIT	:= ""
	Do Case
	Case nIdImp == 1
		cIdPco	:= "10"
		cAbtImp	:= MVPIABT
		cDescNat := "PIS"
		cNatureza := Alltrim(SuperGetMv("MV_PISNAT"))
	Case nIdImp == 2
		cIdPco := "09"
		cAbtImp	:= MVCFABT
		cDescNat := "COFINS"
		cNatureza := Alltrim(SuperGetMv("MV_COFINS"))
	Case nIdImp == 3
		cIdPco := "11"
		cAbtImp	:= MVCSABT
		cDescNat := "CSLL"
		cNatureza := Alltrim(SuperGetMv("MV_CSLL"))
	Case nIdImp == 4
		cIdPco := "12"
		cAbtImp	:= MVIRABT
		cDescNat := "IRRF"
		cNatureza := Alltrim(&(SuperGetMv("MV_IRF")))
	EndCase
	cNatureza := cNatureza + Space(10-Len(cNatureza))
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Cria a natureza do IMPOSTO caso nao exista ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SED->(DbSetOrder(1))
	If SED->(!(DbSeek(xFilial("SED")+cNatureza)))
		RecLock("SED",.T.)
		SED->ED_FILIAL  := xFilial("SED")
		SED->ED_CODIGO  := cNatureza
		SED->ED_CALCIRF := "N"
		SED->ED_CALCISS := "N"
		SED->ED_CALCINS := "N"
		SED->ED_CALCCSL := "N"
		SED->ED_CALCCOF := "N"
		SED->ED_CALCPIS := "N"
		SED->ED_DESCRIC := cDescNat
		SED->ED_TIPO	:= "2"
		Msunlock()
		FKCommit()
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gera titulo abatimento de Imposto ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dVencImp := dVencto
	dVencRea := DataValida(dVencImp,.F.)
	If dEmissao >= dLastPcc
		dVencRea := F050VImp("PIS",dEmissao,dDataBase,) // Calcula o vencimento do imposto
	Else
		dVencRea := DataValida(dVencImp,.F.)
	EndIf
	SE1->(DbSetOrder(1))
	cTitPai		:= cPrefixo+cNum+cParcela+cTPTIT+cCliente+cLoja
	If ! SE1->(MsSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+cAbtImp))
		RecLock("SE1",.T.)
		SE1->E1_FILIAL  := xFilial("SE1")
		SE1->E1_PREFIXO := cPrefixo
		SE1->E1_NUM		 := cNum
		SE1->E1_PARCELA := cParcela
		SE1->E1_TIPO	 := cAbtImp
		SE1->E1_EMISSAO := dEmissao
		SE1->E1_VENCORI := dVencto
		SE1->E1_VENCTO  := dVencRea
		SE1->E1_VENCREA := dVencRea
		SE1->E1_CLIENTE := cCliente
		SE1->E1_LOJA	 := cLoja
		SE1->E1_NOMCLI  := cNomeReduz
		SE1->E1_MOEDA   := 1
		SE1->E1_NATUREZ := cNatureza
		SE1->E1_SITUACA := "0"
		SE1->E1_OCORREN := "04"
		SE1->E1_EMIS1   := dDataBase
		SE1->E1_ORIGEM  := IIf(Empty(cOrigem),"FINA040",cOrigem)
		SE1->E1_TITPAI  := cTitPai
		SE1->E1_FILORIG := xFilial("SE1")
	Else
		If  SE1->E1_FLUXO == 'S'
			AtuSldNat(cNatOri, dVencRea, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "+",,FunName(),"SE1",SE1->(Recno()),0)
		Endif
		RecLock("SE1",.F.)
	Endif
	SE1->E1_VALOR   := nValorImp
	SE1->E1_SALDO   := nValorImp
	If  SE1->E1_FLUXO == 'S'
		// Movimenta o valor do imposto na natureza do titulo principal
		AtuSldNat(cNatOri, dVencRea, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),0)
	Endif
	If ( cPaisLoc == "CHI" )
		SE1->E1_VLCRUZ  := Round( nValorImp, MsDecimais(1) )
	Else
		SE1->E1_VLCRUZ  := nValorImp
	Endif
	If AllTrim(E1_ORIGEM) $ 'S|L|T' .And. E1_SALDO == 0 .And. E1_VALOR == 0
		SE1->E1_STATUS := "A"
	Else
		SE1->E1_STATUS := Iif(E1_SALDO >= 0.01,"A","B")
	EndIf

	Msunlock()
	PcoDetLan("000001",cIdPco,"FINA040")	// Altera lançamento no PCO ref. a retencao de IMPOSTO

	SED->(RestArea(aAreaSed))
	SE1->(RestArea(aAreaSe1))

Return nil

Static Function RetTotGrupo
Return nSomaGrupo

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  F040RecalcMesº Autor ³ Claudio Donizete   º Data ³ 24/08/09  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Recalculo os impostos quando a base do mes for menor que o º±±
±±º			 ³ valor minimo de retencao											  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ dExp1 - Data de referencia											  º±±
±±º          ³ nExp1 - Valor minimo de retencao                           º±±
±±º          ³ cExp1 - Codigo do Cliente de referencia   			   	  º±±
±±º          ³ cExp2 - Loja do Cliente de referencia							  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Contas a Receber                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040RecalcMes(dReferencia, nValMinRet, cCliente, cLoja ,lVldChave , lConsRecno)
Local aAreaSE1  := SE1->( GetArea() )
Local aAreaSfq  := SFQ->(GetArea())
Local aRecnos   := {}
Local dIniMes   := FirstDay( dReferencia )
Local dFimMes   := LastDay( dReferencia )
Local cModTot   := GetNewPar( "MV_MT10925", "1" )
Local lAbatIRF  := SE1->( FieldPos( "E1_SABTIRF" ) ) > 0
Local lTodasFil	:= ExistBlock("F040FRT")
Local aFil10925	:= {}
Local cFilAtu	:= FWGETCODFILIAL
Local lVerCliLj	:= ExistBlock("F040LOJA")
Local aCli10925	:= {}
Local nFil 			:= 0
Local lLojaAtu  := ( GetNewPar( "MV_LJ10925", "1" ) == "1" )
Local nLoop     := 0
Local cPrefixo
Local cNum
Local cParcela
Local nTotMes := 0
Local aTab := {}
Local lNewRetentor := .F.
Local cModRetIRF 	:= GetNewPar("MV_IRMP232", "0" )
Local cNccRet  := SuperGetMv("MV_NCCRET",.F.,"1")
Local nTotARet := 0
Local nValorTit:= 0
Local nSobra	:= 0
Local nFatorRed:= 0
Local nDiFerImp:= 0
Local lDescISS := IIF(SA1->A1_RECISS == "1" .And. GetNewPar("MV_DESCISS",.F.),.T.,.F.)
Local lMinOK	:= .F.
Local nRecSE1	:= 0
Local nVlrDif	:= 0
Local nIndexSE1, cIndexSE1

Local aStruct   := {}
Local aCampos   := {}
Local cQuery    := ""
Local cAliasQry := ""
Local cSepNeg   := If("|"$MV_CRNEG,"|",",")
Local cSepProv  := If("|"$MVPROVIS,"|",",")
Local cSepRec   := If("|"$MVRECANT,"|",",")

Local nSavRec

//639.04 Base Impostos diferenciada
Local lBaseImp	:= F040BSIMP()
Local cChave := ""
Local lSabtPis := .F.
Local lSabtCof := .F.
Local lSabtCsl := .F.
Local nValBase	:= 0
Local lContinua:= .F.
Local lFinanc	:= "FIN" $ FUNNAME()

//--- Tratamento Gestao Corporativa
Local lGestao   := FWSizeFilial() > 2	// Indica se usa Gestao Corporativa
Local lSE1Comp  := FWModeAccess("SE1",3)== "C" // Verifica se SE1 é compartilhada
Local aFilAux	  := {}

DEFAULT lVldChave := .F.
DEFAULT lConsRecno:= .T.

// cChave será necessaria somente na exclusao de titulo retentor de PCC para que o calculo fique correto dos demais titulos retentores apos a exclusao
// Somente será .T. na função Fa040Delet(), ao final das validações e exclusoes.
IF lVldChave
	cChave := SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_CLIENTE+E1_LOJA)
Endif
nRecSE1 := SE1->(RECNO())

SE1->(DBGOTO(nRecSE1))
If lTodasFil
	aFil10925 := ExecBlock( "F040FRT", .F., .F. )
Else
	aFil10925 := { cFilAnt }
Endif

If lVerCliLj
	aCli10925 := ExecBlock("F040LOJA",.F.,.F.)
Endif

// Salvo ambiente anterior
SaveInter()

lRecalcMes := .T.

If !lFinanc
	RegToMemory("SE1",.T.,.F.)
EndIf

For nFil := 1 to Len(aFil10925)

   dbSelectArea("SE1")
	cFilAnt := aFil10925[nFil]

	//Se SE1 for compartilhada e ja passou pela mesma Empresa e Unidade, pula para a proxima filial
	If lGestao .and. lSE1Comp .and. Ascan(aFilAux, {|x| x == xFilial("SE1")}) > 0
		Loop
	EndIf

	aCampos := { "E1_VALOR","E1_PIS","E1_COFINS","E1_CSLL","E1_IRF","E1_SABTPIS","E1_SABTCOF","E1_SABTCSL","E1_SABTIRF","E1_MOEDA","E1_VENCREA"}
	aStruct := SE1->( dbStruct() )

	SE1->( dbCommit() )

	cAliasQry := GetNextAlias()

	cQuery	:= "SELECT E1_VALOR,E1_PIS,E1_COFINS,E1_CSLL,E1_IRRF,E1_SABTPIS,E1_SABTCOF,E1_SABTCSL, "
	cQuery	+=	"E1_PREFIXO,E1_NUM,E1_PARCELA,E1_TIPO,E1_CLIENTE,E1_LOJA,E1_NATUREZ,E1_MOEDA,E1_FATURA,E1_VENCREA, "

	If lAbatIrf
		cQuery 	+= 	"E1_SABTIRF , "
	Endif

	cQuery += "	R_E_C_N_O_ RECNO FROM "
	cQuery += RetSqlName( "SE1" ) + " SE1 "
	cQuery += "WHERE "
	cQuery += "E1_FILIAL='"    + xFilial("SE1")       + "' AND "

	If Len(aCli10925) > 0	//Verifico quais clientes e loja considerar (raiz do CNPJ)
		cQuery += "("
		For nLoop := 1 to Len(aCli10925)
			cQuery += "(E1_CLIENTE='"   + aCli10925[nLoop,1]  + "' AND "
			cQuery += "E1_LOJA='"      + aCli10925[nLoop,2]  + "') OR  "
		Next
		//Retiro o ultimo OR
		cQuery := Left( cQuery, Len( cQuery ) - 4 )
		cQuery += ") AND "
	Else
		//Considero apenas o cliente atual
		cQuery += "E1_CLIENTE='"   + cCliente             + "' AND "
		If lLojaAtu  //Considero apenas a loja atual
			cQuery += "E1_LOJA='"      + cLoja             + "' AND "
		Endif
	Endif

	cQuery += "E1_VENCREA>= '" + DToS( dIniMes )      + "' AND "
	cQuery += "E1_VENCREA<= '" + DToS( dFimMes )      + "' AND "
	cQuery += "E1_VALOR = E1_SALDO AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepNeg)  + " AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv) + " AND "
	cQuery += "E1_TIPO NOT IN " + FormatIn(MVRECANT,cSepRec)  + " AND "

	//-- Tratamento para titulos baixados por Cancelamento de Fatura
	//-- ou Pré Faturamento de Serviços (SIGAPFS)
	If nModulo = 77
		cQuery += " NOT EXISTS (SELECT E5_FILIAL "
		cQuery += "					FROM " + RetSqlName("SE5") + " SE5 "
		cQuery += "					WHERE SE5.E5_FILIAL = '" + xFilial("SE5") + "' "
		cQuery += "					AND SE5.E5_TIPO     = SE1.E1_TIPO "
		cQuery += "					AND SE5.E5_PREFIXO  = SE1.E1_PREFIXO "
		cQuery += "					AND SE5.E5_NUMERO   = SE1.E1_NUM "
		cQuery += "					AND SE5.E5_PARCELA  = SE1.E1_PARCELA  "
		cQuery += "					AND SE5.E5_CLIFOR   = SE1.E1_CLIENTE "
		cQuery += "					AND SE5.E5_LOJA     = SE1.E1_LOJA "
		cQuery += "					AND SE5.E5_MOTBX    = 'CNF' "
		cQuery += "					AND SE5.D_E_L_E_T_  = ' ') AND "
	EndIf
	cQuery += "(E1_FATURA = '"+Space(Len(E1_FATURA))+"' OR "
	cQuery += "E1_FATURA = 'NOTFAT') AND "
	IF lConsRecno
		cQuery += "R_E_C_N_O_ > "+STR(nRecSE1)+" AND "
	Endif

	//Verificar ou nao o limite de 5000 para Pis cofins Csll
	// 1 = Verifica o valor minimo de retencao
	// 2 = Nao verifica o valor minimo de retencao

	cQuery += "E1_APLVLMN <> '2' AND "
	cQuery += "D_E_L_E_T_=' '"
	cQuery += " ORDER BY RECNO "

	cQuery := ChangeQuery( cQuery )

	dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), cAliasQry, .F., .T. )

	For nLoop := 1 To Len( aStruct )
		If !Empty( AScan( aCampos, AllTrim( aStruct[nLoop,1] ) ) )
			TcSetField( cAliasQry, aStruct[nLoop,1], aStruct[nLoop,2],aStruct[nLoop,3],aStruct[nLoop,4])
		EndIf
	Next nLop

	( cAliasQRY )->(DBGOTOP())

	While !( cAliasQRY )->( Eof())
		SE1->(MsGoto((cAliasQRY)->Recno))
		If SE1->E1_VALOR == SE1->E1_SALDO .And. (IIF(lVldChave, cChave <> ( cAliasQRY )->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_CLIENTE+E1_LOJA) , .T.)) .And.;
			(cModTot == "1" .Or. ( !Empty( ( cAliasQRY )->(E1_PIS+E1_COFINS + E1_CSLL+E1_IRRF) ) ) )

			aTab := {}
			// Exclui os impostos, caso eles ja existam
			AADD(aTab,{( cAliasQRY )->E1_PIS		, MVPIABT, "MV_PISNAT"})
			AADD(aTab,{( cAliasQRY )->E1_COFINS	, MVCFABT, "MV_COFINS"})
			AADD(aTab,{( cAliasQRY )->E1_CSLL	, MVCSABT, "MV_CSLL"})
			cPrefixo := SE1->E1_PREFIXO
			cNum		:= SE1->E1_NUM
			cParcela	:= SE1->E1_PARCELA
			For nLoop := 1 to Len(aTab)
				If aTab[nLoop,1] != 0
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Apaga tambem os registro de impostos		  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					SE1->(dbSetOrder(1))
					// Procura o abatimento do imposto do titulo e exclui
					If SE1->(MsSeek(xFilial("SE1")+cPrefixo+cNum+cParcela+aTab[nLoop,2])) .And.;
						AllTrim(SE1->E1_NATUREZ) == GetMv(aTab[nLoop,3])
						RecLock( "SE1" ,.F.,.T.)
						dbDelete( )
					EndIf
				EndIf
			Next
			SE1->(MsGoto((cAliasQRY)->Recno))
			nTotMes += Iif(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR)
			// Se o total do mes for menor ou igual ao valor minimo re retencao,	// calculo o imposto apenas do titulo atual
			IF !lMinOK .and. (SA1->A1_RECPIS $ "S#P" .or. SA1->A1_RECCSLL $ "S#P" .or. SA1->A1_RECCOFI $ "S#P")
				If cModTot == "1"
					lMinOK := (F040TotMes(SE1->E1_VENCREA,@nIndexSE1,@cIndexSE1)[1] - ;
									Iif(lBaseImp .and. M->E1_BASEIRF > 0, M->E1_BASEIRF, M->E1_VALOR));
																													> 5000
				ElseIf cModTot == "2"
					nVlrDif	:=	(F040TotMes(SE1->E1_VENCREA,@nIndexSE1,@cIndexSE1)[1] - ;
									Iif(lBaseImp .and. M->E1_BASEIRF > 0, M->E1_BASEIRF, M->E1_VALOR))
					lMinOK 	:= nVlrDif > 0
					nTotMes 	+=	nVlrDif
				Endif
			Endif
			If nTotMes <= nValMinRet .AND. !lMinOK
				AAdd( aRecnos, ( cAliasQRY )->RECNO )
				// Se for um titulo retentor, recalculo os impostos
				FaAvalSE1(4,lVldChave)
			Else
				// Atingiu o valor minimo, crio o titulo retentor e abandono o processamento
				lNewRetentor := .T.
				SA1->(DbSetORder(1))
				SA1->(MsSeek(xFilial("SED")+SE1->(E1_CLIENTE+E1_LOJA)))
				SED->(DbSetORder(1))
				SED->(MsSeek(xFilial("SED")+SE1->E1_NATUREZ))
				cPrefOri  := SE1->E1_PREFIXO
				cNumOri   := SE1->E1_NUM
				cParcOri  := SE1->E1_PARCELA
				cTipoOri  := SE1->E1_TIPO
				cCfOri    := SE1->E1_CLIENTE
				cLojaOri  := SE1->E1_LOJA
				nValBase := Iif(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR)
				dbSelectArea("SFQ")
				dbSetOrder(2)
				If DbSeek(xFilial("SFQ")+"SE1"+cPrefOri+cNumOri+cParcOri+cTipoOri+cCfOri+cLojaOri)
					lContinua := .T. //nTotMes -= Iif(lBaseImp .and. SE1->E1_BASEIRF > 0, SE1->E1_BASEIRF, SE1->E1_VALOR)
				Endif
				If !(lSabtPis .OR. lSabtCof .OR. lSabtCsl) //verifica se o valor para calculo de PCC devera considerar somente o titulo ou a o anterior tb
					nValorPis	 := Round(nTotMes * (SED->ED_PERCPIS/100),TamSx3("E1_VALOR")[2])
					nValorCofins := Round(nTotMes * (SED->ED_PERCCOF/100),TamSx3("E1_VALOR")[2])
					nValorCsll 	 := Round(nTotMes * (SED->ED_PERCCSL/100),TamSx3("E1_VALOR")[2])
				Else
					If lSabtPis
						nValorPis	 := Round(nTotMes * (SED->ED_PERCPIS/100),TamSx3("E1_VALOR")[2])
					Else
						nValorPis	 := Round(nValBase * (SED->ED_PERCPIS/100),TamSx3("E1_VALOR")[2])
					Endif
					If lSabtCof
						nValorCofins := Round(nTotMes* (SED->ED_PERCCOF/100),TamSx3("E1_VALOR")[2])
					Else
						nValorCofins := Round(nValBase* (SED->ED_PERCCOF/100),TamSx3("E1_VALOR")[2])
					Endif
					If lSabtCsl
						nValorCsll 	 := Round(nTotMes * (SED->ED_PERCCSL/100),TamSx3("E1_VALOR")[2])
					Else
						nValorCsll 	 := Round(nValBase * (SED->ED_PERCCSL/100),TamSx3("E1_VALOR")[2])
					Endif
				Endif

              // Validação do novo valor de PCC a ser gerado para o titulo escolhido como GERADOR
				nTotARet := nValorPis + nValorCofins + nValorCsll
				nValorTit := SE1->(E1_VALOR-E1_IRRF-E1_INSS-If(lDescIss,E1_ISS,0))
				nSobra := nValorTit - nTotARet
				If nSobra < 0
					nFatorRed := 1 - ( Abs( nSobra ) / nTotARet )

					nValorPis  	:= NoRound( nValorPis * nFatorRed, 2 )
					nValorCofins:= NoRound( nValorCofins * nFatorRed, 2 )
					nValorCsll 	:= nValorTit - ( nValorPis + nValorCofins)

					nDiFerImp := nTotARet - (nValorPis + nValorCofins + nValorCsll)

					If cNccRet == "1"
						ADupCredRt(nDiferImp,"001",SE1->E1_MOEDA,.T.)
					Endif
				EndIf

				If nValorPis <= SuperGetMV("MV_VRETPIS")
					nValorPis	:= 0
					lSabtPis := .T. // indica se devemos considerar o valor deste titulo acumulado para o proximo do while, pois ficou pendente a retenção de PIS
				Else
					F040CriaImp(1, nValorPis, SE1->E1_EMISSAO, SE1->E1_VENCREA, SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_CLIENTE, SE1->E1_LOJA, SA1->A1_NREDUZ, SE1->E1_ORIGEM)
				Endif
				If nValorCofins <= SuperGetMV("MV_VRETCOF")
					nValorCofins:= 0
					lSabtCof := .T. // indica se devemos considerar o valor deste titulo acumulado para o proximo do while, pois ficou pendente a retenção de COFINS
				Else
					F040CriaImp(2, nValorCofins, SE1->E1_EMISSAO, SE1->E1_VENCREA, SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_CLIENTE, SE1->E1_LOJA, SA1->A1_NREDUZ, SE1->E1_ORIGEM)
				Endif
				If nValorCsll <= SuperGetMV("MV_VRETCSL")
					nValorCsll	:= 0
					lSabtCsl := .T. // indica se devemos considerar o valor deste titulo acumulado para o proximo do while, pois ficou pendente a retenção de CSLL
				Else
					F040CriaImp(3, nValorCsll, SE1->E1_EMISSAO, SE1->E1_VENCREA, SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_CLIENTE, SE1->E1_LOJA, SA1->A1_NREDUZ, SE1->E1_ORIGEM)
				Endif
				lMinOK 	:= .T.
				IF !(lSabtPis .OR. lSabtCof .OR. lSabtCsl)
					nTotMes	:= 0
				Endif
				IF !lContinua
					Exit
				Endif
			Endif
		Endif
		(cAliasQRY)->( dbSkip())
	EndDo

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Fecha a area de trabalho da query                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	( cAliasQRY )->( dbCloseArea() )
	dbSelectArea( "SE1" )

	//Se Filial for totalmente compartilhada, faz somente 1 vez
	If Empty(xFilial("SE1"))
		Exit
	ElseIf lGestao .and. lSE1Comp
		AAdd(aFilAux, xFilial("SE1"))
	EndIf

Next

If lNewRetentor
	For nLoop := 1 to Len( aRecnos )

		SE1->( dbGoto( aRecnos[ nLoop ] ) )

		FImpCriaSFQ("SE1", cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
						"SE1", SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, SE1->E1_TIPO, SE1->E1_CLIENTE, SE1->E1_LOJA,;
						SE1->E1_SABTPIS, SE1->E1_SABTCOF, SE1->E1_SABTCSL,;
						If( FieldPos('FQ_SABTIRF') > 0 .And. lAbatIRF .And. cModretIRF =="1", SE1->E1_SABTIRF, 0),;
						SE1->E1_FILIAL )

		RecLock( "SE1", .F. )
		SE1->E1_SABTPIS := 0
		SE1->E1_SABTCOF := 0
		SE1->E1_SABTCSL := 0
		If lAbatIRF .And. cModRetIRF == "1"
			SE1->E1_SABTIRF := 0
		Endif

		SE1->( MsUnlock() )

	Next nLoop
Endif

RestInter()

cFilAnt := cFilAtu

SE1->( RestArea( aAreaSE1 ) )
SFQ->(RestArea(aAreaSfq))

Return Nil

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040GetNTiºAutor  ³Alberto Deviciente  º Data ³ 13/Jun/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Esta funcao tem por objetivo buscar o codigo sequencial p/ oº±±
±±º          ³No. Titulo utilizando a tabela de controle do RM Classis Netº±±
±±º          ³para que nao seja gerado codigo duplicado entre os sistemas.º±±
±±º          ³Neste caso nao sera considerado o controle de numeracao     º±±
±±º          ³para o titulo utilizando o SXE e SXF e sim a tabela do      º±±
±±º          ³CLASSIS.NET                                                 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao - Protheus x RM Classis Net (RM Sistemas)       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function F040GetNTi()
Local lOk   		:= .T.
Local nIdLan 		:= 0
Local cAlias 		:= GetNextAlias()
Local cQuery 		:= ""
Local cIdLan  		:= Space(TamSX3("E1_NUM")[1])
Local aArea			:= getArea()
Local lExiste		:= .T.
Local nI			:= 0
Local lLinkOk    	:= .F.
Local nAmbTOP		:= 0
Local nAmbCLASSIS 	:= 0


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Monta as conexoes com as bases de dados Protheus e CorporeRm via TopConnect³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
lLinkOk := _IntRMTpCon(@nAmbTOP,@nAmbCLASSIS)

if lLinkOk

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Alterna o TOP para o ambiente do RM Classis Net (RM Sistemas)³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	TCSetConn( nAmbCLASSIS )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Verifica se existe no banco de dados a tabela GAUTOINC. ³
	//³Se Existir, coleta o valor atual e soma 1 no final.     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	if TCCanOpen("GAUTOINC")
		cQuery := "SELECT VALAUTOINC FROM GAUTOINC "
		cQuery += " WHERE CODCOLIGADA = " + alltrim(str(val(SM0->M0_CODIGO)))
		cQuery += "   AND CODSISTEMA = 'F'"
		cQuery += "   AND CODAUTOINC = 'IDLAN'"
		cQuery := ChangeQuery(cQuery)
		iif(Select(cAlias)>0,(cAlias)->( dbCloseArea()),Nil)
		dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery), cAlias, .F., .T.)
		nIdLan := (cAlias)->VALAUTOINC+1
		cIdLan := StrZero(nIdLan,TamSX3("E1_NUM")[1])

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Alterna o TOP para o ambiente padrao³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TCSetConn( nAmbTOP )

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Verifica se ja existe titulos na SE1 com o IdLan retornado, sem considerar FILIAL³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cQuery := "SELECT COUNT(E1_NUM) AS QTD "
		cQuery += "  FROM " + RetSQLName("SE1")
		cQuery += "  WHERE E1_NUM = '" + cIdLan + "'"
		cQuery += " 	AND D_E_L_E_T_ = ' ' "
		cQuery := ChangeQuery(cQuery)
		iif(Select(cAlias)>0,(cAlias)->( dbCloseArea()),Nil)
		dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery), cAlias, .F., .T.)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Se ja existe, entao coleta qual o proximo IdLan Disponivel da SE1 para atualizar a GAUTOINC³
		//³OBS: Trecho foi alterado em 09/03/09 para nao mais coletar qual o max(E1_NUM) por mudancas ³
		//³no contexto de geracao de titulos atraves das rotinas de liquidacao. Cesar/Alberto/Michelle³
		//³evitando assim que um "range" de codigos seja perdido.								      ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		if (cAlias)->QTD > 0
			lExiste := .T.
			nI		:= nIdLan + 1
			While lExiste
				cQuery := "SELECT COUNT(E1_IDLAN) AS QTD "
				cQuery += " FROM " + RetSQLName("SE1")
				cQuery += " WHERE E1_NUM = '" + alltrim(str(nI)) + "'"
				cQuery += " 	AND D_E_L_E_T_ = ' ' "
				cQuery := ChangeQuery(cQuery)
				iif(Select(cAlias)>0,(cAlias)->( dbCloseArea()),Nil)
				dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery), cAlias, .F., .T.)
				if (cAlias)->QTD > 0
					nI++
					loop
				else
					nIdLan := nI
					cIdLan := StrZero(nI,TamSX3("E1_NUM")[1])
					exit
				endif
			EndDo
		endif
		iif(Select(cAlias)>0,(cAlias)->( dbCloseArea()),Nil)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Alterna o TOP para o ambiente do RM Classis Net (RM Sistemas)³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		TCSetConn( nAmbCLASSIS )

		//Antes de atualizar a tabela de controle de numeracao do RM Classis Net (RM Sistemas), verifica se o registro ja existe
		cQuery := "SELECT COUNT(VALAUTOINC) AS QTD"
		cQuery += "  FROM GAUTOINC"
		cQuery += " WHERE CODCOLIGADA = "+SM0->M0_CODIGO+" AND CODSISTEMA = 'F' AND CODAUTOINC = 'IDLAN'"
		cQuery := ChangeQuery(cQuery)
		iif(Select(cAlias)>0,(cAlias)->( dbCloseArea()),Nil)
		dbUseArea( .T., "TOPCONN", TCGENQRY(,,cQuery), cAlias, .F., .T.)

		//Se ja existir o registro somente atualiza, senao insere o registro
		if (cAlias)->QTD > 0
			//Atualiza a tabela de controle de numeracao do RM Classis Net (RM Sistemas)
			cQuery := "UPDATE GAUTOINC SET VALAUTOINC = "+AllTrim(Str(nIdLan))
			cQuery += " WHERE CODCOLIGADA = "+alltrim(str(val(SM0->M0_CODIGO)))
			cQuery += "   AND CODSISTEMA = 'F'"
			cQuery += "   AND CODAUTOINC = 'IDLAN'"
		else
			//Insere o registro na tabela de controle de numeracao do RM Classis Net (RM Sistemas)
			cQuery := "INSERT INTO GAUTOINC "
			cQuery += " (CODCOLIGADA, CODSISTEMA, CODAUTOINC, VALAUTOINC)
			cQuery += " VALUES( "+alltrim(str(val(SM0->M0_CODIGO)))+", 'F', 'IDLAN', "+AllTrim(Str(nIdLan))+")"
		endif
		TcSqlExec( cQuery )
		TcSqlExec( "COMMIT" )
		iif(Select(cAlias)>0,(cAlias)->( dbCloseArea()),Nil)
	else
		MsgSTop(STR0094+"."+Chr(13)+Chr(10)+Chr(13)+Chr(10)+STR0095) //"Não foi possível gerar o número do título"###"Não foi encontrada a tabela [GAUTOINC] na base de dados do RM Classis Net."
		lOk := .F.
	endif
endif

if lLinkOk
	TCUNLINK(nAmbCLASSIS) //Finaliza a conexao com o ambiente RM Clasis Net (Base do sistema RM Classis Net)
endif
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Alterna o TOP para o ambiente padrao³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
TCSetConn( nAmbTOP )

RestArea(aArea)
Return cIdLan

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040WhnNumºAutor  ³Alberto Deviciente  º Data ³ 27/Jan/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ X3_WHEN do campo E1_NUM                                    º±±
±±º          ³ Se a integracao do Protheus x RM Classis Net estiver ativa,º±±
±±º          ³nao permite editar o campo E1_NUM.                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao - Protheus x RM Classis Net (RM Sistemas)       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040WhnNum()
Local lRet := .T.
Local nPos := 0

//MV_RMCLASS: Parametro de ativacao da integracao do Protheus x RM Classis Net (RM Sistemas)
If GetNewPar("MV_RMCLASS", .F.)
	if IsInCallStack("FINA040")//Bloqueia a edicao do campo E1_NUM pela rotina FINA040
		if !empty(M->E1_PARCELA)
			for nPos:=1 to TamSX3("E1_PARCELA")[1]
				if !empty(SubStr(alltrim(M->E1_PARCELA),nPos,1)) .and. SubStr(alltrim(M->E1_PARCELA),nPos,1) <> "0"
					lRet := .F.
					exit
				endif
			next nPos
		else
			lRet := .F.
		endif
	endif
EndIf

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040RelNumºAutor  ³Alberto Deviciente  º Data ³ 27/Jan/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ X3_RELACAO do campo E1_NUM                                 º±±
±±º          ³ Se a integracao do Protheus x RM Classis Net estiver ativa º±±
±±º          ³e for inclusao de titulo pela rotina FINA040, tras o numero º±±
±±º          ³como "0" (zero) e somente busca o proximo numero do titulo  º±±
±±º          ³qdo. confirmar a tela.                                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao - Protheus x RM Classis Net (RM Sistemas)       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040RelNum()
Local cRet 	:= ""
Local aArea	:= getArea()

dbSelectArea('SE1')

//MV_RMCLASS: Parametro de ativacao da integracao do Protheus x RM Classis Net (RM Sistemas)
If GetNewPar("MV_RMCLASS", .F.)
	if (FunName() == "FINA040" .or. FunName() == "FINA740") .and. Inclui
		//Caso a chamada seja realizada pela rotina "Contas a Receber" ou "Funcoes Contas a Receber"
		//o numero do titulo deve ser automatico conforme a GAUTOINC
		cRet := Replicate("0",TamSX3("E1_NUM")[1])
	Else
		cRet := SE1->E1_NUM
	EndIf
else
	cRet := SE1->E1_NUM
endif

RestArea(aArea)
Return cRet

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040RelIdBºAutor  ³Cesar A. Bianchi    º Data ³ 06/Mar/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º          ³Se a integracao do Protheus x RM Classis Net estiver ativa  º±±
±±º          ³e for inclusao de titulo pela rotina FINA040, ja traz o     º±±
±±º          ³proximo numero do IDBOLET.                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao - Protheus x RM Classis Net (RM Sistemas)       º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Function F040RelIdB()
Local nRet := 0
Local aArea 		:= getArea()

dbSelectArea('SE1')

If cPaisLoc == "BRA"
	nRet := SE1->E1_IDBOLET
EndIf

RestArea(aArea)
Return nRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FINA040   ºAutor  ³ Gustavo Henrique   º Data ³  28/09/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Seleciona titulos provisorios em uma nova area para selecaoº±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ EXPC1 - Codigo do cliente                                  º±±
±±º          ³ EXPC2 - Loja                                               º±±
±±º          ³ EXPC3 - Outras Moedas                                      º±±
±±º          ³ EXPN4 - Moeda do titulo                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINA040                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function F040FilProv( cCodigo, cLoja, cOutMoeda, nMoedSubs )

Local cChave := ""
Local cFor   := ""
Local cIndex := ""
Local nIndex := 0
Local lRet   := .T.
Local cTipoProvis := ""

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria indice condicional												  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If Select("__SUBS") > 0
	DbSelectArea("__SUBS")
	dbCloseArea()
Endif

ChkFile("SE1",.F.,"__SUBS")
cIndex := CriaTrab(nil,.f.)
cChave := IndexKey()

If cPaisLoc == "EQU"
	cTipoProvis := MVPROVIS
	cTipoProvis += "|NF "
Else
	cTipoProvis := MVPROVIS
EndIf

cFor :=  'E1_SALDO == E1_VALOR .And. E1_TIPO $ "'+cTipoProvis+'" .And. E1_ORIGEM # "FINI055" .And. '
cFor +=  'E1_CLIENTE == "'+cCodigo+'" .and. E1_LOJA == "'+cLoja+'"'
If cOutMoeda == "1" // Nao considera outras moedas
	cFor +=  '.and. E1_MOEDA=='+Alltrim(STR(nMoedSubs))
Endif
IndRegua("__SUBS",cIndex,cChave,,cFor,STR0026) // "Selecionando Registros..."
nIndex := RetIndex("SE1","__SUBS")
dbSelectArea("__SUBS")
#IFNDEF TOP
	dbSetIndex(cIndex+OrdBagExt())
#ENDIF
dbSetOrder(nIndex+1)
dbGoTop()
If BOF() .and. EOF()
	Help(" ",1,"RECNO")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Restaura os indices								 						  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("__SUBS")
	dbCloseArea()
	Ferase(cIndex+OrdBagExt())
	cIndex:=""
	dbSelectArea("SE1")
	dbGoTop()
	lRet := .F.
EndIf

Return lRet


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040VlCposºAutor  ³ Marcelo Celi Marquesº Data ³  11/11/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Varre os campos de memoria em busca de caracteres especiais º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINA040                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040VlCpos()
Local nX := 1
Local aStruct := SE1->( dbStruct() )
Local lOk := .T.
Local cCposVld := "|E1_FILIAL|E1_PREFIXO|E1_NUM|E1_PARCELA|E1_TIPO|E1_CLIENTE|E1_LOJA|" //Campos Considerados na validacao (Campos Chave da tabela)
Do While nX <= Len(aStruct) .And. lOk
	If Upper(aStruct[nX][2]) == "C" .And. Upper(Alltrim(aStruct[nX][1])) $ cCposVld
		If CHR(39) $ M->&(Alltrim(aStruct[nX][1]))	 .Or. ;
	       CHR(34) $ M->&(Alltrim(aStruct[nX][1]))
			lOk := .F.
		Endif
	Endif
	nX++
Enddo
If !lOk
   Help("",1,"INVCAR",,STR0104,1,0)
Endif
Return lOk


//------ FUNCOES PARA 639.04 Base Impostos diferenciada
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040BSIMP ³ Autor ³ Mauricio Pequim Jr	³ Data ³ 26/11/09 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verificacao do uso de base diferenciada para impostos	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ F040BSIMP()			 									  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040BSIMP(nOpcao)

Local lRet := .F.
Local lSE1Ok := .F.
Local aArea	:= GetArea()
Local cCondImp := ".T."

//NAO TRANSFORME ESTA VARIAVEL EM LOCAL
//ELA SERA MACRO-EXECUTADA
PRIVATE lCposImp := cPaisLoc == "BRA"

DEFAULT nOpcao := 1  // 1 = Verificar campos e calculo dos impostos;
							//	2 = Verificar apenas existencia dos campos
							// 3 = Verificar calculo dos impostos;

If nOpcao == 1
	//Se existirem os campos de base de impostos
	//Verifica se o cliente e a natureza calcula impostos
	If Upper(AllTrim(FunName())) == "MATA521A" .Or. Upper(AllTrim(FunName())) == "MATA521" .Or. (Upper(AllTrim(FunName())) == "FINA740" .and. !INCLUI)
		cCondImp := 'lCposImp .and. cPaisLoc == "BRA" .and. SED->(MsSeek(xFilial("SED")+SE1->E1_NATUREZ))'
		lSe1Ok := !Empty(SE1->E1_NATUREZ) .and. !EMPTY(SE1->E1_CLIENTE)
    Else
		cCondImp := 'lCposImp .and. cPaisLoc == "BRA" .and. SED->(MsSeek(xFilial("SED")+M->E1_NATUREZ))'
		lSe1Ok := !Empty(M->E1_NATUREZ) .and. !EMPTY(M->E1_CLIENTE)
	EndIf
ElseIf nOpcao == 2
	//Se existirem os campos de base de impostos
	lRet := lCposImp
	lSe1Ok := .F.
ElseIf nOpcao == 3
	//Verifica apenas se calcula algum dos impostos (Desdobramento)
	lCposImp := .T.
	lSe1Ok := .T.
Endif

If lCposImp .and. lSe1Ok .and. &cCondImp .and. ;
	(	(SED->ED_CALCIRF == "S" ) .OR. ;
		(SED->ED_CALCISS == "S".and. (SA1->A1_RECISS != "1" .Or. GetNewPar("MV_DESCISS",.F.))) .OR. ;
		(SED->ED_CALCINS == "S" .and. SA1->A1_RECINSS == "S") .OR. ;
		(SED->ED_CALCCSL == "S" .and. SA1->A1_RECCSLL $ "S#P") .OR. ;
		(SED->ED_CALCCOF == "S" .and. SA1->A1_RECCOFI $ "S#P") .OR. ;
		(SED->ED_CALCPIS == "S" .and. SA1->A1_RECPIS $ "S#P") )

	lRet := .T.

Endif

RestArea(aArea)

Return lRet




/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³F040IMPAUT³ Autor ³ Mauricio Pequim Jr	  ³ Data ³ 26/11/09 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica se os impostos foram informados no array da rotina³±±
±±³          ³ automatica ou se devem ser calculados normalmente.         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±ºSintaxe   ³ F040IMPAUT()            	                                º±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040																	  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040ImpAut(cImposto, nPsimp)

Local nI := 0
Local nT := 0
Local lRet := .F.

aAutoCab := If(Type("aAutoCab") != "A",{},aAutoCab)
DEFAULT cImposto	:= ""
DEFAULT nPsimp	:= 0

//639.04 Base Impostos diferenciada
If Len(aAutoCab) > 0

	//Verifico se algum imposto foi enviado no array aRotAuto
	//Significa que o imposto foi preh calculado e não deve ser calculado novamente
	IF !Empty(cImposto) .and. (nT := ascan(aAutoCab,{|x| Alltrim(x[1]) == cImposto}) ) > 0
		lRet 	:= .T.
		nPsimp	:= nT
	Endif

Endif

Return (lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040ChkOldNat ºAutor  ³Pedro Pereira Lima  º Data ³  21/05/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Verifica se a natureza antiga (caso tenha sido alterada)       º±±
±±º          ³ calculava imposto, controlando os campos de impostos digitados º±±
±±º          ³ pelo usuário, evitando que sejam apagados incorretamente.      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINA040 - FA040NATUR                                           º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040ChkOldNat(cNatureza, nImposto)

Local aArea    := GetArea()
Local aAreaSED := SED->(GetArea())
Local lRet     := .F. //Retorno TRUE se natureza antiga calculava o imposto selecionado

Default cNatureza := ""
Default nImposto := 0

If !Empty(cNatureza) .And. nImposto > 0
	dbSelectArea("SED")
	dbSetOrder(1)
	If DbSeek(xFilial("SED")+cNatureza)
		Do Case
			Case nImposto == 1 //IRRF
				lRet := SED->ED_CALCIRF == "S"

			Case nImposto == 2 //ISS
				lRet := SED->ED_CALCISS == "S"

			Case nImposto == 3 //INSS
				lRet := SED->ED_CALCINS == "S"

			Case nImposto == 4 //CSLL
				lRet := SED->ED_CALCCSL == "S"

			Case nImposto == 5 //COFINS
				lRet := SED->ED_CALCCOF == "S"

			Case nImposto == 6 //PIS
				lRet := SED->ED_CALCPIS == "S"
		EndCase
	EndIf
EndIf

RestArea(aAreaSED)
RestArea(aArea)

Return lRet

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³F040VlAdClLj³ Autor ³Totvs                ³ Data ³20.05.2010³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±ºDescricao ³ Valida cliente e loja para titulo de adiantamento de pedidoº±±
±±º          ³ de venda ou documento de saida.                            º±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ExpL1: Indica se validou a condicao                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Observacao³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao Efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function F040VlAdClLj()

Local lOk := .T.

If FunName() = "MATA410"
	If Type("M->C5_CLIENTE") != "U" .and. Type("M->C5_LOJACLI") != "U"
		If M->E1_CLIENTE+M->E1_LOJA != M->C5_CLIENTE+M->C5_LOJACLI
			lOk := .F.
		Endif
	Endif
Elseif FunName() = "MATA460A" .or. FunName() = "MATA460B"
	If SC5->(!Eof())
		If M->E1_CLIENTE+M->E1_LOJA != SC5->C5_CLIENTE+SC5->C5_LOJACLI
			lOk := .F.
		Endif
	Endif
Endif

If !lOk
   Aviso(STR0039,STR0106,{ "Ok" }) //"ATENCAO"#"Por tratar-se de título para processo de adiantamento, é obrigatório que o código do cliente e loja sejam os mesmos do 'Pedido de Venda/Documento de Saída'."
Endif

Return lOk


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³Fa040GetCC³ Autor ³ Lucas			 	    ³ Data ³ 18/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Obter os dados do Cartão de Credito.						  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa040GetCC()					 							  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function Fa040GetCC(lSE1)
Local aArea  	 := GetArea()
Local nOpca  	 := 0
Local aSize  	 := MSADVSIZE()
Local cCodAdm 	 := CriaVar("FRB_CODADM")
Local cNumCartao := CriaVar("FRB_NUMCAR")
Local cNomeAdm   := CriaVar("AE_DESC")
Local cValidade  := Space(4)
Local cCodSeg 	 := CriaVar("FRB_CODSEG")
Local aParcelas  := {"01"}	//"02","03","04","05","06","07","08","09","10","11","12"}
Local cParcela   := "01"
Local aPicture   := Array(4)
Local oCbxParc
Local oDlgCC
Local nOpc 		 := 0
Local aTitulos   := {}

aPicture[1] := PesqPict("FRB","FRB_CODADM", TamSX3("FRB_CODADM"))
aPicture[2] := PesqPict("FRB","FRB_NUMCAR", TamSX3("FRB_NUMCAR"))
aPicture[3] := PesqPict("SAE","AE_DESC"   , TamSX3("AE_DESC"))
aPicture[4] := PesqPict("FRB","FRB_CODSEG", TamSX3("FRB_CODSEG"))

dbSelectArea("FRB")

DEFINE MSDIALOG oDlgCC TITLE STR0109 From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL // "Informe Dados do Cartão de Credito"

	@ 027,010 SAY STR0110	PIXEL OF oDlgCC COLOR CLR_HBLUE // "Administradora"
	@ 025,060 MSGET cCodAdm F3 "SAE" Picture aPicture[1] SIZE 40,08		Valid Fa040CodAdm(cCodAdm,@cNomeAdm)		PIXEL OF oDlgCC
	@ 025,120 MSGET cNomeAdm         Picture aPicture[3] SIZE 170,08		PIXEL OF oDlgCC WHEN .F.

	@ 042,010 SAY STR0111	PIXEL OF oDlgCC COLOR CLR_HBLUE // "Num. Cartão"
	@ 040,060 MSGET cNumCartao		 Picture aPicture[2] SIZE 120,08 	Valid Fa040NumCart(cNumCartao)	PIXEL OF oDlgCC

	@ 057,010 SAY STR0112   PIXEL OF oDlgCC COLOR CLR_HBLUE // "Validade"
	@ 055,060 MSGET cValidade		 Picture "@R 99/99"	 SIZE 30,08 	Valid Fa040Valid(cValidade)		PIXEL OF oDlgCC

	@ 072,010 SAY STR0113	PIXEL OF oDlgCC
	@ 070,060 MSGET cCodSeg			 Picture aPicture[4] SIZE 30,08 Valid Fa040CodSeg()					PIXEL OF oDlgCC
	@ 070,100 SAY STR0114	PIXEL OF oDlgCC

	@ 087,010 SAY STR0115	PIXEL OF oDlgCC
	@ 085,060 MSCOMBOBOX oCbxParc  VAR cParcela		ITEMS aParcelas SIZE 60, 54 WHEN !lSE1	PIXEL OF oDlgCC	//ON CHANGE (nMoedSubs := Val(Substr(cMoeda,1,2)))

ACTIVATE MSDIALOG oDlgCC ON INIT EnchoiceBar(oDlgCC,{|| If(fa040Ok(),(nOpca := 1,oDlgCC:End()),NIL)},{|| nOpca := 2,oDlgCC:End()})

//Gravar titulos em um array para posterior substituição.
If nOpca == 1
	If lSE1
		nPosicao := Ascan(aTitulos, { |x| x[1]+x[2]+x[3]+[4] == SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO })
		If nPosicao == 0
			AADD(aTitulos,{SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,cCodAdm,cNumCartao,cValidade,cCodSeg,cParcela})
		Else
			aTitulos[nPosicao][1]:= SE1->E1_PREFIXO
			aTitulos[nPosicao][2]:= SE1->E1_NUM
			aTitulos[nPosicao][3]:= SE1->E1_PARCELA
			aTitulos[nPosicao][4]:= SE1->E1_TIPO
			aTitulos[nPosicao][5]:= cCodAdm
			aTitulos[nPosicao][6]:= cNumCartao
			aTitulos[nPosicao][7]:= cValidade
			aTitulos[nPosicao][8]:= cCodSeg
			aTitulos[nPosicao][9]:= cParcela
		EndIf
	Else
		nPosicao := Ascan(aTitulo2CC, { |x| x[1]+x[2]+x[3]+[4] == __SUBS->E1_PREFIXO+__SUBS->E1_NUM+__SUBS->E1_PARCELA+__SUBS->E1_TIPO })
		If nPosicao == 0
			AADD(aTitulo2CC,{__SUBS->E1_PREFIXO,__SUBS->E1_NUM,__SUBS->E1_PARCELA,__SUBS->E1_TIPO,cCodAdm,cNumCartao,cValidade,cCodSeg,cParcela})
		Else
			aTitulo2CC[nPosicao][1]:= __SUBS->E1_PREFIXO
			aTitulo2CC[nPosicao][2]:= __SUBS->E1_NUM
			aTitulo2CC[nPosicao][3]:= __SUBS->E1_PARCELA
			aTitulo2CC[nPosicao][4]:= __SUBS->E1_TIPO
			aTitulo2CC[nPosicao][5]:= cCodAdm
			aTitulo2CC[nPosicao][6]:= cNumCartao
			aTitulo2CC[nPosicao][7]:= cValidade
			aTitulo2CC[nPosicao][8]:= cCodSeg
			aTitulo2CC[nPosicao][9]:= cParcela
		EndIf
	EndIf
Else
	aTitulo2CC := {}
EndIf

RestArea(aArea)
Return( If(lSE1,aTitulos,) )

Function Fa040dValid()
Return .T.

Function Fa040Ok()
Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040CodAdm()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Validar Codigo da Administradora de Cartão de Credito.     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ ExpL1 := Fa040CodAdm(cCodAdm)	  			              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ ExpL1 -> transação efetuada com sucesso ou não			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA050	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040CodAdm( cCodAdm, cNomeAdm )
Local lResult := .T.

If Empty(cCodAdm)
	MsgAlert(STR0116,STR0039)		//Informe o Codigo da Administradora !" ### Atenção
	lResult := .F.
EndIf
If lResult
	SAE->(dbSetOrder(1))
	If ! SAE->(dbSeek(xFilial("SAE")+cCodAdm))
		MsgAlert(STR0117,STR0039)	//Administradora de Cartões Invalida !" ### Atenção
		lResult := .F.
	Else
		cNomeAdm := SAE->AE_DESC
	EndIf
EndIf
Return (lResult)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040NumCart()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Verifica se o número do cartão digitado é válido.          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ ExpL1 := Fa040NumCart(cNumCartao)  			              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ ExpL1 -> transação efetuada com sucesso ou não			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040NumCart( cNumCartao )
Local lResult := .T.
If Empty(cNumCartao)
	MsgAlert(STR0118,STR0039)	//"É obrigatório o preenchimento do número do cartão !" ### Atenção
	lResult := .F.
ElseIf Len(AllTrim(cNumCartao))>19
	MsgAlert(STR0119,STR0039)	//"Número do Cartão maior que 19 dígitos !" ### Atenção
	lResult := .F.
EndIf
Return (lResult)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040dValid()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Verifica se o número do cartão digitado é válido.          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ ExpL1 := Fa040dValid(cValid)		  			              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ ExpL1 -> transação efetuada com sucesso ou não			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040Valid( cValid )
Local lResult := .T.
Local dValid  := CTOD("")

//LastDay(dDataBase)+"/"+Subs(cValid,1,2)+"/"+Subs(cValid,3,2)

If Empty(cValid)
	MsgAlert(STR0120,STR0039)	//"É obrigatório o preenchimento do validade do cartão !"  ### Atenção
	lResult := .F.
EndIf
If lResult
	//Consistir mes e ano de validade do cartão.
	If Subs(cValid,1,2) < "01" .or. Subs(cValid,1,2) > "12"
		MsgAlert(STR0121,STR0039)	//"Mes Informado invalido !"  ### Atenção
		lResult := .F.
	EndIf
	If "20"+Subs(cValid,3,2) < StrZero(Year(dDataBase),4)
		MsgAlert(STR0122,STR0039)	//"Ano Informado invalido !" ### Atenção
		lResult := .F.
	EndIf
EndIf
If lResult
	//Consitir mes no mesmo ano da dDataBase.
	If Subs(cValid,1,2) < StrZero(Month(dDatabase),2) .and. "20"+Subs(cValid,3,2) == StrZero(Year(dDataBase),4)
		MsgAlert(STR0123,STR0039)	//"Cartão com validade vencida !" ### Atenção
		lResult := .F.
	EndIf
	//Consitir último dia de validade do cartão, quando mes igual a dDataBase.
	If Subs(cValid,1,2) == StrZero(Month(dDatabase),2)
		dValid := Subs(DTOC(LastDay(dDataBase)),1,2)
		dValid += "/"+Subs(cValid,1,2)+"/"+Subs(cValid,3,2)
		dValid := CTOD(dValid)
		If dValid < dDataBase
			MsgAlert(STR0124,STR0039)	//"Cartão com validade vencida !" ### Atenção
			lResult := .F.
		EndIf
	EndIf
EndIf
Return (lResult)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040CodSeg()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Verifica se o número do cartão digitado é válido.          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ ExpL1 := Fa040CodSeg(cCodSeg)	  			              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ ExpL1 -> transação efetuada com sucesso ou não			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040CodSeg( cCodSeg )
Local lResult := .T.

If Empty(cCodSeg)
	lResult := .T.
EndIf
Return (lResult)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040Tit2CC()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Substituir títulos por títulos contra a Administradora de  ³±±
±±³          ³ Cartão de Credito, mantendo o titulo original baixado.     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa040Tit2CC()          						              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ Null                                          			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA050	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040Tit2CC()
Local aArea 	:= GetArea()
Local lResult 	:= .T.
Local lDivide   := GetNewPar("MV_DIVTCC","1") == "1"
Local lEdita    := GetNewPar("MV_EDITCC","1") == "2"
LOCAL cIndex 		:= ""
LOCAL cChave
LOCAL aDeletar 	:= {}
Local lPadrao   := .F.
Local cPadrao   := "503"
Local cArquivo  := ""
Local nHdlPrv   := 0
Local nTotal    := 0
Local lDigita
Local nRecSubs  := 0
LOCAL nHdlLock 	:= 0
LOCAL lInverte 	:= .F.
LOCAL oValor  		:= 0
LOCAL oQtdTit		:= 0
LOCAL oDlg
LOCAL oDlg1
Local nRecSE1 := SE1->(RECNO())
LOCAL aMoedas		:= {}
LOCAL aOutMoed		:= {STR0107,STR0108}	//"1=Nao Considera"###"2=Converte"
LOCAL cOutMoeda	:= "1"
LOCAL cMoeda		:= "1"
Local cSimb
Local nRecno := 0
Local aSize := {}
Local oPanel
Local oPanel2
Local nTotalParc := 0.00
Local nValTotal  := SE1->E1_VALOR
Local nParcela   := 1
Local nValorSE1  := 0.00
Local nCount     := 0
Local nReg       := SE1->(RecNo())
Local lSubsSuces := .F.
Local nC         := 0
Local aCampos    := {}
Local aChaveLbn  := {}
Local aAreaAFT   := AFT->(GetArea())
Local cParcela 	 := GetMV("MV_1DUP")

VALOR 		:= 0
VLRINSTR 	:= 0

If Len(aTitulo2CC) > 0

	For nCount := 1 To Len(aTitulo2CC)

		dbSelectArea("SE1")
		dbSetOrder(1)
		dbSeek(xFilial("SE1")+aTitulo2CC[nCount][1]+aTitulo2CC[nCount][2]+aTitulo2CC[nCount][3]+aTitulo2CC[nCount][4])

		If lDivide .and. aTitulo2CC[nCount][09] <> "01"
			nTotalParc := Val(aTitulo2CC[nCount][09])
		Else
			nTotalParc := 1
		EndIf

	    nValTotal  := SE1->E1_VALOR
		nValorSE1  := nValTotal/nTotalParc

		For nParcela := 1 To nTotalParc
			nOpc:=3			 //Inclusao
			lSubst:=.T.
			lSubsSuces := .F.
			If lEdita    	//Abre Enchoice para editar os títulos a Substituir...
				lSubsSuces := FA040Inclu("SE1",nReg,nOpc,,,lSubst) == 1
				//Ajustar Tipo do Título.
				RecLock("SE1",.F.)
				E1_TIPO    := "CC"
				MsUnLock()
			Else
				aCampos := {}
			    For nC := 1 To SE2->(FCount())
			    	If SE1->(FieldName(nC)) == "E1_PARCELA"
				    	AADD(aCampos,{SE1->(FieldName(nC)),cParcela})
                    ElseIf SE1->(FieldName(nC)) == "E1_TIPO"
				    	AADD(aCampos,{SE1->(FieldName(nC)),"CC"})
					Else
			    		AADD(aCampos,{SE1->(FieldName(nC)),SE1->(FieldGet(nC))})
			    	EndIf
			    Next nC
			    RecLock("SE1",.T.)
			    For nC := 1 To Len(aCampos)
			    	FieldPut(nC,aCampos[nC,2])
			    Next nC
			    E1_VALOR 	:= nValorSe1
			    E1_SALDO 	:= E1_VALOR
			    E1_VALLIQ   := E1_VALOR
				If nParcela > 1
					E1_PARCELA := Soma1(cParcela)
				EndIf
			    If nParcela == nTotalParc
			    	E1_VALOR  += (nValTotal-(E1_VALOR*nTotalParc))
			    	E1_SALDO  := E1_VALOR
			    	E1_VALLIQ := E1_VALOR
			    EndIf
			    MsUnLock()
			    lSubsSuces := .T.
			EndIf
			If lSubsSuces
				//Incluir registros na tabela de Controle de Títulos a pagar por Cartão de Credito
				dbSelectArea("FRB")
				RecLock("FRB",.T.)
				FRB_FILIAL := xFilial("FRB")
				FRB_DATTEF := dDataBase
				FRB_HORTEF := Subs(Time(),1,5)
				FRB_DOCTEF := "" //Reservado para implementação futura quando localizar e integrar o SigaLoja no Equador
				FRB_AUTORI := "" //Idem.
				FRB_NSUTEF := "" //Idem.
                FRB_STATUS := "01"
                FRB_MOTIVO := ""
                FRB_TIPCAR := "CC"
               	FRB_PREFIX := SE1->E1_PREFIXO
                FRB_NUM	   := SE1->E1_NUM
                FRB_PARCEL := SE1->E1_PARCELA
                FRB_TIPO   := SE1->E1_TIPO
                FRB_CODADM := aTitulo2CC[nCount][5]
                FRB_NUMCAR := aTitulo2CC[nCount][6]
                FRB_DATVAL := aTitulo2CC[nCount][7]
                FRB_CODSEG := aTitulo2CC[nCount][8]
                FRB_NUMPAR := nParcela
                FRB_SEQOPE := "1"
                FRB_FORMA  := "CC"	//Substituir por SE4->E4_FORMA
                FRB_VALOR  := SE1->E1_VALOR
                FRB_CLIENT := SE1->E1_CLIENTE
                FRB_LOJA   := SE1->E1_LOJA
       			If cPaisLoc == "EQU"
					FRB->FRB_PREORI := aTitulo2CC[nCount][1]
    	    		FRB->FRB_NUMORI := aTitulo2CC[nCount][2]
        			FRB->FRB_PARORI := aTitulo2CC[nCount][3]
					FRB->FRB_TIPORI := aTitulo2CC[nCount][4]
				EndIf
                MsUnLock()


            EndIf
			lSubst:=.F.
			//Só contabilizar após a gravação da última parcela do Cartão de Credito.
			If nParcela <> nTotalParc
				Loop
			EndIf
			If ( lPadrao )
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Inicializa Lancamento Contabil                                   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				nHdlPrv := HeadProva( cLote,;
			       	    		      "FINA040" /*cPrograma*/,;
				       	      		  Substr(cUsuario,7,6),;
			           				  @cArquivo )
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicializa a gravacao dos lancamentos do SIGAPCO          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			PcoIniLan("000001")

			If ! lF040Auto
				dbSelectArea("__SUBS")
				dbGoTop()
				While !Eof()
					If E1_OK == cMarca
						nRecSubs := RecNo()
						dbSelectArea("SE1")
						dbGoto(nRecSubs)
						If ( lPadrao )
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Prepara Lancamento Contabil                                      ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If lUsaFlag  // Armazena em aFlagCTB para atualizar no modulo Contabil
								aAdd( aFlagCTB, {"E1_LA", "S", "SE1", SE1->( Recno() ), 0, 0, 0} )
							Endif
							nTotal += DetProva( nHdlPrv,;
						        	            cPadrao,;
						            	        "FINA040" /*cPrograma*/,;
						                	    cLote,;
					    	                	/*nLinha*/,;
							       	            /*lExecuta*/,;
						    	                /*cCriterio*/,;
						   		                /*lRateio*/,;
						   	                    /*cChaveBusca*/,;
						                        /*aCT5*/,;
						                        /*lPosiciona*/,;
						                        @aFlagCTB,;
						                        /*aTabRecOri*/,;
						                        /*aDadosProva*/ )
						EndIf

						dbSelectArea("SE1")
						dbSetOrder(1)
						If dbSeek(xFilial("SE1")+aTitulo2CC[nCount][1]+aTitulo2CC[nCount][2]+aTitulo2CC[nCount][3]+aTitulo2CC[nCount][4])

							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Atualizacao dos dados do Modulo SIGAPMS    ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If IntePms().AND. !lPmsInt
								PmsWriteFI(2,"SE1")	//Estorno
								PmsWriteFI(3,"SE1")	//Exclusao
							EndIF

							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³ Chama a integracao com o SIGAPCO antes de apagar o titulo ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							PcoDetLan("000001","01","FINA040",.T.)

							If ExistBlock("F040PROV")
								ExecBlock("F040PROV",.F.,.F.)
							Endif
			   				If  SE1->E1_FLUXO == 'S'
								AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),0)
							Endif
							cChave := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
										SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
							FINDELFKs(cChave,"SE1")

							Reclock("SE1",.F.,.T.)
							dbDelete()
							MsUnlock()
						EndIf
					Endif
					dbSelectArea("__SUBS")
					dbSkip()
				Enddo
			Else
				dbSelectArea("__SUBS")
				dbGoTop()
				While !Eof()
					If E1_OK == cMarca
						BEGIN TRANSACTION
							If ( lPadrao )
								nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
							EndIf
							// Caso tenha integracao com PMS para alimentar tabela AFT
					  		If IntePms().AND. !lPmsInt
					   			IF PmsVerAFT()
							  		aGravaAFT := PmsIncAFT()
						   		Endif
							Endif

							nRecSubs := __SUBS->(Recno())
							dbSelectArea("SE1")
							dbGoto(nRecSubs)
							dbSelectArea("SE1")
							dbSetOrder(1)
							If dbSeek(xFilial("SE1")+aTitulo2CC[nCount][1]+aTitulo2CC[nCount][2]+aTitulo2CC[nCount][3]+aTitulo2CC[nCount][4])

								//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
								//³ Apaga o lacamento gerado para a conta orcamentaria - SIGAPCO ³
								//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
								PcoDetLan("000001","01","FINA040",.T.)

								If SE1->E1_FLUXO == 'S'
									AtuSldNat(SE1->E1_NATUREZ, SE1->E1_VENCREA, SE1->E1_MOEDA, "2", "R", SE1->E1_VALOR, SE1->E1_VLCRUZ, "-",,FunName(),"SE1",SE1->(Recno()),0)
								Endif
								cChave := xFilial("SE1")+"|"+SE1->E1_PREFIXO+"|"+SE1->E1_NUM+"|"+SE1->E1_PARCELA+"|"+;
											SE1->E1_TIPO+"|"+SE1->E1_CLIENTE+"|"+SE1->E1_LOJA
								FINDELFKs(cChave,"SE1")

								RecLock("SE1",.F.,.T.)
								SE1->(dbDelete())
								MsUnlock()
							EndIf
						END TRANSACTION
						//Se o registro não foi gerado através do botão de integração do PMS na tela de titulos a receber do financeiro
						//Grava o registro na AFT com os dados obtidos na rotina PMSIncAFT()
						If Len(aGravaAFT) > 0 .And. (!AFT->(dbSeek(aGravaAFT[1]+aGravaAFT[6]+aGravaAFT[7]+aGravaAFT[8]+aGravaAFT[9]+aGravaAFT[10]+aGravaAFT[11]+aGravaAFT[2]+aGravaAFT[3]+aGravaAFT[5])))
							RecLock("AFT",.T.)
						 	AFT->AFT_FILIAL	:= aGravaAFT[1]
							AFT->AFT_PROJET	:= aGravaAFT[2]
							AFT->AFT_REVISA	:= aGravaAFT[3]
							AFT->AFT_EDT		:= aGravaAFT[4]
							AFT->AFT_TAREFA	:= aGravaAFT[5]
							AFT->AFT_PREFIX	:= aGravaAFT[6]
							AFT->AFT_NUM		:= aGravaAFT[7]
							AFT->AFT_PARCEL	:= aGravaAFT[8]
							AFT->AFT_TIPO		:= aGravaAFT[9]
							AFT->AFT_CLIENT	:= aGravaAFT[10]
							AFT->AFT_LOJA		:= aGravaAFT[11]
							AFT->AFT_VENREA	:= aGravaAFT[12]
							AFT->AFT_EVENTO 	:= aGravaAFT[13]
							AFT->AFT_VALOR1	:= aGravaAFT[14]
							AFT->AFT_VALOR2	:= aGravaAFT[15]
							AFT->AFT_VALOR3	:= aGravaAFT[16]
							AFT->AFT_VALOR4	:= aGravaAFT[17]
							AFT->AFT_VALOR5	:= aGravaAFT[18]
							MsUnLock()
						EndIf
					Endif
					dbSelectArea("__SUBS")
					dbSkip()
				Enddo
			Endif

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Finaliza a gravacao dos lancamentos do SIGAPCO          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			PcoFinLan("000001")

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Contabiliza a diferenca               			    ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("SE1")
			nRecSE1 := Recno()
			dbGoBottom()
			dbSkip()

			VALOR := (nValorS - nValorSe1)
			VLRINSTR := VALOR
			If nTotal > 0
				nTotal+=DetProva(nHdlPrv,cPadrao,"FINA040",cLote)
			Endif
			dbSelectArea("SE1")
			dbGoTo(nRecSE1)
			If ( lPadrao )
				RodaProva(nHdlPrv,nTotal)
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Envia para Lancamento Contabil					    ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lDigita:=IIF(mv_par01==1,.T.,.F.)
				If UsaSeqCor()
		 			aDiario := {}
					aDiario := {{"SE1",SE1->(recno()),SE1->E1_DIACTB,"E1_NODIA","E1_DIACTB"}}
				Else
					aDiario := {}
				EndIf
				cA100Incl(cArquivo,nHdlPrv,3,cLote,lDigita,.F.,,,,,,aDiario)
			EndIf
		Next nParcela
	Next nCount

	If !Empty(aChaveLbn)
		aEval(aChaveLbn, {|e| UnLockByName(e,.T.,.F.) } ) // Libera Lock
	Endif

	VALOR    := 0
	VLSINSTR := 0
	If Select("__SUBS") > 0
		dbSelectArea("__SUBS")
		dbCloseArea()
		Ferase(cIndex+OrdBagExt())
	Endif
	dbSelectArea("SE1")
	If ! lF040Auto
		RetIndex("SE1")
		dbGoto(nReg)
    EndIf
EndIf

RestArea(aArea)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040GrvFRB()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Gravar titulos do Tipo "CC" na tabela FRB para controle das³±±
±±³          ³ das operações a receber através de Cartão de Credito.      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa040GrvFRB()          						              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ Null                                          			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040GrvFRB(aTituloCC)
Local aArea   := GetArea()
Local lAppend := .F.

If Len(aTituloCC) > 0
	//Incluir ou alterar registros na tabela de Controle de Títulos a pagar por Cartão de Credito
	dbSelectArea("FRB")
	dbSetOrder(1)
	If !dbSeek(xFilial("FRB")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)
		lAppend := .T.
	Else
		lAppend := .F.
	EndIf
	RecLock("FRB",lAppend)
	FRB_FILIAL := xFilial("FRB")
	FRB_DATTEF := dDataBase
	FRB_HORTEF := Subs(Time(),1,5)
	FRB_DOCTEF := "" //Reservado para implementação futura quando localizar e integrar o SigaLoja no Equador
	FRB_AUTORI := "" //Idem.
	FRB_NSUTEF := "" //Idem.
	FRB_STATUS := "01"
	FRB_MOTIVO := ""
	FRB_TIPCAR := "CC"
	FRB_PREFIX := SE1->E1_PREFIXO
	FRB_NUM	   := SE1->E1_NUM
	FRB_PARCEL := SE1->E1_PARCELA
	FRB_TIPO   := SE1->E1_TIPO
	FRB_CODADM := aTituloCC[Len(aTituloCC)][5]
	FRB_NUMCAR := aTituloCC[Len(aTituloCC)][6]
	FRB_DATVAL := aTituloCC[Len(aTituloCC)][7]
	FRB_CODSEG := aTituloCC[Len(aTituloCC)][8]
	FRB_NUMPAR := 1
	FRB_SEQOPE := "1"
	FRB_FORMA  := "CC"	//Substituir por SE4->E4_FORMA
	FRB_VALOR  := SE1->E1_VALOR
	FRB_CLIENT := SE1->E1_CLIENTE
	FRB_LOJA   := SE1->E1_LOJA
	If cPaisLoc == "EQU"
	   FRB->FRB_PREORI := aTituloCC[Len(aTituloCC)][1]
	   FRB->FRB_NUMORI := aTituloCC[Len(aTituloCC)][2]
	   FRB->FRB_TIPORI := aTituloCC[Len(aTituloCC)][3]
	   FRB->FRB_PARORI := aTituloCC[Len(aTituloCC)][4]
	EndIf
	MsUnLock()
EndIf

RestArea(aArea)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³ Fa040DelFRB()³ Autor ³ José Lucas  	    ³ Data ³ 20/08/10 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Apagar titulos do Tipo "CC" na tabela FRB para controle    ³±±
±±³          ³ das operações a receber através de Cartão de Credito.      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ Fa040DelFRB()          						              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorna	 ³ Null                                          			  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040	 												  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function Fa040DelFRB(aTituloCC)
Local aArea   := GetArea()

//Excluir registros na tabela de Controle de Títulos a pagar por Cartão de Credito
FRB->(dbSetOrder(1))
If FRB->(dbSeek(xFilial("FRB")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA))
	If FRB->FRB_STATUS == "01"	//Em analise
		RecLock("FRB",.F.)
		dbDelete()
		MsUnLock()
	EndIf
EndIf

RestArea(aArea)
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Fa040Drop ºAutor  ³Clovis Magenta      º Data ³  09/11/10   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que dropara as tabelas temporarias quando utilizado º±±
±±º          ³ banco de dados postgres                                   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ LOJXFUNC                                         			  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Fa040Drop()
Local lDelTrbIR	:= .T.
Local cAglImPJ	:= SuperGetMv("MV_AGLIMPJ",.T.,"1")

//Fecha arquivo temporario
If cAglImPJ != "1" .and. lDelTrbIR .and. !Empty(cArqTmp)
	DELTRBIR(SM0->M0_CODIGO, FWGETCODFILIAL ,.F.,0,cArqTmp,TCGetDb())
Endif

Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040VlAbtºAutor  ³ Clovis Magenta     º Data ³  09/06/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que valida o valor do abatimento a ser incluso no  º±±
±±º          ³ 'tudok' do fina040                                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040VlAbt()
Local lRet := .T.
Local nValTot := 0
Local nValTit := 0
Local aArea := getArea()
Local aAreaSE1 := SE1->(getArea())
Local cTipo	:= SE1->E1_TIPO

Default lAltera := .F.

dbSelectArea("SE1")
dbSetOrder(1)

If m->e1_tipo $ MVABATIM .and. !Empty(m->e1_num)
	If !(dbSeek(xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela))
		Help(" ",1,"FA040TIT")
		lRet := .F.
	ElseIf dbSeek(xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela)
		nValTit := IIF(lAltera, 0, SE1->E1_VALOR)

		While !Eof() .and. SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA) == ;
				xFilial("SE1")+m->e1_prefixo+m->e1_num+m->e1_parcela

			If SE1->E1_TIPO $ MVABATIM+"/"+MV_CRNEG+"/"+MVRECANT
				nValTot += SE1->E1_VALOR
			Else
				nValTit := SE1->E1_VALOR
			Endif

			SE1->(DbSkip())
		Enddo

		nValTot := IIF(lAltera, nValTot, (M->E1_VALOR+nValTot))

		If nValTot > nValTit
			Help(" ",1,"F040VLABT")
			lRet := .F.
		Endif
	Endif
Endif

RestArea(aAreaSE1)
RestArea(aArea)

Return lRet


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³FCriaFIH  ³ Autor ³Carlos A. Queiroz      ³ Data ³27.06.2011 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³Funcao que cria os registros de relacionamento de titulos    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpC1 : Alias do registro  do titulo origem                  ³±±
±±³          ³ExpC2 : Prefixo Origem                                       ³±±
±±³          ³ExpC3 : Numero Origem                                        ³±±
±±³          ³ExpC4 : Parcela Origem                                       ³±±
±±³          ³ExpC5 : Tipo Origem                                          ³±±
±±³          ³ExpC6 : Cliente Origem                                       ³±±
±±³          ³ExpC7 : Loja Origem                                          ³±±
±±³          ³ExpC8 : Alias do registro  do titulo destino                 ³±±
±±³          ³ExpC9 : Prefixo Destino                                      ³±±
±±³          ³ExpC10: Numero Destino                                       ³±±
±±³          ³ExpC11: Parcela Destino                                      ³±±
±±³          ³ExpC12: Tipo Destino                                         ³±±
±±³          ³ExpC13: Cliente Destino                                      ³±±
±±³          ³ExpC14: Loja Destino                                         ³±±
±±³          ³ExpC15: Loja Destino                                         ³±±
±±³          ³ExpC16: Filial destino                                       ³±±
±±³          ³ExpC17: Sequencia de baixa                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³Esta rotina tem como objetivo criar o registro relacionado ao³±±
±±³          ³titulo aglutinador                                           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Geral                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FCriaFIH(cEntOri, cPrefOri, cNumOri, cParcOri, cTipoOri, cCfOri, cLojaOri,;
							cEntDes, cPrefDes, cNumDes, cParcDes, cTipoDes, cCfDes, cLojaDes,;
							cFilDes, cFIHSeq )

Local aArea			:= GetArea()


RecLock("FIH",.T.)
FIH->FIH_FILIAL := xFilial("FIH")
FIH->FIH_ENTORI := cEntOri
FIH->FIH_PREFOR := cPrefOri
FIH->FIH_NUMORI := cNumOri
FIH->FIH_PARCOR := cParcOri
FIH->FIH_TIPOOR := cTipoOri
FIH->FIH_CFORI  := cCfOri
FIH->FIH_LOJAOR := cLojaOri

FIH->FIH_ENTDES := cEntDes
FIH->FIH_PREFDE := cPrefDes
FIH->FIH_NUMDES := cNumDes
FIH->FIH_PARCDE := cParcDes
FIH->FIH_TIPODE := cTipoDes
FIH->FIH_CFDES  := cCfDes
FIH->FIH_LOJADE := cLojaDes
FIH->FIH_FILDES := cFilDes
FIH->FIH_SEQ    := cFIHSeq
FIH->FIH_ROTINA := FUNNAME()
FIH->FIH_OPERAC := "  "

FIH->(MsUnlock())

RestArea(aArea)

Return Nil


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040RetPR ºAutor  ³ Carlos A. Queiroz   º Data ³  06/27/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Efetua o estorno de titulos provisorios.                   º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040RetPR()
Local cWhileFIH := (xFilial("FIH")+"SE1"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)
Local aAreaSE1	:= SE1->(GetArea())
PRIVATE lMsErroAuto := .F.

dbselectarea("FIH")
dbsetorder(2)
If dbseek(xFilial("FIH")+"SE1"+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)
	While cWhileFIH == (FIH->FIH_FILDES+"SE1"+FIH->FIH_PREFDE+FIH->FIH_NUMDES+FIH->FIH_PARCDE+FIH->FIH_TIPODE+FIH->FIH_CFDES+FIH->FIH_LOJADE)

		lMsErroAuto := .F.
		dbselectarea("SE5")
		dbsetorder(7)
		if dbseek(xFilial("SE5")+FIH->FIH_PREFOR+FIH->FIH_NUMORI+FIH->FIH_PARCOR+FIH->FIH_TIPOOR+FIH->FIH_CFORI+FIH->FIH_LOJAOR)
			aVetor 	:= {{"E1_PREFIXO"	, SE5->E5_PREFIXO 		,Nil},;
			{"E1_NUM"		, SE5->E5_NUMERO       	,Nil},;
			{"E1_PARCELA"	, SE5->E5_PARCELA  		,Nil},;
			{"E1_TIPO"	    , SE5->E5_TIPO     		,Nil},;
			{"AUTMOTBX"	    , SE5->E5_MOTBX      	,Nil},;
			{"AUTDTBAIXA"	, SE5->E5_DATA			,Nil},;
			{"AUTDTCREDITO" , SE5->E5_DTDISPO		,Nil},;
			{"AUTHIST"	    , STR0137+alltrim(SE5->E5_PREFIXO)+STR0129+alltrim(SE5->E5_NUMERO)+STR0130+alltrim(SE5->E5_PARCELA)+STR0131+alltrim(SE5->E5_TIPO)+"."	,Nil},; //"Estorno de Baixa referente a substituicao de titulo tipo Provisorio para Efetivo. Prefixo: "#", Numero: "#", Parcela: "#", Tipo: "
			{"AUTVALREC"	, SE5->E5_VALOR		    ,Nil}}

			MSExecAuto({|x,y| Fina070(x,y)},aVetor,5)
			If lMsErroAuto
				DisarmTransaction()
				MostraErro()
			ElseIf SE1->E1_STATUS == "A"
				Reclock("FIH" ,.F.,.T.)
				FIH->(dbDelete())
				FIH->(MsUnlock())
			EndIf
		EndIf
		FIH->(DbSkip())
	EndDo

EndIf

RestArea(aAreaSE1)

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³Fa040LstPreºAutor ³Vendas Cliente	     º Data ³  02/16/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Rotina que verifica se o titulo foi gerado a partir da listaº±±
±±º          ³de presentes e elimina os vinculos						  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ LOJA846													  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function Fa040LstPre()

Local aArea		:= GetArea()																		//Grava a area atual
Local cChaveSE1	:= xFilial("ME4") + SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO	//Chave de Pesquisa para a tabela ME4

DbSelectArea("ME4")
DbSetOrder(2)	//ME4_FILIAL+ME4_PRFTIT+ME4_NUMTIT+ME4_PARTIT+ME4_TIPTIT
If ME4->( dbSeek( cChaveSE1 ) )
	While !ME4->( Eof() ) .And. cChaveSE1 == ME4->ME4_FILIAL + ME4->ME4_PRFTIT + ME4->ME4_NUMTIT + ME4->ME4_PARTIT + ME4->ME4_TIPTIT
		If ME4->ME4_TIPREG == "1"	//Credito
			RecLock("ME4",.F.)
			ME4->ME4_PRFTIT	:= Space(TamSX3("ME4_PRFTIT")[1])
			ME4->ME4_NUMTIT	:= Space(TamSX3("ME4_NUMTIT")[1])
			ME4->ME4_PARTIT	:= Space(TamSX3("ME4_PARTIT")[1])
			ME4->ME4_TIPTIT	:= Space(TamSX3("ME4_TIPTIT")[1])
			ME4->( MsUnLock() )
		Else						//Debito
			RecLock("ME4",.F.)
			ME4->( dbDelete() )
			ME4->( MsUnLock() )
		EndIf

		ME4->( dbSkip() )
	End
EndIf

RestArea(aArea)

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ F040RetParc º Autor ³ Gustavo Henrique º Data ³  12/07/11  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Formatando o valor da parcela de acordo com o seu tamanho  º±±
±±º          ³ para fazer com que a sequencia dos desdobramentos siga a   º±±
±±º          ³ sequencia da parcela declarada em E1_PARCELA, independente º±±
±±º          ³ do tamanho utilizado no campo.                             º±±
±±º          ³ Ex: Se parcela for definida como 3, a sequencia sera 04 e  º±±
±±º          ³ nao 31 como estava antes.                                  º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ EXPC1 - Parcela atual                                      º±±
±±º          ³ EXPC2 - Tipo de parcela de acordo com MV_1DUP              º±±
±±º          ³         "N" - Numerico           					      º±±
±±º          ³         "C" - Caracter       	                          º±±
±±º          ³ EXPC3 - Tamanho da parcela		                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ EXPC1 - Nova parcela	  				                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ FINA040 - Desdobramento titulos a receber - GeraParcSE1()  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function F040RetParc( cParcSE1, cTipoPar, nTamParc )

If cTipoPar == "N"
	cParcSE1 := StrZero( Val( cParcSE1 ), nTamParc )
EndIf

cParcSE1 := Soma1( cParcSE1, nTamParc, .T. )

Return cParcSE1

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³INTEGDEF  ºAutor  ³Wilson de Godoi      º Data ³ 06/02/2012 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Função para a interação com EAI                             º±±
±±º          ³envio e recebimento                                         º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function IntegDef( cXml, nType, cTypeMsg )
		Local aRet := {}
		aRet:= FINI040( cXml, nType, cTypeMsg )
Return aRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³FVerImpRet³ Autor ³ Andre Lago            ³ Data ³ 09/08/12 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica o valor minimo de retencao dos impostos IR, PIS   ³±±
±±³          ³ COFINS, CSLL para retenção na baixa para RA                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe	 ³ FVerImpRet() 								              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ FINA040													  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function FVerImpRet(lVerRet)

Local nVlMinImp 	:= GetNewPar("MV_VL10925",5000)
Local cModRet   	:= GetNewPar( "MV_AB10925", "0" )
Local lContrRet 	:= .T.
Local lContrRetIRF	:= .T.
Local cModRetIRF 	:= GetNewPar("MV_IRMP232", "0" )
Local cRetCli   	:= "1"
Local nVlMinIrf 	:= 0
Local aSomaImp	  	:= {0,0,0}
Local aAreaSe1 		:=  SE1->(GetArea())
Local lMenor 		:= .F.
Local lRetBaixado 	:= .F.
Local cCond 		:= ""
//Controla o Pis Cofins e Csll na baixa (1-Retem PCC na Baixa ou 2-Retem PCC na Emissão(default))
Local lPccBxCr		:= FPccBxCr()
//639.04 Base Impostos diferenciada
Local lBaseImp		:= F040BSIMP()

Default lVerRet 	:= .T.

If M->E1_EMISSAO >= dLastPcc
	nVlMinImp	:= 0
EndIf

If lPccBxCr
	If lContrRet .Or. lContrRetIRF
		If cPaisLoc $ "ANG|ARG|AUS|BOL|BRA|CHI|COL|COS|DOM|EQU|EUA|HAI|MEX|PAD|PAN|PAR|PER|POR|PTG|SAL|URU|VEN"
			cRetCli := Iif(Empty(SA1->A1_ABATIMP),"1",SA1->A1_ABATIMP)
		Endif
	Endif
	If (lContrRetIRF .Or. lContrRet) .And. (cModRet != "0" .Or. cModRetIRF != "0")
	   //Nao retem Pis,Cofins,CSLL
		If cRetCli == "3"  //Nao retem PIS
			If cModRet !="0"
				nVlRetPis := M->E1_PIS
				nVlRetCof := M->E1_COFINS
				nVlRetCsl := M->E1_CSLL
				M->E1_PIS := 0
				M->E1_COFINS := 0
				M->E1_CSLL := 0
			Endif
			If cModRetIRF != "0"
				nVlRetIRF := M->E1_IRRF
				M->E1_IRRF := 0
			Endif
		Endif

		If cRetCli<>"3"
			If lVerRet .and. M->E1_TIPO $ MVRECANT
				aDadosRet := F040TImpBx(M->E1_VENCREA)
			Endif
			IF cRetCli == "1"		//Calculo do Sistema
				If cModRet == "1"  //Verifica apenas este titulo

					//639.04 Base Impostos diferenciada
					If lBaseImp .and. M->E1_BASEIRF > 0
						cCond := "M->E1_BASEIRF"
					Else
						cCond := "M->E1_VALOR"
					Endif

					AFill( aDadosRet, 0 )
				ElseIf cModRet == "2"  //Verifica o total acumulado no mes/ano

					//639.04 Base Impostos diferenciada
					If lBaseImp .and. M->E1_BASEIRF > 0
						cCond := "aDadosRet[1]+M->E1_BASEIRF"
					Else
						cCond := "aDadosRet[1]+M->E1_VALOR"
					Endif

				Endif

				If cModRetIrf == "1" 	//Empresa se enquadra na MP232
					nVlMinIrf := nVlMinImp

					//Se for menor que o valor minimo para retencao de IRRF P Fisica
					If &cCond <= nVlMinIrf
						nVlRetIRF 		:= M->E1_IRRF
						M->E1_IRRF 		:= 0
					Endif
	   			Endif

				//Se for menor que o valor minimo para retencao de IRRF P Fisica mas
				//Se for maior que o valor minimo para retencao de Pis, Cofins e Csll
				If &cCond <= nVlMinImp
					nVlRetPis := M->E1_PIS
					nVlRetCof := M->E1_COFINS
					nVlRetCsl := M->E1_CSLL
					M->E1_PIS 		:= 0
					M->E1_COFINS 	:= 0
					M->E1_CSLL 		:= 0
					lMenor := .T.
				Endif
			Endif

			If M->E1_PIS+M->E1_COFINS+M->E1_CSLL+M->E1_IRRF > 0

				If	M->E1_PIS+M->E1_COFINS+M->E1_CSLL > 0

					IF M->E1_PIS > 0 .And. (M->E1_PIS != nVlOriPis)
						nVlRetPis := M->E1_PIS
					Endif

					IF M->E1_COFINS > 0 .And. (M->E1_COFINS != nVlOriCof)
						nVlRetCof := M->E1_COFINS
					Endif

					IF M->E1_CSLL > 0 .And. (M->E1_CSLL != nVlOriCsl .Or. lAltera)
						nVlRetCsl := M->E1_CSLL
					Endif

					//Caso o usuario tenha alterado os valores de pis, cofins e csll, antes da cofirmacao
					//respeito o que foi informado descartando o valor canculado.
					If lVerRet
						If !lMenor .Or. lRetBaixado
							//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
							//³Alterar apenas quando o valor do imposto for diferente do   ³
							//³calculado (o que caracteriza alteração manual). A alteracao ³
							//³sem esta validacao faz com que os valores do PCC sejam      ³
							//³calculados erroneamente, jah que eh abatido de seu valor o  ³
							//³PCC do proprio titulo.                                      ³
							//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
							If nVlRetPis # nVlOriPis
								M->E1_PIS 	:= nVlRetPis + aDadosRet[2] - nVlOriPis
							Else
								If lAltera .and. ReadVar() $ "M->E1_VENCTO|M->E1_VENCREA"
									M->E1_PIS 	:= nVlRetPis + aDadosRet[2]
								Else
									M->E1_PIS 	:= nVlRetPis
								Endif
							Endif

							If nVlRetCof # nVlOriCof
								M->E1_COFINS := nVlRetCof + aDadosRet[3] - nVlOriCof
							Else
								If lAltera .and. ReadVar() $ "M->E1_VENCTO|M->E1_VENCREA"
									M->E1_COFINS := nVlRetCof + aDadosRet[3]
								Else
									M->E1_COFINS := nVlRetCof
								Endif
							Endif

							If nVlRetCsl # nVlOriCsl
								M->E1_CSLL 	:= nVlRetCsl + aDadosRet[4] - nVlOriCsl
							Else
								If lAltera .and. ReadVar() $ "M->E1_VENCTO|M->E1_VENCREA"
									M->E1_CSLL 	:= nVlRetCsl + aDadosRet[4]
								Else
									M->E1_CSLL 	:= nVlRetCsl
								Endif
							Endif
						Endif
					Endif
				Endif

				If M->E1_IRRF > 0	 .and. cModRetIrf == "1"
					nVlRetIRF := M->E1_IRRF
					//Caso o usuario tenha alterado os valores de pis, cofins e csll, antes da cofirmacao
					//respeito o que foi informado descartando o valor canculado.
					If lVerRet
						M->E1_IRRF 	:= nVlRetIRF+ aDadosRet[6]
					Endif
				Endif

				If lVerRet
					f040VerVlr()
				Endif

			Else
				//Natureza nao calculou Pis/Cofins/Csll
				AFill( aDadosRet, 0 )
			Endif
		Endif
	Endif
Endif
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³F040TImpBx³ Autor ³ Andre Lago    	    ³ Data ³05/08/2004³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Efetua o calculo do valor de titulos financeiros que        ³±±
±±³          ³calcularam a retencao do PIS / COFINS / CSLL e nao          ³±±
±±³          ³criaram os titulos de abatimento                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ExpA1 := F040TotMes( ExpD1 )                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ExpA1 -> Array com os seguintes elementos                   ³±±
±±³          ³       1 - Valor dos titulos                                ³±±
±±³          ³       2 - Valor do PIS                                     ³±±
±±³          ³       3 - Valor do COFINS                                  ³±±
±±³          ³       4 - Valor da CSLL                                    ³±±
±±³          ³       5 - Array contendo os recnos dos registos processados³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpD1 - Data de referencia                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function F040TImpBx(dReferencia)

Local aAreaSE1  := SE1->( GetArea() )
Local aAreaSE5  := SE5->( GetArea() )
Local aDadosRef := Array( 6 )
Local aRecnos   := {}
Local dIniMes   := FirstDay( dReferencia )
Local dFimMes   := LastDay( dReferencia )
Local cModTot   := GetNewPar( "MV_MT10925", "1" )
Local lTodasFil	:= ExistBlock("F040FRT")
Local aFil10925	:= {}
Local cFilAtu	:= FWGETCODFILIAL
Local lVerCliLj	:= ExistBlock("F040LOJA")
Local aCli10925	:= {}
Local nFil 			:= 0
Local lLojaAtu  := ( GetNewPar( "MV_LJ10925", "1" ) == "1" )
Local nLoop     := 0
Local lRaRtImp	:= lFinImp .And.FRaRtImp()
Local lIrrfBxPj := FIrPjBxCr()

//639.04 Base Impostos diferenciada
Local lBaseImp	 := F040BSIMP()

Local aStruct   := {}
Local aCampos   := {}
Local cQuery    := ""
Local cAliasQry := ""
Local cSepNeg   := If("|"$MV_CRNEG,"|",",")
Local cSepProv  := If("|"$MVPROVIS,"|",",")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Parametro que permite ao usuario utilizar o desdobramento³
//³da maneira anterior ao implementado com o rastreamento.  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

AFill( aDadosRef, 0 )

nRCalCSL := 0
nRCalCOF := 0
nRCalPIS := 0
nRCalIRF := 0

If lTodasFil
	aFil10925 := ExecBlock( "F040FRT", .F., .F. )
Else
	aFil10925 := { cFilAnt }
Endif

If lVerCliLj
	aCli10925 := ExecBlock("F040LOJA",.F.,.F.)
Endif
For nFil := 1 to Len(aFil10925)

	dbSelectArea("SE5")
	cFilAnt := aFil10925[nFil]

	aCampos := { "E5_VALOR","E5_VRETPIS","E5_VRETCOF","E5_VRETCSL","E5_VLJUROS","E5_VLMULTA","E5_VLDESCO", "E5_FORNADT", "E5_LOJAADT"}

	If lIrrfBxPj
		aadd(aCampos,"E5_VRETIRF")
	Endif

	aStruct := SE5->( dbStruct() )

	SE5->( dbCommit() )

  	cAliasQry := GetNextAlias()

	cQuery := "SELECT E5_PREFIXO,E5_NUMERO,E5_PARCELA,E5_TIPO,E5_CLIFOR,E5_LOJA,"
	cQuery += "E5_SEQ,E5_VALOR,E5_VRETPIS,E5_VRETCOF,E5_VRETCSL,E5_DATA,E5_VLJUROS,"
	cQuery += "E5_VLMULTA,E5_VLDESCO,E5_PRETPIS,E5_PRETCOF,E5_PRETCSL,E5_MOTBX,"
	cQuery += "E5_DOCUMEN,E5_RECPAG,E5_FORNADT,E5_LOJAADT,"

	If lIrrfBxPj
		cQuery += "E5_VRETIRF,"
	Endif

	cQuery += "R_E_C_N_O_ RECNOSE5 FROM "
	cQuery += RetSqlName( "SE5" ) + " SE5 "
	cQuery += "WHERE "
	cQuery += "E5_FILIAL='"    + xFilial("SE5")       + "' AND "

	If Len(aCli10925) > 0  //Verificar determinados CLIENTES (raiz do CNPJ)
		cQuery += "( "
		For nLoop := 1 to Len(aCli10925)
			cQuery += "(E5_CLIFOR ='"   + aCli10925[nLoop,1]  + "' AND "
			cQuery += "E5_LOJA='"       + aCli10925[nLoop,2]  + "') OR "
		Next
		//Retiro o ultimo OR
		cQuery := Left( cQuery, Len( cQuery ) - 4 )
		cQuery += ") AND "
	Else  //Apenas o Fornecedor Atual
		cQuery += "E5_CLIFOR='"		+ M->E1_CLIENTE			+ "' AND "
		If lLojaAtu  //Considero apenas a loja atual
			cQuery += "E5_LOJA='"		+ M->E1_LOJA				+ "' AND "
		EndIf
	Endif

	cQuery += "E5_DATA>= '"		+ DToS( dIniMes )      + "' AND "
	cQuery += "E5_DATA<= '"		+ DToS( dFimMes )      + "' AND "
	cQuery += "E5_TIPO NOT IN " + FormatIn(MVABATIM,"|") + " AND "
	cQuery += "E5_TIPO NOT IN " + FormatIn(MV_CRNEG,cSepNeg)  + " AND "
	cQuery += "E5_TIPO NOT IN " + FormatIn(MVPROVIS,cSepProv) + " AND "
	If !lRaRtImp
		cQuery += "E5_TIPO NOT IN " + FormatIn(MVRECANT,cSepRec)  + " AND "
	EndIf
	cQuery += "E5_RECPAG = 'R' AND "
	cQuery += "E5_MOTBX <> 'FAT' AND "
	cQuery += "E5_MOTBX <> 'STP' AND "
	cQuery += "E5_MOTBX <> 'LIQ' AND "
	cQuery += "E5_SITUACA <> 'C' AND "
	cQuery += "(E5_PRETPIS <= '1' OR E5_PRETCOF <= '1' OR E5_PRETCSL <= '1') AND "

	//Apenas titulos que tem retencao de PIS,Cofins e CSLL
	If cModTot == "2"
		cQuery += " ((E5_VRETPIS > 0 OR E5_VRETCOF > 0 OR E5_VRETCSL > 0) OR (E5_MOTBX = 'CMP')) AND "
   	Endif

	cQuery += "D_E_L_E_T_=' '"
	cQuery += "AND NOT EXISTS ( "
	cQuery += "SELECT A.E5_NUMERO "
	cQuery += "FROM "+RetSqlName("SE5")+" A "
	cQuery += "WHERE A.E5_FILIAL='"+xFilial("SE5")+"' AND "
	cQuery +=		"A.E5_PREFIXO=SE5.E5_PREFIXO AND "
	cQuery +=		"A.E5_NUMERO=SE5.E5_NUMERO AND "
	cQuery +=		"A.E5_PARCELA=SE5.E5_PARCELA AND "
	cQuery +=		"A.E5_TIPO=SE5.E5_TIPO AND "
	cQuery +=		"A.E5_CLIFOR=SE5.E5_CLIFOR AND "
	cQuery +=		"A.E5_LOJA=SE5.E5_LOJA AND "
	cQuery +=		"A.E5_SEQ=SE5.E5_SEQ AND "
	cQuery +=		"A.E5_TIPODOC='ES' AND "
	cQuery +=		"A.E5_RECPAG<>'R' AND "
	cQuery +=		"A.D_E_L_E_T_<>'*')"

	cQuery := ChangeQuery( cQuery )

	dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), cAliasQry, .F., .T. )

	For nLoop := 1 To Len( aStruct )
		If !Empty( AScan( aCampos, AllTrim( aStruct[nLoop,1] ) ) )
			TcSetField( cAliasQry, aStruct[nLoop,1], aStruct[nLoop,2],aStruct[nLoop,3],aStruct[nLoop,4])
		EndIf
	Next nLop

	( cAliasQRY )->(DBGOTOP())

	While !( cAliasQRY )->( Eof())
		//Todos os titulos
		If cModTot == "1"
			SE1->(dbSetOrder(1))
			IF !(SE1->(MsSeek(xFilial("SE1")+(cAliasQRY)->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA))))
				(cAliasQRY)->(DbSkip())
				Loop
			Endif

			//639.04 Base Impostos diferenciada
			If lBaseImp .and. SE1->E1_BASEPIS > 0
				adadosref[1] += SE1->E1_BASEPIS
			Else
				aDadosRef[1] += ( cAliasQRY )->E5_VALOR
			Endif

			// Se ha pendencia de retencao, retorno os valores pendentes
			If ( (!Empty( ( cAliasQRY )->E5_VRETPIS ) ;
				.Or. !Empty( ( cAliasQry )->E5_VRETCOF ) ;
				.Or. !Empty( ( cAliasQry )->E5_VRETCSL ) ))

				If ( ( cAliasQRY )->E5_PRETPIS == "1" ;
					.Or. ( cAliasQry )->E5_PRETCOF == "1" ;
					.Or. ( cAliasQry )->E5_PRETCSL == "1" )
					aDadosRef[2] += ( cAliasQRY )->E5_VRETPIS
					aDadosRef[3] += ( cAliasQRY )->E5_VRETCOF
					aDadosRef[4] += ( cAliasQRY )->E5_VRETCSL
					nRCalCSL	   += SE1->E1_BASECSL
					nRCalPIS	   += SE1->E1_BASEPIS
					nRCalCOF	   += SE1->E1_BASECOF
					AAdd( aRecnos, ( cAliasQRY )->RECNOSE5 )
				EndIf
			EndIf
			If	lIrrfBxPj .And. !Empty( (cAliasQRY)->E5_VRETIRF )
				aDadosRef[6] += (cAliasQRY)->E5_VRETIRF
				aDadosRef[1] += (cAliasQRY)->E5_VRETIRF
				If cPaisLoc == "BRA"
					nRCalIRF	   += SE1->E1_BASEIRF
				EndIf
				If Len(aRecnos)==0 .Or.aRecnos[Len(aRecnos)] <>  (cAliasQRY)->RECNOSE5
					AAdd( aRecnos, (cAliasQRY)->RECNOSE5 )
				Endif
			Endif
		Else
        //Apenas titulos que tiveram Pis Cofins ou Csll
			If ( cAliasQRY )->(E5_VRETPIS+E5_VRETCOF+E5_VRETCSL+E5_VRETIRF) > 0
				SE1->(dbSetOrder(1))
				IF !(SE1->(MsSeek(xFilial("SE1")+(cAliasQRY)->(E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA))))
					(cAliasQRY)->(DbSkip())
					Loop
				Endif
				//639.04 Base Impostos diferenciada
				If lBaseImp .and. SE1->E1_BASEPIS > 0
					adadosref[1] += SE1->E1_BASEPIS
				Else
					aDadosRef[1] += ( cAliasQRY )->E5_VALOR
				Endif

				If !Empty( ( cAliasQRY )->E5_VRETPIS ) .And.;
				 	!Empty( ( cAliasQry )->E5_VRETCOF ) .And. ;
					!Empty( ( cAliasQry )->E5_VRETCSL )

					If ( ( cAliasQRY )->E5_PRETPIS == "1" ;
						.Or. ( cAliasQry )->E5_PRETCOF == "1" ;
						.Or. ( cAliasQry )->E5_PRETCSL == "1" )
						aDadosRef[2] += ( cAliasQRY )->E5_VRETPIS
						aDadosRef[3] += ( cAliasQRY )->E5_VRETCOF
						aDadosRef[4] += ( cAliasQRY )->E5_VRETCSL
						nRCalCSL	   += SE1->E1_BASECSL
						nRCalPIS	   += SE1->E1_BASEPIS
						nRCalCOF	   += SE1->E1_BASECOF
						AAdd( aRecnos, ( cAliasQRY )->RECNOSE5 )
					EndIf
				EndIf
				If	lIrrfBxPj .And. !Empty( (cAliasQRY)->E5_VRETIRF )
					aDadosRef[6] += (cAliasQRY)->E5_VRETIRF
					If cPaisLoc == "BRA"
						nRCalIRF += SE1->E1_BASEIRF
					EndIf
					If! ( lBaseImp .and. SE1->E1_BASEPIS > 0 )
						aDadosRef[1] += (cAliasQRY)->E5_VRETIRF
					Endif
					If Len(aRecnos)==0 .Or. aRecnos[Len(aRecnos)] <>  (cAliasQRY)->RECNOSE5
						AAdd( aRecnos, (cAliasQRY)->RECNOSE5 )
					Endif
				Endif
			Endif
		Endif
		( cAliasQRY )->( dbSkip())

	EndDo

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Fecha a area de trabalho da query                                      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	( cAliasQRY )->( dbCloseArea() )
	dbSelectArea( "SE1" )

Next

cFilAnt := cFilAtu

aDadosRef[ 5 ] := AClone( aRecnos )

SE1->( RestArea( aAreaSE1 ) )
SE5->( RestArea( aAreaSE5 ) )

Return( aDadosRef )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³F040TOPBLQºAutor  ³Jandir Deodato      º Data ³ 18/10/2012 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Função para verificar se o titulo                            º±±
±±º          ³esta bloqueado no Totvs Obras e Projetos                     º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function F040TOPBLQ()
Local aArea:=GetArea()
Local aAreaAFT
Local lViaAFT :=.F.
Local lRet :=.F.

If lPmsInt .And. SE1->E1_ORIGEM # "WSFINA04" .and. !lF040Auto .and. !(cPaisLoc $('BRA|'))
	dbSelectArea("AFT")
	aAreaAFT  := AFT->(GetArea())
	dbSetOrder(2)//AFT_FILIAL+AFT_PREFIX+AFT_NUM+AFT_PARCEL+AFT_TIPO+AFT_CLIENT+AFT_LOJA+AFT_PROJET+AFT_REVISA+AFT_TAREFA
	lViaAFT:=.T.
	If MsSeek(xFilial("AFT")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO+SE1->E1_CLIENTE+SE1->E1_LOJA)
		If lViaAFT
		  If AFT->AFT_VIAINT == 'S'
				lRet:=.T.
			Endif
		Endif
	Endif
	RestArea(aAreaAFT)
End	if
RestArea(aArea)
return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ F040Vend º Autor ³   Julio Saraiva      º Data ³ 25/06/2013º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ajusta X3_VALID do campo E1_CLIENTE                         º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                         º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function F040Vend()
Local aArea		:= GetArea()
Local aAreaSA1	:= IIF(SELECT("SA1") > 0, SA1->( GetArea() ), {})
Local lIsAlt	:= ReadVar() $ "M->E1_CLIENTE|M->E1_LOJA|M->E1_VEND1"

//se o campo ja está preenchido não será sobreposto
IF Empty(M->E1_VEND1)

	dbSelectArea("SA1")
	dbSetOrder(1)
	If MsSeek(xFilial("SA1") + M->E1_CLIENTE + M->E1_LOJA ) .And. !Empty(SA1->A1_VEND)
		If lF040Auto
			M->E1_VEND1 := IIF(Empty(M->E1_VEND1), SA1->A1_VEND, M->E1_VEND1)
		Else
			M->E1_VEND1 := SA1->A1_VEND
		EndIf
		If SA1->A1_COMIS > 0
			M->E1_COMIS1 := SA1->A1_COMIS
		Else
			M->E1_COMIS1 := Posicione("SA3",1,xFilial("SA3") + SA1->A1_VEND,"A3_COMIS")
		Endif
	Else
		If lIsAlt
			M->E1_VEND1  := Space(TamSX3("E1_VEND1")[1]) //cliente não possui vendedor.
		EndIf
	Endif
EndIf

If !Empty(aAreaSA1)
	RestArea( aAreaSA1 )
EndIf

RestArea( aArea )

Return (.T.)


/*/{Protheus.doc}FA040VLMV
Verifica se na inclusão de titulos, tipo RA.
A Natureza permite movimentação bancaria

@author Thiago Malaquias
@since  24/05/2014
@version 12
/*/
Function FA040VLMV()

Local lRet := .T.
Local aArea := GetArea()

If M->E1_TIPO $ MVRECANT .And. Posicione("SED",1,xfilial("SED") + M->E1_NATUREZ,"ED_MOVBCO") == "2"
	Help(" ",1,"FA040VLMV", , STR0158,1,0) //"A natureza não permite movimento bancário"
	lRet:=.F.
Endif

RestArea(aArea)

Return lRet

/*/{Protheus.doc}F040VldVlr
Verifica se o valor do título está negativo.

@author Daniel Mendes
@since  18/11/2014
@version 12
/*/
Function F040VldVlr()
Local lRet := .T.

If ( M->E1_VALOR + M->E1_ACRESC ) - ( M->E1_ISS + M->E1_DECRESC + M->E1_INSS + M->E1_IRRF + M->E1_CSLL + M->E1_COFINS + M->E1_PIS ) < 0
	MsgAlert( STR0161 , STR0064 )
	lRet := .F.
EndIf

Return lRet

/*/{Protheus.doc} F040VERPAR
Validação do campo E1_PARCELA
@author TOTVS S/A
@since 25/02/2015
@version P12.1.4
@return Retorno Booleano da validação dos dados
/*/

FUNCTION F040VERPAR()

Local lRet := .T.

lRet := FA040Num()

RETURN lRet


//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//± Funcao	   	  	: FA040PenC
//± Autor         : Totvs
//± Data          : 18/03/2015
//± Uso           : Rotina que verifica se há títulos
//±						pendentes de contabilização
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

Function FA040PenC(aChave)

Local aPenCont := {}
Local cQuery := ""
Local lRet := .F.
Local aArea := SE5->(GetArea())
Local cLAP	:= 'S'
Local cLAR	:= 'S'

cQuery := " SELECT P.LAP,P.RECNOP,R.LAR,R.RECNOR "
cQuery += " FROM "
cQuery += " (SELECT  E5_LA LAP, R_E_C_N_O_ RECNOP "
cQuery += " FROM "+ RetSqlName( "SE5" ) + " SE5 "
cQuery += " WHERE D_E_L_E_T_ = ' '  AND "
cQuery += " E5_FILIAL = '" +aChave[1]+ "' AND "
cQuery += " E5_PREFIXO = '" +aChave[2]+ "' AND "
cQuery += " E5_NUMERO = '" +aChave[3]+ "' AND "
cQuery += " E5_PARCELA = '" +aChave[4]+ "' AND "
cQuery += " E5_TIPO = '" +aChave[5]+ "' AND "
cQuery += " E5_CLIFOR = '" +aChave[6]+ "' AND "
cQuery += " E5_LOJA = '" +aChave[7]+ "' AND "
cQuery += " E5_SITUACA <> 'C' AND "
cQuery += " E5_RECPAG = 'P')P,  "
cQuery += " (SELECT  E5_LA LAR, R_E_C_N_O_ RECNOR "
cQuery += " FROM "+ RetSqlName( "SE5" ) + " SE5 "
cQuery += " WHERE D_E_L_E_T_ = ' '  AND "
cQuery += " E5_FILIAL = '" +aChave[1]+ "' AND "
cQuery += " E5_PREFIXO = '" +aChave[2]+ "' AND "
cQuery += " E5_NUMERO = '" +aChave[3]+ "' AND "
cQuery += " E5_PARCELA = '" +aChave[4]+ "' AND "
cQuery += " E5_TIPO = '" +aChave[5]+ "' AND "
cQuery += " E5_CLIFOR = '" +aChave[6]+ "' AND "
cQuery += " E5_LOJA = '" +aChave[7]+ "' AND "
cQuery += " E5_SITUACA <> 'C' AND "
cQuery += " E5_RECPAG = 'R')R  "


If Select("TSQL") > 0
	dbSelectArea("TSQL")
	DbCloseArea()
EndIf

dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),"TSQL",.F.,.T.)

dbSelectArea("TSQL")
dbGotop()
Do While TSQL->(!Eof())
	TCSetField("TSQL", "RECNOP" ,"N",16,0)
	TCSetField("TSQL", "RECNOR" ,"N",16,0)
	cLAP	:= If(alltrim(TSQL->LAP) <> 'S','N','S')
	cLAR	:= If(alltrim(TSQL->LAR) <> 'S','N','S')

	If alltrim(cLAP) <> alltrim(cLAR)
		If alltrim(cLAP) <> 'S'
			aAdd(aPenCont,TSQL->RECNOP)
		Else
			aAdd(aPenCont,TSQL->RECNOR)
		Endif
	Endif
	TSQL->(DbSkip())
EndDo

DbCloseArea()
RestArea(aArea)

Return aPenCont


Function FA040MonP(aPenCont)

Local lRet		:= .F.
Local nX 		:= 0
Local aReg 	:= {}
Local oDlg
Local cTit 	:=  ""
Local cReg		:= " { "
Local cTxtRotAut := ""
Local aArea		:= SE5->(GetArea())

DbSelectArea("SE5")
For nX := 1 to Len(aPenCont)
	If nX > 1
		cReg += " , "
	EndIf
	DbGoTo(aPenCont[nX])
 	cReg += " { '" + Alltrim(E5_TIPODOC)+ "','"+ VerTpDoc(E5_TIPODOC)+ "',Val('" + Str(Round(E5_VALOR,2))+ "') ,'" + Alltrim(E5_SEQ)+ "','" +AllTrim(Str(aPenCont[nX])) + "' }	"
Next nX
cReg		+= " } "
aReg		:= &(cReg)

cTit := SE5->(E5_FILIAL + E5_PREFIXO + E5_NUMERO + E5_PARCELA + E5_TIPO  + E5_CLIFOR + E5_LOJA )
If !FwIsInCallStack("FaAvalSE1") .And. !lF040Auto

	DEFINE MSDIALOG oDlg TITLE STR0039 FROM 180,180  TO 500,700 PIXEL
		@ 10, 10 TO 130,255 of oDlg PIXEL
		@ 20, 030 SAY STR0163 SIZE 170,10 of oDlg PIXEL
		@ 35, 030 SAY STR0164 SIZE 30,10 of oDlg PIXEL
		@ 35, 070 SAY cTit SIZE 100,10 of oDlg PIXEL
		@ 50, 030 SAY STR0165 SIZE 170,10 of oDlg PIXEL
		@ 25, 220 BUTTON STR0009 SIZE 030, 015 PIXEL OF oDlg ACTION (lRet := .T., oDlg:End())
		@ 45, 220 BUTTON STR0166 SIZE 030, 015 PIXEL OF oDlg ACTION (lRet := .F., oDlg:End())

		oBrowse := TWBrowse():New( 70 , 15, 235,50,,{STR0170,STR0171,STR0172,STR0173,'Recno'},{30,100,30,50,30},;
				oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )

		oBrowse:SetArray(aReg)
		oBrowse:bLine := &("{ || {aReg[oBrowse:nAt,01], aReg[oBrowse:nAt,02], aReg[oBrowse:nAt,03], aReg[oBrowse:nAt,04], aReg[oBrowse:nAt,05] } } ")
		oBrowse:lColDrag	:= .T.

	ACTIVATE MSDIALOG oDlg
Else
	lRet := .F.
	If lF040DELC
		lRet := Execblock("F040DELC",.F.,.F.,aReg)
	EndIf
	If !lRet
		cTxtRotAut := STR0167 +cTit+ STR0168
		cTxtRotAut += STR0169 +CRLF+CRLF
		lMsErroAuto := .F.
		Help(" ",1,"PENCONT","FINA040 - " + STR0007,cTxtRotAut,1,0)

	EndIf
EndIF

RestArea(aArea)

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc}FI040PerAut
Carrega o valor das variaveis da rotina automatica
@author Alvaro Camillo Neto
@since  08/10/2015
@version 12
/*/
//-------------------------------------------------------------------
Function FI040PerAut()
Local nX 		:= 0
Local cVarParam := ""

If Type("aParamAuto") != "U"
	For nX := 1 to Len(aParamAuto)
		cVarParam := Alltrim(Upper(aParamAuto[nX][1]))
		If "MV_PAR" $ cVarParam
			&(cVarParam) := aParamAuto[nX][2]
		EndIf
	Next nX
EndIf

Return

//-------------------------------------------------------------------
/*/ {Protheus.doc} F040VLDSDAC
Função de validação de alteração do valor do acrescimos, quando houver baixa no saldo do acrescimo

@sample F040VLDSDAC()
@author Caio Quiqueto dos Santos
@since 02/06/2016
@version 1.0

@return lRet	se o valor é valido ou não
/*/
//-------------------------------------------------------------------

Function F040VLDSDAC()
Local lRet := .T.

	If SE1->E1_SALDO != SE1->E1_VALOR
		If !(SE1->E1_SALDO == 0)
			If SE1->E1_ACRESC != SE1->E1_SDACRES
				If (M->E1_ACRESC < (SE1->E1_ACRESC - SE1->E1_SDACRES)) .OR. ( M->E1_ACRESC == SE1->E1_SDACRES .AND. M->E1_ACRESC != SE1->E1_ACRESC )
					HELP(" ",1,"SDACRES")
					lRet := .F.
				Endif
			 Endif
		EndIf
	ElseIf M->E1_SALDO == SE1->E1_VALOR .AND. SE1->E1_ACRESC != SE1->E1_SDACRES
		If M->E1_ACRESC < SE1->E1_SDACRES
			HELP(" ",1,"SDACRES")
			lRet := .F.
		EndIf
	Endif

Return lRet


Function CalcINSS(nBaseInss, lRegra)
Local nCalcINSS := 0
Local nDedBase := 0
Local nDedValor := 0

Default nBaseInss := M->E1_VALOR
Default lRegra := .T.

If cPaisLoc == "BRA"
	nDedBase := Fa986regra("SE1","INSS","1" )
	If lRegra
		nDedValor := Fa986regra("SE1","INSS","2" )
	EndIf
EndIf

nBaseInss := nBaseInss + nDedBase

If SED->ED_CALCINS == "S" .and. SA1->A1_RECINSS == "S"
	If !Empty(SED->ED_BASEINS)
		nBaseInss := NoRound((nBaseInss * (SED->ED_BASEINS/100)),2)
	EndIf
	nCalcINSS := (nBaseInss * (SED->ED_PERCINS / 100))
EndIf
nCalcINSS := nCalcINSS + nDedValor

If nCalcINSS < 0
	nCalcINSS := 0
EndIf

Return nCalcINSS

//-------------------------------------------------------------------
/*/{Protheus.doc} F040VLDSBPR
Função de validação de alteração da data de emissão quando houver substituição de titulo

@sample F040VLDSBPR()
@author Fagner Barreto
@since 23/06/2017
@version 1.0

@return lRet se a data é valida ou não
/*/
//-------------------------------------------------------------------

Function F040VLDSBPR()
Local lRet := .T.

	If IsInCallStack('FA040Subst')
		If M->E1_EMISSAO < SE1->E1_EMISSAO
			Help( " ", 1, "DATAERR" )
			lRet := .F.
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/ {Protheus.doc} Fa040VA
Função de inclusão de valores acessórios para titulos CR

@author Mauricio Pequim Jr
@since 02/08/2016
@version 1.0

@return lRet	se o processo foi concluido com sucesso
/*/
//-------------------------------------------------------------------
Function Fa040VA(lVAAuto)

Local oModelVA		:= NIL
Local oSubFKD		:= NIL
Local cChave		:= ""
Local cIdDoc		:= ""
Local cLog			:= ""
Local lRet			:= .T.
Local nX			:= 0
Local nTamCod		:= 0

DEFAULT lVAAuto	:= .F.

If __lExisFKD
	nTamCod	:=	TamSx3("FKD_CODIGO")[1]

	If lVAAuto
		//Rotina Automática para VA
		oModelVA := FWLoadModel('FINA040VA')
		oModelVA:SetOperation( 4 ) //Alteração
		oModelVA:Activate()

		oSubFKD := oModelVA:GetModel('FKDDETAIL')

		cChave := xFilial("SE1",SE1->E1_FILORIG) +"|"+ SE1->E1_PREFIXO +"|"+ SE1->E1_NUM +"|"+ SE1->E1_PARCELA +"|"+ SE1->E1_TIPO +"|"+ SE1->E1_CLIENTE +"|"+ SE1->E1_LOJA
		cIdDoc := FINGRVFK7( 'SE1', cChave )
		oModelVA:LoadValue("FK7DETAIL","FK7_IDDOC", cIdDoc )

		For nX := 1 to Len(aVAAuto)
			If !oSubFKD:IsEmpty()
				oSubFKD:AddLine()
			EndIf
			oSubFKD:SetValue("FKD_CODIGO"	, Padr(aVAAuto[nX,1],nTamCod) )
			oSubFKD:SetValue("FKD_VALOR"	, aVAAuto[nX,2] )
		Next

		If oModelVA:VldData()
			FWFormCommit( oModelVA )
		Else
			lRet	 := .F.
			cLog := cValToChar(oModelVA:GetErrorMessage()[4]) + ' - '
			cLog += cValToChar(oModelVA:GetErrorMessage()[5]) + ' - '
			cLog += cValToChar(oModelVA:GetErrorMessage()[6])
			Help( ,,"F040VALAC",,cLog, 1, 0 )
		Endif
		oModelVA:Deactivate()
		oModelVA:Destroy
		oModelVA := NIL

	Else
		//Chamada com tela para cadastro de VA do títulos CR
		If __lFINA040VA .And. MsgYesNo(STR0200,STR0039)		//"Deseja cadastrar os valores acessórios deste título agora?"###"Atençäo"
			FINA040VA()
		Endif
	Endif
Endif

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} f40IsDesdobr
Função que verifica se o titulo desdobrado é o titulo originador ou o gerado pelo desdobramento
@return lDesdobrPrin .T. se for o titulo originador. F se for o gerado pelo desdobramento

@author Karen Honda
@version P12
/*/
//-------------------------------------------------------------------

Static function f40IsDesdobr()
Local lDesdobrPrin := .F.

If Type("Inclui")=="U"
	Inclui:=.F.
EndIf

//Desconsiderar titulo originador de desdobramento
If Inclui
	lDesdobrPrin := M->E1_DESDOBR == "1"
Else
	dbSelectArea("FI7")
	FI7->(DbSetOrder(1))
	If dbSeek(xFilial("FI7")+ SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA))
		lDesdobrPrin := .T.
	Endif

Endif

Return lDesdobrPrin
