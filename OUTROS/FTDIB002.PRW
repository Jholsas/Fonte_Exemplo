#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TOTVS.CH"

#INCLUDE 'FONT.CH'
#INCLUDE 'COLORS.CH' 
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "xmlxfun.ch"

#DEFINE DS_MODALFRAME   128
#DEFINE X3_USADO_EMUSO "ÄÄÄÄÄÄÄÄÄÄÄÄÄÄ†"

/*/
‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±⁄ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒø±±
±±≥Programa  ≥FTDIB002  ≥   Fernando Rocha              ≥ Data ≥16.06.2011≥±±
±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒ¥±±
±±≥Descricao ≥TELA DO CONTROLE DE PESAGEM						          ≥±±
±±√ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¥±±
±±≥Uso       ≥DIACO                                                       ≥±±
±±¿ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± 04/04/2017: Inclus„o de tela para controle de DiferenÁa de Peso nas     ±±
±± entradas das Notas (Compra) enviando email para o financeiro. (F·bio L.)±±
±± 07/04/2017: Inclus„o de tela para controle de Entrada de DevoluÁ„o de   ±±
±± Venda.  													F·bio Loures   ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
/*/

USER FUNCTION FTDIB002

Private	xCodFil := "01" 
Private xCodEmp := "01"    

Private nPESENTR :=  nPESSAID := nPLIQ := nPNTS :=  nPDIF :=  0
Private cRecSF1  := ""  
Private cMsgDifQ := cMsgAss := ""
Private cInfF4   := "F4 - Informar as NF's"
Private oSay20  
Private cNotasS  := ""

//PREPARE ENVIRONMENT EMPRESA "01" FILIAL "01" MODULO "FAT"
//executa direto    sem precisar entrar no microsiga

//*/
RPCSetType(3)
If (Select("SZ8") == 0)
	RPCSetEnv(xCodEmp,xCodFil,"","","","",{"SZ8"})
Endif
//*/      
xCodEmp := "  "
Private _cUsuario := Space(15)
Private _cEmpresa := Space(35)

Private nParVaria:= Getnewpar("MV_YDIFNTA",10) // VariaÁ„o e diferenÁa considerada na pesagem

//AUTENTICAR USUARIO
_AVUSER := U_FACG001()
IF _AVUSER[1]
	//MONTAR INTERFACE
	_cUsuario := _AVUSER[2]
	_cEmpresa := _AVUSER[3]+"-"+SM0->M0_NOMECOM
	MontaTela()
ENDIF

RESET ENVIRONMENT

RETURN



//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//MONTAR A INTERFACE PRINCIPAL
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
STATIC FUNCTION MontaTela()

//OBJETOS LOCAL
Local nComboBo1 := 1
Local nComboBo2 := 1
Local nComboBo3 := 1
Local nComboBo4 := 1
Local oPanel1
Local oPanel2
Local oPanel3
Local oSay1
Local oSay10
Local oSay3
Local oSay5
Local oSay6
Local oSay7
Local oSay8
Local oSay9     
Local oSayKM


//ESPECIFICOS
Local _AliasTmp

//OBJETOS PRIVATE
Private oDlgBal
Private oSayPesagem
Private oSayUsuario
Private oComboBo1
Private oComboBo2
Private oComboBo3
Private oComboBo4
Private oGetLITROS
Private nGetLITROS := 0
Private nKM := 0
Private oButtonPESAR
Private oTimerBal
Private oSayDATA
Private oSayHORA
Private cPESAGEM := ""
Private oGetMOTOR
Private cGetMOTOR := SPACE(30)
Private oGetPLACA
Private cGetPLACA := SPACE(7)
Private oGetTRANSP
Private cGetTRANSP := SPACE(30)
Private oGetDOC
Private cGetDOC := SPACE(15)
Private oGetEMP
Private cGetEMP := SPACE(20)
Private oGetNFS
Private cGetNFS := SPACE(250)
Private oGetOBSERV
Private cGetOBSERV := SPACE(200)
Private oGetPESO
Private nGetPESO := 0
Private oGetPESONFS
Private nGetPESONFS := 0 
Private oGetKM     
Private cInfENTtmp := "" 
Private cInfENTt2  := ""

//ESPECIFICOS
Private dData := dDataBase
Private cHora := SubStr(Time(),1,8)
Private nTipoPesq := 1
//Private cRecNFS := ""
Private cPESENT := ""

//DEFINICAO DAS FONTES DA INTERFACE
Private oFont1 := TFont():New("Verdana",,026,,.T.,,,,,.F.,.F.)
Private oFont2 := TFont():New("Verdana",,026,,.F.,,,,,.F.,.F.)
Private oFont3 := TFont():New("Verdana",,026,,.T.,,,,,.F.,.F.)
Private oFont4 := TFont():New("Verdana",,026,,.F.,,,,,.F.,.F.)
Private oFont5 := TFont():New("Verdana",,026,,.T.,,,,,.F.,.F.)
Private oFont6 := TFont():New("Verdana",,032,,.T.,,,,,.F.,.F.)
Private oFont7 := TFont():New("Verdana",,032,,.T.,,,,,.F.,.F.)
Private oFont8 := TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
Private oFont9 := TFont():New("Verdana",,014,,.T.,,,,,.F.,.F.)
Private oFont10:= TFont():New("Verdana",,017,,.T.,,,,,.F.,.F.)


//LISTAS PARA OS COMBOBOX
Private aTPDados 	:= {" ","E","S","I","T"}
Private aTPList 	:= {" ","1-ENTRADA","2-SAIDA","3-INTERMEDIARIA","4-ENTRADA TEMP"}
Private aTVDados 	:= {" ","P","T"}
Private aTVList 	:= {" ","1-PR”PRIO","2-TERCEIRO"}
Private aMOTDados 	:= {" ","V","C","D","E","R","O"}
Private aMOTList 	:= {" ","1-VENDA","2-COMPRA","3-DEVOLU«√O VENDA","4-DEVOLU«√O COMPRA","5-REMESSA INDUSTRIALIZA«√O","6-OUTROS"}
Private aABASTDados := {" ","S","N"}
Private aABASTList 	:= {" ","1-SIM","2-N√O"}
Private lTick  		:= .T.  
Private lEmail 		:= .F.
Private lDif   		:= .F.
Private lEmDev 		:= .F.
//CARGA DOS DADOS
ReStart(.T.)


//DEFINE MSDIALOG oDlg FROM 00,00 TO 48,161 TITLE "CONTROLE DE PESAGEM DE VEICULOS" COLOR CLR_BLACK,CLR_WHITE
DEFINE WINDOW oDlgBal FROM 01,01 TO 22,75 TITLE "CONTROLE DE PESAGEM DE VEICULOS" COLOR CLR_BLACK,CLR_WHITE // COMENTADO ADD FLS
//oDlgBal      := MSDialog():New(  01,01,22,75,"CONTROLE DE PESAGEM DE VEICULOS",,,.F.,,,,,,.T.,,,.T. )	  		

//MENU PARA OS RELATORIOS
TMenuBar := TMenuBar():New(oDlgBal)
TMenuBar:nClrPane := RGB(183,208,248) // Cor de fundo do Menu
oTMenu1 := TMenu():New(0,0,0,0,.T.,,oDlgBal)
TMenuBar:AddItem('OpÁıes', oTMenu1, .T.)

// Cria Itens do Menu
oTMenuItem := TMenuItem():New(oDlgBal,'Imprimir ⁄ltima Pesagem',,,,{|| fReimpTkt() },,/*'AVGLBPAR1'*/,,,,,,,.T.)
oTMenu1:Add(oTMenuItem)

//oTMenuItem2 := TMenuItem():New(oDlgBal,'Cliente Retira',,,,{|| ExecLink("u_MATA010Ex('U_DIA165('fabio')')") },,,,,,,,,.T.)
//"u_MATA010Ex('01','U_DIA165('fabio'))"

//oTMenu1:Add(oTMenuItem2)

//oTMenuItem3 := TMenuItem():New(oDlgBal,'PrÈ-Nota',,,,{|| ExecLink("u_MATA140Ex") },,,,,,,,,.T.)
//oTMenu1:Add(oTMenuItem3)


//oTMenuItem3 := TMenuItem():New(oDlgBal,'MATA010',,,,{|| U_MATA010Ex("01","MATA010()") },,,,,,,,,.T.)
//oTMenu1:Add(oTMenuItem3)


//oTMenuItem := TMenuItem():New(oDlgBal,'Capturar Peso',,,,{|| CPesoProc() },,,,,,,,,.T.)
//oTMenu1:Add(oTMenuItem)

@ 000, 000 MSPANEL oPanel1 SIZE 500, 031 OF oDlgBal COLORS 0, 16777215 RAISED
@ 015, 004 SAY oSay1 PROMPT "Data:" SIZE 044, 020 OF oPanel1 FONT oFont5 COLORS 8388608, 16777215 PIXEL
@ 015, 043 SAY oSayDATA PROMPT DTOC(dData) SIZE 074, 017 OF oPanel1 FONT oFont2 COLORS 0, 16777215 PIXEL
@ 015, 119 SAY oSay3 PROMPT "Hora:" SIZE 043, 020 OF oPanel1 FONT oFont5 COLORS 8388608, 16777215 PIXEL
@ 015, 159 SAY oSayHORA PROMPT cHora SIZE 055, 015 OF oPanel1 FONT oFont2 COLORS 0, 16777215 PIXEL

@ 015, 222 SAY oSay5 PROMPT "Nr.Pesagem:" SIZE 090, 017 OF oPanel1 FONT oFont3 COLORS 8388608, 16777215 PIXEL
@ 015, 314 SAY oSayPesagem PROMPT cPESAGEM SIZE 066, 015 OF oPanel1 FONT oFont4 COLORS 0, 16777215 PIXEL
@ 015, 380 SAY oSay18 PROMPT "Usu·rio:" SIZE 057, 017 OF oPanel1 FONT oFont3 COLORS 8388608, 16777215 PIXEL
@ 015, 438 SAY oSayUsuario PROMPT _cUsuario SIZE 125, 015 OF oPanel1 FONT oFont4 COLORS 0, 16777215 PIXEL

//@ 004, 500 SAY oSay18 PROMPT "Empresa:" SIZE 057, 017 OF oPanel1 FONT oFont3 COLORS 8388608, 16777215 PIXEL
@ 000, 130 SAY oSayEmpresa PROMPT _cEmpresa SIZE 400, 015 OF oPanel1 FONT oFont8 COLORS 0, 16777215 PIXEL

@ 031, 000 MSPANEL oPanel2 SIZE 500, 228 OF oDlgBal COLORS 0, 16777215 RAISED

@ 010, 003 SAY oSay2 PROMPT "Placa:" SIZE 057, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 010, 100 MSGET oGetPLACA VAR cGetPLACA SIZE 071, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont2 PIXEL VALID(VALPLACA())  //"@! AAA-9999"

@ 040, 003 SAY oSay6 PROMPT "Tipo Pesagem:" SIZE 103, 015 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 040, 100 MSCOMBOBOX oComboBo1 VAR nComboBo1 ITEMS aTPList SIZE 092, 018 OF oPanel2 COLORS 0, 16777215 FONT oFont2 PIXEL VALID(VALTPPE())

@ 040, 200 SAY oSay8 PROMPT "Motivo:" SIZE 055, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 040, 271 MSCOMBOBOX oComboBo3 VAR nComboBo3 ITEMS aMOTList SIZE 195, 018 OF oPanel2 COLORS 0, 16777215 FONT oFont2 PIXEL VALID(VALMOT())

@ 071, 003 SAY oSay7 PROMPT "Tipo VeÌculo:" SIZE 102, 016 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 071, 100 MSCOMBOBOX oComboBo2 VAR nComboBo2 ITEMS aTVList SIZE 092, 018 OF oPanel2 COLORS 0, 16777215 FONT oFont2 PIXEL VALID(VALTPVE())

@ 071, 200 SAY oSay9 PROMPT "Abasteceu:" SIZE 075, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 071, 271 MSCOMBOBOX oComboBo4 VAR nComboBo4 ITEMS aABASTList SIZE 050, 018 OF oPanel2 COLORS 0, 16777215 FONT oFont2 PIXEL  VALID(VALBAST())

@ 071, 331 SAY oSay10 PROMPT "Litros:" SIZE 070, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 064, 370 MSGET oGetLITROS VAR nGetLITROS SIZE 030, 018 OF oPanel2 PICTURE "@E 9999" COLORS 0, 16777215 FONT oFont2  PIXEL

@ 071, 415 SAY oSayKM PROMPT "Km:" SIZE 070, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 064, 439 MSGET oGetKM VAR nKM SIZE 050, 018 OF oPanel2 PICTURE "@E 999999" COLORS 0, 16777215 FONT oFont2  PIXEL


@ 102, 003 SAY oSay4 PROMPT "Motorista:" SIZE 070, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 102, 100 MSGET oGetMOTOR VAR cGetMOTOR SIZE 142, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont2 PIXEL

@ 102, 325 SAY oSay12 PROMPT "Doc. (CPF):" SIZE 090, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 102, 407 MSGET oGetDOC VAR cGetDOC Valid If (!Empty(alltrim(cGetDOC)),U_fCGC(alltrim(cGetDOC)),"") SIZE 109, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont2 PIXEL
@ 134, 003 SAY oSay11 PROMPT "Transportadora:" SIZE 088, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 134, 100 MSGET oGetTRANSP VAR cGetTRANSP SIZE 142, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont2 PIXEL
//@ 134, 245 BUTTON oButtonPTRANSP PROMPT "Pesquisar" SIZE 067, 020 OF oPanel2 FONT oFont2 PIXEL ACTION( CONMOD1(3,cGetTRANSP) )
@ 134, 325 SAY oSay13 PROMPT "Empresa:" SIZE 064, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 134, 407 MSGET oGetEMP VAR cGetEMP SIZE 109, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont2 PIXEL
@ 166, 003 SAY oSay14 PROMPT "Notas Fiscais:" SIZE 102, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 166, 100 MSGET oGetNFS VAR cGetNFS SIZE 517, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont8 PIXEL //READONLY PIXEL WHEN(.F.)
@ 197, 003 SAY oSay15 PROMPT "Peso NFs:" SIZE 102, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 197, 100 MSGET oGetPESONFS VAR nGetPESONFS SIZE 071, 018 OF oPanel2 PICTURE "@E 999,999" COLORS 0, 16777215 FONT oFont2 PIXEL //READONLY PIXEL WHEN(.F.)
@ 197, 190 SAY oSay16 PROMPT "ObservaÁ„o:" SIZE 102, 014 OF oPanel2 FONT oFont1 COLORS 0, 16777215 PIXEL
@ 197, 268 MSGET oGetOBSERV VAR cGetOBSERV SIZE 350, 018 OF oPanel2 PICTURE "@!" COLORS 0, 16777215 FONT oFont2 PIXEL
@ 231, 220 SAY oSay17 PROMPT "PESO:" SIZE 058, 023 OF oPanel2 FONT oFont6 COLORS 0, 16777215 PIXEL
@ 227, 278 MSGET oGetPESO VAR nGetPESO SIZE 111, 028 OF oPanel2 PICTURE "@E 999,999,999" COLORS 255, 16777215 FONT oFont7 READONLY PIXEL

@ 232, 396 SAY oSay16 PROMPT cInfENTtmp SIZE 250, 014 OF oPanel2 FONT oFont10 COLORS 255, 16777215 PIXEL // InformaÁ„o quando for NOTA ENTRADA TEMPOR¡RIA
@ 240, 396 SAY oSay16 PROMPT cInfENTt2  SIZE 250, 014 OF oPanel2 FONT oFont10 COLORS 255, 16777215 PIXEL // InformaÁ„o quando for NOTA ENTRADA TEMPOR¡RIA



@ 260, 000 MSPANEL oPanel3 SIZE 500, 040 OF oDlgBal COLORS 0, 16777215 RAISED
@ 000, 005 SAY oSay17 PROMPT "F3 - Pesquisa por Placa ou Motorista." SIZE 300, 023 OF oPanel3 FONT oFont9 COLORS 0, 16777215 PIXEL
//@ 010, 005 SAY oSay17 PROMPT "F4 - Informar as NF's de entrada." SIZE 300, 023 OF oPanel3 FONT oFont9 COLORS 0, 16777215 PIXEL
@ 010, 005 SAY oSay20 PROMPT cInfF4 SIZE 300, 023 OF oPanel3 FONT oFont9 COLORS 0, 16777215 PIXEL
//cInfF4 := "F4 - Informar as NF's de entrada."

//@ 000, 300 BUTTON oButtonPESAR PROMPT "PESAR" SIZE 099, 039 OF oPanel3 FONT oFont3 PIXEL ACTION (CaptPeso())
//@ 000, 400 BUTTON oButtonCONF PROMPT "CONFIRMAR" SIZE 099, 039 OF oPanel3 FONT oFont3 PIXEL ACTION (Salvar())
@ 000, 400 BUTTON oButtonPESAR PROMPT "PESAR" SIZE 099, 039 OF oPanel3 FONT oFont3 PIXEL ACTION (CaptPeso())

@ 010, 174 BUTTON oButtonPPLACA PROMPT "Pesquisar" SIZE 067, 020 OF oPanel2 FONT oFont2 PIXEL ACTION( CONMOD1(1,cGetPLACA) )
@ 102, 245 BUTTON oButtonPMOTOR PROMPT "Pesquisar" SIZE 067, 020 OF oPanel2 FONT oFont2 PIXEL ACTION( CONMOD1(2,cGetMOTOR) )

DEFINE TIMER oTimerBal INTERVAL 1000 ACTION SETDATETIME() OF oDlgBal 

// Don't change the Align Order
oPanel1:Align := CONTROL_ALIGN_TOP
oPanel3:Align := CONTROL_ALIGN_BOTTOM
oPanel2:Align := CONTROL_ALIGN_ALLCLIENT

//oButtonCONF:Align := CONTROL_ALIGN_RIGHT
oButtonPESAR:Align := CONTROL_ALIGN_RIGHT

oTimerBal:lActive := .T. //comentado add fls

oGetNFS:Disable()
oGetPESONFS:Disable()
oGetPESO:Disable()


//EVENTOS
oGetPLACA:bChange := {|| SetPesq(1)}
oGetMOTOR:bChange := {|| SetPesq(2)}
oGetTRANSP:bChange := {|| SetPesq(3)}

//TECLAS DE ATALHO
SetKey(VK_F3 , { || GoPesqF3()  } )
SetKey(VK_F4 , { || fCalc()  } )
//SetKey(VK_F10 , { || fReimpTkt()  } )

//ACTIVATE MSDIALOG oDlgBal CENTERED
ACTIVATE WINDOW oDlgBal MAXIMIZED // COMENTADO FLS ADD
//oDlgBal:Activate(,,,.T.)


//oDlgBal:lMaximized := .T.
//oDlgBal:lEscClose  := .F.
//oDlgBal:Activate(,,,.F./*[alCentered]*/,/*[abValid]*/,/*[lPar6]*/,/*[abInit]*/,)


RETURN

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//SELECIONANDO CAMPO DE PESQUISA ATIVA
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function SetPesq(nOpc)
nTipoPesq := nOpc
Return(.T.)

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//TECLA DE ATALHO F3
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function  GoPesqF3()
IF nTipoPesq = 1
	CONMOD1(1,cGetPLACA)
ELSEIF nTipoPesq = 2
	CONMOD1(2,cGetMOTOR)
ELSEIF nTipoPesq = 3
	CONMOD1(3,cGetTRANSP)
ENDIF
Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//AJUSTAR DATA E HORA DA TELA
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
STATIC FUNCTION SETDATETIME()

dData := dDataBase
cHora := SubStr(Time(),1,8)
oSayHORA:REFRESH()
oDlgBal:REFRESH()

RETURN

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//CAPTURAR PESO DA BALANCA
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
STATIC FUNCTION CaptPeso()
Local _nRet := ""//"9999"

If !fVldPesar()
	Return(.F.)
EndIf

//Capturando peso
If !(aMOTDados[oComboBo3:nAT] $ "C" .AND. aTPDados[oComboBo1:nAT] == "E" .and. fEntTEMP(Alltrim(cGetPLACA)) .and. nGetPESO>0)	// Quando obter o peso de uma pesagem tempor·ria, n„o È necess·rio obter o peso da balanÁa
	LjMsgRun("Capturando Peso...  ",, { || _nRet := CPesoProc() } )
	If ValType(_nRet) <> "U"
		nGetPESO := VAL(_nRet)     
	Elseif ValType(_nRet) == "U" // Caso dÍ algum problema na leitura da BalanÁa Lider-Cida, retorna ZERO e n„o peso
	    nGetPESO := 0            // N„o foi possivel ler o valor. 
	   	cCabc 	:= "BALAN«A - PESO"
		cMSg 	:= "ATEN«√O: N„o foi possÌvel ler o peso da balanÁa."+CHR(13)+CHR(10)
		cMSg 	+= "Verfique se o cabo da balanÁa est· conectado ao PC e o Display da BalanÁa."+CHR(13)+CHR(10)	
		cMSg 	+= "Informar ao depto de TI."+CHR(13)+CHR(10)		
	    U_fTelAviso(cCabc, cMSg , .F.)  	
	Endif
Endif
oGetPESO:Refresh()

oDlgBal:Refresh()

//oButtonCONF:SetFocus()
If GetMV("MV_YDIGPES")
	fDigPeso()
EndIf
//----------

//Salvando registro  
If !LjMsgRun("Gravando Peso...  ",, { || _nRet := Salvar() } )
	Return
EndIf
//-------

Return

Static Function CPesoProc()
//Sleep(2000)
RETURN(U_PESOBAL())


//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//CONSULTA MODELO 1
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function CONMOD1(nTipo,cDados)
Local oFont1 := TFont():New("Verdana",,020,,.F.,,,,,.F.,.F.)
Local oPanel1
Local oPanel2
Local oSay2
Local oSay3
Local oSButton1
Local oSButton2
Local nOpc := 2
Local _CTIPO := ""
Local nCont

PRIVATE oGD1

SET KEY VK_F3 TO
SetKey(VK_F5 , { || nOpc := 1, oDlgMod1:End()  } )

Private oDlgMod1

If nTipo == 1
	_CTIPO := "PLACA"
ElseIf nTipo == 2
	_CTIPO := "MOTORISTA"
ElseIf nTipo == 3
	_CTIPO := "TRANSPORTADORA"
EndIf

nCont := Mod1LData(nTipo,cDados)

IF nCont == 0
	//MsgAlert("N„o h· resultados para esta pesquisa!","BALAN«A - PESQUISA")
   	cCabc 	:= "BALAN«A - PESQUISA"
	cMSg 	:= "N„o h· resultados para esta pesquisa!"+CHR(13)+CHR(10)
    U_fTelAviso(cCabc, cMSg, .F.)
	//cGetPLACA  	:= SPACE(7)
	cGetMOTOR  	:= SPACE(30)
	cGetDOC   	:= SPACE(15)
	cGetTRANSP 	:= SPACE(30)
	cGetEMP   	:= SPACE(20)
	SetKey(VK_F3 , { || GoPesqF3()  } )
	SET KEY VK_F5 TO
	Return(nOpc)
ENDIF

IF nCont > 1
	DEFINE MSDIALOG oDlgMod1 TITLE "CONTROLE DE BALAN«A - PESQUISA" FROM 000, 000  TO 300, 700 COLORS 0, 16777215 PIXEL
	
	fGD1()
	@ 000, 000 MSPANEL oPanel1 SIZE 350, 025 OF oDlgMod1 COLORS 0, 16777215 RAISED
	@ 008, 009 SAY oSay2 PROMPT "PESQUISANDO POR:" SIZE 089, 011 OF oPanel1 FONT oFont1 COLORS 0, 16777215 PIXEL
	@ 008, 097 SAY oSay3 PROMPT _CTIPO SIZE 089, 011 OF oPanel1 FONT oFont1 COLORS 0, 16777215 PIXEL
	@ 132, 000 MSPANEL oPanel2 SIZE 350, 017 OF oDlgMod1 COLORS 0, 16777215 RAISED
	DEFINE SBUTTON oSButton1 FROM 003, 288 TYPE 01 OF oPanel2 ENABLE ACTION ( nOpc := 1, oDlgMod1:End() )
	DEFINE SBUTTON oSButton2 FROM 003, 317 TYPE 02 OF oPanel2 ENABLE ACTION ( nOpc := 2, oDlgMod1:End() )
	
	// Don't change the Align Order
	oPanel1:Align := CONTROL_ALIGN_TOP
	oPanel2:Align := CONTROL_ALIGN_BOTTOM
	oGD1:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
	ACTIVATE MSDIALOG oDlgMod1 CENTERED
ELSE
	TRBMOD1->(DbGoTop())
	nOpc = 1
ENDIF

IF nOpc = 1
	
	cGetPLACA := TRBMOD1->PLACA
	cGetMOTOR  := TRBMOD1->MOTOR
	cGetDOC  := TRBMOD1->DOC
	cGetTRANSP := TRBMOD1->TRANSP
	cGetEMP  := TRBMOD1->EMP
	oDlgBal:Refresh()
	
ENDIF

SetKey(VK_F3 , { || GoPesqF3()  } )
SET KEY VK_F5 TO
Return(nOpc)

Static Function Mod1LData(nTipo,cDados)
Local nCont := 0
Local _struCd:={}
Local _cAliasTmp
Local CSQL

If SELECT("TRBMOD1") > 0
	TRBMOD1->(DbCloseArea())
EndIf

AADD(_struCd,{"PLACA"		,"C", 7,0})
AADD(_struCd,{"MOTOR"		,"C", 30,0})
AADD(_struCd,{"DOC"			,"C", 20,0})
AADD(_struCd,{"TRANSP"		,"C", 30,0})
AADD(_struCd,{"EMP"			,"C", 30,0})

cArq:=Criatrab(_struCd,.T.)
DBUSEAREA(.t.,,carq,"TRBMOD1")

_cAliasTmp := GetNextAlias()

CSQL := "SELECT DISTINCT TOP 20 MAX(Z8_DATA), Z8_PLACA, Z8_MOTORIS, Z8_DOCMOTO, Z8_TRANSP, Z8_EMPRESA FROM "+RETSQLNAME("SZ8")+" (nolock) "
IF nTipo == 1
	CSQL += " WHERE Z8_PLACA LIKE '%"+AllTrim(cDados)+"%'
ELSEIF nTipo == 2
	CSQL += " WHERE Z8_MOTORIS LIKE '%"+AllTrim(cDados)+"%'
ELSE
	CSQL += " WHERE Z8_TRANSP LIKE '%"+AllTrim(cDados)+"%'
ENDIF
CSQL += " AND D_E_L_E_T_=' ' "
CSQL += " GROUP BY Z8_PLACA, Z8_MOTORIS, Z8_DOCMOTO, Z8_TRANSP, Z8_EMPRESA "
//IF nTipo == 1
//	CSQL += " ORDER BY Z8_PLACA LIKE '%"+AllTrim(cDados)+"%'
//ELSEIF nTipo == 2
//	CSQL += " ORDER BY Z8_MOTORIS LIKE '%"+AllTrim(cDados)+"%'
//ELSE
//	CSQL += " ORDER BY Z8_TRANSP LIKE '%"+AllTrim(cDados)+"%'
//ENDIF

TcQuery CSQL New Alias (_cAliasTmp)

IF !Empty(AllTrim(cDados)) .And. !(_cAliasTmp)->(Eof())
	nCont := 0
	(_cAliasTmp)->(DbGoTop())
	While !(_cAliasTmp)->(Eof())
		
		RecLock("TRBMOD1",.T.)
		TRBMOD1->PLACA 		:= (_cAliasTmp)->Z8_PLACA
		TRBMOD1->MOTOR 		:= (_cAliasTmp)->Z8_MOTORIS
		TRBMOD1->DOC 		:= (_cAliasTmp)->Z8_DOCMOTO
		TRBMOD1->TRANSP 	:= (_cAliasTmp)->Z8_TRANSP
		TRBMOD1->EMP 		:= (_cAliasTmp)->Z8_EMPRESA
		TRBMOD1->(MsUnlock())
		nCont++
		
		(_cAliasTmp)->(DbSkip())
	EndDo
ELSE
	
	(_cAliasTmp)->(DbCloseArea())
	_cAliasTmp := GetNextAlias()
	
	CSQL := "SELECT DISTINCT DA3_PLACA, DA4_NOME FROM "+RETSQLNAME("DA3")+" DA3 (nolock) , "+RETSQLNAME("DA4")+" DA4 (nolock)  "
	CSQL += "WHERE DA3_FILIAL = DA4_FILIAL AND DA3_MOTORI = DA4_COD "
	IF nTipo == 1
		CSQL += " AND DA3_PLACA LIKE '%"+AllTrim(cDados)+"%' "
	ELSEIF nTipo == 2
		CSQL += " AND DA4_NOME LIKE '%"+AllTrim(cDados)+"%' "
	ELSE
		CSQL += " AND DA3_PLACA LIKE '%"+AllTrim(cDados)+"%'
	ENDIF
	
	CSQL += " AND DA3.D_E_L_E_T_=' ' AND DA4.D_E_L_E_T_=' ' "
	
	TcQuery CSQL New Alias (_cAliasTmp)
	
	IF !(_cAliasTmp)->(Eof())
		
		nCont := 0
		(_cAliasTmp)->(DbGoTop())
		While !(_cAliasTmp)->(Eof())
			
			RecLock("TRBMOD1",.T.)
			TRBMOD1->PLACA := (_cAliasTmp)->DA3_PLACA
			TRBMOD1->MOTOR := (_cAliasTmp)->DA4_NOME
			TRBMOD1->(MsUnlock())
			nCont++
			
			(_cAliasTmp)->(DbSkip())
		EndDo
		
	ENDIF
	
ENDIF

TRBMOD1->(DbGoTop())
Return(nCont)

//------------------------------------------------
Static Function fGD1()
//------------------------------------------------
Local nX
Local aHeaderEx := {}
Local aColsEx := {}
Local aFieldFill := {}
Local aFields := {}
Local aAlterFields := {}

lInverte  := .f.
cMarca    := GetMark()
aCpoBro   := { { "PLACA"    ,,"Placa"   ,"@!"},;
{ "MOTOR" ,,"Motorista"  ,"@!"},;
{ "DOC" ,,"Documento"  ,"@!"},;
{ "TRANSP" ,,"Transportadora"  ,"@!"},;
{ "EMP" ,,"Empresa"  ,"@!"}}

//COLUNAS DO GRID
Aadd(aHeaderEx, {"Placa","PLACA","@!",8,0,"",X3_USADO_EMUSO,"C","","R","",""})
Aadd(aHeaderEx, {"Motorista","MOTOR","@!",20,0,"",X3_USADO_EMUSO,"C","","R","",""})
Aadd(aHeaderEx, {"Documento","DOC","@!",20,0,"",X3_USADO_EMUSO,"C","","R","",""})
Aadd(aHeaderEx, {"Transportadora","TRANSP","@!",20,0,"",X3_USADO_EMUSO,"C","","R","",""})
Aadd(aHeaderEx, {"Empresa","EMP","@!",20,0,"",X3_USADO_EMUSO,"C","","R","",""})

oGD1 := MsSelect():New("TRBMOD1","","",aCpoBro,@lInverte,@cMarca,{20,1,210,275})

Return


//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//GRAVAR OS DADOS NO BANCO DE DADOS
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function Salvar()

Local _AliasTmp
Local nPesoOur 	:= 0  // Peso Outros DevoluÁ„o de Vendas

IF nGetPESO <= 0
	//MsgAlert("PESO ZERADO - Capture o peso da balanÁa!","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "PESO ZERADO - Capture o peso da balanÁa!"+CHR(13)+CHR(10)
    U_fTelAviso(cCabc, cMSg, .F.) 
    If fEntTEMP(Alltrim(cGetPLACA)) .AND. aMOTDados[oComboBo3:nAT] $ "C" .AND. aTPDados[oComboBo1:nAT] == "E" .and. fPesoTEMP(cGetPLACA)>0 // Caso ENTRADA DE COMPRA E tenha entrada tempor·ria e conseguentemente PESO TEMPOR¡RIO
		//Return(.T.)
		cInfENTtmp :=  cInfENTt2 := "" // Limpar caso tenha algo escrito		
	Else
		Return(.F.)
	Endif
ENDIF

Private lConfirmou := .F.
fConfirma()
If !lConfirmou
	Return(.F.)
EndIf    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Caso encontre diferenÁa PESO: Registrar, alertar e criticar quando o Fornecedor fizer uma entrega a menor NF x BALAN«A.	  //
// Parametro Default : MENOR OU IGUAL A 10 KG : Getnewpar("MV_YDIFNTA",10)                            F·bio Loures 05/04/2017 //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If lDif 
 If alltrim(GETNEWPAR("MV_FTDIB01","S"))=="S"
  fPesoDif() // Chama a tela para informar item a item a diferenÁa da COMPRA
 Endif
Endif

/*
2) Alertar o usu·rio pela TARA do veÌculo. Comparar TARA DO VEÕCULO (DA3) com o PESO DO VEÕCULO, quando veÌculo for PR”PRIO e nas condiÁıes abaixo:
	a) Tipo Pesagem = ENTRADA - Motivo = VENDA
	b) Tipo Pesagem = ENTRADA - Motivo = REMESSA INDUSTRIALIZACAO
	c) Tipo Pesagem = SAÕDA - Motivo = COMPRA
	d) Tipo Pesagem = SAÕDA - Motivo = DEV. VENDA
*/   

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//	a) Tipo Pesagem = ENTRADA - Motivo = VENDA / b) Tipo Pesagem = ENTRADA - Motivo = REMESSA INDUSTRIALIZACAO //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If Alltrim(aTVDados[oComboBo2:nAT]) == "P"
	If  Alltrim(aTPDados[oComboBo1:nAT]) $ "#E#" .and. Alltrim(aMOTDados[oComboBo3:nAT]) $ "#V#R#"
		nTara := fRetTara(cGetPLACA)
		If nTara-nPESENTR>0
		  nDifTara := nTara-nPESENTR
		Elseif nPESENTR-nTara>0
		  nDifTara := nPESENTR-nTara		
		Else
		  nDifTara := 0
		Endif      
		If nPESENTR-nTara>=0   // Considerar TARA MENOS VEÕCULO ->    em 20/07 veÌculo - tara
		  cSimb := ""
		Else
		  cSimb := "-"        // DiferenÁa Negativa (TARA MENOS VEÕCULO)  -> em 20/07 veÌculo - tara
		Endif
		If nDifTara>0
			cMgsTara := "ATEN«√O: DivergÍncia de peso entre a TARA DO VEÕCULO e o PESO DO VEÕCULO VAZIO."+chr(13)+chr(10)          
			cMgsTara += "PESO VEÕCULO:  "+Transform(nPESENTR,"@E 99999999")+""+chr(13)+chr(10)  			
			cMgsTara += "PESO TARA:         "+Transform(nTara,"@E 99999999")+""+chr(13)+chr(10)   //DA3->DA3_TARA+chr(13)+chr(10)  
			cMgsTara += "DIFEREN«A:        "+cSimb+Transform(nDifTara,"@E 99999999")+""+chr(13)+chr(10)
			cMgsTara += "Verifique se: "+chr(13)+chr(10)  
			cMgsTara += "1 - Existem outros pesos no veÌculo. N„o pode haver peso extra sobre o veÌculo."+chr(13)+chr(10)  
			cMgsTara += "2 - Se o motorista abasteceu o veÌculo antes de iniciar o carregamento. Deve carregar abastecido."+chr(13)+chr(10)  
			cMgsTara += "3 - Se foi realizada alguma reforma no veÌculo que agregou peso. O PESO TARA no cadastro do veÌculo deve ser atualizado (depto logÌstica)."+chr(13)+chr(10)	
		   	cCabc 	:= "TARA x PESO DO VEÕCULO"
		    U_fTelAviso(cCabc, cMgsTara , .F.)
			//Return(.F.)  // Apenas aviso, n„o bloqueia o processo
		Endif
	Endif       
	///////////////////////////////////////////////////////////////////////////////////////////////
	//c) Tipo Pesagem = SAÕDA - Motivo = COMPRA / d) Tipo Pesagem = SAÕDA - Motivo = DEV. VENDA  //
	///////////////////////////////////////////////////////////////////////////////////////////////
	If	Alltrim(aTPDados[oComboBo1:nAT]) $ "#S#" .and. Alltrim(aMOTDados[oComboBo3:nAT]) $ "#C#D#"  
		nTara := fRetTara(cGetPLACA)
		If nTara-nPESSAID>0
		  nDifTara := nTara-nPESSAID
		Elseif nPESSAID-nTara>0
		  nDifTara := nPESSAID-nTara		
		Else
		  nDifTara := 0
		Endif 
		If nTara-nPESSAID>=0 // Considerar TARA MENOS VEÕCULO
		  cSimb := ""
		Else
		  cSimb := "-"        // DiferenÁa Negativa (TARA MENOS VEÕCULO) 
		Endif
		If nDifTara>0
			cMgsTara := "ATEN«√O: DivergÍncia de peso entre a TARA DO VEÕCULO e o PESO DO VEÕCULO VAZIO."+chr(13)+chr(10)  		
			cMgsTara += "PESO TARA:         "+Transform(nTara,"@E 99999999")+""+chr(13)+chr(10) //DA3->DA3_TARA+chr(13)+chr(10)  
			cMgsTara += "PESO VEÕCULO:  "+Transform(nPESSAID,"@E 99999999")+""+chr(13)+chr(10)  
			cMgsTara += "DIFEREN«A:         "+cSimb+Transform(nDifTara,"@E 99999999")+""+chr(13)+chr(10)
			cMgsTara += "Verifique se: "+chr(13)+chr(10)  
			cMgsTara += "1 - Existem outros pesos no veÌculo. N„o pode haver peso extra sobre o veÌculo."+chr(13)+chr(10)  
			cMgsTara += "2 - Se o motorista abasteceu o veÌculo antes de iniciar o carregamento. Deve carregar abastecido."+chr(13)+chr(10)  
			cMgsTara += "3 - Se foi realizada alguma reforma no veÌculo que agregou peso. O PESO TARA no cadastro do veÌculo deve ser atualizado (depto logÌstica)."+chr(13)+chr(10)
		   	cCabc 	:= "TARA x PESO DO VEÕCULO"
		    U_fTelAviso(cCabc, cMgsTara , .F.)
			//Return(.F.)  // Apenas aviso, n„o bloqueia o processo
		Endif
	Endif
Endif


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Se existir diferenÁa de PESO na DevoluÁ„o de venda >= 10   (Getnewpar("MV_YDIFNTA",10))      						  ///
// Emitir aviso ao usuario e caso ele confirme envie email para ExpediÁ„o/Financeiro/Diretoria    F·bio Loures 06/04/2017 ///
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If lEmDev .and.  alltrim(GETNEWPAR("MV_FTDIB02","S"))=="S"
    /* 1) Abater Peso da ObsevarÁ„o (cGetOBSERV). Ex.: PESO entre os campos : #200.50# e verificar se ainda a Diferena continua  >= 10  (Peso referente a outros PESOS informados na Entrada da DevoluÁ„o.
	      1.2) Abri aviso , permitir usu·rio voltar para a tela e informar outros pesos. 
	         1.3) Se ele confirmar novamente enviar· email para ExpediÁ„o/Financeiro/Diretoria */	         
        nParVaria	:= Getnewpar("MV_YDIFNTA",10)
        nPesoOur 	:= fRetPeso(alltrim(cGetOBSERV))      // Retorno o peso da observaÁ„o caso exista (peso que n„o È da nota, outro PRODUTO dentro do caminh„o
        If !VALTYPE(nPesoOur)=='N'  
	        nPesoOur := 0
        Endif
        If (nPDIF-nPesoOur)>=nParVaria              // SÛ ira informar se exisitr diferenÁa
		   	cCabc 		:= "BALAN«A - DIFEREN«A PESO"
			cMSg 		:= "ATEN«√O: Existe uma diferenÁa no peso dessa devoluÁ„o de Venda."+CHR(13)+CHR(10)
			cMSg 		+= "->DiferenÁa maior que "+cvaltochar(nParVaria)+" KG."+CHR(13)+CHR(10)			
			cMSg 		+= "->DiferenÁa encontrada foi de "+cvaltochar(nPDIF)+" KG."+CHR(13)+CHR(10)
			//If nPesoOur>0
			cMSg 		+= "->Outros pesos "+cvaltochar(nPesoOur)+" KG."+CHR(13)+CHR(10)// Fazer uma funÁ„o para buscar o valor do outro peso		
			//Endif
			If nPesoOur>0 .AND. nPDIF>nPesoOur
				cMSg 		+= "DIFEREN«A CONSIDERADA: "+cvaltochar(nPDIF-nPesoOur)+" KG."+CHR(13)+CHR(10)// Fazer uma funÁ„o para buscar o valor do outro peso		
			Endif
			cMSg 		+= "Deseja continuar com essa pesagem ? "+CHR(13)+CHR(10)		
		    nOpcao      := U_fTelAviso(cCabc, cMSg , .T.)	        
		    If nOpcao==2 // N„o 
			    lEmDev := .F.
				Return(.F.)  
			Else
				lEmDev := .T.
			Endif
        Else   // Abatendo o valor de outros n„o ultrapassou  o parametro Getnewpar("MV_YDIFNTA",10)
	         lEmDev := .F.
		Endif
EndIf

/*
IF !MsgYesNo("Confirma a pesagem?","CONTROLE DE BALAN«A")
	Return(.F.)
ENDIF
*/

//BUSCANDO PESAGEM DE ENTRADA ORIGINAL
cPESENT := ""
IF aTPDados[oComboBo1:nAT] $ "S#I"// .And. aMOTDados[oComboBo3:nAT] $ ('V#C#D#E')
	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT TOP 1 Z8_NRPESA, Z8_QTLITRO FROM %TABLE:SZ8% SZ8
		WHERE Z8_PLACA = %EXP:cGetPLACA% 
		AND Z8_TPVEIC = %EXP:aTVDados[oComboBo2:nAT]% 
		AND Z8_TPMOVI = %EXP:aMOTDados[oComboBo3:nAT]%
		//Fernando - 29/11 - buscar a ultima entrada que  nao tenha saida vinculada
		AND NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.Z8_TPPESA = 'S' AND X.D_E_L_E_T_=' ')
		AND Z8_TPPESA  = 'E'
		AND Z8_NRPESEN = ' '
		AND SZ8.D_E_L_E_T_=' '
		ORDER BY Z8_DATA DESC, Z8_HORA DESC
	EndSql
//BUSCA PESAGEM ORIGINAL QUANDO O PROCESSO COME«A COM SAIDA - FERNANDO - 26/01/2012
ELSEIF aTPDados[oComboBo1:nAT] == "E" .And. aMOTDados[oComboBo3:nAT] $ ('C#D#O#E')
	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT TOP 1 Z8_NRPESA, Z8_QTLITRO FROM %TABLE:SZ8% SZ8
		WHERE Z8_PLACA = %EXP:cGetPLACA% 
		AND Z8_TPVEIC = %EXP:aTVDados[oComboBo2:nAT]% 
		AND Z8_TPMOVI = %EXP:aMOTDados[oComboBo3:nAT]%
		//Fernando - 29/11 - buscar a ultima entrada que  Nao tenha saida vinculada
		AND NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.Z8_TPPESA = 'E' AND X.D_E_L_E_T_=' ')		
		AND SZ8.Z8_TPPESA = 'S'  
		AND SZ8.Z8_NRPESEN= ' '
		AND SZ8.D_E_L_E_T_=' '
		ORDER BY Z8_DATA DESC, Z8_HORA DESC
	EndSql
ENDIF

IF SELECT(_AliasTmp) > 0
	(_AliasTmp)->(DbGoTop())
	IF .Not. (_AliasTmp)->(Eof())
		cPESENT := (_AliasTmp)->Z8_NRPESA
	ENDIF
	(_AliasTmp)->(DbCloseArea())
ENDIF


BEGIN TRANSACTION

//Analisa se existe registro com o mesmo NUMERO possivelmente utilizado por outro usuario de pesagem.
cAux := Posicione("SZ8",1,xFilial("SZ8")+cPESAGEM,"Z8_NRPESA")
If !Empty(cAux)
	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT ISNULL(MAX(Z8_NRPESA),'000000') NUM FROM %TABLE:SZ8% WHERE %NOTDEL%
	EndSql

	cPESAGEM := SOMA1((_AliasTmp)->NUM)
	(_AliasTmp)->(DbCloseArea())
EndIf
//-------------
cPESENTtmp := ""
If aMOTDados[oComboBo3:nAT] $ "C" .AND. aTPDados[oComboBo1:nAT] == "E" .and. fEntTEMP(Alltrim(cGetPLACA))
	cPESENTtmp :=  fNumTEMP(Alltrim(cGetPLACA)) // NumeraÁ„o tempor·ria EXISTE ENTRADA COMPRAR TEMPOR¡RIA
Endif
If !Empty(cPESENTtmp)   // Caso ENTRADA DE COMPRA E tenha PESO TEMPOR¡RIO, altera os registros TEMPOR¡RIOS
	//cPESENT := cPESENTtmp  //REGISTRA RELACAO ENTRE OS REGISTROS DE ENTRADA E SAIDA
	_aSZ8ENT := SZ8->(GetArea())	
	SZ8->(DbSetOrder(1))
	If SZ8->(DbSeek(XFilial("SZ8")+cPESENTtmp))  // Alterar· o TEMPOR¡RIO PARA ENTRADA
		RECLOCK("SZ8",.F.)
		SZ8->Z8_TPPESA 	:= aTPDados[oComboBo1:nAT]  // "E"
		SZ8->Z8_TPVEIC 	:= aTVDados[oComboBo2:nAT]
		SZ8->Z8_TPMOVI 	:= aMOTDados[oComboBo3:nAT]
		
		SZ8->Z8_KM      := nKM
		SZ8->Z8_MOTORIS := cGetMOTOR
		SZ8->Z8_DOCMOTO := cGetDOC
		SZ8->Z8_TRANSP 	:= cGetTRANSP
		SZ8->Z8_EMPRESA := cGetEMP
		SZ8->Z8_OBS 	:= cGetOBSERV
				
		SZ8->Z8_PESO 	:= nGetPESO
		SZ8->Z8_NUMNFS 	:= cGetNFS
		SZ8->Z8_PESONFS := nGetPESONFS
		SZ8->Z8_NRPESEN := ""
		SZ8->Z8_USUARIO := _cUsuario		
		SZ8->(MsUnlock())
	Endif
	SZ8->(RestArea(_aSZ8ENT))		
Else
	RECLOCK("SZ8",.T.)
	SZ8->Z8_FILIAL 	:= XFILIAL("SZ8")
	SZ8->Z8_NRPESA 	:= cPESAGEM
	SZ8->Z8_PLACA 	:= cGetPLACA
	SZ8->Z8_DATA 	:= dDataBase
	SZ8->Z8_TPPESA 	:= aTPDados[oComboBo1:nAT]
	SZ8->Z8_TPVEIC 	:= aTVDados[oComboBo2:nAT]
	SZ8->Z8_TPMOVI 	:= aMOTDados[oComboBo3:nAT]
	SZ8->Z8_ABASTEC := aABASTDados[oComboBo4:nAT]
	SZ8->Z8_QTLITRO := nGetLITROS
	SZ8->Z8_HORA 	:= SUBSTR(cHora,1,5)
	SZ8->Z8_PESO 	:= nGetPESO
	SZ8->Z8_CARGA 	:= ""
	SZ8->Z8_MOTORIS := cGetMOTOR
	SZ8->Z8_DOCMOTO := cGetDOC
	SZ8->Z8_TRANSP 	:= cGetTRANSP
	SZ8->Z8_EMPRESA := cGetEMP
	SZ8->Z8_OBS 	:= cGetOBSERV
	SZ8->Z8_NUMNFS 	:= cGetNFS
	SZ8->Z8_PESONFS := nGetPESONFS
	SZ8->Z8_NRPESEN := ""
	SZ8->Z8_USUARIO := _cUsuario  
	SZ8->Z8_KM      := nKM
	SZ8->(MsUnlock())
Endif
//- ATUALIZA NAS NFs DO VEICULO, O N⁄MERO DA PESAGEM.
IF aTPDados[oComboBo1:nAT] == "S"

	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA
		FROM %TABLE:SF2% SF2
		JOIN %TABLE:DA3% DA3 
			ON DA3.DA3_COD = SF2.F2_VEICUL1 
			AND DA3.%NotDel%
		WHERE SF2.%NOTDEL%
		AND SF2.F2_YNRPESA = ' '
		AND DA3.DA3_PLACA  = %EXP:AllTrim(cGetPLACA)%
	EndSql

    dbSelectArea("SF2")
    dbSetOrder(1)
    
	dbSelectArea(_AliasTmp)

	While (_AliasTmp)->(!Eof())

		cF2_FILIAL	:=	(_AliasTmp)->F2_FILIAL
		cF2_DOC		:=	(_AliasTmp)->F2_DOC
		cF2_SERIE	:=	(_AliasTmp)->F2_SERIE
		cF2_CLIENTE	:=	(_AliasTmp)->F2_CLIENTE
		cF2_LOJA	:=  (_AliasTmp)->F2_LOJA

		If SF2->(DbSeek(cF2_FILIAL+cF2_DOC+cF2_SERIE+cF2_CLIENTE+cF2_LOJA))
			While !SoftLock("SF2") ; EndDo
			While !RecLock("SF2",.F.) ; EndDo

			SF2->F2_YNRPESA := cPESAGEM
			SF2->(MsUnlock())
		EndIf

		(_AliasTmp)->(dbSkip())
	EndDo

ENDIF	
/*
IF !Empty(cRecNFS)
	cSQL := "UPDATE "+RETSQLNAME("SF2")+" SET F2_YNRPESA = '"+cPESAGEM+"'
	cSQL += " WHERE R_E_C_N_O_ IN ("+cRecNFS+") AND D_E_L_E_T_=' ' "
	tcSQLExec(cSQL)
ENDIF
*/


//REGISTRA RELACAO ENTRE OS REGISTROS DE ENTRADA E SAIDA
IF !EMPTY(cPESENT)
	SZ8->(DbSetOrder(1))
	IF SZ8->(DbSeek(XFilial("SZ8")+cPESAGEM))
		RECLOCK("SZ8",.F.)
		SZ8->Z8_NRPESEN := cPESENT
		SZ8->(MsUnlock())
	ENDIF
	
	IF SZ8->(DbSeek(XFilial("SZ8")+cPESENT))
		RECLOCK("SZ8",.F.)
		SZ8->Z8_DATAF := dDatabase
		SZ8->Z8_HORAF := SUBSTR(cHora,1,5)
		SZ8->Z8_PESOF := nGetPESO
		SZ8->(MsUnlock())
	ENDIF
ENDIF

END TRANSACTION

//IMPRESSAO DE TICKETS DE ACORDO COM AS CONDICOES
SZ8->(DbSetOrder(1))
IF SZ8->(DbSeek(XFilial("SZ8")+cPESAGEM))

	IF SZ8->Z8_TPPESA $ ("E,S") //.And. SZ8->Z8_TPMOVI $ ("V#C#D#E#O")

		If !Empty(SZ8->Z8_NRPESEN)	//Entrada ou Saida finalizando processo de pesagem.
		    If alltrim(Getnewpar("MV_YIMTICK","N"))=="S" //Eliminar a opÁ„o de impress„o do ticket apÛs a pesagem. Definir por parametro. Atualmente se cancelar funciona, mas est· muito lento para reabrir a tela para nova pesagem.
				PrTicket(2, cPESAGEM)                      
			Endif
		ELSE
	      If alltrim(Getnewpar("MV_YIMTICK","N"))=="S" //Eliminar a opÁ„o de impress„o do ticket apÛs a pesagem. Definir por parametro. Atualmente se cancelar funciona, mas est· muito lento para reabrir a tela para nova pesagem.		
			PrTicket(1, cPESAGEM)
		  Endif
		EndIf

	ELSEIF SZ8->Z8_TPPESA $ ("I")
      If alltrim(Getnewpar("MV_YIMTICK","N"))=="S" //Eliminar a opÁ„o de impress„o do ticket apÛs a pesagem. Definir por parametro. Atualmente se cancelar funciona, mas est· muito lento para reabrir a tela para nova pesagem.		
		PrTicket(2, cPESAGEM)
      Endif
	ENDIF
	
	/*
	IF SZ8->Z8_TPPESA $ ("E") .And. SZ8->Z8_TPMOVI $ ("V#C#D#E#O")
		
		PrTicket(1, cPESAGEM)
		
	ELSEIF SZ8->Z8_TPPESA $ ("I") .And. SZ8->Z8_TPMOVI $ ("V")
		
		PrTicket(3, cPESAGEM)
		
	ELSEIF SZ8->Z8_TPPESA $ ("S") .And. SZ8->Z8_TPMOVI $ ("V")
		
		PrTicket(2, cPESAGEM)
		
	ELSEIF SZ8->Z8_TPPESA $ ("S") .And. SZ8->Z8_TPMOVI $ ("C#D#E#O")
		
		//PrTicket(4, cPESAGEM)
		PrTicket(2, cPESAGEM)
		
	ELSE
		
		PrTicket(1, cPESAGEM)
		
	ENDIF
	*/
ENDIF 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Envia email CIDA/DIACO - PESO VEÕCULO x PESO NF SUPERIOR caso DIFEREN«A do peso seja maior que parametro //
// Getnewpar("MV_YDIFBAL",50)                                                                                //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
If lEmail 
	  If alltrim(substr(_cEmpresa,1,2))=="01"	
		cEmail :=  GetNewPar("MV_YEMADIF","luiz.frechiani@diaco.com.br,expedicao@diaco.com.br")
	  Else 
		cEmail :=  GetNewPar("MV_YEMADIC","luiz.frechiani@diaco.com.br,expedicao@diaco.com.br")	  
	  Endif
	  cEmpr := ""
	  If alltrim(substr(_cEmpresa,1,2))=="01"		    	
	 	cEmpr := "DIA«O"
	  Elseif alltrim(substr(_cEmpresa,1,2))=="02"		    	
		cEmpr := "CIDA"  
	  Endif		

	  
		Msg := " " + chr(13)+chr(10)
		Msg += cEmpr+" - PESO VEÕCULO ACIMA DE <B>"+cvaltochar(Getnewpar("MV_YDIFBAL",50))+" KG.</B>"+chr(13)+chr(10)+chr(13)+chr(10)
		Msg += "<B> VEÕCULO PLACA:       </B> "+alltrim(cGetPLACA)+""+chr(13)+chr(10)+chr(13)+chr(10)
	
		Msg += "<B>PESO ENTRADA :     </B>"+Transform(nPESENTR,"@E 99999999")+""+chr(13)+chr(10)  
		Msg += "<B>PESO SAÕDA   :     </B>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp"+Transform(nPESSAID,"@E 99999999")+""+chr(13)+chr(10)+chr(13)+chr(10)
		
		Msg += "<B>PESO LÕQUIDO :     </B>&nbsp&nbsp&nbsp"+Transform(nPLIQ,"@E 99999999")+""+chr(13)+chr(10)  		
		Msg += "<B>PESO NF'S    :     </B>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp"+Transform(nPNTS,"@E 99999999")+""+chr(13)+chr(10)  		
		
		Msg += "<font color='red'> EST¡ COM DIFEREN«A DE <B>"+Transform(nPDIF,"@E 99999999")+" KG </B> a maior. </font>"+chr(13)+chr(10)+chr(13)+chr(10)+chr(13)+chr(10)   		
		
        If nGetLITROS>0	        
			Msg += "<B>Abastecimento: </B>&nbsp&nbsp&nbsp"+Transform(nGetLITROS,"@E 99999999")+" Litros "+" ( Peso considerado KG"+Transform( nGetLITROS*0.85,"@E 99999999")+" )"+chr(13)+chr(10)  				
		Endif

		
		//cGetNFS := "" 
		cNFS :=  cGetNFS
		If Empty(alltrim(cNFS)) // Trazendo as notas caso esteja em branco este campo , identificado alguns casos na Cida						
			cQuery := "  	SELECT DISTINCT F2_DOC+'/'+F2_SERIE as DOC "
			cQuery += "  	FROM "+RetSqlName("SF2")+" SF2 (NOLOCK) "
			cQuery += "  	INNER JOIN "+RetSqlName("DA3")+" DA3 (NOLOCK) "
			cQuery += "     ON  DA3.DA3_FILIAL = F2_FILIAL "								
			cQuery += "     AND DA3.DA3_COD = F2_VEICUL1 AND DA3.D_E_L_E_T_='' "												
			cQuery += "  	WHERE  SF2.F2_FILIAL='"+xFilial("SF2")+"' AND SF2.F2_EMISSAO='"+DtoS(dDatabase)+"' AND SF2.D_E_L_E_T_='' "
			cQuery += "  	AND  DA3.DA3_PLACA='"+Alltrim(cGetPLACA)+"' "				
			If Select("QRY") > 0
				QRY->(DbCloseArea())
			EndIf
			TcQuery cQuery New Alias "QRY"
			WHILE !QRY->(EOF())
				cNFS += QRY->DOC+','
				QRY->(dbSkip())
			EndDO 
			cNFS := SUBSTR(Alltrim(cNFS),1,Len(cNFS)-1)
		    QRY->(DbCloseArea())		    
		Endif				
		Msg += " TRANSPORTANDO A(S) NF(S): "+cNFS+""+chr(13)+chr(10)+chr(13)+chr(10)
		// Traz os Pedidos / Cliente dessa pesagem
		cQuery := "  	SELECT DISTINCT D2_PEDIDO,D2_CLIENTE , A1_NOME , A1_NREDUZ " // , D2_DOC+'/'+D2_SERIE AS DOC "
		cQuery += "  	FROM "+RetSqlName("SD2")+" A (NOLOCK) "
		cQuery += "  	JOIN "+RetSqlName("SA1")+" B (NOLOCK) ON D2_CLIENTE=A1_COD AND D2_LOJA=A1_LOJA AND B.D_E_L_E_T_='' "
		//cQuery += "  	WHERE  A.D2_FILIAL='"+xFilial("SD2")+"' AND A.D2_DOC IN "+FormatIn(Alltrim(cNFS),",")+" "
		cQuery += "  	WHERE  A.D2_FILIAL+A.D2_DOC+A.D2_SERIE IN "+FormatIn(Alltrim(cNFS),",")+" "

		cQuery += "  	AND A.D2_EMISSAO='"+DtoS(dDatabase)+"' AND A.D_E_L_E_T_='' "
		If Select("QRYPEDIDOS") > 0
			QRYPEDIDOS->(DbCloseArea())
		EndIf
		TcQuery cQuery New Alias "QRYPEDIDOS"
		WHILE !QRYPEDIDOS->(EOF())
			Msg += "PEDIDO : "+alltrim(QRYPEDIDOS->D2_PEDIDO)+ " Cliente :" +alltrim(QRYPEDIDOS->A1_NREDUZ)+chr(13)+chr(10)
			QRYPEDIDOS->(dbSkip())			
		EndDO
		QRYPEDIDOS->(DbCloseArea())   

		u_fEmail(cEmail,cEmpr+" - PESO VEÕCULO x PESO NF (SUPERIOR a "+cvaltochar(Getnewpar("MV_YDIFBAL",50))+" KG)",Msg+chr(13)+chr(10)+chr(13)+chr(10),.F.)
Endif 

If	lEmDev // Se exitir diferenÁa na DevoluÁ„o de Vendas -> Envia email sobre a diferenÁa dessa DevoluÁ„o
	fEmailDev(nPesoOur) 
Endif



If !Empty(cMsgDifQ)
	//////////////////////////////////////////////////////
	// Anexar ticket BalanÁa no prÛprio corpo do email  //
	//IMPRESSAO DE TICKETS DE ACORDO COM AS CONDICOES   //
	//////////////////////////////////////////////////////
	cMsgTick := ""
	_aSZ8 := SZ8->(GetArea())
	DbSelectArea("SZ8")
	SZ8->(DbSetOrder(1))
	If SZ8->(DbSeek(XFilial("SZ8")+cPESAGEM))	
		If SZ8->Z8_TPPESA $ ("E,S")	
			If !Empty(SZ8->Z8_NRPESEN)	//Entrada ou Saida finalizando processo de pesagem.
				cMsgTick := fTiket(2, cPESAGEM)
			Else
				cMsgTick := fTiket(1, cPESAGEM)
			EndIf	
		ElseiF SZ8->Z8_TPPESA $ ("I")	
			cMsgTick := fTiket(2, cPESAGEM)	
		Endif
	Endif
   	SZ8->(RestArea(_aSZ8))
	cMsgDifQ := cMsgDifQ+CRLF+CRLF+"Anexo informaÁıes do Ticket da BalanÁa: "+CRLF+cMsgTick+CRLF+CRLF+" Aguardo retorno, "+CRLF+CRLF+CRLF
	u_fEmail( alltrim(GETNEWPAR("MY_YEMFTDI",'expedicao@diaco.com.br,diretoria@diaco.com.br,financeiro@diaco.com.br,fabio.loures@diaco.com.br')) ,cMsgAss,cMsgDifQ,.F.)
	cMsgDifQ := ""    
	cMsgAss  := ""  
	cMsgTick := ""  
Endif

ReStart()

Return(.T.)

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//SELECAO DA FUNCAO DE IMPRESSAO DOS TICKETS
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function PrTicket(nModelo, cNrPesa)
Local nComboBo1 := 1
Local oComboTk
Local nOpcI
Static oDlgPrTic

//Return

DEFINE MSDIALOG oDlgPrTic TITLE "MODO DE IMPRESSAO" FROM 000, 000  TO 100, 200 COLORS 0, 16777215 PIXEL

@ 019, 007 MSCOMBOBOX oComboTk VAR nComboBo1 ITEMS {"LASER","MATRICIAL"} SIZE 084, 010 OF oDlgPrTic COLORS 0, 16777215 PIXEL
DEFINE SBUTTON oSButton1 FROM 036, 068 TYPE 01 OF oDlgPrTic ENABLE ACTION (nOpcI := oComboTk:nAT, oDlgPrTic:End())

ACTIVATE MSDIALOG oDlgPrTic CENTERED

If nOpcI == 1
	U_FACR004(nModelo, cNrPesa)
Else
	U_FACR003(nModelo, cNrPesa)
Endif

Return


//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//REINICIA - PREPARA TELA PARA PROXIMA ENTRADA
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ
Static Function ReStart(lInicio)
Local _AliasTmp
Default lInicio := .F.

_AliasTmp := GetNextAlias()
BeginSQl Alias  _AliasTmp
	SELECT ISNULL(MAX(Z8_NRPESA),'000000') NUM FROM %TABLE:SZ8% WHERE %NOTDEL%
EndSql

//CSQL := "SELECT ISNULL(MAX(Z8_NRPESA),'000000') NUM FROM "+RETSQLNAME("SZ8")+" WHERE D_E_L_E_T_=' '"
//TcQuery CSQL New Alias (_AliasTmp)

cPESAGEM := SOMA1((_AliasTmp)->NUM)
(_AliasTmp)->(DbCloseArea())

IF !lInicio
	oComboBo1:nAT := 1
	oComboBo2:nAT := 1
	oComboBo3:nAT := 1
	oComboBo4:nAT := 1
ENDIF

cGetMOTOR := SPACE(30)
cGetPLACA := SPACE(7)
cGetTRANSP := SPACE(30)
cGetDOC := SPACE(15)
cGetEMP := SPACE(20)
cGetNFS := SPACE(250)
cGetOBSERV := SPACE(200)
nGetLITROS := 0
nKM		   := 0
nGetPESO := 0
nGetPESONFS := 0 
cInfENTtmp  := cInfENTt2 := ""
//cRecNFS	:= ""

IF !lInicio
	oGetPLACA:SetFocus()
	oDlgBal:Refresh()
ENDIF

Return

//‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//VALIDACOES DOS CAMPOS DA TELA
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ

//TIPO DO VEICULO
Static Function VALTPVE()
   

IF aTVDados[oComboBo2:nAT] == "T"
	oComboBo4:nAT := 1
	nGetLITROS := 0
	oComboBo4:Disable()
	oGetLITROS:Disable()
	oGetLITROS:lReadOnly := .T.
	oGetDOC:Enable()
	oGetDOC:lReadOnly := .F.
	oGetTRANSP:Enable()
	oGetTRANSP:lReadOnly := .F.
	oGetEMP:Enable()
	oGetEMP:lReadOnly := .F.
	
	//oGetPLACA:SetFocus()
ELSE
	oGetLITROS:Enable()
	oGetLITROS:lReadOnly := .F.
	oComboBo4:Enable()
	oGetDOC:Disable()
	oGetDOC:lReadOnly := .T.
	oGetTRANSP:Disable()
	oGetTRANSP:lReadOnly := .T.
	oGetEMP:Disable()
	oGetEMP:lReadOnly := .T.
	//oComboBo4:SetFocus()   
	If aMOTDados[oComboBo3:nAT] $ "V," // Caso venda permite Digitar ObservarÁ„o  e empresa 
		oGetOBSERV:Enable() 
		oGetEMP:Enable() // Permite a DigitaÁ„o da Empresa "V,"
		oGetEMP:lReadOnly := .F.
	EndIf

ENDIF 

IF aTPDados[oComboBo1:nAT] $ "T"  .AND. aMOTDados[oComboBo3:nAT] $ "C" // Habilita o campos empresa quando COMPRA -> TEMPOR¡RIA
	oGetEMP:Enable()
	oGetEMP:lReadOnly := .F.
Endif


oDlgBal:Refresh()
Return(.T.)

//TIPO DA PESAGEM
Static Function VALTPPE()

//Desabilita Abastecimento na Intermediaria
/*IF aTPDados[oComboBo1:nAT] == "I"
	oComboBo4:nAT := 1
	nGetLITROS := 0
	oComboBo4:Disable()
	oGetLITROS:Disable()
	oGetLITROS:lReadOnly := .T.
ENDIF
*/

//Busca o PESO e NR.NFs faturadas referente ao veiculo informado.
fBuscaNf() 


If aTPDados[oComboBo1:nAT] $ "T" // SE tipo pesagem TEMPOR¡RIA SUGERE 2-compra
	oComboBo3:nAT := 3 // Compra 
Endif
//Como na ENTRADA DE COMPRAR QUE EXISTA TEMPOR¡RIA traz o valor da pesagem TEMPOR[ARIA:
//Se compra e Diferente de ENTRADA e existir E existir TEMPORARIA, zera PESO NA TELA
If aMOTDados[oComboBo3:nAT] $ "C" .AND. !aTPDados[oComboBo1:nAT] $ "E" .AND. nGetPESO>0 .and. fEntTEMP(Alltrim(cGetPLACA)) 
	 nGetPESO   := 0                    
	 cInfENTtmp := cInfENTt2 := ""
Elseif aMOTDados[oComboBo3:nAT] $ "C" .AND. aTPDados[oComboBo1:nAT] $ "E"  .and. fEntTEMP(Alltrim(cGetPLACA)) // Caso seja entrada COMPRA e tenha tempor·ria, traz o peso da tempor·ria
	nGetPESO    :=  fPesoTEMP(cGetPLACA)                              
    	 //ATEN«√O: Foi identifica uma ENTRADA TEMPOR¡RIA e o sistema ir· utilizar o PESO REGISTRADO para esta pesagem.
	cInfENTtmp  :=  "ATEN«√O: Foi identificada uma ENTRADA TEMPOR¡RIA e o"
	cInfENTt2   :=  "sistema ir· utilizar o PESO REGISTRADO para esta pesagem."	
	// Quando entrada de um tempor·rio desabilitar todos os campos da tela -> deixar apenas o campo observaÁ„o. (OK)
	oComboBo2:Disable()  // "Tipo VeÌculo:"
	oComboBo4:Disable()  // "Abasteceu:"
	oGetLITROS:Disable() // "Litros:"
	oGetKM:Disable()
	oGetMOTOR:Disable()
	oGetDOC:Disable()
	oGetTRANSP:Disable()
	oGetEMP:Disable()
	oGetNFS:Disable()
	oGetPESONFS:Disable()
	oButtonPPLACA:Disable()
	oButtonPMOTOR:Disable()		
Else
	 cInfENTtmp := cInfENTt2 := ""
Endif



Return(.T.)

Static Function VALMOT()

//Desabilita Abastecimento na Intermediaria
/*
IF aMOTDados[oComboBo3:nAT] <> "V"
	oComboBo4:nAT := 1
	nGetLITROS := 0
	oComboBo4:Disable()
	oGetLITROS:Disable()
	oGetLITROS:lReadOnly := .T.
ENDIF
*/

// Permite digitar o PESO das NFs caso nao seja VENDA ou REMESSA INDUSTRIALIZA«√O.
If !aMOTDados[oComboBo3:nAT] $ "V,R,C"   // C=2,D=3,E=4    VR->"C,D,E"->VRC
	oGetNFS:Enable()
	oGetPESONFS:Enable()  
	If aMOTDados[oComboBo3:nAT] $ "D,"
		cInfF4   := "F4 - Informar as NF's de Venda"
	 	oSay20:Refresh()
	 	If !aMOTDados[oComboBo3:nAT] $ "C,D" .and.  !aTPDados[oComboBo1:nAT] $ "S" .and.  !Empty(cGetNFS)
		   nGetPESONFS := 0 
		   cGetNFS		:= SPACE(250)
		Endif
		// Desabilita PESO NF / NOTAS e ObservalÁ„o
 		oGetPESONFS:Disable()    
 		oGetNFS:Disable() 
 		oGetOBSERV:Disable()		
	Else
		cInfF4   := "F4 - Informar as NF's"
		oSay20:Refresh()
		oGetOBSERV:Enable() 
		oGetOBSERV:Refresh()	
	Endif
Else
	oGetPESONFS:Disable()
	If !aMOTDados[oComboBo3:nAT] $ "C" .and.  !aTPDados[oComboBo1:nAT] $ "S" .and.  !Empty(cGetNFS) // Quando for compra e SaÌda e existir NOTAS E PESO n„o apagar
		nGetPESONFS := 0
		cGetNFS		:= SPACE(250)
	Endif
	oGetNFS:Disable()
	If aMOTDados[oComboBo3:nAT] $ "C,"
	  cInfF4   := "F4 - Informar as NF's de Entrada"
	  oSay20:Refresh()
  	Else
		cInfF4   := "F4 - Informar as NF's"
		oSay20:Refresh()
	Endif 
	oGetOBSERV:Enable() 
	oGetOBSERV:Refresh()
EndIf
If aMOTDados[oComboBo3:nAT] $ "V," // Caso venda permite Digitar ObservarÁ„o  
	oGetOBSERV:Enable() 
	oGetEMP:Enable() // Permite a DigitaÁ„o da Empresa "V,"
	oGetEMP:lReadOnly := .F.
EndIf

//Busca o PESO e NR.NFs faturadas referente ao veiculo informado.
fBuscaNf() 	


// Caso seja uma COMPRE TEMPOR¡RIA Habiliar o campo EMPRESA
IF aTPDados[oComboBo1:nAT] $ "T"  .AND. aMOTDados[oComboBo3:nAT] $ "C"
	oGetEMP:Enable()
	oGetEMP:lReadOnly := .F.
Endif
If aTPDados[oComboBo1:nAT] $ "T"  .AND. !aMOTDados[oComboBo3:nAT] $ "C" // SÛ pode dar usar ENTRADA TEMPOR¡RIA 	Quando motivo for COMPRA
   	cCabc 	:= "Entrada Tempor·ria"
	cMSg 	:= "SÛ È permitido usar Entrada Tempor·ria quando MOTIVO for COMPRA."+CHR(13)+CHR(10)
	cMSg 	+= "Altere o MOTIVO PARA COMPRA."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)		 
	Return(.F.)
Endif

Return(.T.)

//PLACA
Static Function VALPLACA()
Local lRET := .F.

LjMsgRun("Pesquisando PLACA...  ",, { || lRET := VALPPROC() } )
//VALTPVE() // Atualizando campos habilita/ou desabilita

Return(lRET)

Static Function VALPPROC()
Local _AliasTmp
Local _nOpc

IF Empty(cGetPLACA)

	cGetPLACA := SPACE(7)
	oComboBo1:nAT := 1
	oComboBo2:nAT := 1
	oComboBo3:nAT := 1
	oComboBo4:nAT := 1
	
	cGetMOTOR := SPACE(30)
	cGetPLACA := SPACE(7)
	cGetTRANSP := SPACE(30)
	cGetDOC := SPACE(15)
	cGetEMP := SPACE(20)
	cGetNFS := SPACE(250)
	cGetOBSERV := SPACE(200)
	nGetLITROS := 0
	nGetPESO   := 0  
	nKM		   := 0   
	cInfENTtmp := cInfENTt2 := ""

	oGetPeso:Refresh()
	nGetPESONFS := 0
	oGetPESONFS:Refresh()

	oDlgBal:Refresh()

	Return(.T.)
ELSE
   	nGetPESO   := 0  //add
   	cInfENTtmp := cInfENTt2 := ""  // add 	
   	oComboBo2:Enable()  // "Tipo VeÌculo:"
	oComboBo4:Enable()  // "Abasteceu:"
	oGetLITROS:Enable() // "Litros:"
	oGetKM:Enable()
	oGetMOTOR:Enable()
	oGetDOC:Enable()
	oGetTRANSP:Enable()
	oGetEMP:Enable()
	oGetNFS:Enable()
	oGetPESONFS:Enable()
	oButtonPPLACA:Enable()
	oButtonPMOTOR:Enable()	
   	
	IF (Len(Alltrim(cGetPLACA))<=4 .AND. !IsDigit(Alltrim(cGetPLACA)))  .OR.;
	   (Len(Alltrim(cGetPLACA)) > 4 .AND. !IsAlpha(Alltrim(cGetPLACA))) .OR.;
	   "'" $ cGetPLACA
	   

		cGetPLACA := SPACE(07)
		oGetPlaca:SetFocus()
		//MsgAlert("Placa incorreta. N„o È permitido ESPA«O ou TRA«O entre os numeros e letras. Digite apenas LETRAS e NUMEROS.")
	   	cCabc 	:= "Placa incorreta"
		cMSg 	:= "Placa incorreta."+CHR(13)+CHR(10)
		cMSg 	+= "N„o È permitido ESPA«O ou TRA«O entre os numeros e letras. Digite apenas LETRAS e NUMEROS."+CHR(13)+CHR(10)
    	U_fTelAviso(cCabc, cMSg, .F.)		
		Return(.T.)
	ENDIF
ENDIF

// Busca placa completa do veÌculo.
_AliasTmp := GetNextAlias()
BeginSQl Alias  _AliasTmp
	SELECT DISTINCT Z8_PLACA FROM %TABLE:SZ8% SZ8
	WHERE Z8_PLACA LIKE "%"+%EXP:AllTrim(cGetPLACA)%
	AND SZ8.D_E_L_E_T_=' '
EndSql
(_AliasTmp)->(DbGoTop())
nCont := 0
While .Not. (_AliasTmp)->(Eof())
	nCont++
	(_AliasTmp)->(dbSkip())
End
// Se encontrou apenas um veÌculo com a numeracao informada, considerado-o.
(_AliasTmp)->(DbGoTop())
If nCont = 1
	cGetPLACA := (_AliasTmp)->Z8_PLACA
	(_AliasTmp)->(DbCloseArea())
Else
	(_AliasTmp)->(DbCloseArea())
	// Mostra tela para o usuario escolher o veiculo caso tenha mais de um com a mesma numeracao de placa.
	_nOpc := CONMOD1(1,cGetPLACA)
	IF (_nOpc<>1) .And. Len(AllTrim(cGetPLACA)) <> 7
		//MsgAlert("Informar placa corretamente!","CONTROLE DE PESAGEM")
	   	cCabc 	:= "CONTROLE DE PESAGEM"
		cMSg 	:= "Informar placa corretamente!"+CHR(13)+CHR(10)
    	U_fTelAviso(cCabc, cMSg, .F.)
		cGetPLACA := SPACE(7)
		oGetPLACA:Refresh()
		
		oComboBo1:nAT := 1
		nComboBo1 := 1
		
		oComboBo2:nAT := 1
		nComboBo2 := 1
		
		oComboBo3:nAT := 1
		nComboBo3 := 1
	
		oComboBo4:nAT := 1
		nComboBo4 := 1

		cGetMOTOR := CriaVar("Z8_MOTORIS")
		oGetMOTOR:Refresh()

		cGetDOC	  := CriaVar("Z8_DOCMOTO")
		cGetTRANSP:= CriaVar("Z8_TRANSP")
		cGetEMP	  := CriaVar("Z8_EMPRESA")
		cGetOBSERV:= CriaVar("Z8_OBS")
		cGetNFS   := CriaVar("Z8_NUMNFS")
		nGetPESONFS:= 0
		oDlgBal:Refresh()
		Return(.F.)
	ENDIF
	oDlgBal:Refresh()
EndIf
//------------------------

// Busca ˙ltima movimentaÁ„o do veÌculo para sugerir a atual.
_AliasTmp := GetNextAlias()
BeginSQl Alias  _AliasTmp
	SELECT SZ8.Z8_NRPESA, SZ8.Z8_TPPESA, SZ8.Z8_TPVEIC, SZ8.Z8_TPMOVI, SZ8.Z8_ABASTEC, SZ8.Z8_QTLITRO, SZ8.Z8_MOTORIS, SZ8.Z8_DOCMOTO,
	SZ8.Z8_TRANSP, SZ8.Z8_EMPRESA, SZ8.Z8_OBS, SZ8.Z8_NRPESEN, Z8_NUMNFS, Z8_PESONFS , Z8_PESO
	FROM %TABLE:SZ8% SZ8
	WHERE SZ8.Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
	AND   SZ8.Z8_NRPESA = (SELECT MAX(X.Z8_NRPESA) AS Z8_NRPESA FROM %TABLE:SZ8% X 
							WHERE X.Z8_PLACA = %EXP:AllTrim(cGetPLACA)% 
							AND X.D_E_L_E_T_=' ')
	AND   SZ8.D_E_L_E_T_=' '
EndSql

dbSelectArea(_AliasTmp)
(_AliasTmp)->(DbGoTop())

lSugMov := .T.	//Sugere informaÁıes do movimento inicial.

IF (_AliasTmp)->(!Eof())

	If (_AliasTmp)->Z8_TPPESA == "E" .AND. (_AliasTmp)->Z8_TPMOVI $ "V,R" .AND. (_AliasTmp)->Z8_TPVEIC == "P" //entrada veiculo proprio
		oComboBo1:nAT := 4    //sugere intermediaria
		
	ElseIf (_AliasTmp)->Z8_TPPESA == "E"
		oComboBo1:nAT := 3		// sugere saÌda
		If !Empty((_AliasTmp)->Z8_NRPESEN)	//se È um processo concluÌdo, nao sugere dados do movimento.
			lSugMov := .F.
		EndIf

	ElseIf (_AliasTmp)->Z8_TPPESA == "I" //.AND. (_AliasTmp)->Z8_TPMOVI == "V"
		oComboBo1:nAT := 3 //sugere saida
		
	ElseIf (_AliasTmp)->Z8_TPPESA == "S"	// Sugere entrada

		oComboBo1:nAT := 2
		If !Empty((_AliasTmp)->Z8_NRPESEN)	//se È um processo concluÌdo, nao sugere dados do movimento.
			lSugMov := .F.
		EndIf
    ElseIf (_AliasTmp)->Z8_TPPESA == "T"	// QUANDO EXISTE COMPRA TEMPOR¡RIA -> Sugere entrada E TRAZ TODOS OS DADOS 
		oComboBo1:nAT := 2    // Entrada
	    nGetPESO      := (_AliasTmp)->Z8_PESO //fPesoTEMP(cGetPLACA) // Trazer o peso total que o veÌculo foi pesado peala TEMPOR¡RIA
		cInfENTtmp  :=  "ATEN«√O: Foi identificada uma ENTRADA TEMPOR¡RIA e o"
		cInfENTt2   :=  "sistema ir· utilizar o PESO REGISTRADO para esta pesagem."			
		// Quando entrada de um tempor·rio desabilitar todos os campos da tela -> deixar apenas o campo observaÁ„o. (OK)
		oComboBo2:Disable()  // "Tipo VeÌculo"
		oComboBo4:Disable()  // "Abasteceu"
		oGetLITROS:Disable() // "Litros"
		oGetKM:Disable()
		oGetMOTOR:Disable()
		oGetDOC:Disable()
		oGetTRANSP:Disable()
		oGetEMP:Disable()
		oGetNFS:Disable()
		oGetPESONFS:Disable() 
		oButtonPPLACA:Disable()
		oButtonPMOTOR:Disable()
	EndIf
	nComboBo1 := oComboBo1:nAT
	
	oComboBo2:nAT := aScan(aTVDados,(_AliasTmp)->Z8_TPVEIC)
	nComboBo2 := oComboBo2:nAT

	If lSugMov //Sugere MOV. E OBS de um processo nao concluido.

		oComboBo3:nAT := aScan(aMOTDados,(_AliasTmp)->Z8_TPMOVI)
		nComboBo3 := oComboBo3:nAT

		cGetNFS	   := (_AliasTmp)->Z8_NUMNFS
		nGetPESONFS:= (_AliasTmp)->Z8_PESONFS
		cGetOBSERV:= (_AliasTmp)->Z8_OBS
	Else
		oComboBo3:nAT := 1
		nComboBo3 := 1
		cGetOBSERV:= SPACE(200)

		cGetNFS	   := SPACE(250)
		nGetPESONFS:= 0
	EndIf

	oComboBo4:nAT := aScan(aABASTDados,(_AliasTmp)->Z8_ABASTEC)
	nComboBo4 := oComboBo4:nAT

	cGetMOTOR := (_AliasTmp)->Z8_MOTORIS
	cGetDOC	  := (_AliasTmp)->Z8_DOCMOTO
	cGetTRANSP:= (_AliasTmp)->Z8_TRANSP
	cGetEMP	  := (_AliasTmp)->Z8_EMPRESA

	//cGetNFS   := ""
	//nGetPESONFS:= 0
	oDlgBal:Refresh()
ELSE
	oComboBo1:nAT := 1
	nComboBo1 := 1
	
	oComboBo2:nAT := 1
	nComboBo2 := 1
	
	oComboBo3:nAT := 1
	nComboBo3 := 1

	oComboBo4:nAT := 1
	nComboBo4 := 1

	cGetMOTOR := CriaVar("Z8_MOTORIS")

	cGetDOC	  := CriaVar("Z8_DOCMOTO")
	cGetTRANSP:= CriaVar("Z8_TRANSP")
	cGetEMP	  := CriaVar("Z8_EMPRESA")
	cGetOBSERV:= CriaVar("Z8_OBS")
	cGetNFS   := CriaVar("Z8_NUMNFS")
	nGetPESONFS:= 0
	oDlgBal:Refresh()
ENDIF
(_AliasTmp)->(DbCloseArea())
//-------------------------------------

//Busca o PESO e NR.NFs faturadas referente ao veiculo informado.
fBuscaNf()

Return(.T.)

User Function DIPqMOT(_cMOTI)
Local _cRET := ""

IF AllTrim(_cMOTI) == "V"
	_cRET := "VENDA"
ELSEIF AllTrim(_cMOTI) == "C"
	_cRET := "COMPRA"
ELSEIF AllTrim(_cMOTI) == "D"
	_cRET := "DEVOLU«√O DE VENDA"
ELSEIF AllTrim(_cMOTI) == "E"
	_cRET := "DEVOLU«√O DE COMPRA"
ELSEIF AllTrim(_cMOTI) == "O"
	_cRET := "OUTROS"
ELSEIF AllTrim(_cMOTI) == "R"
	_cRET := "REMESSA INDUSTRIALIZA«√O"
ENDIF

Return(_cRET)


Static Function fVldPesar()
lResp := .T.

//VALIDANDO REGISTRO ORIGINAL DE SAIDA OU ENTRADA
_cTPesa := aTPDados[oComboBo1:nAT]

IF EMPTY(_cTPesa) .OR. EMPTY(aMOTDados[oComboBo3:nAT])
	//MsgAlert("Preencha os dados: TIPO e MOTIVO DA PESAGEM","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Preencha os dados: TIPO e MOTIVO DA PESAGEM"+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)	
	oComboBo1:SetFocus()
	Return(.F.)
ENDIF

IF EMPTY(cGetPLACA) .OR. EMPTY(cGetMOTOR)
	//MsgAlert("Preencha os dados: PLACA E MOTORISTA","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Preencha os dados: PLACA E MOTORISTA"+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)		
	oGetMOTOR:SetFocus()
	Return(.F.)
ENDIF

IF _cTPesa == "I" .And. !aMOTDados[oComboBo3:nAT] $ "V,R"
	//MsgAlert("Pesagem INTERMEDI¡RIA somente pode ser usada para motivo VENDA ou REMESSA INDUSTRIALIZA«√O.")
   	cCabc 	:= "Pesagem INTERMEDI¡RIA"
	cMSg 	:= "Pesagem INTERMEDI¡RIA somente pode ser usada para motivo VENDA ou REMESSA INDUSTRIALIZA«√O."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)	
	oComboBo3:SetFocus()
	Return(.F.)
ENDIF

//VALIDACOES
IF EMPTY(aTVDados[oComboBo2:nAT])
	//MsgAlert("Informe o TIPO DE VEICULO!","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Informe o TIPO DE VEICULO!"+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)		
	oComboBo2:SetFocus()
	Return(.F.)
ENDIF

IF (aABASTDados[oComboBo4:nAT] == "S" .And. nGetLITROS <= 0)
	//MsgAlert("Informe a QUANTIDADE DE LITROS abastecido!","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Informe a QUANTIDADE DE LITROS abastecido!"+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)			
	oGetLITROS:SetFocus()
	Return(.F.)
ENDIF

IF (aABASTDados[oComboBo4:nAT] <> "S" .And. nGetLITROS > 0)
	//Alert("Se ABASTECIDO = N√O!"+CRLF+"N„o pode informar a QUANTIDADE DE LITROS abastecido!","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Se ABASTECIDO = N√O!"+CRLF+"N„o pode informar a QUANTIDADE DE LITROS abastecido!"+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)		
	oGetLITROS:SetFocus()
	Return(.F.)
ENDIF

IF aTPDados[oComboBo1:nAT] == "I" .And. aABASTDados[oComboBo4:nAT] == "S"
	//MsgAlert("PESAGEM INTERMEDI¡RIA!"+CRLF+"N„o pode realizar abastecimento!","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "PESAGEM INTERMEDI¡RIA!"+CRLF+"N„o pode realizar abastecimento!"+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)	
	Return(.F.)
ENDIF

IF aMOTDados[oComboBo3:nAT] == "O" .AND. Empty(cGetOBSERV)
	//MsgAlert("Motivo OUTROS, È necess·rio preencher o campo OBSERVA«√O com detalhes da operaÁ„o que ser· realizada.","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Motivo OUTROS, È necess·rio preencher o campo OBSERVA«√O com detalhes da operaÁ„o que ser· realizada."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)	
	Return(.F.)
ENDIF   

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Quando ENTRADA TEMPOR¡RIA e motivo for COMPRA                                                                                             //
// SÛ permitir realizar uma ENTRADA TEMPOR¡RIA se no campo EMPRESA contiver o conte˙do do parametro MV_YPESTEM. Por padr„o conter ARCELLOR.  //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
IF aTPDados[oComboBo1:nAT] $ "T"  .AND. aMOTDados[oComboBo3:nAT] $ "C" .and.  Empty(cGetEMP) // ObrigatÛrio preencher o campo EMPRESA
   	cCabc 	:= "NOME DA EMPRESA"
	cMSg 	:= "… necess·rio preencher o campo EMPRESA para uma entrada de compra TEMPOR¡RIA."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)	
	oGetEMP:SetFocus()
	Return(.F.) 
Endif 
lPerTEMP := .F.
If aTPDados[oComboBo1:nAT] $ "T"  .AND. aMOTDados[oComboBo3:nAT] $ "C"
	cPermTMP := UPPER(GETNEWPAR("MV_YPESTEM","ARCELLOR;")) // Separar os nomes das empresas por ponto e vÌrgula (;)
	aPermTMP := strtokarr((ALLTRIM(cPermTMP)),";")
	For nX := 1 To Len(aPermTMP)
		If UPPER(alltrim(aPermTMP[nX])) $ UPPER(alltrim(cGetEMP))
	   	    lPerTEMP := .T.
		Endif
	Next nX		
Endif
If !lPerTEMP .and. aTPDados[oComboBo1:nAT] $ "T"  .AND. aMOTDados[oComboBo3:nAT] $ "C"
   	cCabc 	:= "Entrada Tempor·ria"
	cMSg 	:= "Somente as empresas listadas abaixo:"+CHR(13)+CHR(10)
	cMSg 	+= " (MV_YPESTEM) :"+ALLTRIM(Getnewpar("MV_YPESTEM","ARCELLOR;"))+CHR(13)+CHR(10)
	cMSg 	+= "Podem realizar uma entrada tempor·ria."+CHR(13)+CHR(10)	
   	U_fTelAviso(cCabc, cMSg, .F.)		 
	Return(.F.)
Endif


////////////////////////////////////////
// Valida CPF informado caso Terceiro //
////////////////////////////////////////
If ALLTRIM(Getnewpar("MV_YCPFTIC","S"))=="S" .and. aTVDados[oComboBo2:nAT] == "T"
	lValida := U_fCGC(alltrim(cGetDOC))                      
	If !lValida
		Return(.F.)
	Endif	
Endif  


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Criticar -> Caso seja uma SAÕDA DE COMPRA e exista um TEMPOR¡RIO, informar que dever· dar a ENTRADA da TEMPOR¡RIA.  //  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If aTPDados[oComboBo1:nAT] $ "S"  .AND. aMOTDados[oComboBo3:nAT] $ "C" .and. fEntTEMP(Alltrim(cGetPLACA))  
   	cCabc 	:= "ENTRADA TEMPOR¡RIA ENCONTRADA"
	cMSg 	:= "AtenÁ„o: Existe uma ENTRADA TEMPOR¡RIA para essa placa."+CHR(13)+CHR(10)
	cMSg 	+= "Deve escolher tipo pesagem: 1-ENTRADA (COMPRA) e efetiv·-la."+CHR(13)+CHR(10)	
   	U_fTelAviso(cCabc, cMSg, .F.)
	Return(.F.)
Endif

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Criticar se PESO NFS estiver vazio. N„o permitir prosseguir com a pesagem. (MOTIVO = 2,3 ou 4, desabilitar os campos NOTAS FISCAIS e PESO)   //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If Alltrim(aMOTDados[oComboBo3:nAT]) $ ALLTRIM(GETNEWPAR("MV_YFTBVA1","#C#D#") )  .AND. !nGetPESONFS>0; // "C#D#E"    -> DEVOLU«√O D -> TIPO E/S -> DEVOLU«√O C -> TIPO E/S
	 .and.   aTPDados[oComboBo1:nAT] $ ALLTRIM(GETNEWPAR("MV_YFTBVA2","#E#S#")) .and.  !aTPDados[oComboBo1:nAT] $ "#T#" // Tipo Pesagem "S#I#E" -> Saida , intermediaria, Entrada  E N√O FOR ENTRADA TEMPOR¡RIA
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= ""
   	If Alltrim(aMOTDados[oComboBo3:nAT]) $ "#C#" 
		cMSg 	:= "Quando MOTIVO for COMPRA e Tipo pesagem Entrada È necess·rio informar as notas (Use a tecla de atalho F4 para Informar as NF's de entrada.)."+CHR(13)+CHR(10)
	Elseif  Alltrim(aMOTDados[oComboBo3:nAT]) $ "#D#"
		cMSg 	:= "Quando MOTIVO for DEVOLU«√O DE VENDA e Tipo pesagem Entrada ou SaÌda È necess·rio informar as notas (Use a tecla de atalho F4 para Informar as NF's de Venda.)."+CHR(13)+CHR(10)
	Endif
   	U_fTelAviso(cCabc, cMSg, .F.)	
   	fCalc() // J· abre a tela solicitada
	Return(.F.)
Endif

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Quando for ENTRADA e veÌculo PR”PRIO exigir o preenchimento do campo ->  KM VEÕCULO na tela de pesagem 12/06/2017//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
If  aTPDados[oComboBo1:nAT] $ "#E#" .and.  aTVDados[oComboBo2:nAT] == "P" .and. nKM==0
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Deve preencher o campo KM. Pois o sistema identificou que È uma ENTRADA e vocÍ informou veÌculo PR”PRIO."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)		
   	oGetKM:Enable()
   	oGetKM:SetFocus()
	Return(.F.)
Endif     

// Verifica se foi preenchido corretamente a informaÁ„o de veÌculo PROPRIO/TERCEIRO.
_AliasTmp := GetNextAlias()
BeginSQl Alias  _AliasTmp
	SELECT	DA3_PLACA FROM %TABLE:DA3% DA3
	WHERE	DA3_PLACA = %EXP:AllTrim(cGetPLACA)%
	AND		DA3_ATIVO = '1'
	AND		DA3_FROVEI= '1'
	AND 	DA3.D_E_L_E_T_=' '
EndSql
(_AliasTmp)->(DbGoTop())

If (_AliasTmp)->(Eof()) .AND. aTVDados[oComboBo2:nAT] == "P"

	//MsgAlert("Confirme se foi digitado corretamente a PLACA DO VEÕCULO. Pois o sistema identificou que este N√O … UM VEÕCULO DA EMPRESA e vocÍ informou PR”PRIO.","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Confirme se foi digitado corretamente a PLACA DO VEÕCULO. Pois o sistema identificou que este N√O … UM VEÕCULO DA EMPRESA e vocÍ informou PR”PRIO."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)		
	(_AliasTmp)->(DbCloseArea())
	Return(.F.)
	
ElseIf  !(_AliasTmp)->(Eof()) .AND. aTVDados[oComboBo2:nAT] == "T"

	//MsgAlert("Confirme se foi digitado corretamente a PLACA DO VEÕCULO. Pois o sistema identificou que este … UM VEÕCULO DA EMPRESA e vocÍ informou TERCEIRO.","CONTROLE DE BALAN«A")
   	cCabc 	:= "CONTROLE DE BALAN«A"
	cMSg 	:= "Confirme se foi digitado corretamente a PLACA DO VEÕCULO. Pois o sistema identificou que este … UM VEÕCULO DA EMPRESA e vocÍ informou TERCEIRO."+CHR(13)+CHR(10)
   	U_fTelAviso(cCabc, cMSg, .F.)			
	(_AliasTmp)->(DbCloseArea())
	Return(.F.)

EndIf
(_AliasTmp)->(DbCloseArea())
//------------------------

//VALIDACOES APOS DIGITAR A PLACA E PESQUISAR
// Busca ˙ltima movimentaÁ„o do veÌculo para calcular os pesos.
_AliasTmp := GetNextAlias()
BeginSQl Alias  _AliasTmp
	SELECT SZ8.Z8_NRPESA, SZ8.Z8_TPPESA, SZ8.Z8_TPVEIC, SZ8.Z8_TPMOVI, SZ8.Z8_ABASTEC, SZ8.Z8_QTLITRO, SZ8.Z8_MOTORIS, SZ8.Z8_DOCMOTO,
	SZ8.Z8_TRANSP, SZ8.Z8_EMPRESA, SZ8.Z8_OBS, SZ8.Z8_NRPESEN, SZ8.Z8_NUMNFS, SZ8.Z8_PESONFS, SZ8.Z8_PESO, SZ8.Z8_DATA, SZ8.Z8_HORA
	FROM %TABLE:SZ8% SZ8
	WHERE SZ8.Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
	AND   SZ8.Z8_NRPESA = (SELECT MAX(X.Z8_NRPESA) AS Z8_NRPESA FROM %TABLE:SZ8% X 
							WHERE X.Z8_PLACA = %EXP:AllTrim(cGetPLACA)% 
							AND X.D_E_L_E_T_=' ')
	AND   SZ8.D_E_L_E_T_=' '
EndSql

dbSelectArea(_AliasTmp)
(_AliasTmp)->(DbGoTop())

IF (_AliasTmp)->(!Eof())

	cDataHora := DTOC(STOD((_AliasTmp)->Z8_DATA))+" "+(_AliasTmp)->Z8_HORA
	
	If _cTPesa == "I" 	// PESANDO INTERMEDIARIA

		// Critica se estiver pesando INTERMEDIARIA e o ultimo registro nao for ENTRADA/INTERMEDIARIA do mesmo movimento (VENDA ou REMESSA).
		If ! ((_AliasTmp)->Z8_TPPESA $ 'E,I' .AND. (_AliasTmp)->Z8_TPMOVI = aMOTDados[oComboBo3:nAT] )

			cMsg := "N„o foi encontrado um registro de ENTRADA de VENDA para este veÌculo."+CRLF+;
			"N„o È possÌvel fazer a PESAGEM INTERMEDI¡RIA"

			If Empty((_AliasTmp)->Z8_NRPESEN)
				cMsg += CRLF+CRLF+"Existe registro de "+IIF((_AliasTmp)->Z8_TPPESA$"S","SAIDA","ENTRADA")+ " de " +U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" em " +cDataHora+ " para esse veÌculo."
				cMsg += CRLF+CRLF+"SOLU«√O: "
				cMsg += CRLF+"1 - Verifique se vocÍ digitou a placa corretamente;"
				cMsg += CRLF+"2 - Verifique se o MOTIVO escolhido est· correto;"
				cMsg += CRLF+"3 - Verifique se o TIPO DE PESAGEM escolhido est· correto;"
				cMsg += CRLF+"4 - FaÁa a pesagem final para encerrar o processo de pesagem preenchendo as informaÁıes da ocorrÍncia na observaÁ„o, em seguida faÁa esta pesagem."
			EndIf

			//MsgAlert(cMsg)
		   	cCabc 	:= "ENTRADA de VENDA"
			U_fTelAviso(cCabc, cMsg, .F.)			

			(_AliasTmp)->(DbCloseArea())
		
			Return(.F.)
			
		EndIf
	Else   //PESANDO SAIDA OU ENTRADA
		// Critica se informou o mesmo tipo de pesagem(entrada/saida) do ultimo registro e este ultimo estiver em aberto.
		// OU
		// Critica se o MOTIVO da pesagem(entrada/saida) for diferente do ultimo registro e este ultimo estiver em aberto.
		If  (Empty((_AliasTmp)->Z8_NRPESEN) .AND. (_AliasTmp)->Z8_TPPESA == _cTPesa) .OR.;
			(Empty((_AliasTmp)->Z8_NRPESEN) .AND. (_AliasTmp)->Z8_TPMOVI <> aMOTDados[oComboBo3:nAT])

			/*MsgAlert("Existe registro de "+IIF((_AliasTmp)->Z8_TPPESA$"S","SAIDA","ENTRADA")+ " de " +U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" em " +cDataHora+ " para esse veÌculo. "+;
			CRLF+CRLF+"SOLU«√O: "+;
			CRLF+"1 - Verifique se vocÍ digitou a placa corretamente;"+;
			CRLF+"2 - Verifique se o MOTIVO escolhido est· correto;"+;
			CRLF+"3 - Verifique se o TIPO DE PESAGEM escolhido est· correto;"+;
			CRLF+"4 - FaÁa a pesagem final para encerrar o processo de pesagem preenchendo"+;
			" as informaÁıes da ocorrÍncia na observaÁ„o, em seguida faÁa esta pesagem.","CONTROLE DE PESAGEM")*/
			cMsg := "Existe registro de "+IIF((_AliasTmp)->Z8_TPPESA$"S","SAIDA","ENTRADA")+ " de " +U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" em " +cDataHora+ " para esse veÌculo. "+;
			CRLF+CRLF+"SOLU«√O: "+;
			CRLF+"1 - Verifique se vocÍ digitou a placa corretamente;"+;
			CRLF+"2 - Verifique se o MOTIVO escolhido est· correto;"+;
			CRLF+"3 - Verifique se o TIPO DE PESAGEM escolhido est· correto;"+;
			CRLF+"4 - FaÁa a pesagem final para encerrar o processo de pesagem preenchendo"+;
			" as informaÁıes da ocorrÍncia na observaÁ„o, em seguida faÁa esta pesagem."			

		   	cCabc 	:= "CONTROLE DE PESAGEM"
			U_fTelAviso(cCabc, cMsg, .F.)
						
			(_AliasTmp)->(DbCloseArea())

			Return(.F.)

		EndIf

		//Critica se estiver pesando uma saida de venda sem ter encontrado a ENTRADA OU INTERMEDIARIA DE VENDA.
		//OU
		//Critica se estiver pesando uma saida de REMESSA INDUSTR. sem ter encontrado a ENTRADA OU INTERMEDIARIA DE REM.INDUST.
		If  ((_cTPesa == "S" .AND. aMOTDados[oComboBo3:nAT] == "V") .AND.;
			(! ((_AliasTmp)->Z8_TPPESA $ "E,I") .OR. (_AliasTmp)->Z8_TPMOVI <> 'V')) .OR.;
			((_cTPesa == "S" .AND. aMOTDados[oComboBo3:nAT] == "R") .AND.;
			(! ((_AliasTmp)->Z8_TPPESA $ "E,I") .OR. (_AliasTmp)->Z8_TPMOVI <> 'R'))

			cMsg := "N„o existe registro de ENTRADA DE " +U_DIPqMOT(aMOTDados[oComboBo3:nAT])+" em aberto para este veÌculo."+;
			CRLF+"N„o È possÌvel fazer SAÕDA DE " +U_DIPqMOT(aMOTDados[oComboBo3:nAT])+;
			CRLF+CRLF+"Existe registro de "+IIF((_AliasTmp)->Z8_TPPESA$"S","SAIDA","ENTRADA")+ " de " +U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" em " +cDataHora+ " para esse veÌculo."+;
			CRLF+CRLF+"SOLU«√O: "+;
			CRLF+"1 - Verifique se vocÍ digitou a placa corretamente;"+;
			CRLF+"2 - Verifique se o MOTIVO escolhido est· correto;"+;
			CRLF+"3 - Verifique se o TIPO DE PESAGEM escolhido est· correto;"
			
			If Empty((_AliasTmp)->Z8_NRPESEN)
				cMsg += CRLF+"4 - FaÁa a pesagem final para encerrar o processo de pesagem preenchendo"+;
				" as informaÁıes da ocorrÍncia na observaÁ„o, em seguida faÁa a pesagem de ENTRADA "+U_DIPqMOT(aMOTDados[oComboBo3:nAT])+" e depois a pesagem de SAÕDA "+U_DIPqMOT(aMOTDados[oComboBo3:nAT])+"."
			ELSE
				cMsg += CRLF+"4 - Procure o ticket da pesagem de ENTRADA DE "+U_DIPqMOT(aMOTDados[oComboBo3:nAT])+" e se informe se a pesagem foi realizada, "+;
				"caso n„o, faÁa a pesagem de ENTRADA DE VENDA e SAÕDA DE "+U_DIPqMOT(aMOTDados[oComboBo3:nAT])+" com o mesmo peso e preencha as informaÁıes da ocorrÍncia na observaÁ„o das pesagens."
			EndIf

			//MsgAlert(cMsg)
			cCabc 	:= "CONTROLE DE PESAGEM"
			U_fTelAviso(cCabc, cMsg, .F.)

			(_AliasTmp)->(DbCloseArea())

			Return(.F.)
		EndIf

		//Critica se a ultima pesagem foi uma INTERMEDIARIA e nao est· pesando uma SAIDA DE VENDA.
		//OU
		//Critica se a ultima pesagem foi uma INTERMEDIARIA e nao est· pesando uma SAIDA DE REMESSA INDUST.
		If (_AliasTmp)->Z8_TPPESA == 'I' .AND. (_cTPesa <> "S" .OR. (_AliasTmp)->Z8_TPMOVI <> aMOTDados[oComboBo3:nAT])

			/*MsgAlert("Existe registro pesagem INTERMEDI¡RIA de "+U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" em " +cDataHora+ " para esse veÌculo."+;
			CRLF+CRLF+"SOLU«√O: "+;
			CRLF+"1 - Verifique se vocÍ digitou a placa corretamente;"+;
			CRLF+"2 - Verifique se o MOTIVO escolhido est· correto;"+;
			CRLF+"3 - Verifique se o TIPO DE PESAGEM escolhido est· correto;"+;
			CRLF+"4 - FaÁa a pesagem de SAÕDA DE "+U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" preenchendo"+;
			" as informaÁıes da ocorrÍncia na observaÁ„o, em seguida faÁa esta pesagem.","CONTROLE DE PESAGEM")
			*/
			cMsg := "Existe registro pesagem INTERMEDI¡RIA de "+U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" em " +cDataHora+ " para esse veÌculo."+;
			CRLF+CRLF+"SOLU«√O: "+;
			CRLF+"1 - Verifique se vocÍ digitou a placa corretamente;"+;
			CRLF+"2 - Verifique se o MOTIVO escolhido est· correto;"+;
			CRLF+"3 - Verifique se o TIPO DE PESAGEM escolhido est· correto;"+;
			CRLF+"4 - FaÁa a pesagem de SAÕDA DE "+U_DIPqMOT((_AliasTmp)->Z8_TPMOVI)+" preenchendo"+;
			" as informaÁıes da ocorrÍncia na observaÁ„o, em seguida faÁa esta pesagem."

			(_AliasTmp)->(DbCloseArea())
			
			cCabc 	:= "CONTROLE DE PESAGEM"
			U_fTelAviso(cCabc, cMsg, .F.)

			Return(.F.)

		EndIf
	EndIf
EndIf
(_AliasTmp)->(DbCloseArea())
//----------------------------------------------------------

//BUSCANDO PESAGEM DE ENTRADA ORIGINAL
nLITROS := 0
IF aTPDados[oComboBo1:nAT] $ "S#I"
	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT TOP 1 Z8_NRPESA, Z8_QTLITRO FROM %TABLE:SZ8%
		WHERE Z8_PLACA = %EXP:cGetPLACA% AND Z8_TPVEIC = %EXP:aTVDados[oComboBo2:nAT]% AND Z8_TPMOVI = %EXP:aMOTDados[oComboBo3:nAT]%
		AND Z8_TPPESA = 'E'
		ORDER BY Z8_DATA DESC, Z8_HORA DESC
	EndSql
ELSE
	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT TOP 1 Z8_NRPESA, Z8_QTLITRO FROM %TABLE:SZ8%
		WHERE Z8_PLACA = %EXP:cGetPLACA% AND Z8_TPVEIC = %EXP:aTVDados[oComboBo2:nAT]% AND Z8_TPMOVI = %EXP:aMOTDados[oComboBo3:nAT]%
		AND Z8_TPPESA = 'S'
		ORDER BY Z8_DATA DESC, Z8_HORA DESC
	EndSql
ENDIF

(_AliasTmp)->(DbGoTop())
IF .Not. (_AliasTmp)->(Eof())
	nLITROS := (_AliasTmp)->Z8_QTLITRO
	_lFound := .T.
ENDIF
(_AliasTmp)->(DbCloseArea())

//VALIDA GRAVACA COM RELACAO A ENTRADA
IF nGetLITROS > 0 .And. nLITROS > 0
	IF aTPDados[oComboBo1:nAT] == "S"
		//MsgAlert("VeÌculo foi abastecido na entrada."+CRLF+" N„o pode abastecer novamente.","CONTROLE DE BALAN«A")
			cCabc 	:= "CONTROLE DE BALAN«A"
			cMsg    := "VeÌculo foi abastecido na entrada."+CRLF+" N„o pode abastecer novamente."
			U_fTelAviso(cCabc, cMsg, .F.)
		
	ELSE
		//MsgAlert("VeÌculo foi abastecido na saÌda."+CRLF+" N„o pode abastecer novamente.","CONTROLE DE BALAN«A")
			cCabc 	:= "CONTROLE DE BALAN«A"
			cMsg    := "VeÌculo foi abastecido na saÌda."+CRLF+" N„o pode abastecer novamente."
			U_fTelAviso(cCabc, cMsg, .F.)		
	ENDIF
	Return(.F.)
ENDIF

/*
IF _cTPesa $ "S#E#I"

	_cMOTI  := "" //Edner
	
	IF _cTPesa $ "S#E"
		_lFound := .F.

		_AliasTmp := GetNextAlias()
		BeginSQl Alias  _AliasTmp
			SELECT TOP 1 Z8_NRPESA,Z8_TPMOVI FROM %TABLE:SZ8% SZ8
			WHERE Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
			AND Z8_TPPESA = %EXP:_cTPesa%
			//AND NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.Z8_TPPESA = 'S' AND X.D_E_L_E_T_=' ')
			//FERNANDO - 26/01/2012
			AND NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.D_E_L_E_T_=' ')
			AND SZ8.Z8_NRPESEN = ' '
			AND SZ8.D_E_L_E_T_ = ' '
		EndSql
		(_AliasTmp)->(DbGoTop())
		IF .Not. (_AliasTmp)->(Eof())
			_lFound := .T.
			
			//Edner
			_cMOTI := (_AliasTmp)->Z8_TPMOVI
			//---

		ENDIF
		(_AliasTmp)->(DbCloseArea())
		
		IF _lFound
			MsgAlert("Existe registro de "+IIF(_cTPesa$"S","SAIDA","ENTRADA")+" motivo " +U_DIPqMOT(_cMOTI)+ " em aberto para este veÌculo."+;
			CRLF+CRLF+"Deve ser efetuada a "+IIF(_cTPesa$"S","ENTRADA","SAIDA")+" antes de qualquer outra ENTRADA/SAÕDA com motivo diferente.","CONTROLE DE PESAGEM")
			Return(.F.)
		ENDIF
	ELSEIF _cTPesa $ "I"
		_lFound := .F.
		_AliasTmp := GetNextAlias()
		BeginSQl Alias  _AliasTmp
			SELECT TOP 1 Z8_NRPESA FROM %TABLE:SZ8% SZ8
			WHERE Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
			AND Z8_TPPESA = 'E'
			AND Z8_TPMOVI = 'V'
			AND NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.Z8_TPPESA = 'S' AND X.D_E_L_E_T_=' ')
			AND SZ8.Z8_NRPESEN = ' '
			AND SZ8.D_E_L_E_T_=' '
		EndSql
		(_AliasTmp)->(DbGoTop())
		IF .Not. (_AliasTmp)->(Eof())
			_lFound := .T.
		ENDIF
		(_AliasTmp)->(DbCloseArea())
		
		IF !_lFound
			MsgAlert("N„o existe registro de ENTRADA DE VENDA em aberto para este veÌculo. "+;
			CRLF+CRLF+"N„o È possÌvel fazer a PESAGEM INTERMEDI¡RIA.","CONTROLE DE PESAGEM")
			Return(.F.)
		ENDIF
	ENDIF
	
	//Fernando - 29/11 - Nao pode fazer saida de venda sem entrada de venda - linha 874
	IF _cTPesa == "S" .And. aMOTDados[oComboBo3:nAT] == "V"
		_lFound := .F.
		_AliasTmp := GetNextAlias()
		BeginSQl Alias  _AliasTmp
			SELECT TOP 1 Z8_NRPESA FROM %TABLE:SZ8% SZ8
			WHERE Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
			AND Z8_TPPESA = 'E'
			AND Z8_TPMOVI = 'V'
			AND NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.Z8_TPPESA = 'S' AND X.D_E_L_E_T_=' ')
			AND SZ8.Z8_NRPESEN = ' '
			AND SZ8.D_E_L_E_T_=' '
		EndSql
		
		(_AliasTmp)->(DbGoTop())
		IF .Not. (_AliasTmp)->(Eof())
			_lFound := .T.
		ENDIF
		(_AliasTmp)->(DbCloseArea())
		
		IF !_lFound
			MsgAlert("N„o existe registro de ENTRADA DE VENDA em aberto para este veÌculo."+;
			CRLF+CRLF+"N„o È possÌvel fazer SAÕDA DE VENDA.","CONTROLE DE PESAGEM")
			Return(.F.)
		ENDIF
	ENDIF
	
	_lFound := .F.
	_AliasTmp := GetNextAlias()
	BeginSQl Alias  _AliasTmp
		SELECT TOP 1 Z8_TPMOVI FROM %TABLE:SZ8% SZ8
		WHERE Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
		AND Z8_TPPESA = %EXP:IIF(_cTPesa$"S#I","E","S")%
		AND Z8_TPMOVI <> %EXP:aMOTDados[oComboBo3:nAT]%
		AND SZ8.Z8_NRPESEN = ' '
		AND ((NOT EXISTS(SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND X.D_E_L_E_T_=' '))
		OR
		( (EXISTS (SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND Z8_TPPESA = 'I' AND X.D_E_L_E_T_=' '))
		AND
		(NOT EXISTS (SELECT Z8_NRPESA FROM %TABLE:SZ8% X WHERE X.Z8_NRPESEN = SZ8.Z8_NRPESA AND Z8_TPPESA = %EXP:IIF(_cTPesa$"S#I","S","E")% AND X.D_E_L_E_T_=' '))
		)
		)
		AND SZ8.D_E_L_E_T_=' '
	EndSql
	(_AliasTmp)->(DbGoTop())
	IF .Not. (_AliasTmp)->(Eof())
		_cMOTI := (_AliasTmp)->Z8_TPMOVI
		_lFound := .T.
	ENDIF
	(_AliasTmp)->(DbCloseArea())
	
	IF _lFound
		MsgAlert("Existe registro de "+IIF(_cTPesa$"S#I","ENTRADA","SAIDA")+" em aberto para este veÌculo "+;
		CRLF+"com motivo "+U_DIPqMOT(_cMOTI)+"."+;
		CRLF+CRLF+"A operaÁ„o do motivo "+U_DIPqMOT(_cMOTI)+" deve ser concluÌda para iniciar uma nova operaÁ„o.","CONTROLE DE PESAGEM")
		Return(.F.)
	ENDIF
	
	//BUSCANDO PESAGEM DE ENTRADA ORIGINAL
	nLITROS := 0
	IF aTPDados[oComboBo1:nAT] $ "S#I"
		_AliasTmp := GetNextAlias()
		BeginSQl Alias  _AliasTmp
			SELECT TOP 1 Z8_NRPESA, Z8_QTLITRO FROM %TABLE:SZ8%
			WHERE Z8_PLACA = %EXP:cGetPLACA% AND Z8_TPVEIC = %EXP:aTVDados[oComboBo2:nAT]% AND Z8_TPMOVI = %EXP:aMOTDados[oComboBo3:nAT]%
			AND Z8_TPPESA = 'E'
			ORDER BY Z8_DATA DESC, Z8_HORA DESC
		EndSql
	ELSE
		_AliasTmp := GetNextAlias()
		BeginSQl Alias  _AliasTmp
			SELECT TOP 1 Z8_NRPESA, Z8_QTLITRO FROM %TABLE:SZ8%
			WHERE Z8_PLACA = %EXP:cGetPLACA% AND Z8_TPVEIC = %EXP:aTVDados[oComboBo2:nAT]% AND Z8_TPMOVI = %EXP:aMOTDados[oComboBo3:nAT]%
			AND Z8_TPPESA = 'S'
			ORDER BY Z8_DATA DESC, Z8_HORA DESC
		EndSql
	ENDIF
	
	(_AliasTmp)->(DbGoTop())
	IF .Not. (_AliasTmp)->(Eof())
		nLITROS := (_AliasTmp)->Z8_QTLITRO
		_lFound := .T.
	ENDIF
	(_AliasTmp)->(DbCloseArea())
	
	//VALIDA GRAVACA COM RELACAO A ENTRADA
	IF nGetLITROS > 0 .And. nLITROS > 0
		IF aTPDados[oComboBo1:nAT] == "S"
			MsgAlert("VeÌculo foi abastecido na entrada."+CRLF+" N„o pode abastecer novamente.","CONTROLE DE BALAN«A")
		ELSE
			MsgAlert("VeÌculo foi abastecido na saÌda."+CRLF+" N„o pode abastecer novamente.","CONTROLE DE BALAN«A")
		ENDIF
		Return(.F.)
	ENDIF
	
ENDIF
*/

Return(lResp)      

//////////////////////////
// Valida CPF informado //
//////////////////////////
User function fCGC(cGetDOC)

Local lRet := .T.
	If ALLTRIM(Getnewpar("MV_YCPFTIC","S"))=="S" .and. aTVDados[oComboBo2:nAT] == "T"
		If !Empty(alltrim(cGetDOC)) 
			If !CGC(strtran(strtran(strtran(alltrim(cGetDOC),".",""),"-","")," ","")  )          
			   cCabc 	:= "CPF inv·lido"
			   cMSg 	:= "CPF informado n„o È v·lido, favor digit·-lo corretamente para o setor de ExpediÁ„o faturar a nota."+CHR(13)+CHR(10)
			   cMSg 	+= "O par‚metro (MV_YCPFTIC) est· habilitado: neste caso o campo CPF È obrigatÛrio."+CHR(13)+CHR(10)                                  		   
			   U_fTelAviso(cCabc, cMSg, .F.) // Chama uma tela de aviso 
			   lRet := .F.			  
			Endif
		else  
			   cCabc 	:= "CPF ObrigatÛrio"
			   cMSg 	:= "CPF deve ser informado para o setor de ExpediÁ„o faturar a nota."+CHR(13)+CHR(10)
			   cMSg 	+= "O par‚metro (MV_YCPFTIC) est· habilitado: neste caso o campo CPF È obrigatÛrio."+CHR(13)+CHR(10)                                  		   
	 		   //Aviso("CPF n„o informado : ",cMSg,{"OK"},2)  
			   U_fTelAviso(cCabc, cMSg, .F.)
   			   lRet := .F.
		Endif
	Endif	
	
Return(lRet)       


/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±±  Tela criada devido n„o funcionar comando Aviso/Alert nesta tela    	       ±±
±±  "Define Window" apos protheus 11 n„o abri por Alert - F·bio Loures19/05/14 ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
User Function fTelAviso(cCabc, cGmsn, lBotNao ) 

Private cEstilo1   := cEstilo2 := ""
Default lBotNao := .F. 
nOpcao := ""

fCorTelaCSS() // Chama os estilos
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± DeclaraÁ„o de Variaveis Private dos Objetos                             ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	SetPrvt("oFont1","oFont2","oDlg1","oSay1","oMGet1","oBtnOK","oBtnOK","oBtnNAO")
	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± Definicao do Dialog e todos os seus componentes.                        ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	oFont1     := TFont():New( "Arial",0,-16,,.T.,0,,700,.T.,.F.,,,,,, )
	oFont2     := TFont():New( "Arial",0,-15,,.T.,0,,700,.F.,.F.,,,,,, )
	
	oDlg1      := MSDialog():New( 205,446,446,918, substr(cCabc,1,40),,,.F.,,,,,,.T.,,,.T. )
	oSay1      := TSay():New( 003,008,{|| substr(alltrim(cCabc),1,600) },oDlg1,,oFont1,.F.,.F.,.F.,.T.,CLR_HRED,CLR_WHITE,216,012)
	oMGet1     := TMultiGet():New( 016,008,{|u| If(PCount()>0,cGmsn:=u,cGmsn)},oDlg1,216,080,oFont2,,CLR_BLACK,CLR_WHITE,,.T.,"",,,.F.,.F.,.T.,,,.F.,,  )
	
	If lBotNao	
		oBtnOK  := TButton():New( 098,136,"SIM",oDlg1,{|| nOpcao := 1 , oDlg1:End()},042,022,,,,.T.,,"",,,,.F. )   
		oBtnNAO := TButton():New( 098,182,"N√O",oDlg1,{|| nOpcao := 2 , oDlg1:End()},042,022,,,,.T.,,"",,,,.F. )    	//nOpcao := 2
		If  isInCallStack("U_DIA234") 
			oBtnOK:lCanGotFocus := .F.     // Indica se objeto pode (.T.) ou n„o (.F.) receber foco.  -> TSrvObject:lCanGotFocus   (COMANDO Bom para usar QUANDO … TOUCH) OU USAR bGotFocus		
			oBtnNAO:lCanGotFocus := .F.     // Indica se objeto pode (.T.) ou n„o (.F.) receber foco.  -> TSrvObject:lCanGotFocus   (COMANDO Bom para usar QUANDO … TOUCH) OU USAR bGotFocus		
        Endif		
		oBtnOK:SetCss(cEstilo1) 
		oBtnNAO:SetCss(cEstilo1) 		
	Else
		oBtnOK  := TButton():New( 098,182,"OK",oDlg1,{|| nOpcao := 1 , oDlg1:End()},042,022,,,,.T.,,"",,,,.F. )
		If  isInCallStack("U_DIA234") 
			oBtnOK:lCanGotFocus := .F.     // Indica se objeto pode (.T.) ou n„o (.F.) receber foco.  -> TSrvObject:lCanGotFocus   (COMANDO Bom para usar QUANDO … TOUCH) OU USAR bGotFocus						
	    Endif
		oBtnOK:SetCss(cEstilo1) 
	Endif

	oDlg1:Activate(,,,.T.)

Return (nOpcao) 

///////////////////////////////////////////////////
// Tela com as definiÁıes CSS de cada estilo     //  
//                            F·bio Loures       //
///////////////////////////////////////////////////
Static function fCorTelaCSS()
   
    //////////////////////////////////////////
    // BOT√O VERDE -> PADR√O DAS TELAS      //
    //////////////////////////////////////////
    //cEstilo1 := " border-style: outset;" 
    cEstilo1 := " background-color: #32CD99;"  //ADD
    /*cEstilo1 += " border-width: 2px;"
    cEstilo1 += " border: 1px solid #C0C0C0;"
    cEstilo1 += " border-radius: 5px;"
    cEstilo1 += " border-color: #C0C0C0;"
    cEstilo1 += " font: bold 17px Verdana;" //cEstilo1 += " font: bold 19px Arial;"
    cEstilo1 += " padding: 6px;"*/
    cEstilo1 += "}"      
    //Na classe QPushButton:pressed , temos o efeito pressed, onde ao se pressionar o bot„o ele muda
    cEstilo1 += "QPushButton:pressed {"
    cEstilo1 += " background-color: #e6e6f9;"
    cEstilo1 += " border-style: inset;"
    cEstilo1 += "}"    
    

    //////////////////////////////////////////////////////
    // Estilo do OBJETO MSDIOLOG  -> FUNDO CINZA CLARO  //
    //////////////////////////////////////////////////////
    cEstilo2 := " background-color: #D8D8BF;"     //#C0D9D9  #D8D8BF #C0C0C0     
    cEstilo2 += "}"  
      
    ////////////////////////////////////////////////////////    
    //oBtnInicia:SetCss(cEstVerde) // BOT√O ->Fundo Verde //        
    ////////////////////////////////////////////////////////    
    cEstVerde := " background-color: #99CC32;"  
    cEstVerde += "}"   
    cEstVerde += "QPushButton:pressed {"
    cEstVerde += " background-color: #e6e6f9;"
    cEstVerde += " border-style: inset;"
    cEstVerde += "}"  

    //////////////////////////////////////////////////////////    	
	//oBtnParada:SetCss(cEstVerme) // BOT√O ->Fundo Vermelho//            
    //////////////////////////////////////////////////////////    	
    cEstVerme := " background-color: #8C1717;"  
    cEstVerme += "}" 
    cEstVerme += "QPushButton:pressed {"
    cEstVerme += " background-color: #e6e6f9;"
    cEstVerme += " border-style: inset;"
    cEstVerme += "}" 
    
    cEstVerm1 := " background-color: #FF0000;"  
    cEstVerm1 += "}" 
    cEstVerm1 += "QPushButton:pressed {"
    cEstVerm1 += " background-color: #FF0000;"
    cEstVerm1 += " border-style: inset;"
    cEstVerm1 += "}"         
        

    ////////////////////////////////////////////////////////////    		
	//oBtnPerda:SetCss(cEstLaranj)  // BOT√O ->Fundo Laranja  //
    ////////////////////////////////////////////////////////////    		
    cEstLaranj := " background-color: #FF7F00;"  
    cEstLaranj += "}" 
    cEstLaranj += "QPushButton:pressed {"
    cEstLaranj += " background-color: #e6e6f9;"
    cEstLaranj += " border-style: inset;"
    cEstLaranj += "}"   
    
   
    ////////////////////////////////////////////////////
    // BOT√O VERDE -> PADR√O DAS TELAS tamanho maior  //
    ////////////////////////////////////////////////////
    //cEstilo3 := " border-style: outset;" 
    cEstilo3 := " background-color: #32CD99;"  //ADD
    /*cEstilo3 += " border-width: 2px;"
    cEstilo3 += " border: 1px solid #C0C0C0;"
    cEstilo3 += " border-radius: 5px;"
    cEstilo3 += " border-color: #C0C0C0;"
    cEstilo3 += " font: bold 19px Verdana;" //cEstilo1 += " font: bold 19px Arial;"
    cEstilo3 += " padding: 6px;"*/
    cEstilo3 += "}"      
    //Na classe QPushButton:pressed , temos o efeito pressed, onde ao se pressionar o bot„o ele muda
    cEstilo3 += "QPushButton:pressed {"
    cEstilo3 += " background-color: #e6e6f9;"
    cEstilo3 += " border-style: inset;"
    cEstilo3 += "}"
    
    
    cEstGRID := " background-color: #32CD99;"  //ADD
	cEstGRID := " font: bold 22px Verdana;" //cEstilo1 += " font: bold 19px Arial;"
    cEstGRID += " padding: 9px;"
    cEstGRID += "}" 
 
    

Return(.T.) 



Static Function fReimpTkt()

//IMPRESSAO DE TICKETS DE ACORDO COM AS CONDICOES
SZ8->(DbSetOrder(1))
SZ8->(dbGoBottom())
cPESAGEM := SZ8->Z8_NRPESA

IF SZ8->(DbSeek(XFilial("SZ8")+cPESAGEM))

	IF SZ8->Z8_TPPESA $ ("E,S") //.And. SZ8->Z8_TPMOVI $ ("V#C#D#E#O")

		If !Empty(SZ8->Z8_NRPESEN)	//Entrada ou Saida finalizando processo de pesagem.
			PrTicket(2, cPESAGEM)
		ELSE
			PrTicket(1, cPESAGEM)
		EndIf

	ELSEIF SZ8->Z8_TPPESA $ ("I")

		PrTicket(2, cPESAGEM)

	ENDIF
	/*
	IF SZ8->Z8_TPPESA $ ("E") .And. SZ8->Z8_TPMOVI $ ("V#C#D#E#O")
		
		PrTicket(1, cPESAGEM)
		
	ELSEIF SZ8->Z8_TPPESA $ ("I") .And. SZ8->Z8_TPMOVI $ ("V")
		
		PrTicket(3, cPESAGEM)
		
	ELSEIF SZ8->Z8_TPPESA $ ("S") .And. SZ8->Z8_TPMOVI $ ("V")
		
		PrTicket(2, cPESAGEM)
		
	ELSEIF SZ8->Z8_TPPESA $ ("S") .And. SZ8->Z8_TPMOVI $ ("C#D#E#O")
		
		//PrTicket(4, cPESAGEM)
		PrTicket(2, cPESAGEM)
		
	ELSE
		
		PrTicket(1, cPESAGEM)
		
	ENDIF
	*/
	
ENDIF

Return

Static Function fDigPeso()

/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± DeclaraÁ„o de Variaveis Private dos Objetos                             ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
SetPrvt("nPeso","oFont1","oDlg2","osay1","oPeso","oBtn1")

/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± Definicao do Dialog e todos os seus componentes.                        ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
oFont1     := TFont():New( "MS Sans Serif",0,-16,,.T.,0,,700,.F.,.F.,,,,,, )
oDlg2      := MSDialog():New( 178,362,322,638,"Informe o PESO",,,.F.,,,,,,.T.,,,.T. )
osay1      := TSay():New( 010,018,{||"Informe o peso da balanÁa"},oDlg2,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,120,010)
oPeso      := TGet():New( 028,029,{|u| If(PCount()>0,nGetPESO:=u,nGetPESO)},oDlg2,075,012,'@E 999,999.999',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.T.,.F.,,.F.,.F.,,"nGetPESO",,)
oBtn1      := TButton():New( 052,046,"&OK",oDlg2,{|| oDlg2:End()},037,012,,oFont1,,.T.,,"",,,,.F. )

oDlg2:Activate(,,,.T.)

Return

// Busca as NFs que foram faturadas e estao relacionadas ao veiculo informado.
Static Function fBuscaNf()

_CNFS := ""
//cRecNFS := ""
_nPESO := 0
cProdPerda := Alltrim(GetNewPar("MV_YPROPER",""))

//SE SAIDA PARA VENDA - BUSCAR O NUMERO E PESO DAS NFs
IF Empty(cGetNFS) .and. aTPDados[oComboBo1:nAT] == "S" .And. aMOTDados[oComboBo3:nAT] $ "V,R" 

 //condiÁ„o desativada para considerar tambem as NFs de remessa p/ industr .And. aMOTDados[oComboBo3:nAT] == "V"

	_AliasTmp := GetNextAlias()

	BeginSQl Alias  _AliasTmp
		SELECT DISTINCT SF2.R_E_C_N_O_ REC, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA , F2_PLIQUI , F2_FILIAL
		FROM %TABLE:SF2% SF2
		JOIN %TABLE:DA3% DA3 
			ON DA3.DA3_COD = SF2.F2_VEICUL1 
			AND DA3.%NotDel%
		WHERE SF2.%NOTDEL%
		//AND SF2.F2_TIPO = 'N'
		AND SF2.F2_YNRPESA = ' '
		AND DA3.DA3_PLACA  = %EXP:AllTrim(cGetPLACA)%
	EndSql

	dbSelectArea(_AliasTmp)

    nPeLiqf2 := 0
	(_AliasTmp)->(DbGoTop())
	While .Not. (_AliasTmp)->(Eof())

		
		_AliasTmp2 := GetNextAlias()
		BeginSQl Alias  _AliasTmp2
			SELECT ISNULL(SUM(SC9.C9_YPESO),0) AS C9_YPESO
			FROM %TABLE:SC9% SC9
			WHERE SC9.%NOTDEL%
			AND SC9.C9_NFISCAL = %EXP:AllTrim((_AliasTmp)->F2_DOC)%
			AND SC9.C9_SERIENF = %EXP:AllTrim((_AliasTmp)->F2_SERIE)%
			AND SC9.C9_PRODUTO <> %EXP:cProdPerda%
			AND SC9.C9_CLIENTE = %EXP:AllTrim((_AliasTmp)->F2_CLIENTE)%
			AND SC9.C9_LOJA    = %EXP:AllTrim((_AliasTmp)->F2_LOJA)%
			AND SC9.C9_FILIAL  = %EXP:AllTrim((_AliasTmp)->F2_FILIAL)%			
		EndSql

		If (_AliasTmp2)->(!Eof())
            If (_AliasTmp2)->C9_YPESO == 0
            	/*Alert("ATEN«√O: A NOTA FISCAL "+AllTrim((_AliasTmp)->F2_DOC)+" est· com o peso zerado. Provavelmente È uma nota de remessa "+;
            	"e o pedido fatura n„o foi pesado e n„o foi faturado. Haver· diferenÁa de peso das NFs x BALAN«A."+CRLF+CRLF+;
            	"IMPORTANTE: AVISE AO DEPTO DE FATURAMENTO TODO O CONTE⁄DO DESSA MENSAGEM E SOLICITE A CORRE«√O PARA LIBERAR O VEÕCULO.")            	
            	*/                          
               cMSg 	:= "ATEN«√O: A NOTA FISCAL "+AllTrim((_AliasTmp)->F2_DOC)+" est· com o peso zerado. Provavelmente È uma nota de remessa "+;
            	"e o pedido fatura n„o foi pesado e n„o foi faturado. Haver· diferenÁa de peso das NFs x BALAN«A."+CRLF+CRLF+;
            	"IMPORTANTE: AVISE AO DEPTO DE FATURAMENTO TODO O CONTE⁄DO DESSA MENSAGEM E SOLICITE A CORRE«√O PARA LIBERAR O VEÕCULO."            	      	            	
			   cCabc 	:= "Peso das NFs x BALAN«A"
			   U_fTelAviso(cCabc, cMSg, .F.)
	   		   
            EndIf
            If (_AliasTmp2)->C9_YPESO == 0 
              	_nPESO += (_AliasTmp)->F2_PLIQUI
            Else			
				_nPESO += (_AliasTmp2)->C9_YPESO
		    Endif
		EndIf
		(_AliasTmp2)->(dbCloseArea())
		//---------

		If !Empty(_CNFS)
			_CNFS+=","
		EndIf

		/*If !Empty(cRecNFS)
			cRecNFS += ","
		EndIf
		*/
		_CNFS += (_AliasTmp)->F2_FILIAL+(_AliasTmp)->F2_DOC+(_AliasTmp)->F2_SERIE //ALLTRIM((_AliasTmp)->F2_DOC)
		//cRecNFS += ALLTRIM(STR((_AliasTmp)->REC))
	    
	    nPeLiqf2 += (_AliasTmp)->F2_PLIQUI // Somando peso liquido, devido algumas notas terem sucatas -> o campo C9_YPESO zerado. Consideramos o F2_PLIQUI das notas.
	    
		(_AliasTmp)->(DbSkip())
	EndDo
	(_AliasTmp)->(DbCloseArea()) 
	
	If _nPESO==0 // Devido algumas notas terem sucatas -> o campo C9_YPESO est· zerado,consideramos o F2_PLIQUI das notas para que este campo n„o fique zerado.
		_nPESO := nPeLiqf2  
        //conout("TEMP alterou _nPESO ZERO PARA "+CVALTOCHAR(nPeLiqf2))
	Endif
	If !aMOTDados[oComboBo3:nAT] $ "C,D".and.  aTPDados[oComboBo1:nAT] $ "S,I" .and. !Empty(_CNFS)  // Venda
		cGetNFS     := _CNFS 
	    nGetPESONFS := _nPESO	
	ElseIf  !aMOTDados[oComboBo3:nAT] $ "C,D" .and.  !aTPDados[oComboBo1:nAT] $ "S" .and.  !Empty(cGetNFS)  // Quando for COMPRA OU DEV. VENDA e SAIDA e existir NOTAS E PESO n„o apagar
		cGetNFS     := _CNFS 
	    nGetPESONFS := _nPESO
	Else
		cGetNFS     := _CNFS 
	    nGetPESONFS := _nPESO
    Endif	
	oGetPESONFS:Refresh()
	oGetNFS:Refresh()
	//oDlgBal:Refresh()
	
ENDIF

Return

Static Function VALBAST()
lResp := .T.

IF aTPDados[oComboBo1:nAT] == "I" .AND. aABASTDados[oComboBo4:nAT] == "S"
	/*MsgAlert("N„o È permitido informar o abastecimento em uma pesagem INTERMEDIARIA."+CRLF+;
	"Informe o abastecimento na SAÕDA DO VEÕCULO.")                                           */	
    cMSg 	:= "N„o È permitido informar o abastecimento em uma pesagem INTERMEDIARIA."+CRLF+"Informe o abastecimento na SAÕDA DO VEÕCULO."
    cCabc 	:= "Abastecimento informado"
    U_fTelAviso(cCabc, cMSg, .F.)
	oComboBo4:nAT	:= 1
	nComboBo4		:= 1
	nGetLITROS		:= 0
	oGetLITROS:Refresh()
	
	lResp := .F.
ElseIf aABASTDados[oComboBo4:nAT] == "N" .OR. Empty(aABASTDados[oComboBo4:nAT])
	nGetLITROS		:= 0
	oGetLITROS:Refresh()
ENDIF

Return(lResp)

///////////////////////////////////////////////////////////////////
// FunÁ„o para Incluir as nota de Entrada e SaÌda                //
// 									F·bio Loures 03/04/2017.     // 
///////////////////////////////////////////////////////////////////
Static Function fCalc()

If Alltrim(aMOTDados[oComboBo3:nAT]) $ ALLTRIM(GETNEWPAR("MV_YFTBVA3","#C#") ) .and.;
             aTPDados[oComboBo1:nAT] $ ALLTRIM(GETNEWPAR("MV_YFTBVA4","#E#") ) // Tipo Pesagem "S#I#E" -> Saida , intermediaria, Entrada

/*ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± Compras (Busca as Notas de Entrada)      ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	Private cGetFornec := Space(6)
	Private cGetNota   := CRIAVAR("D1_DOC") 
	Private cGetSerie  := CRIAVAR("D1_SERIE")
	Private cSayEmissa := Space(20)
	Private cSayFilial := Space(1)
	Private cSayForn   := Space(1)
	Private cSayNF     := Space(06)
	Private cSayNomFor := Space(50)
	Private cSayP      := Space(1)
	Private cPesoTot   := 0            
	Private nPesoNota  := 0    	
	Private cSaySerie  := Space(1)
	Private nCBoxFilia         
	Private aCampos	   := {}  
	Private aColors    := {}
	Private cMarca	   := GetMark()   
	Private nRecno     := 0    
	Private cCodForn   := CRIAVAR("D1_FORNECE")

	cRecSF1 		   :=  "" 
	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± DeclaraÁ„o de Variaveis Private dos Objetos                             ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	SetPrvt("oFont1","oFont2","oDlgNOTA","oSay2","oSayP","oSayPeso","oBrwNotas","oBtnConfirmar","oBtnFechar")
	SetPrvt("oSayFilial","oSayNF","oSaySerie","oSayForn","oSayNomFornec","oSay3","oSayEmissao","oCBoxFilial","oSayPNF","oSay4")
	SetPrvt("oGetSerie","oGetFornec","oBtnIncluir","oBtnXML")
	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± Definicao do Dialog e todos os seus componentes.                        ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	oFont1     := TFont():New( "Verdana",0,-16,,.T.,0,,700,.F.,.F.,,,,,, )
	oFont2     := TFont():New( "Verdana",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )
	oFont3     := TFont():New( "Verdana",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )	
	oDlgNOTA   := MSDialog():New( 162,311,577,1065,"Recebimento de Material - Documento de Entrada",,,.F.,,,,,,.T.,,,.T. )

 	fHeader()         
	DbSelectArea("TMP") 
	oBrwNotas  := MsSelect():New( "TMP","","", aCampos ,.F.,cMarca ,{085,005,176,364},,, oDlgNOTA,,aColors ) 

	oGrpDados  := TGroup():New( 004,004,072,364,"",oDlgNOTA,CLR_BLACK,CLR_WHITE,.T.,.F. )

	oSay2      := TSay():New( 075,007,{||"Notas Fiscais:"},oDlgNOTA,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,280,008)
	
	oSayFilial := TSay():New( 012,008,{||"Filial:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,016)
	oSayNF     := TSay():New( 012,077,{||"NR. NF:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,047,012)
	oSaySerie  := TSay():New( 012,182,{||"SÈrie:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,034,012)

	oSayForn   := TSay():New( 029,007,{||"Fornecedor:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)
	oSayNomFor := TSay():New( 028,124,{||cSayNomFor },oGrpDados,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,241,012)

	oSay3      := TSay():New( 046,008,{||"Emiss„o:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)
	oSayEmissa := TSay():New( 045,061,{||cSayEmissa },oGrpDados,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,083,012)
	
    If "01" $ alltrim(_cEmpresa)
	   oCBoxFilia := TComboBox():New( 013,044,{|u| If(PCount()>0,nCBoxFilial:=u,nCBoxFilial)},{"01","02","04"},024,010,oGrpDados,,,,CLR_BLACK,CLR_WHITE,.T.,,"",,,,,,,nCBoxFilial )
	Else
	   oCBoxFilia := TComboBox():New( 013,044,{|u| If(PCount()>0,nCBoxFilial:=u,nCBoxFilial)},{"01"},024,010,oGrpDados,,,,CLR_BLACK,CLR_WHITE,.T.,,"",,,,,,,nCBoxFilial )	
	Endif

	oGetNota   := TGet():New( 011,124,{|u| If(PCount()>0,cGetNota:=u,cGetNota)}    ,oGrpDados,044,010,'', {|| If(!empty(cGetNota)   ,fRetInf(alltrim(nCBoxFilial),alltrim(cGetNota),'',''),"")   ,     oGetSerie:refresh(), oGetFornec:refresh()  } ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetNota",,)
	oGetSerie  := TGet():New( 011,217,{|u| If(PCount()>0,cGetSerie:=u,cGetSerie)}  ,oGrpDados,020,010,'', {|| If(!empty(cGetSerie)  ,fRetInf(alltrim(nCBoxFilial),alltrim(cGetNota),cGetSerie,''),"")  , oGetFornec:refresh()   } ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetSerie",,)
	oGetFornec := TGet():New( 028,074,{|u| If(PCount()>0,cGetFornec:=u,cGetFornec)},oGrpDados,038,010,'', {|| If(!empty(cGetFornec) ,fRetInf(alltrim(nCBoxFilial),alltrim(cGetNota),cGetSerie,cGetFornec),"")  } ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"SA2","cGetFornec",,)

 
   	oSayPNF    := TSay():New( 046,125,{||"Peso:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,035,015)
    oSay4      := TSay():New( 045,167,{|| PADL(Transform(nPesoNota,"@E 999,999.99"),10)  },oGrpDados,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,083,012)
				                                                                      
				  
	oSayP      := TSay():New( 180,008,{||"Peso Total:"},oDlgNOTA,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)
	oSayPeso   := TSay():New( 180,075,{|| PADL(Transform(cPesoTot,"@E 999,999.99"),10) },oDlgNOTA,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,156,016)

	oBtnInclui := TButton():New( 044,272,"Incluir",oDlgNOTA, {|| LjMsgRun("Incluindo notas... ",, { || inclNF(nCBoxFilial,cGetNota,cGetSerie,cSayNomFor,cSayEmissa,nPesoNota,nRecno, cCodForn ), 	oGetNota:refresh(), 	oGetSerie:refresh() ,   oGetFornec:refresh() , oBrwNotas:oBrowse:Refresh(), oSayPeso:refresh(),GETDREFRESH()  } )}  ,036,013,,,,.T.,,"",,,,.F. )

	oBtnInclui:Disable()
	oBtnConfir := TButton():New( 180,260,"Confirmar",oDlgNOTA, {|| LjMsgRun("Confirmando Notas... ",, { || Confirma(cPesoTot),oDlgNOTA:End()  } )}  ,037,012,,,,.T.,,"",,,,.F. )
	oBtnFechar := TButton():New( 180,301,"Fechar",oDlgNOTA,{|| oDlgNOTA:End() } ,037,012,,,,.T.,,"",,,,.F. )
	
	//oBtnXML	   := TButton():New( 044,313,"Busca Peso(XML)",oDlgNOTA,{|| fLexml() } ,046,013,,,,.T.,,"",,,,.F. )   // Ser· usado atÈ Central XML ficar pronta 02/06/2017
	//oBtnXML:Disable()	

	oCBoxFilia:SetFocus()	// Seta inicialmente no campo Filial (pois n„o È para usar mouse)
	oBrwNotas:oBrowse:Refresh() 
	
	oDlgNOTA:Activate(,,,.T.)   
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	    
ElseIf Alltrim(aMOTDados[oComboBo3:nAT]) $ "#D#" .and.;   // 3-DevoluÁ„o de Venda  Tela para Buscar as Notas de SaÌda
       aTPDados[oComboBo1:nAT] $  "#I#E#S#"               // Tipo Pesagem "S#I#E" -> Saida , intermediaria, Entrada

	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± DevoluÁ„o de Vendas (Busca as Notas de SaÌda)      ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	Private cGetNota   := CRIAVAR("D2_DOC")  
	Private cGetOBS    := Space(250)
	Private cGetOutPs  := 0 
	Private cGetSerie  := CRIAVAR("D2_SERIE")
	Private cSayClient := Space(1)
	Private cSayEmissa := Space(20)
	
	Private cSayFilial := Space(1)
	Private cSayForn   := Space(1)
	Private cSayNF     := Space(1)
	Private cSayNomCli := Space(50)
	Private cSayobs    := Space(1)
	Private cSayP      := Space(1)
	Private cSayPeso   := Space(1)
	Private cSayPesTot := Space(1)
	Private cSayPNF    := Space(1)
	Private cSaySerie  := Space(1)
	Private nCBoxFilia 
	
	Private cPesoTot   := 0 // Total Geral           
	Private nPesoNota  := 0
	Private nPesoNTT   := 0 // Total das notas 
	Private aHoBrwNTS  := {}
	Private aCoBrwNTS  := {}	
	Private noBrwCon   := 0 
	Private cNTSer     := "" 
	Private cPesoDEV   := 0
	nOpcPSDEV    	   := GD_UPDATE // GD_DELETE+GD_INSERT
	cNotasS := ""
	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± DeclaraÁ„o de Variaveis Private dos Objetos                             ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	SetPrvt("oFont1","oFont2","oDlg122","oSay2","oSayP","oSayPeso","oSay5","oSayobs","oSay6","oSay7","oBrwNotas","oSayPeso")
	SetPrvt("oBtnFechar","oGrpDados","oSayFilial","oSayNF","oSaySerie","oSayCliente","oSayNomCliente","oSay3")
	SetPrvt("oSayPNF","oSay4","oCBoxFilial","oGetNota","oGetSerie","oBtnIncluir","oGetOutPs","oGetOBS","oSayPeso","oSayPSNTT","oSayPSTT","oSayPDEV","oSayP1")
		   
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± Definicao do Dialog e todos os seus componentes.                        ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	oFont1     := TFont():New( "Verdana",0,-16,,.T.,0,,700,.F.,.F.,,,,,, )
	oFont2     := TFont():New( "Verdana",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )
	oFont3     := TFont():New( "Verdana",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )	
	oDlg122    := MSDialog():New( 083,220,546,1237,"Recebimento de Material - Documento de SaÌda",,,.F.,,,,,,.T.,,,.T. )
	
	oGrpDados  := TGroup():New( 004,004,072,492,"",oDlg122,CLR_BLACK,CLR_WHITE,.T.,.F. )
	
	oSayFilial := TSay():New( 012,008,{||"Filial:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,032,016)
	oSayNF     := TSay():New( 012,077,{||"NR. NF:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,047,012)
	oSaySerie  := TSay():New( 012,182,{||"SÈrie:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,034,012)
	oSayClient := TSay():New( 029,007,{||"Cliente:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)
	oSayNomCli := TSay():New( 028,056,{|| cSayNomCli },oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,304,012)
	oSay3      := TSay():New( 046,008,{||"Emiss„o:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)
	oSayEmissa := TSay():New( 045,061,{|| cSayEmissa },oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,083,012)
	oSayPNF    := TSay():New( 046,145,{||"Peso:"},oGrpDados,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,035,015)
	oSayPeso      := TSay():New( 045,178,{|| PADL(Transform(nPesoNota,"@E 999,999.99"),10)  },oGrpDados,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,083,012)

	If "01" $ alltrim(_cEmpresa)
	   oCBoxFilia := TComboBox():New( 013,044,{|u| If(PCount()>0,nCBoxFilial:=u,nCBoxFilial)},{"01","02","04"},024,010,oGrpDados,,,,CLR_BLACK,CLR_WHITE,.T.,,"",,,,,,,nCBoxFilial )
	Else
	   oCBoxFilia := TComboBox():New( 013,044,{|u| If(PCount()>0,nCBoxFilial:=u,nCBoxFilial)},{"01"},024,010,oGrpDados,,,,CLR_BLACK,CLR_WHITE,.T.,,"",,,,,,,nCBoxFilial )	
	Endif
	oGetNota   := TGet():New( 011,124,{|u| If(PCount()>0,cGetNota:=u,cGetNota)},oGrpDados,048,008,''  ,  {|| If(!empty(cGetNota)   , fRetInfD(alltrim(nCBoxFilial),alltrim(cGetNota),cGetSerie,''),flimpCam())  , oSayNomCli:refresh() , oSayEmissa:refresh()   }  ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetNota",,)
	oGetSerie  := TGet():New( 011,217,{|u| If(PCount()>0,cGetSerie:=u,cGetSerie)},oGrpDados,048,008,'',  {|| If(!empty(cGetNota)  , fRetInfD(alltrim(nCBoxFilial),alltrim(cGetNota),cGetSerie,'') ,flimpCam())  , oSayNomCli:refresh() , oSayEmissa:refresh()   }   ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetSerie",,)
	oBtnInclui := TButton():New( 044,272,"Incluir",oDlg122, { || inclNFd(nCBoxFilial,cGetNota,cGetSerie ), 	oGetNota:refresh(), 	oGetSerie:refresh() ,   oBrwNotas:oBrowse:Refresh(), oSayPeso:refresh(),GETDREFRESH()  }  ,036,013,,,,.T.,,"",,,,.F. )
	
	oSay2      := TSay():New( 075,007,{||"Notas Fiscais:"},oDlg122,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,280,008)                                                     
	//fAtualQtd(),fQTDDSum(),fSumQTDDEV()
	oBtnQTDddev:= TButton():New( 073,392,"Preencher QTD DEV com a QTD."   ,oDlg122,  {|| LjMsgRun("Atualizando campo QTD DEV... ",, { || fAtualQtd(), oBrwNotas:refresh() } )} ,090,011,,,,.T.,,"",,,,.F. )
	 
	oSayP      := TSay():New( 204,008,{||"Peso Total NF'S:"},oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,150,015)
	oSayPSNTT  := TSay():New( 204,115,{|| PADL(Transform(nPesoNTT,"@E 999,999.99"),10) },oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,088,012)

	oSay6      := TSay():New( 204,193,{||""},oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)  //Peso Total
	oSayPSTT   := TSay():New( 204,279,{|| ""},oDlg122,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,065,015) //oSayPSTT   := TSay():New( 204,279,{|| PADL(Transform(cPesoTot,"@E 999,999.99"),10) },oDlg122,,oFont3,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,065,015)

	oSayPDEV   := TSay():New( 202,358,{||"Peso Dev.:"},oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,065,015)
	oSayP1	   := TSay():New( 202,437,{|| PADL(Transform(cPesoDEV,"@E 999,999.99"),10) },oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_RED,CLR_WHITE,088,012)


	oSay5      := TSay():New( 181,009,{||"Outros Pesos:"},oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,083,015)
	oGetOutPs  := TGet():New( 184,092,{|u| If(PCount()>0,cGetOutPs:=u,cGetOutPs)},oDlg122,060,008,'@E 999,999,999.99', {|| If(!empty(cGetOutPs)  , fAtPeso(),"")  , oSayPSTT:refresh() , oSayPSNTT:refresh()   } 	 ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetOutPs",,)
	oGetOutPs:lHasButton := .F.  // Habilitar bot„o no estilo calculadora
	
	oSayobs    := TSay():New( 182,158,{||"OBS.:"},oDlg122,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,030,015)
	oGetOBS    := TGet():New( 184,192,{|u| If(PCount()>0,cGetOBS:=u,cGetOBS)},oDlg122,212,008,'',,CLR_HBLUE,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetOBS",,)

	///////////////////////////////////////////////////////////////////////////
	//-- GRID ITENS DAS NOTAS de SAÕDA para informar a QUANTIDADE DEVOLVIDA  //
	///////////////////////////////////////////////////////////////////////////
	MHoBrwNTS()
	MCoBrwNTS(cPESAGEM)
	LinOkNTS 	:= 'AllwaysTrue()'                   
	TudOkNTS 	:= "ExecBlock('U_fQTDDSum',.F.,.F.)"
	oBrwNotas   := MsNewGetDados():New(085,005,176,492,nOpcPSDEV,LinOkNTS,TudOkNTS,'',,0,99,'AllwaysTrue()','','AllwaysTrue()',oDlg122,aHoBrwNTS,aCoBrwNTS )
    ///////////////////////////////////////////////////////////////////////////	
	
	oBtnConfir := TButton():New( 180,408,"Confirmar",oDlg122, {|| LjMsgRun("Confirmando Notas... ",, { || ConfirNTD(cPesoDEV) } )} ,037,012,,,,.T.,,"",,,,.F. )
	oBtnFechar := TButton():New( 180,453,"Fechar"   ,oDlg122, {|| oDlg122:End() },037,012,,,,.T.,,"",,,,.F. )
	
	oDlg122:Activate(,,,.T.)

     
EndIf   


Return

/////////////////////////////////////////////////////////////////////////////
// Atualiza a QTD DEV igual aos itens da nota, caso QTD. DEV IGUAL A ZERO  //
///////////////////////////////////////////////////////
Static function fAtualQtd()

    lAtualiz := .F.
	///////////////////////
    // Percorre o acols  //
	///////////////////////
	cPesoDEV := 0
	For Ni:=1 To Len(oBrwNotas:aCols)
    	nQTDINF := NwFieldGet(oBrwNotas, "C9_YPESO"	, Ni)
    	citem   := NwFieldGet(oBrwNotas, "ZS_ITEM"	, Ni)
    	nQTDdev := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)
    	If Len(aCobrwNTS)>0
			If aCobrwNTS[Ni][10] ==0
			    aCobrwNTS[Ni][10]	:= aCobrwNTS[Ni][8]
			    lAtualiz := .T.
			Endif    	  
		 cPesoDEV += aCobrwNTS[Ni][10] //nQTDdev
		Endif    	  				
		oSayP1:Refresh()
    Next Ni   
    If lAtualiz
	    //U_fQTDDSum() //U_ValQTDDEV() // // Atualiza os totalizadores
	    //oSayP1:Refresh()
	    oBrwNotas   := MsNewGetDados():New(085,005,176,492,nOpcPSDEV,LinOkNTS,TudOkNTS,'',,0,99,'AllwaysTrue()','','AllwaysTrue()',oDlg122,aHoBrwNTS,aCoBrwNTS )       
    Endif


Return

///////////////////////////////////////////////////////
// Limpa os campos caso n„o digitar nada nos campos  //
///////////////////////////////////////////////////////
Static function flimpCam()

	cSayNomCli := cSayEmissa := ""  
	nPesoNota := 0 

	oSayNomCli:Refresh()
	oSayEmissa:Refresh()
    oSayPeso:Refresh()

    If !empty(cGetNota)
		cGetNota := CRIAVAR("D2_DOC")
    	oGetNota:Refresh()    
	    oGetNota:SetFocus()
    Endif
	cGetNota := CRIAVAR("D2_DOC")
   	oGetNota:Refresh()    

Return
/////////////////////////////////////////////////////////////////
// Ao confirmar as notas incluidas no Grid DEVOLU«¬O DE VENDAS //
/////////////////////////////////////////////////////////////////
Static function ConfirNTD(nPesoG)

	If nPesoG>0	 // Peso TOTAL das notas nPesoNTT   cPesoDEV-PESO TOTAL DA DEVOLU«√O SELECIONADA
		////////////////////////////////////////////////
	    // Informa o Peso das notas na tela principal //
		////////////////////////////////////////////////
	    nGetPESONFS := nPesoG
		oGetPESONFS:Disable()  
	   	oGetPESONFS:Refresh() 
	   	
	   	cGetNFS := cNotasS 
		oGetNFS:Disable()     	
	   	oGetNFS:Refresh() 	
	   	                   
	   	cNotasS := "" 
		//////////////////////////////////////////
	   	// Atualiza e Desabilitar o campo OBS.  //
	   	//////////////////////////////////////////
	  	cGetOBSERV :=  "PESO: #"+cvaltochar(cGetOutPs)+"# "+cGetOBS//+"  "+alltrim(cGetOBSERV)
		oGetOBSERV:Disable()     	
	  	oGetOBSERV:Refresh()		
	  	oDlg122:End()
	Else
	   cCabc 	:= "Qtd. Dev. n„o informada"
	   cMSg 	:= "ATEN«√O: A QTD. DEV. n„o foi informada."+CHR(13)+CHR(10)
	   cMSg 	+= "Confirme cada QTD. DEV. do(s) iten(s) dessa devoluÁ„o de venda."+CHR(13)+CHR(10)	
	   U_fTelAviso(cCabc, cMSg, .F.)	
	Endif
Return

////////////////////////////////////////////////
// Incluir as notas de saÌda no grid da tela  //
////////////////////////////////////////////////
Static function fRetInfD(cFil,cGetNota,cSerie)


If !Empty(cGetNota) .and.  !Empty(cFil)

 	   oBtnInclui:Disable()
      
       cQuery := "  SELECT   D2_DOC,D2_ITEM,       "
       cQuery += "           D2_SERIE,  "
       cQuery += "           A1_NOME,   "
       cQuery += "           A1_COD,    "
       cQuery += "           D2_EMISSAO,"
       cQuery += "     	     D2_UM, D2_QUANT,D2_PESO,C9_YPESO,F2_PLIQUI," 
       cQuery += "     	     C6_YUNV, 
       cQuery += "           A.R_E_C_N_O_ as R_E_C_N_O_ "
       cQuery += "           ,D2_CLIENTE,B1_COD,B1_YCOMPRI,B1_YLARGUR,B1_UM,D2_COD"
       cQuery += "  FROM "+RetSQlName("SD2")+" A (nolock) "
       cQuery += "  LEFT JOIN "+RetSQlName("SA1")+" B   (nolock) ON B.D_E_L_E_T_='' AND D2_CLIENTE=A1_COD AND D2_LOJA=A1_LOJA"
       cQuery += "  JOIN "+RetSQlName("SB1")+"      C   (nolock) ON C.D_E_L_E_T_='' AND D2_COD=B1_COD AND B1_LOCPAD=D2_LOCAL AND B1_FILIAL=D2_FILIAL"
       cQuery += "  LEFT JOIN "+RetSQlName("SC9")+" E   (nolock) ON E.D_E_L_E_T_='' AND D2_FILIAL = C9_FILIAL AND D2_PEDIDO=C9_PEDIDO AND D2_COD= C9_PRODUTO"  
       cQuery += "  AND D2_ITEMPV=C9_ITEM AND D2_DOC=C9_NFISCAL AND D2_SERIE=C9_SERIENF AND D2_LOTECTL=C9_LOTECTL"
       cQuery += "  LEFT JOIN "+RetSQlName("SC6")+" F   (nolock) ON F.D_E_L_E_T_='' AND C6_NUM=D2_PEDIDO AND D2_FILIAL=C6_FILIAL AND D2_ITEMPV=C9_ITEM "
       cQuery += "  AND C6_PRODUTO=D2_COD "
       cQuery += "  LEFT JOIN "+RetSQlName("SF2")+" G   (nolock) ON G.D_E_L_E_T_='' AND D2_DOC=F2_DOC AND D2_FILIAL=F2_FILIAL AND D2_SERIE=F2_SERIE"
       cQuery += "  WHERE A.D_E_L_E_T_='' "
       cQuery += "  AND D2_FILIAL='"+cFil+"'"
       cQuery += "  AND D2_DOC='"+cGetNota+"' "  
       If empty(cSerie) .AND. !empty(cGetNota)
	       cQuery += "  AND D2_EMISSAO  BETWEEN CONVERT(varchar, Getdate()-180, 112) AND CONVERT(varchar, Getdate(), 112)"
       Endif
       If !empty(cSerie)
	       cQuery += "  AND D2_SERIE='"+alltrim(cSerie)+"' "       
       Endif       
       cQuery += "  ORDER BY A.D2_ITEM ASC"
		
		If 	Select("QRY") > 0 	         
			QRY->(DbCloseArea())             
		Endif  

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRY", .F., .T.)   
		
		nPesoNota := 0  
		nRecno := "" 
        If QRY->(Eof())     // Se vazio informa que n„o existe NOTA        
	       // Limpa as vari·veis de pesquisa, caso n„o encontre registro selecionado
	       If !empty(cGetNota)  
		       nPesoNota  := 0 		   	        
		       cCabc 	:= "Documento n„o encontrado"
			   cMSg 	:= "ATEN«√O: N„o encontrado o Documento de Venda."+CHR(13)+CHR(10)
		       cMSg 	+= "Confirme os dados digitados."+CHR(13)+CHR(10)	
	           U_fTelAviso(cCabc, cMSg, .F.)  
	           oGetNota:SetFocus()
           Endif
   	       oBtnInclui:Disable()

		   cGetNota   := CRIAVAR("D2_DOC") //SPACE(06)
		   cGetSerie  := CRIAVAR("D2_SERIE") //SPACE(02)
		   cSayNomCli := SPACE(60) 
		   cSayEmissa := SPACE(12)  
        Endif
	    lPrime := .T.
		While !QRY->(Eof())   

		   	oBtnInclui:Enable()			
		    cGetSerie  := QRY->D2_SERIE
		    cSayNomCli := alltrim(QRY->A1_NOME)		    
		    cSayEmissa := DTOC(STOD(QRY->D2_EMISSAO))
		    nRecno     := QRY->R_E_C_N_O_     // Recno do SF1
		    
			cPar := alltrim(GETNEWPAR("MV_YFTBVA7","S"))
			If cPar=="S" .AND. lPrime
			       lPrime := .F.
			       nPesoNota += QRY->F2_PLIQUI			
		    ElseIf Alltrim(QRY->C6_YUNV)<>'KG' .AND. Alltrim(QRY->B1_UM)<>'KG'			
		           If cPar=="N"
					nPesoNota += QRY->C9_YPESO
			       Endif					
			ElseIf Alltrim(QRY->D2_UM)=='KG' .AND.  QRY->B1_UM==QRY->D2_UM
		           If cPar=="N"
			  		nPesoNota += QRY->D2_QUANT
				  Endif
			Elseif Alltrim(QRY->B1_UM)<>'KG'
		           If cPar=="N"
					nPesoNota += QRY->C9_YPESO		    		    		    
				   Endif			    
			Else
	           If cPar=="N"
					nPesoNota += QRY->D2_QUANT
			  Endif
			Endif 

			
			QRY->(dbSkip())
			
		oBtnInclui:SetFocus()	// Bot„o no focus incluir 
		
		Enddo		    	
		QRY->(DbCloseArea())
     
        oGetSerie:refresh() 
        oGetNota:refresh()      
Endif

Return    

/////////////////////////////
// Atualizar PESO na tela  //
/////////////////////////////
Static Function fAtPeso() 
     ///////////////////////////////////////////////
     // Soma Pesos totais da tela de Dev. Vendas ///
     ///////////////////////////////////////////////     
	If nPesoNTT>0 .or. cGetOutPs>0     		  // Atualizando campo Total
	   If ValType(cGetOutPs)=="C" 	
		cPesoTot := nPesoNTT+val(cGetOutPs)   // Atualizando campo Total
	   Else
		cPesoTot := nPesoNTT+cGetOutPs        // Atualizando campo Total		   
	   Endif
		oSayPSTT:Refresh()   			
		oGetOutPs:Refresh()
	Endif
Return

////////////////////////////////////////////////
// Incluir as notas de VENDAS no grid da tela //
////////////////////////////////////////////////
Static function inclNFd(cFil,cGetNota,cSerie )

Local lExist := .F.
If !empty(cGetNota) .AND. !empty(cFil)

		If Empty(cNTSer)  //  Verifica se j· foi incluÌdo essa nota informada 
	       	   cNTSer +=  cFil+cGetNota+cSerie
		Else
			If !cFil+cGetNota+cSerie $ cNTSer 
			   cNTSer +=  cFil+cGetNota+cSerie 
 			Else
  			    lExist := .T.
		        cCabc 	:= "Nota fiscal j· informada"
			    cMSg 	:= "ATEN«√O: A Nota fiscal  "+cvaltochar(cGetNota)+ " j· foi informada."+CHR(13)+CHR(10)
			    cMSg 	+= "Confirme os dados digitados."+CHR(13)+CHR(10)	
			    U_fTelAviso(cCabc, cMSg, .F.)	
    			oGetNota:refresh()
	   			oGetNota:SetFocus()  // Foca no campo NOTA novamente
	        	GETDREFRESH() 	
            	oBtnInclui:Disable()
                Return					   			   
			Endif
	   Endif

       cQuery := "  SELECT   D2_FILIAL,D2_DOC,D2_ITEM,"
       cQuery += "           D2_SERIE,  	"
       cQuery += "           A1_NOME,   	"
       cQuery += "           A1_COD,    	"
       cQuery += "           D2_EMISSAO,	"
       cQuery += "     	     D2_UM, D2_QUANT,D2_PESO,C9_YPESO,C6_UM,C6_YUNV,C6_YUNTVEN,F2_PLIQUI,"
       cQuery += "           A.R_E_C_N_O_ as R_E_C_N_O_ "
       cQuery += "           ,D2_CLIENTE,B1_COD,B1_YCOMPRI,B1_YLARGUR,B1_UM,D2_COD,B1_YNMREDU"
       cQuery += "  FROM "+RetSQlName("SD2")+" A (NOLOCK)
       cQuery += "  LEFT JOIN "+RetSQlName("SA1")+" B   (nolock) ON B.D_E_L_E_T_='' AND D2_CLIENTE=A1_COD AND D2_LOJA=A1_LOJA"
       cQuery += "  JOIN "+RetSQlName("SB1")+"      C   (nolock) ON C.D_E_L_E_T_='' AND D2_COD=B1_COD AND B1_LOCPAD=D2_LOCAL AND B1_FILIAL=D2_FILIAL"
       cQuery += "  LEFT JOIN "+RetSQlName("SC9")+" D   (nolock) ON D.D_E_L_E_T_='' AND D2_FILIAL = C9_FILIAL AND D2_PEDIDO=C9_PEDIDO AND D2_COD= C9_PRODUTO  AND D2_ITEMPV=C9_ITEM AND D2_DOC=C9_NFISCAL AND D2_SERIE=C9_SERIENF AND D2_LOTECTL=C9_LOTECTL"
       cQuery += "  LEFT JOIN "+RetSQlName("SF2")+" E   (nolock) ON E.D_E_L_E_T_='' AND D2_DOC=F2_DOC AND D2_FILIAL=F2_FILIAL AND D2_SERIE=F2_SERIE"
       cQuery += "  LEFT JOIN "+RetSQlName("SC6")+" F   (nolock) ON F.D_E_L_E_T_='' AND C6_NUM=D2_PEDIDO AND D2_FILIAL=C6_FILIAL AND D2_ITEMPV=C9_ITEM AND C6_PRODUTO=D2_COD"
       cQuery += "  WHERE A.D_E_L_E_T_='' "
       cQuery += "  AND D2_FILIAL='"+cFil+"'"
       cQuery += "  AND D2_DOC='"+cGetNota+"' "  
       If !empty(cSerie)
	       cQuery += "  AND D2_SERIE='"+alltrim(cSerie)+"' "       
       Endif       
       cQuery += "  ORDER BY A.D2_ITEM ASC"       

		
		If 	Select("QRYSD2") > 0 	         
			QRYSD2->(DbCloseArea())             
		Endif                

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYSD2", .F., .T.)   	
	    lPrime := .T. 
		While !QRYSD2->(Eof())
				
		    //nPesoNTT += QRYSD2->D2_QUANT // Peso nota Total 

		    oSayPSNTT:Refresh()  
            
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            //Campo Quantidade: Se a Venda for por unidade Diferente de KG, calcular e trazer pela unidade Diferente, pois no SD2 estar· em KG. //
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		    nQuant := 0

			If Alltrim(QRYSD2->C6_YUNV)<>'KG' .AND. Alltrim(QRYSD2->B1_UM)<>'KG'			
			     If QRYSD2->C9_YPESO>0
					nQuant := QRYSD2->C9_YPESO
			     Elseif QRYSD2->D2_QUANT>0 
					nQuant := QRYSD2->D2_QUANT			     
			     Endif
			ElseIf Alltrim(QRYSD2->D2_UM)=='KG' .AND.  QRYSD2->B1_UM==QRYSD2->D2_UM
			     If QRYSD2->D2_QUANT>0
			  		nQuant := QRYSD2->D2_QUANT		    		    		    
			     Elseif QRYSD2->C9_YPESO>0 
					nQuant := QRYSD2->C9_YPESO			     
			     Endif
			Elseif Alltrim(QRYSD2->B1_UM)<>'KG'
			     If QRYSD2->C9_YPESO>0
					nQuant := QRYSD2->C9_YPESO		    		    		    
			     Elseif QRYSD2->D2_QUANT>0 
					nQuant := QRYSD2->D2_QUANT			     
			     Endif					
			Else    
			     If QRYSD2->D2_QUANT>0
					nQuant := QRYSD2->D2_QUANT		    		    		    					
			     Elseif QRYSD2->C9_YPESO>0 
					nQuant := QRYSD2->C9_YPESO			     
			     Endif					
			Endif 
            cPar := alltrim(GETNEWPAR("MV_YFTBVA7","S"))
			If cPar=="S" .and. lPrime
			    lPrime := .F.
			    nPesoNTT += QRYSD2->F2_PLIQUI			
		    Else
		        If cPar=="N" 
	   			     If QRYSD2->D2_QUANT>0
				   		nPesoNTT += QRYSD2->D2_QUANT  //Peso nota Total 
				     Elseif QRYSD2->C9_YPESO>0 
						nPesoNTT += QRYSD2->C9_YPESO			     
				     Endif								   		
				Endif
			Endif  
			If nPesoNTT==0 // Caso n„o tenha informaÁ„o do F2_PLIQUI somar D2_QUANT
 			     If QRYSD2->D2_QUANT>0
					nPesoNTT += QRYSD2->D2_QUANT  
			     Elseif QRYSD2->C9_YPESO>0 
					nPesoNTT += QRYSD2->C9_YPESO			     
			     Endif					
			Endif
             
			aAdd(aCoBrwNTS, { QRYSD2->D2_DOC,;  
							  QRYSD2->D2_SERIE,;
							  STOD(QRYSD2->D2_EMISSAO),;
							  QRYSD2->D2_ITEM,;
							  QRYSD2->D2_COD,; 						  
							  QRYSD2->B1_YNMREDU,;  						  
							  QRYSD2->D2_UM,; 						  
							  nQuant,; 				   												//QRYSD2->D2_QUANT,; 
							  If( QRYSD2->C9_YPESO>0, QRYSD2->C9_YPESO, QRYSD2->D2_QUANT ) ,; 		//D2_QUANT C9_YPESO			  						  
				    		     0,;	 															// Quantidade que ser· informada
			              	  .F.})
			              	  
	  	   //////////////////////////////
		   // Gravar as notas no campo //
	  	   //////////////////////////////	   
	       If Empty(cNotasS)  //  conte˙do existente mais (FILIAL+NR.NF+SERIE) separados por vÌrgula
	       	   	cNotasS +=  QRYSD2->D2_FILIAL+QRYSD2->D2_DOC+QRYSD2->D2_SERIE  
	       Else      
	          If !alltrim(QRYSD2->D2_FILIAL+QRYSD2->D2_DOC+QRYSD2->D2_SERIE) $ cNotasS
			    cNotasS +=  ','+QRYSD2->D2_FILIAL+QRYSD2->D2_DOC+QRYSD2->D2_SERIE 
		      Endif
	       Endif			              	  
			QRYSD2->(dbSkip())			
		Enddo 
		QRYSD2->(DbGotop())  
		  
		If nPesoNTT>0 .or. cGetOutPs>0     		  // Atualizando campo Total
		   If ValType(cGetOutPs)=="C" 	
			cPesoTot := nPesoNTT+val(cGetOutPs)   // Atualizando campo Total
		   Else
			cPesoTot := nPesoNTT+cGetOutPs       // Atualizando campo Total		   
		   Endif
			oSayPSTT:Refresh()   			
			oGetOutPs:Refresh() // cGetOutPs
		Endif

  		If !QRYSD2->(Eof())
			cGetNota   := CRIAVAR("D2_DOC") //SPACE(06)
			cGetSerie  := CRIAVAR("D2_SERIE") //SPACE(02)
	   		cSayNomCli := SPACE(60) 
			cSayEmissa := SPACE(12) 
		    nPesoNota  := 0	    	  
		    cGetNota   := CRIAVAR("D2_DOC") 
		    flimpCam()    // Limpa os campos 
			oGetNota:refresh()
	   		oGetSerie:refresh() 	   		
	   		oGetNota:SetFocus()  // Foca no campo NOTA novamente
	        GETDREFRESH() 	
            oBtnInclui:Disable()
         Endif 
         
         oGetNota:refresh()
		 oGetSerie:refresh() 
  		 oSayPeso:refresh() 
	 	 oBrwNotas   := MsNewGetDados():New(085,005,176,492,nOpcPSDEV,LinOkNTS,TudOkNTS,'',,0,99,'AllwaysTrue()','','AllwaysTrue()',oDlg122,aHoBrwNTS,aCoBrwNTS )
	 	 //oBrwNotas:ForceRefresh()
         oBrwNotas:oBrowse:Refresh() 
         GETDREFRESH()         

Endif
  
   
Return  

/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
Function  ≥ MHoBrwNTS() - Monta aHeader da MsNewGetDados para TELA DE DEVOLU«√O DE VENDAS
ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
Static Function MHoBrwNTS()

	aCamCON := {}
	
	aAdd(aCamCON,"ZS_DOC")
	aAdd(aCamCON,"ZS_SERIE") 
	aAdd(aCamCON,"ZS_EMISSAO")
	aAdd(aCamCON,"ZS_ITEM")
	aAdd(aCamCON,"ZS_COD")
	aAdd(aCamCON,"AA7_DESPRO") //aAdd(aCamCON,"B1_YNMREDU")
	aAdd(aCamCON,"D2_UM")
	aAdd(aCamCON,"C9_YPESO")   //aAdd(aCamCON,"D2_QUANT")
	aAdd(aCamCON,"C9_YPESO")
	aAdd(aCamCON,"ZS_QTDDIF")
	
	DbSelectArea("SX3")
	DbSetOrder(2)
	
	For i:=1 To Len(aCamCON)
	   If DbSeek(aCamCON[i])
	      noBrwCon++ 
          cValid   := ""
	      If alltrim(aCamCON[i])=="ZS_QTDDIF" .and. i==10 
	         cTitulo := "QTD. DEV"  
	         cValid  := "U_ValQTDDEV()"    // Valida a Quantidade Dev informada maior que o item atual.
	      Elseif    alltrim(aCamCON[i])=="C9_YPESO" .and. !i==9
	         cTitulo := "QTD"
	      Elseif    alltrim(aCamCON[i])=="C9_YPESO" .and. i==9 
	         cTitulo := "Peso"	         
          Else
            cTitulo := trim(X3Titulo())
          Endif                     
	      
	      Aadd(aHoBrwNTS,{   cTitulo ,;
	           SX3->X3_CAMPO,;
	           SX3->X3_PICTURE,;
	           SX3->X3_TAMANHO,;
	           SX3->X3_DECIMAL,;
	           cValid ,;	//ValidaÁ„o, X3_VALID  
	           "",;
	           SX3->X3_TIPO,;
	           "",;
	           "" } )
	   EndIf
	Next

Return

/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
Function  ≥ MCoBrwNTS() - Monta aCols da MsNewGetDados para TELA DE DEVOLU«√O
ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
Static Function MCoBrwNTS(cPESAGEM)

Local aArea   := GetArea()
Local cNotasG := "" 

Return

/////////////////////////////////////////////////////////////////////////////////////
// Entrada   : Tela que abre caso exista diferenÁa entre PESO NFS X PESO BALAN«A   //
// COMPRA  									     	F·bio Loures  03/04/2017.      //
/////////////////////////////////////////////////////////////////////////////////////
Static Function fPesoDif()

///////////////////////////////
// Tela referente as COMPRAS //
/////////////////////////////// 
cMsgDifQ := ""

If Alltrim(aMOTDados[oComboBo3:nAT]) $ ALLTRIM(GETNEWPAR("MV_YFTBVA5","#C#") )  .AND. nPDIF<0; // "C#D#E"   2-3-4
	 .and.   Alltrim(aTPDados[oComboBo1:nAT]) $ ALLTRIM(GETNEWPAR("MV_YFTBVA6","#S#") ) // Tipo Pesagem "S#I#E" -> Saida , intermediaria, Entrada

    
	nOpcPSDIF    := GD_UPDATE // GD_DELETE+GD_INSERT
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± DeclaraÁ„o de cVariable dos componentes                                 ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	Private cSayDif    		:= Space(1)
	Private cSayDifSel 		:= 0
	Private cSayP      		:= Space(1)
	Private cSayPsDif  		:= nPDIF // DiferenÁa de peso   

	Private noBrwCon   		:= 0      
	Private aHoBrwNTD  		:= {} 
	Private aCoBrwNTD  		:= {}
	Private cGetOutroPeso 	:= 0   
	Private cGetObs    		:= Space(250)
	cMsgDifQ := ""
	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± DeclaraÁ„o de Variaveis Private dos Objetos                             ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	SetPrvt("oFont1","oFont2","oDlgNT","oSay2","oSayP","oSayPsDif","oSayDif","oSayDifSel","oBrwNotas","oBtnConfirmar","oSay5","oSayoutPes","oGetObs","oGetOutroP")
	
	/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
	±± Definicao do Dialog e todos os seus componentes.                        ±±
	Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
	oFont1     := TFont():New( "Verdana",0,-16,,.T.,0,,700,.F.,.F.,,,,,, )
	oFont2     := TFont():New( "Verdana",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )

    DEFINE MSDIALOG oDlgNT TITLE "DiferenÁa no Recebimento de Material" STYLE DS_MODALFRAME   FROM 142,170  TO 591,1318 COLORS 0, 16777215 PIXEL
	//oDlgNT      := MSDialog():New(142,170,591,1318,"DiferenÁa no Recebimento de Material",,,.F.,,,,,,.T.,,,.T. )
	oDlgNT:lEscClose := .F. //Nao permite sair ao se pressionar a tecla ESC.
	
	oSay2      := TSay():New( 003,003,{||"Informe as DiferenÁas nos itens das Notas Fiscais:"},oDlgNT,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,233,008)
	
	oSayP      := TSay():New( 180,004,{||"DiferenÁa encontrada:"},oDlgNT,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,124,015)
	oSayPsDif  := TSay():New( 180,136,{|| cSayPsDif   },oDlgNT,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,108,016)

	oSayDif    := TSay():New( 197,005,{||"DiferenÁa informada :   "},oDlgNT,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,131,015)
	oSayDifSel := TSay():New( 197,133,{|| cSayDifSel  },oDlgNT,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,107,016)
	
	oSay5      := TSay():New( 201,224,{||"Obs.:"},oDlgNT,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,030,015)
    oSayoutPes := TSay():New( 181,222,{||"Outros Pesos:"},oDlgNT,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,085,015)
    
	oGetOutroP := TGet():New( 182,312,{|u| If(PCount()>0,cGetOutroPeso:=u,cGetOutroPeso)},oDlgNT,040,008,'@E 999,999,999.99',   {|| If(!empty(cGetOutroPeso)  , U_fsomaDif(),"")  , oGetOutroP:refresh()   }   ,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetOutroPeso",,)
	oGetOutroP:lHasButton := .F.  // Habilitar bot„o no estilo calculadora
	
	oGetObs    := TGet():New( 201,259,{|u| If(PCount()>0,cGetObs:=u,cGetObs)},oDlgNT,227,008,'',,CLR_BLACK,CLR_WHITE,,,,.T.,"",,,.F.,.F.,,.F.,.F.,"","cGetObs",,)                  
	
	oBtnConfir := TButton():New( 184,520,"Confirmar",oDlgNT,{|| U_fsomaDif(), oSayDifSel:Refresh(), fInsSZS(cSayPsDif,cGetOutroPeso,cGetObs)},037,012,,,,.T.,,"",,,,.F. )
	oBtnConfir:Disable()

	//////////////////////////////////////////////////////////////////
	//-- GRID ITENS DAS NOTAS de ENTRADA para informar a diferenÁa  //
	//////////////////////////////////////////////////////////////////
	MHoBrwNTD()
	MCoBrwNTD(cPESAGEM)
	LinOkNTD 	:= "ExecBlock('fsomaDif',.F.,.F.)"
	TudOkNTD 	:= 'AllwaysTrue()'       
	oBrwNotas   := MsNewGetDados():New(016,005,176,560,nOpcPSDIF,LinOkNTD,TudOkNTD,'',,0,99,'AllwaysTrue()','','AllwaysTrue()',oDlgNT,aHoBrwNTD,aCoBrwNTD )
	oBrwNotas:oBrowse:bChange    :=  { || U_fsomaDif()  }  // Soma os pesos Selecionados  
	    
    oBrwNotas:Enable()
	
	oDlgNT:Activate(,,,.T.)
     
EndIf

Return     


/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒ
Function  ≥ fInsSZS() - Inerindo os Registros digitados 
ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ*/
Static function fInsSZS(cSayPsDif,cGetOutroPeso,cGetObs)


Local aArea := GetArea()

Local nDifInf	:= nQuant := nVunit := nDifDig := 0
Local cNPesag := cTipo := cEmissao := cDoc := cSerie :=  cFil :=  cFornec := cLoja :=  cCod  := cItem := ""
Local cMsg := cMsgNotas := cMsgItens := cMsgTick := cMsgTab1 := cMsgComp:= ""
Local nPrecTot := nPrcTotal := nCountNt := nQtdDif := 0
lRet := fCompDif()  // Compara diferenÁa entre diferenÁa X Qtd Informada
lInformDif      := .F. // informou a diferenÁa ?
cMsgDifQ := ""     
	
If cGetOutroPeso>0  
    U_fsomaDif()
   If Empty(cGetObs)
        // ObrigatÛrio informa a observaÁ„o do que foi informado nos outros pesos
   		lRet 	:= .F.
        cCabc 	:= "Campo ObrigatÛrio"
	    cMSg 	:= "ATEN«√O: Quando È informado o campo OUTROS PESOS deve preencher tambÈm o campo OBSERVA«√O."+CHR(13)+CHR(10)
	    //U_fsomaDif()
	    oGetObs:SetFocus()  // Foca o campo observaÁ„o
	    U_fTelAviso(cCabc, cMSg, .F.)	
        Return(.F.)        
  Else   // Preenche o campo PESO na observaÁ„o
	 	cGetOBSERV :=  "PESO: #"+cvaltochar(cGetOutroPeso)+"# "+cGetObs//+"  "+alltrim(cGetOBSERV)
		oGetOBSERV:Refresh()     
		oGetOBSERV:Disable()
  Endif
Endif

                    
If lRet  

    fDelSZS(cPESAGEM) // 1) Verifica se existe tabelas SZS para essa mesma pesagem, se existir deve ser excluido antes de tudo
    
	dbSelectArea("SZS")
	Begin Transaction
	
		For ix:=1 To Len(oBrwNotas:aCols)				
				
				cNPesag		:= NwFieldGet(oBrwNotas, "ZS_NRPESA"	, ix)
				cTipo		:= NwFieldGet(oBrwNotas, "ZS_TIPO"	, ix)
				cEmissao	:= NwFieldGet(oBrwNotas, "ZS_EMISSAO"	, ix)
				cDoc    	:= NwFieldGet(oBrwNotas, "ZS_DOC"		, ix)
				cSerie		:= NwFieldGet(oBrwNotas, "ZS_SERIE"		, ix)
				cFil 		:= NwFieldGet(oBrwNotas, "ZS_FILNTA"	, ix)
				cFornec		:= NwFieldGet(oBrwNotas, "ZS_FORNECE"	, ix)
				cLoja		:= NwFieldGet(oBrwNotas, "ZS_LOJA"		, ix)
				cCod		:= NwFieldGet(oBrwNotas, "ZS_COD"		, ix)
				cItem		:= NwFieldGet(oBrwNotas, "ZS_ITEM"		, ix)
				nQuant		:= NwFieldGet(oBrwNotas, "ZS_QUANT" 	, ix)
				nVunit		:= NwFieldGet(oBrwNotas, "ZS_VUNIT" 	, ix)
				nDifDig		:= NwFieldGet(oBrwNotas, "ZS_QTDDIF"	, ix)
				
			If !Empty(cFornec)
				Reclock("SZS",.T.)
				SZS->ZS_NRPESA 	:= cNPesag //xFilial("SZG")
				SZS->ZS_TIPO    := cTipo
				SZS->ZS_EMISSAO := cEmissao //Dtoc(cEmissao)
				SZS->ZS_DOC  	:= cDoc
				SZS->ZS_SERIE 	:= cSerie
				SZS->ZS_FILNTA 	:= cFil
				SZS->ZS_FORNECE	:= cFornec
				SZS->ZS_LOJA	:= cLoja
				SZS->ZS_COD		:= cCod
				SZS->ZS_ITEM	:= cItem									
				SZS->ZS_QUANT	:= nQuant
				SZS->ZS_VUNIT	:= nVunit
				SZS->ZS_QTDDIF	:= nDifDig									
				SZS->(MsUnLock())     


				nPrecUnit :=  NoRound( NoRound(nDifDig,2)*NoRound(nVunit,2) ,2)
				If nPrecUnit>0
				   nPrcTotal += nPrecUnit
				Endif
				If nDifDig>0
				   nQtdDif     += nDifDig    
  	               lInformDif  := .T.     // Se existir um item com diferenÁa , MAIOR QUE ZERO
				Endif
				
	
			Endif
			If !empty(cMsgNotas)
			    If !alltrim(cDoc) $ cMsgNotas
			        nCountNt += 1
					cMsgNotas += " / "+alltrim(cDoc)  
				Endif
			Else
		        nCountNt += 1
				cMsgNotas += alltrim(cDoc)  			
			Endif
			//////////////////////////////////////////////////////////////////////////
			// Salvar as informaÁıes do Corpo do Email que ser„o enviadas por email //
			//////////////////////////////////////////////////////////////////////////
		     cNomeProd := fRetNmPro(cCod,cFil)   
		     If nDifDig<>0 // Informar apenas os itens com divergencia informada
				  cMsgTab1 += "  <tr>"
	  			  cMsgTab1 += "    <td style='width: 542px; '>"+alltrim(cNomeProd)+"</td>"
	  			  cMsgTab1 += "    <td style='width: 148px; text-align: right; '>-"+Transform(NoRound(nDifDig,2) ,"@E 999,999,999.99")+"</td>"	  			  
	  			  cMsgTab1 += "    <td style='width: 173px; text-align: right; '>"+Transform(NoRound(nVunit,2)   ,"@E 999,999,999.99")+"</td>"
	  			  cMsgTab1 += "    <td style='width: 173px; text-align: right; font-weight: bold; '>"+Transform(NoRound(nPrecUnit)  ,"@E 999,999,999.99")+"</td>"
				  cMsgTab1 += "	 </tr>"
			 Endif
		Next
	End Transaction	
	oDlgNT:End()
Endif              

//////////////////////////////////////////////////////////
// Enviando o Email com as diferenÁas de peso informada //
//////////////////////////////////////////////////////////
cMsgAss  := ""
cMsgDifQ := "" 
If lRet .and. !Empty(cMsgTab1)
	cMsgAss := "DIFEREN«A DE PESO ("+cvaltochar(cSayPsDif)+")"+CRLF
	
    cMsgTab := " <table border='1' cellpadding='1' cellspacing='1'>"
	cMsgTab += "	 <tr>"
	cMsgTab += "	   <td style='width: 542px; font-weight: bold; '>Produto</td>"
	cMsgTab += "	   <td style='width: 148px; font-weight: bold; '>Dif. Peso</td>"
	cMsgTab += "	   <td style='width: 173px; font-weight: bold; '>Prc.Unit</td>"
	cMsgTab += "	   <td style='width: 173px; font-weight: bold; '>Vl.Total</td>"
	cMsgTab += "	 </tr>"
	cMsgTab += cMsgTab1 // Dados dos produtos

    /////////////
	/// Total  //
    /////////////
	cMsgTab2 := "  <tr>"
  	cMsgTab2 += "    <td style='width: 542px;'></td>"
  	cMsgTab2 += "    <td style='width: 148px;'></td>" 
  	cMsgTab2 += "    <td style='width: 173px;'></td>"
  	cMsgTab2 += "    <td style='width: 173px; font-weight: bold; text-align: right; '><big style='font-weight: bold;'>"+Transform(NoRound(nPrcTotal,2) ,"@E 999,999,999.99")+"</big></td>"
	cMsgTab2 += "  </tr>"
	cMsgTab2 += " </table>"
	
	cMsgTab += cMsgTab2 
	// Monta a mensagem
	If val(SUBSTR(TIME(), 1, 2))>=12 .and. val(SUBSTR(TIME(), 1, 2))<18
		cMsgComp := "Boa tarde!"+CRLF+CRLF
	Elseif val(SUBSTR(TIME(), 1, 2))<=12
		cMsgComp := "Bom dia!"+CRLF+CRLF
	Elseif val(SUBSTR(TIME(), 1, 2))>=18
		cMsgComp := "Boa Noite!"+CRLF+CRLF	
	Endif
	cMsg := cMsgComp
	If nCountNt>1
		cMsg += "Recebemos as notas "+cMsgNotas+" com as diferenÁas descritas abaixo:"+CRLF+CRLF			
	Else
		cMsg += "Recebemos a nota "+cMsgNotas+" com as diferenÁas descritas abaixo:"+CRLF+CRLF			
	Endif
	cMsg     += cMsgTab+CRLF+CRLF //cMsgItens
	cMsgDifQ := cMsg+CRLF+CRLF
	//u_fEmail( alltrim(GETNEWPAR("MY_YEMFTDI",'fabio.loures@diaco.com.br')) ,cMsgAss,cMsg,.F.) // N„o foi enviado por aqui por n„o existir o SZ8 nesse intante. Devido ter que enviar Ticket no email
	cMsgTab1 := ""  
Endif              
//////////////////////////////////////////////////////////////////////
// Caso outros pesos maior que ZERO Manda email apenas informativo  //
//////////////////////////////////////////////////////////////////////
If cGetOutroPeso>0  .and. lRet
		cMSGOP := " Entrada da(s) nota(s) "+cMsgNotas+CRLF+CRLF
		cMSGOP += " OUTROS PESOS : "+cvaltochar(cGetOutroPeso)+CRLF+CRLF
		If !lInformDif   // N„o informou diferenÁa
			cMSGOP += " N„o foi informado divergÍncias nos itens das notas."+CRLF
		Endif
		cMSGOP += " ObservaÁ„o: "+ALLTRIM(cGetOBSERV)+""+CRLF            

		u_fEmail( alltrim(GETNEWPAR("MY_YEMFTDI",'expedicao@diaco.com.br,diretoria@diaco.com.br,financeiro@diaco.com.br,fabio.loures@diaco.com.br')) ,"DIFEREN«A DE PESO ("+cvaltochar(cSayPsDif)+")"+" (OUTROS PESOS INFORMADO)",cMSGOP,.F.)
		cGetOutroPeso := 0
Endif

	
Return

////////////////////////////////////////////////////////////////////
// Simula impress„o do Tiket da balanÁa, para ser usado no email  //
////////////////////////////////////////////////////////////////////
Static Function fTiket(nModelo, cNrPesa)

Local cMsg := ""
Local aSZ8 := SZ8->(GetArea())

//POSICIONAR NO REGISTRO DA PESAGEM

SZ8->(DbSetOrder(1))
SZ8->(DbSeek(XFilial("SZ8")+cNrPesa))
Private _aAPesagem := SZ8->(GetArea())
Private _cNrPesENT := SZ8->Z8_NRPESEN

Do Case
	Case nModelo = 1
	   	cMsg 	:= '------------------------------------------------------------------------------------------------------------------------------------------'+CRLF	   	

		cTipoCOMPRA	   	:= ""
	   	If Alltrim(aMOTDados[oComboBo3:nAT]) $ "C"
		   	cTipoCOMPRA := space(40)+"<b> COMPRA</b> "
		Elseif Alltrim(aMOTDados[oComboBo3:nAT]) $ "D"
		   	cTipoCOMPRA := space(40)+"<b> DEVOLU«√O DE VENDA</b> "
		Elseif Alltrim(aMOTDados[oComboBo3:nAT]) $ "E"
		   	cTipoCOMPRA := space(40)+"<b> DEVOLU«√O DE COMPRA </b> "
	   	Endif
        cMsg   += cTipoCOMPRA+CRLF 

	   	cTpPesa := If(SZ8->Z8_TPPESA="E","ENTRADA: ","SAÕDA: ")
	    cMsg 	+=  cTpPesa+"                                        <b> PLACA VEICULO: </b> "+SZ8->Z8_PLACA+"                    PESO "+cTpPesa+CRLF
	   	
	   	cMsg 	+=  DTOC(SZ8->Z8_DATA)+CRLF
	   	cMsg 	+=  "                                        <b> HORA: </b> "+SZ8->Z8_HORA+""+"                                          <b>  MOT.:</b>  "+AllTrim(SZ8->Z8_MOTORIS)+"                      <b> DOC.:</b>  "+AllTrim(SZ8->Z8_DOCMOTO)+CRLF+CRLF
		
		cMsg 	+= "                                        <b> NR PESAGEM: </b> "+SZ8->Z8_NRPESA+"         "
		cMsg 	+= "                                        <b> USUARIO: </b> "+SubStr(SZ8->Z8_USUARIO,1,15)+CRLF
		
		If SZ8->Z8_TPVEIC == "P"
			cMsg 	+= "                                        <b> [x] PR”PRIO   [ ] TERCEIRO</b> "+CRLF
		Else
			cMsg 	+= "                                        <b> [ ] PR”PRIO   [x] TERCEIRO</b> "+CRLF
		Endif
		If  !Empty(AllTrim(SZ8->Z8_EMPRESA)) //add 
			cMsg 	+= "                        <b> Empresa:</b> "+AllTrim(SZ8->Z8_EMPRESA)+CRLF
		Endif
		If  !Empty(AllTrim(SZ8->Z8_TRANSP)) //add 
			cMsg 	+= "                        <b> Transp:</b> "+AllTrim(SZ8->Z8_TRANSP)+CRLF
		Endif

	   	cMsg 	+= AllTrim(Transform(SZ8->Z8_PESO,"@E 999,999"))+CRLF

		If SZ8->Z8_TPMOVI <> "V" .OR. !Empty(SZ8->Z8_NUMNFS) .OR. !Empty(SZ8->Z8_PESONFS)
			cMsg 	+= "                                        <b> PESO NF's:</b> "+AllTrim(Transform(SZ8->Z8_PESONFS,"@E 999,999"))+CRLF
			cMsg 	+= "                                        <b> NF's:</b>  "+SUBSTR(AllTrim(SZ8->Z8_NUMNFS),1,140)+CRLF
			If !Empty(SUBSTR(AllTrim(SZ8->Z8_NUMNFS),141,200))
				cMsg 	+= SUBSTR(AllTrim(SZ8->Z8_NUMNFS),141,200)+CRLF
			EndIf
		EndIf
   		cMsg 	+=  "<b> OBS.:</b>  " + AllTrim(SZ8->Z8_OBS)+CRLF
	   	cMsg 	+= '------------------------------------------------------------------------------------------------------------------------------------------'+CRLF	   	
	Case nModelo = 2             
	    
		//POSICIONAR NO REGISTRO DA ENTRADA - REFERENTE A SAIDA OU INTERMEDIARIA SENDO FEITA
		SZ8->(DbSetOrder(1))
		SZ8->(DbSeek(XFilial("SZ8")+_cNrPesENT))
		
		__nPesoEnt := SZ8->Z8_PESO
		__cTpEnt   := SZ8->Z8_TPPESA

	   	cMsg 	:= '------------------------------------------------------------------------------------------------------------------------------------------'+CRLF	   	

		cTipoCOMPRA	   	:= ""
	   	If Alltrim(aMOTDados[oComboBo3:nAT]) $ "C"
		   	cTipoCOMPRA := space(40)+"<b> COMPRA</b> "
		Elseif Alltrim(aMOTDados[oComboBo3:nAT]) $ "D"
		   	cTipoCOMPRA := space(40)+"<b> DEVOLU«√O DE VENDA</b> "
		Elseif Alltrim(aMOTDados[oComboBo3:nAT]) $ "E"
		   	cTipoCOMPRA := space(40)+"<b> DEVOLU«√O DE COMPRA</b> "		   	
	   	Endif
        cMsg   += cTipoCOMPRA+CRLF 
        
   		cTpPesa := If(__cTpEnt="E","<b> ENTRADA:</b> ","<b> SAÕDA:</b> ")
   		cMsg 	+= cTpPesa +" "+DTOC(SZ8->Z8_DATA)

   		cMsg 	+= "                                        <b> HORA:</b>  "+SZ8->Z8_HORA+""
   		cMsg 	+= "                                        <b> N∫ PESAGEM: </b> "+SZ8->Z8_NRPESA+""
	   	cMsg 	+= "                                        <b> USU¡RIO: </b> "+SubStr(SZ8->Z8_USUARIO,1,15)+CRLF
		cMsg 	+= "                                                                   <b>  MOT.: </b> "+AllTrim(SZ8->Z8_MOTORIS)+"                     <b>  DOC.: </b> "+AllTrim(SZ8->Z8_DOCMOTO)+CRLF+CRLF
	   	
	   	//RECUPERA AREA TICKET ORIGINAL
	   	SZ8->(RestArea(_aAPesagem))
  	
	   	If	SZ8->Z8_TPPESA=="I"
			cTpPesaF := "<b> SAÕDA(I):</b> "
		Else
			cTpPesaF := If(SZ8->Z8_TPPESA="E","<b> ENTRADA:</b> ","<b> SAÕDA:</b> ")
		EndIf
	   	cMsg 	+= CRLF+cTpPesaF+" "+DTOC(SZ8->Z8_DATA)

	   	cMsg 	+= "                                        <b> HORA: </b> "+SZ8->Z8_HORA+""
	   	cMsg 	+= "                                        <b> N∫ PESAGEM:</b>  "+SZ8->Z8_NRPESA+""+CRLF
		cMsg 	+= "                                                                 <b>   MOT.:</b>  "+AllTrim(SZ8->Z8_MOTORIS)+"                    <b>   DOC.:</b>  "+AllTrim(SZ8->Z8_DOCMOTO)+CRLF
		cMsg 	+= "<b> PLACA VEÕCULO:</b>  "+SZ8->Z8_PLACA
   	
		IF SZ8->Z8_TPVEIC == "P"
			cMsg 	+= "                                                <b>   [x] PR”PRIO   [ ] TERCEIRO</b> "+CRLF
		ELSE
			cMsg 	+= "                                                <b>   [ ] PR”PRIO   [x] TERCEIRO</b> "+CRLF
		ENDIF 
		If  !Empty(AllTrim(SZ8->Z8_EMPRESA)) //add 
			cMsg 	+= "                        <b> Empresa:</b> "+AllTrim(SZ8->Z8_EMPRESA)+CRLF
		Endif
		If  !Empty(AllTrim(SZ8->Z8_TRANSP)) //add 
			cMsg 	+= "                        <b> Transp:</b> "+AllTrim(SZ8->Z8_TRANSP)+CRLF
		Endif		

	   	cMsg 	+= "<b> PESO</b>  "+cTpPesa+"  "
		cMsg 	+= AllTrim(Transform(__nPesoEnt,"@E 999,999"))+CRLF
	   	
	   	cMsg 	+= "<b> PESO</b>  "+cTpPesaF+"  "
	   	cMsg 	+= AllTrim(Transform(SZ8->Z8_PESO,"@E 999,999"))+CRLF

   		cAbastec := IIF(SZ8->Z8_QTLITRO > 0," (- "+AllTrim(Str(SZ8->Z8_QTLITRO))+" Litros = "+AllTrim(Str(SZ8->Z8_QTLITRO*0.87))+" KG)","")+CRLF
		cMsg 	+= cAbastec
	   	cMsg 	+= "<b> PESO LÕQUIDO:</b>  "
	   	
	   	__PESOLIQ := ABS(SZ8->Z8_PESO - __nPesoEnt - (SZ8->Z8_QTLITRO*0.87))  //abs converte em valor absoluto.
		cMsg 	+= AllTrim(Transform(__PESOLIQ,"@E 999,999"))
	   	
	   	If SZ8->Z8_TPPESA <> "I"
		    cMsg 	+= "                                        <b> PESO NF'S: </b> "+AllTrim(Transform(SZ8->Z8_PESONFS,"@E 999,999"))
		   	cMsg 	+= "                                        <b> PESO DIF.(PL-PNF):</b>  "+AllTrim(Transform(__PESOLIQ - SZ8->Z8_PESONFS,"@E 999,999"))+CRLF
 	
		   	cMsg 	+= "<b> NF'S: </b> "+SUBSTR(ALLTRIM(SZ8->Z8_NUMNFS),1,60)+""+CRLF
		   	IF(LEN(ALLTRIM(SZ8->Z8_NUMNFS))>60)
		   		cMsg 	+= SUBSTR(ALLTRIM(SZ8->Z8_NUMNFS),61,60)+""+CRLF
		   	ENDIF
		   	IF(LEN(ALLTRIM(SZ8->Z8_NUMNFS))>120)
		   		cMsg 	+= SUBSTR(ALLTRIM(SZ8->Z8_NUMNFS),121,60)+""+CRLF
		   	ENDIF
		   	IF(LEN(ALLTRIM(SZ8->Z8_NUMNFS))>180)
		   	 	cMsg 	+= SUBSTR(ALLTRIM(SZ8->Z8_NUMNFS),181,60)+""+CRLF
		   	ENDIF
		EndIf

	   	cMsg 	+= "<b> OBS.: </b> "+AllTrim(SZ8->Z8_OBS)+CRLF
	   	cMsg 	+= '------------------------------------------------------------------------------------------------------------------------------------------'+CRLF	   	
	   	
EndCase   

SZ8->(RestArea(aSZ8))

Return(cMsg)     

////////////////////////////////////
// Retorna o nome do produto      //
////////////////////////////////////
Static function	 fRetNmPro(cCod,cFil)

Local cNome := ""

		cQuerySB1 := " SELECT top 1 B1_DESC,B1_YNMREDU from  "+RetSQlName("SB1")+" (nolock)  " 
		cQuerySB1 += " WHERE D_E_L_E_T_='' AND B1_COD='"+alltrim(cCod)+"' AND B1_FILIAL="+"'"+alltrim(cFil)+"'  " 	
		
		If Select("SB1TMP") > 0
			SB1TMP->(dbCloseArea())
	    Endif
		TCQUERY cQuerySB1 NEW ALIAS "SB1TMP"     				  				   			
				   				   
		dbSelectArea("SB1TMP")  
		SB1TMP->(dbGoTop())
		  While SB1TMP->(!EOF())
	 	    cNome := SB1TMP->B1_DESC
		  SB1TMP->(dbSkip())        			  
		Enddo           
		
	    SB1TMP->(dbCloseArea()) 

Return(cNome)


/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
fsomaDif() - Retorna o total informado  
ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
User Function fsomaDif()

Local lRet := .T.

If ValType(oBrwNotas) == "O" 
	cSayDifSel 	:= 0
	lRet 		:= .T.
	For ix:=1 To Len(oBrwNotas:aCols)
		cSayDifSel		+= NwFieldGet(oBrwNotas, "ZS_QTDDIF"	, ix)
	Next  
	cSayDifSel := cvaltochar(cSayDifSel)
Endif    
If cGetOutroPeso>0
	cSayDifSel := cvaltochar(val(cSayDifSel)+cGetOutroPeso) // Campo NOVO : OUTROS PESOS como diferenÁa.
Endif
oSayDifSel:Refresh()
	
Return(lRet)   

/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
fCompDif() - Compara diferenÁa entre diferenÁa X Qtd Informada
ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
Static Function fCompDif()

Local lRet      := .T.

If ValType(oBrwNotas) == "O"
	cSayDifSel 	:= 0
	lRet 		:= .T.
	For ix:=1 To Len(oBrwNotas:aCols)
		cSayDifSel		+= NwFieldGet(oBrwNotas, "ZS_QTDDIF"	, ix)
	Next

	//If  -1*(cSayPsDif)<>cSayDifSel .and. !cSayDifSel>(-1*(cSayPsDif)) .and. !cSayDifSel>=(-1*(cSayPsDif)-nParVaria) // Verifica as VariaÁıes mÌnimas para criticar
	If  -1*(cSayPsDif)<>cSayDifSel+cGetOutroPeso .and. !(cSayDifSel+cGetOutroPeso)>(-1*(cSayPsDif)) .and. !cSayDifSel+cGetOutroPeso>=(-1*(cSayPsDif)-nParVaria) // Verifica as VariaÁıes mÌnimas para criticar	
		lRet 	:= .F.
        cCabc 	:= "DivergÍncia Quantidade informada"
	    cMSg 	:= "ATEN«√O: DiferenÁa total encontrada "+cvaltochar(-cSayPsDif)+ " est· divergente da DiferenÁa informada : "+cvaltochar(cSayDifSel+cGetOutroPeso)+" nos itens da(s) nota(s)."+CHR(13)+CHR(10)
	   	cMSg 	+= "Peso mÌnimo para informar na diferenÁa: "+cvaltochar(-cSayPsDif-nParVaria)+CHR(13)+CHR(10)
   		cMSg 	+= "Parametro de variaÁ„o: "+cvaltochar(nParVaria)+"       (MV_YDIFNTA)"+CHR(13)+CHR(10)
	    cMSg 	+= "Confirme os dados digitados."+CHR(13)+CHR(10)	
	    U_fTelAviso(cCabc, cMSg, .F.)	
	Endif
	cSayDifSel := cvaltochar(cSayDifSel)
Endif  
oSayDifSel:Refresh()
	
Return(lRet)   

/*‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±≥Descricao  ≥ Retorna Valor da Celula da NewGetDados                       ≥±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ*/
Static Function NwFieldGet(oObjeto,cCampo,nLinha)                               
Local nCol := aScan(oObjeto:aHeader,{|x| AllTrim(x[2]) == Upper(cCampo)})       
Local xRet                                                                      
// Se nLinha nao for preenchida Retorna a Posicao de nAt do Objeto              
Default nLinha := oObjeto:nAt                                                   
	xRet := oObjeto:aCols[nLinha,nCol]                                             
Return(xRet)    

/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
Function  ≥ MHoBrwCon() - Monta aHeader da MsNewGetDados para o Alias: TRBCON
ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
Static Function MHoBrwNTD()
aCamCON := {}
aAdd(aCamCON,"ZS_NRPESA")
aAdd(aCamCON,"ZS_TIPO")
aAdd(aCamCON,"ZS_EMISSAO")
aAdd(aCamCON,"ZS_DOC")
aAdd(aCamCON,"ZS_SERIE")
aAdd(aCamCON,"ZS_FILNTA")
aAdd(aCamCON,"ZS_FORNECE")
aAdd(aCamCON,"ZS_LOJA")  
aAdd(aCamCON,"ZS_COD")
aAdd(aCamCON,"ZS_ITEM")
aAdd(aCamCON,"ZS_QUANT")
aAdd(aCamCON,"ZS_VUNIT")
aAdd(aCamCON,"ZS_QTDDIF")

DbSelectArea("SX3")
DbSetOrder(2)

For i:=1 To Len(aCamCON)
   If DbSeek(aCamCON[i])
      noBrwCon++
	  cValid  	  :=  ""    
      If alltrim(aCamCON[i])=="ZS_QTDDIF" .and. i==13
	      cValid  := "U_fQTDESum()" // Somar a quantidade digitada
      Endif 
      
      Aadd(aHoBrwNTD,{trim(X3Titulo()),;
           SX3->X3_CAMPO,;
           SX3->X3_PICTURE,;
           SX3->X3_TAMANHO,;
           SX3->X3_DECIMAL,;
           cValid,;	//ValidaÁ„o, X3_Valid
           "",;
           SX3->X3_TIPO,;
           "",;
           "" } )
   EndIf
Next

Return


/*ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¬ƒƒƒƒƒƒ¬ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
Function  ≥ MCoBrwNTD() - Monta aCols da MsNewGetDados para o Alias: TRBCON
ƒƒƒƒƒƒƒƒƒƒ≈ƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
Static Function MCoBrwNTD(cPESAGEM)

Local aArea   := GetArea()
Local cNotasG := "" 

 If !Empty(cGetNFS)
 
 		cNTget := cGetNFS 									
		aNTget := strtokarr((ALLTRIM(cNTget)),"/")   // Busca as notas e separa
		For nX := 1 To Len(aNTget)   
		  If !Empty(cNotasG)
			  cNotasG += ",'"+alltrim(aNTget[nX])+"'"
		  Else
		      cNotasG += "'"+alltrim(aNTget[nX])+"'"
		  Endif
		Next nX 
 
       cQuery := "  SELECT F1_DOC,D1_ITEM AS ZS_ITEM,F1_TIPO AS ZS_TIPO,F1_DOC AS ZS_DOC,F1_SERIE AS ZS_SERIE, F1_FILIAL AS ZS_FILNTA, 0 AS ZS_QTDDIF,"
       cQuery += "         F1_LOJA AS ZS_LOJA , D1_COD AS ZS_COD,D1_VUNIT AS ZS_VUNIT, "      
       cQuery += "         CASE WHEN  F1_TIPO='D'  THEN A1_NOME ELSE A2_NOME END A2_NOME,"
       cQuery += "         CASE WHEN  F1_TIPO='D'  THEN A1_COD ELSE A2_COD END A2_COD ,"        
       cQuery += "         F1_EMISSAO AS ZS_EMISSAO,"
       cQuery += "         F1_PLIQUI, "
       cQuery += "  	   D1_UM, D1_QUANT AS ZS_QUANT,D1_PESO,"
       cQuery += "         A.R_E_C_N_O_ as R_E_C_N_O_ "
       cQuery += "        ,F1_FORNECE AS ZS_FORNECE,B1_COD,B1_YCOMPRI,B1_YLARGUR,B1_UM,D1_COD"
       cQuery += "  FROM "+RetSQlName("SF1")+" A (NOLOCK)"
       cQuery += "  LEFT JOIN "+RetSQlName("SA2")+" B   (nolock) ON B.D_E_L_E_T_='' AND F1_FORNECE=A2_COD AND F1_LOJA=A2_LOJA  AND  F1_FILIAL=A2_FILIAL "
       cQuery += "  LEFT JOIN "+RetSQlName("SA1")+" C   (nolock) ON C.D_E_L_E_T_='' AND F1_FORNECE=A1_COD AND F1_LOJA=A1_LOJA"
       cQuery += "  JOIN "+RetSQlName("SD1")+"      D   (nolock) ON D.D_E_L_E_T_='' AND D1_DOC=F1_DOC AND D1_SERIE=F1_SERIE AND D1_FORNECE=F1_FORNECE"
       cQuery += "  JOIN "+RetSQlName("SB1")+"      E   (nolock) ON E.D_E_L_E_T_='' AND D1_COD=B1_COD AND B1_LOCPAD=D1_LOCAL AND B1_FILIAL=D1_FILIAL"
       cQuery += "  WHERE A.D_E_L_E_T_='' "
       cQuery += "  AND ltrim(rtrim(D1_FILIAL))+','+ltrim(rtrim(D1_FORNECE))+','+ltrim(rtrim(D1_SERIE))+','+ltrim(rtrim(D1_DOC)) IN ("+cNotasG+")"
       cQuery += "  ORDER BY F1_FILIAL,F1_DOC,D1_ITEM"
		
		If 	Select("QRYSD1") > 0 	         
			QRYSD1->(DbCloseArea())             
		Endif  

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYSD1", .F., .T.)   

		oBtnConfir:Disable()    // Desabilita bot„o confimar 		
		While !QRYSD1->(Eof())

			oBtnConfir:Enable()   // Habilita bot„o Confimar
			aAdd(aCoBrwNTD, { cPESAGEM,;
							  QRYSD1->ZS_TIPO,;  
							  STOD(QRYSD1->ZS_EMISSAO),;
							  QRYSD1->ZS_DOC,;
							  QRYSD1->ZS_SERIE,;
							  QRYSD1->ZS_FILNTA,;
							  QRYSD1->ZS_FORNECE,;
							  QRYSD1->ZS_LOJA,;  
							  QRYSD1->ZS_COD,; 
							  QRYSD1->ZS_ITEM,;
							  QRYSD1->ZS_QUANT,;					
			                  QRYSD1->ZS_VUNIT,;					
					          QRYSD1->ZS_QTDDIF,;					
			                  .F.})			    
			QRYSD1->(dbSkip())		
		Enddo		    	
		QRYSD1->(DbCloseArea())
  Else
	  fCompDif() // Caso n„o digite as notas / PESO -> Informa que existe a diferenÁa
  Endif

Return

////////////////////////////////////////////////
// Incluir as notas de saÌda no grid da tela  //
////////////////////////////////////////////////
Static function inclNF(nCBoxF,cNota,cSerie,cFornec,cEmissa,nPeNt,nRec,cCodForn )

   If !Empty(nCBoxF)  .and. !Empty(cNota)
       If nPesoNota>0
	       cPesoTot += nPesoNota // Ao inserir soma o peso total
       Endif
	   RecLock("TMP",.T.)
	   TMP->D1_FILIAL  :=	alltrim(nCBoxF)
	   TMP->D1_DOC     :=	alltrim(cNota)
	   TMP->D1_SERIE   :=	alltrim(cSerie)
	   TMP->A2_NREDUZ  :=	alltrim(cFornec)
	   TMP->D1_EMISSAO :=	cEmissa	   	   	   
	   TMP->F1_PLIQUI  :=	nPeNt //nPesoNota	   
	   TMP->R_E_C_N_O_ :=	nRec
	   TMP->D1_FORNECE :=	alltrim(cCodForn)	   
	   TMP->(MsUnLock())
	   
	   // Limpa os campos e posiciona na nota
	   cGetNota   := CRIAVAR("D1_DOC") 
	   cGetSerie  := CRIAVAR("D1_SERIE")
	   cSayNomFor := SPACE(60) 
	   cSayEmissa := SPACE(12) 
	   cCodForn   := CRIAVAR("D1_FORNECE")
	   nRecno     := cGetFornec := SPACE(12)
	   nPesoNota := 0
	   TMP->(dbGoTop())     // Posiciona no primeiro registro ao inserir novo
   	   oGetNota:refresh()
	   oGetSerie:refresh() 
	   oGetFornec:refresh()
	   oGetNota:SetFocus()  // Foca o campo nota novamente
	   GETDREFRESH() 	
       oBtnInclui:Disable()
   Endif         
   oGetNota:refresh()
   oGetSerie:refresh() 
   oGetFornec:refresh()   
   oSayPeso:refresh() 
   oBrwNotas:oBrowse:Refresh() 
   GETDREFRESH()
Return 

////////////////////////////////////////////////
// Incluir as notas de saÌda no grid da tela  //
////////////////////////////////////////////////
Static function fRetInf(cFil,cGetNota,cSerie,cFornec)

  	   
 	    oBtnInclui:Disable()  

 	    //oBtnXML:Disable()

       cQuery := "  SELECT F1_DOC,D1_ITEM, "      
       cQuery += "         F1_SERIE, "
       cQuery += "         CASE WHEN  F1_TIPO='D'  THEN A1_NOME ELSE A2_NOME END A2_NOME,"
       cQuery += "         CASE WHEN  F1_TIPO='D'  THEN A1_COD ELSE A2_COD END A2_COD ,"        
       cQuery += "         F1_EMISSAO,"
       cQuery += "         F1_PLIQUI, "
       cQuery += "  	   D1_UM, D1_QUANT,D1_PESO,"
       cQuery += "         A.R_E_C_N_O_ as R_E_C_N_O_ "
       cQuery += "        ,D1_FORNECE,B1_COD,B1_YCOMPRI,B1_YLARGUR,B1_UM,D1_COD"
       cQuery += "  FROM "+RetSQlName("SF1")+" A (NOLOCK)"
       cQuery += "  LEFT JOIN "+RetSQlName("SA2")+" B   (nolock) ON B.D_E_L_E_T_='' AND F1_FORNECE=A2_COD AND F1_LOJA=A2_LOJA  AND  F1_FILIAL=A2_FILIAL "
       cQuery += "  LEFT JOIN "+RetSQlName("SA1")+" C   (nolock) ON C.D_E_L_E_T_='' AND F1_FORNECE=A1_COD AND F1_LOJA=A1_LOJA"
       cQuery += "  JOIN "+RetSQlName("SD1")+"      D   (nolock) ON D.D_E_L_E_T_='' AND D1_DOC=F1_DOC AND D1_SERIE=F1_SERIE AND D1_FORNECE=F1_FORNECE"
       cQuery += "  JOIN "+RetSQlName("SB1")+"      E   (nolock) ON E.D_E_L_E_T_='' AND D1_COD=B1_COD AND B1_LOCPAD=D1_LOCAL AND B1_FILIAL=D1_FILIAL"
       cQuery += "  WHERE A.D_E_L_E_T_='' "
       cQuery += "  AND F1_FILIAL='"+cFil+"'"
       cQuery += "  AND F1_DOC='"+cGetNota+"' "
       If !empty(cSerie)
	       cQuery += "  AND F1_SERIE='"+alltrim(cSerie)+"' "       
       Endif
       If !empty(cFornec)
	       cQuery += "  AND F1_FORNECE='"+alltrim(cFornec)+"' "       		       
       Endif
       If !empty(cGetNota) .and. empty(cSerie) .and. empty(cFornec) // Ao LanÁar o campo Nota Fiscal sugere a ultima nota dos ultimos 5 dias
	       cQuery += "  AND F1_DTDIGIT BETWEEN CONVERT(varchar, Getdate()-8, 112) AND CONVERT(varchar, Getdate(), 112)"  //  Deixar 8 dias
       Endif
       cQuery += "  ORDER BY A.R_E_C_N_O_ DESC"
		
		If 	Select("QRY") > 0 	         
			QRY->(DbCloseArea())             
		Endif  

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRY", .F., .T.)   
		
		nPesoNota := 0  
		nRecno := "" 
        If QRY->(Eof())     // Se vazio informa que n„o existe NOTA	       
	       If !empty(cGetNota)  .and. !empty(cFornec) // .and. !empty(cSerie)
		       nPesoNota  := 0 		   	        
		       cCabc 	:= "Pre-nota n„o encontrada"
			   cMSg 	:= "ATEN«√O: N„o encontrada a entrada de Pre-nota nos ultimos 60 dias!."+CHR(13)+CHR(10)
		       cMSg 	+= "Confirme os dados digitados."+CHR(13)+CHR(10)	
	           U_fTelAviso(cCabc, cMSg, .F.)  
           Endif
   	       oBtnInclui:Disable()
		   //oBtnXML:Disable()
		   //cGetNota   := SPACE(06)
		   //cGetSerie  := SPACE(02)
		   cSayNomFor := SPACE(60) 
		   cSayEmissa := SPACE(12)  
		   cCodForn   := CRIAVAR("D1_FORNECE")
		   nRecno     := cGetFornec := SPACE(12)
        Endif

		While !QRY->(Eof())   
		   	oBtnInclui:Enable()			
		   	//oBtnXML:Enable()


		   	
		    cGetSerie  := QRY->F1_SERIE
		    cSayNomFor := alltrim(QRY->A2_NOME)		    
		    cGetFornec := alltrim(QRY->A2_COD)		    
		    cSayEmissa := DTOC(STOD(QRY->F1_EMISSAO))
		    nRecno     := QRY->R_E_C_N_O_     // Recno do SF1
		    cCodForn   := QRY->D1_FORNECE
		    
			cGetEMP 	:= cSayNomFor+space(30) // Informa o nome da Empresa na tela principal
			oGetEMP:Refresh()

		    
		    If QRY->F1_PLIQUI>0
		    	nPesoNota := QRY->F1_PLIQUI		    		    		    
		    	//oBtnXML:Disable() // Desabilita bot„o XML, IMPORTAR PESO LIQUIDO       				
		    Else    // Soma o peso de cada item          
				//oBtnXML:Enable()   // Habilita bot„o XML, IMPORTAR PESO LIQUIDO       				
			    If Alltrim(QRY->D1_UM)=='KG'
					nPesoNota += QRY->D1_QUANT		    		    		    
				Else 
					//nPesoNota += QRY->D1_QUANT		    		    		    				
			  		nPesoNota += U_CalcPeso( QRY->B1_COD,;
											 QRY->B1_YCOMPRI,;
											 QRY->B1_YLARGUR,;
											 QRY->B1_UM,;
											 QRY->D1_QUANT,;
											 ,.F.)
				Endif
			Endif					    
			QRY->(dbSkip())
			
		oBtnInclui:SetFocus()	// Bot„o no focus incluir 
		
		Enddo		    	
		QRY->(DbCloseArea())
     
        oGetSerie:refresh() 
        oGetFornec:refresh() 
     
Return

/////////////////////////////////////////////
// Ao confirmar as notas incluidas no Grid //
/////////////////////////////////////////////
Static function Confirma(nPesoG)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Percorre a tabela TMP para bucar os notas e peso total para incluir nos campos NOTAS FISCAIS E PESO NFS   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////
cNotas  :=  ""
If nPesoG>0

	TMP->(dbGoTop())
    cNotas  :=  ""
    cRecSF1 :=  ""    
	While !TMP->(Eof())           
  	   //////////////////////////////
	   // Gravar as notas no campo //
  	   //////////////////////////////	   
       If Empty(cNotas)  //  conte˙do existente mais FILIAL+COD.FOR+SERIE+NR.NF separados por vÌrgula
       	   cNotas +=  alltrim(TMP->D1_FILIAL)+","+alltrim(TMP->D1_FORNECE)+","+alltrim(TMP->D1_SERIE)+","+alltrim(TMP->D1_DOC)
       Else
	       cNotas +=  ' / '+alltrim(TMP->D1_FILIAL)+","+alltrim(TMP->D1_FORNECE)+","+alltrim(TMP->D1_SERIE)+","+alltrim(TMP->D1_DOC)
       Endif    
   	   ///////////////////////
	   // Gravar os Recnos  //
  	   ///////////////////////
       If Empty(cRecSF1)
		   cRecSF1 += cvaltochar(TMP->R_E_C_N_O_)
	   Else
		   cRecSF1 += ","+cvaltochar(TMP->R_E_C_N_O_)
	   Endif

	 TMP->(DbSkip())
	EndDo	
	////////////////////////////////////////////////
    // Informa o Peso das notas na tela principal //
	////////////////////////////////////////////////
    nGetPESONFS := nPesoG
	oGetPESONFS:Disable()  
   	oGetNFS:Refresh()
	
Endif

////////////////////////////////////////
// Informa as notas na tela principal //
////////////////////////////////////////
If !Empty(cNotas)
		cGetNFS := cNotas
		oGetNFS:Disable()
		oGetNFS:Refresh()
Endif

	

Return
//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥Prepara o header do MSSELECT - Recebimento de Material ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ         
Static Function fHeader()

	aCampos := {}   
	AADD(aCampos,{"D1_FILIAL","","Filial",""})   
	AADD(aCampos,{"D1_DOC","","NR.NF",""}) 
	AADD(aCampos,{"D1_SERIE","","Serie",""})  
	AADD(aCampos,{"A2_NREDUZ","","Fornecedor",""})
	AADD(aCampos,{"D1_EMISSAO","","Emiss„o",""})	  
	AADD(aCampos,{"F1_PLIQUI","","Peso",""})					

    // Estrutura , onde os dados ser„o salvos
	aStru := {}
    AADD(aStru,{ "D1_FILIAL"  	, "C"	, 02	, 0})  	
 	AADD(aStru,{ "D1_DOC" 		, "C"	, 10    , 0})  	
 	AADD(aStru,{ "D1_SERIE" 	, "C"	, 03	, 0})  	 		
	AADD(aStru,{ "F1_PLIQUI"	, "N"	, 15 	, 2}) 	
    AADD(aStru,{ "A2_NREDUZ"	, "C"	, 40 	, 0})     	
    AADD(aStru,{ "D1_EMISSAO"	, "C"	, 10 	, 0}) 
    AADD(aStru,{ "R_E_C_N_O_"	, "N"	, 15 	, 0})
    AADD(aStru,{ "D1_FORNECE"	, "C"	, 10 	, 0})    
    
  

	Private TMP   := GetNextAlias() 
	cTRB := CriaTrab(aStru,.T.)
	If Select("TMP") > 0
	   TMP->(dbCloseArea())
	EndIf
	
	dbUseArea(.T.,,cTRB,"TMP",.F.)
	DbselectArea("TMP")     

     // Adicionando legenda a Lista que ser· exibida no msselect	
     //aadd(aColors, {"TMP->TABELA=='SA1'"				                                       , "BR_AMARELO"}) // Cliente	 
     //aadd(aColors, {"TMP->TABELA<>'SA1'"				                                       , "BR_BRANCO"}) 	// SU5     

Return     

Static function fSoma()

nGetPESONFS:= nGetTotal
oGetPESONFS:Refresh()

oDlg1:End()

Return


// Edner G. Alvarenga 28/12/2011
// ConfirmaÁ„o da pesagem.

Static Function fConfirma()

/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± DeclaraÁ„o de cVariable dos componentes                                 ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
Private nPD        := 0
Private nPE        := 0
Private nPL        := 0
Private nPNF       := 0
Private nPS        := 0
Private cConf      := ""   

lEmail:=.F. 
lDif  := .F. 
lEmDev:= .F. // Envia email caso DiferenÁa na DevoluÁ„o 

// Busca ˙ltima movimentaÁ„o do veÌculo para calcular os pesos.
_AliasTmp := GetNextAlias()
BeginSQl Alias  _AliasTmp
	SELECT SZ8.Z8_NRPESA, SZ8.Z8_TPPESA, SZ8.Z8_TPVEIC, SZ8.Z8_TPMOVI, SZ8.Z8_ABASTEC, SZ8.Z8_QTLITRO, SZ8.Z8_MOTORIS, SZ8.Z8_DOCMOTO,
	SZ8.Z8_TRANSP, SZ8.Z8_EMPRESA, SZ8.Z8_OBS, SZ8.Z8_NRPESEN, SZ8.Z8_NUMNFS, SZ8.Z8_PESONFS, SZ8.Z8_PESO
	FROM %TABLE:SZ8% SZ8
	WHERE SZ8.Z8_PLACA = %EXP:AllTrim(cGetPLACA)%
	AND   SZ8.Z8_NRPESA = (SELECT MAX(X.Z8_NRPESA) AS Z8_NRPESA FROM %TABLE:SZ8% X 
							WHERE X.Z8_PLACA = %EXP:AllTrim(cGetPLACA)% 
							AND X.D_E_L_E_T_=' ')
	AND   SZ8.D_E_L_E_T_=' '
EndSql

dbSelectArea(_AliasTmp)
(_AliasTmp)->(DbGoTop())
/*
IF (_AliasTmp)->(!Eof())


	If (_AliasTmp)->Z8_TPPESA $ "E,S" .AND. Empty((_AliasTmp)->Z8_NRPESEN) //Entrada em aberto.

		// CALCULO: Saida/entrada atual -(menos) Entrada/saida em aberto
		If (_AliasTmp)->Z8_TPPESA == "E"
			nPE := (_AliasTmp)->Z8_PESO
			nPS := nGetPESO
			nPNF:= If(!Empty(nGetPESONFS),nGetPESONFS,(_AliasTmp)->Z8_PESONFS)

			nPL := nPS - nPE
			nPD := ABS(nPL) - nPNF

		ElseIf (_AliasTmp)->Z8_TPPESA == "S"
			nPE := nGetPESO
			nPS := (_AliasTmp)->Z8_PESO
			nPNF:= If(!Empty(nGetPESONFS),nGetPESONFS,(_AliasTmp)->Z8_PESONFS)

			nPL := nPE - nPS
			nPD := ABS(nPL) - nPNF
		EndIf

	ElseIf (_AliasTmp)->Z8_TPPESA == "I"	//Intermediaria - Procura a entrada e calcula a saida atual

		// CALCULO: Saida atual - Entrada em aberto
		nPE := Posicione("SZ8",1,xFilial("SZ8")+(_AliasTmp)->Z8_NRPESEN,"Z8_PESO")
		nPS := nGetPESO
		nPNF:= If(!Empty(nGetPESONFS),nGetPESONFS,(_AliasTmp)->Z8_PESONFS)
		nPL := nGetPESO - nPE
		nPD := ABS(nPL) - nPNF

	ElseIf (_AliasTmp)->Z8_TPPESA $ "S,E" .AND. !Empty((_AliasTmp)->Z8_NRPESEN)	//Ultimo movimento fechado (entrada ou saida)

		If (_AliasTmp)->Z8_TPPESA == "E"
			nPE := nGetPESO
			nPS := 0
		Else
			nPS := nGetPESO
			nPE := 0
		EndIf

		nPNF:= 0
		nPL := 0
		nPD := 0
	EndIf
ELSE
	nPE := nGetPESO
	nPS := 0
	nPNF:= 0
	nPL := 0
	nPD := 0
ENDIF
*/             

/*
IF aMOTDados[oComboBo3:nAT] $ "C" .and. aTPDados[oComboBo1:nAT] $ "E"  // Se motivo for compra E entrada e existir TEMPOR¡RIA

Endif
*/

//Calcula PESO INICIAL E PESO FINAL
lFecha := .F. 

If (_AliasTmp)->(!EOF()) .AND. ((_AliasTmp)->Z8_TPPESA == "I" .OR. Empty((_AliasTmp)->Z8_NRPESEN)) //; .and. !fEntTEMP(Alltrim(cGetPLACA)) .AND. !aTPDados[oComboBo1:nAT] == "E" .AND. !aMOTDados[oComboBo3:nAT] $ "C" ;
   //.OR. !fEntTEMP(Alltrim(cGetPLACA)) .AND. aMOTDados[oComboBo3:nAT] $ "C" .AND. !aTPDados[oComboBo1:nAT] == "E" // Caso COMPRA E diferente de ENTRADA e placa N√O tenha uma entrada TEMPOR¡RIA

	lFecha := .T.

	IF (_AliasTmp)->Z8_TPPESA == "I"
		nPI := Posicione("SZ8",1,xFilial("SZ8")+(_AliasTmp)->Z8_NRPESEN,"Z8_PESO")
	ELSE
		nPI := (_AliasTmp)->Z8_PESO
	ENDIF
	nPF := nGetPESO
	
	nPL := If(nPF > nPI,nPF,nPI) - If(nPI < nPF,nPI,nPF)
	If nGetLITROS>0 .and. nPL>nGetLITROS .AND. Alltrim(aTPDados[oComboBo1:nAT] ) $ "S" //SÛ È possivel informar litros na saÌda - Subtrair o litro do peso liquido.
    	nPL  := nPL-(nGetLITROS*0.85)    // 0.85 convers„o LITROS PARA PESO
    Endif
	nPNF:= If(!Empty(nGetPESONFS),nGetPESONFS,(_AliasTmp)->Z8_PESONFS)

	nPD := nPL - nPNF

	// Caso COMPRA e tenha ENTRADA TEMPOR¡RIA ,  ENTRADA TRAR¡ INFORMA«’ES DESSA PESAGEM TEMPOR¡RIA
	// Em um segundo momento, se digitar novamente a PLACA do veÌculo, o sistema dever· identificar a ENTRADA TEMPOR¡RIA e sugerir todos os dados na tela,
	// alterando em tela o Z8_TPPESA de ENTRADA TEMPOR¡RIA para ENTRADA, e preenchendo inclusive o PESO, evitando o veÌculo esteja sobre a balanÁa. 	
	If (_AliasTmp)->Z8_TPPESA == "T" .and. fEntTEMP(Alltrim(cGetPLACA)) .AND. aMOTDados[oComboBo3:nAT] $ "C" .AND. aTPDados[oComboBo1:nAT] == "E" // Caso ENTRADA DE COMPRA E tenha PESO TEMPOR¡RIO
		// Calcula somente PESO INICIAL
		nGetPESO := (_AliasTmp)->Z8_PESO
		nPI := nGetPESO
		nPF := 0
		nPL := 0
		nPNF:= 0
		nPD := 0   
	   	//cCabc  := "PESO DE ENTRADA TEMPOR¡RIA"
	    //cMgsAl := " ATEN«√O: Foi identificada uma ENTRADA TEMPOR¡RIA e o sistema ir· utilizar o PESO REGISTRADO para esta pesagem: "+Cvaltochar(nGetPESO)+CHR(13)+CHR(10)
    	//U_fTelAviso(cCabc, cMgsAl, .F.)		
    	//lFecha := .T.
	Endif
Else
	// Calcula somente PESO INICIAL
	nPI := nGetPESO
	nPF := 0
	nPL := 0
	nPNF:= 0
	nPD := 0
EndIf
	
(_AliasTmp)->(DbCloseArea())

nPESENTR :=  nPESSAID := nPLIQ := nPNTS :=  nPDIF :=  0 

/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± DeclaraÁ„o de Variaveis Private dos Objetos                             ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
SetPrvt("oFont1","oFont2","oDlgOk","oSay1","oSay2","oSay3","oSay4","oSay5","oSay6","oSay7","oSay8","oPE")
SetPrvt("oPL","oPNF","oPD","oPanel2","oCBox1")

/*ƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ±±
±± Definicao do Dialog e todos os seus componentes.                        ±±
Ÿ±±¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒ¡ƒƒƒƒƒƒ¡ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ*/
oFont1     := TFont():New( "MS Sans Serif",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )
oFont2     := TFont():New( "MS Sans Serif",0,-24,,.T.,0,,700,.F.,.F.,,,,,, )
oDlgOk     := MSDialog():New( 187,336,528,749,"Controle de Pesagem de VeÌculos",,,.F.,,,,,,.T.,,,.T. )
/*
oSay1      := TSay():New( 014,014,{||"Peso Entrada:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,073,012)
oSay2      := TSay():New( 032,014,{||"Peso SaÌda:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,073,012)
oSay3      := TSay():New( 065,014,{||"Peso LÌquido:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,066,012)
oSay4      := TSay():New( 085,014,{||"Peso NF's:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,052,012)
oSay5      := TSay():New( 114,014,{||"Peso DiferenÁa:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_HRED,CLR_WHITE,075,012)
oSay6      := TSay():New( 144,006,{||"Confirma pesagem?"},oDlgOk,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,121,016)
oSay7      := TSay():New( 047,094,{||"Na 'VENDA' o peso do abastecimento de "},oDlgOk,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,115,007)
oSay8      := TSay():New( 054,094,{||"saÌda È descontado do peso lÌquido."},oDlgOk,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,106,007)
oPE        := TGet():New( 012,093,{|u| If(PCount()>0,nPE:=u,nPE)},oDlgOk,087,014,'',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPE",,)
oPS        := TGet():New( 031,093,{|u| If(PCount()>0,nPS:=u,nPS)},oDlgOk,087,014,'',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPS",,)
oPL        := TGet():New( 064,093,{|u| If(PCount()>0,nPL:=u,nPL)},oDlgOk,087,014,'',,CLR_HBLUE,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPL",,)
oPNF       := TGet():New( 083,093,{|u| If(PCount()>0,nPNF:=u,nPNF)},oDlgOk,087,014,'',,CLR_HBLUE,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPNF",,)
oPD        := TGet():New( 111,093,{|u| If(PCount()>0,nPD:=u,nPD)},oDlgOk,087,014,'',,CLR_HRED,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPD",,)
oPanel2    := TPanel():New( 134,003,"oPanel2",oDlgOk,,.F.,.F.,,,199,001,.T.,.F. )
oCBox1     := TComboBox():New( 147,129,{|u| If(PCount()>0,cConf:=u,cConf)},{"2-Nao","1-Sim"},045,016,oDlgOk,,,{|| If(oCBox1:nAT=2,lConfirmou:=.T.,""),oDlgOk:End()},CLR_BLACK,CLR_WHITE,.T.,oFont1,"",,,,,,,cConf )
*/
If (lFecha .AND. aTPDados[oComboBo1:nAT] $ "S#I") .OR. (!lFecha .AND. aTPDados[oComboBo1:nAT] == "E") ;
      .or.  aTPDados[oComboBo1:nAT] $ "#T#" .or. aTPDados[oComboBo1:nAT] $ "#E#" .and. fEntTEMP(cGetPLACA)  // COMPRA TEMPOR¡RIA ou ENTRADA de uma compra TEMPOR¡RIA
	oSay1      := TSay():New( 014,014,{||"Peso Entrada:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,073,012)
	oPI        := TGet():New( 012,093,{|u| If(PCount()>0,nPI:=u,nPI)},oDlgOk,087,014,'@E 999,999.999',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPI",,)
	oSay2      := TSay():New( 032,014,{||"Peso SaÌda:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,073,012)
	oPF        := TGet():New( 031,093,{|u| If(PCount()>0,nPF:=u,nPF)},oDlgOk,087,014,'@E 999,999.999',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPF",,)
Else
	oSay2      := TSay():New( 032,014,{||"Peso Entrada:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,073,012)
	oPI        := TGet():New( 012,093,{|u| If(PCount()>0,nPI:=u,nPI)},oDlgOk,087,014,'@E 999,999.999',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPI",,)
	oSay1      := TSay():New( 014,014,{||"Peso SaÌda:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,073,012)
	oPF        := TGet():New( 031,093,{|u| If(PCount()>0,nPF:=u,nPF)},oDlgOk,087,014,'@E 999,999.999',,CLR_BLACK,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPF",,)
EndIf
oSay3      := TSay():New( 065,014,{||"Peso LÌquido:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,066,012)
oSay4      := TSay():New( 085,014,{||"Peso NF's:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_HBLUE,CLR_WHITE,052,012)
oSay5      := TSay():New( 114,014,{||"Peso DiferenÁa:"},oDlgOk,,oFont1,.F.,.F.,.F.,.T.,CLR_HRED,CLR_WHITE,075,012)
oSay6      := TSay():New( 144,006,{||"Confirma pesagem?"},oDlgOk,,oFont2,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,121,016)
oSay7      := TSay():New( 047,094,{||"Na 'VENDA' o peso do abastecimento de "},oDlgOk,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,115,007)
oSay8      := TSay():New( 054,094,{||"saÌda È descontado do peso lÌquido."},oDlgOk,,,.F.,.F.,.F.,.T.,CLR_BLACK,CLR_WHITE,106,007)
oPL        := TGet():New( 064,093,{|u| If(PCount()>0,nPL:=u,nPL)},oDlgOk,087,014,'@E 999,999.999',,CLR_HBLUE,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPL",,)
oPNF       := TGet():New( 083,093,{|u| If(PCount()>0,nPNF:=u,nPNF)},oDlgOk,087,014,'@E 999,999.999',,CLR_HBLUE,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPNF",,)
oPD        := TGet():New( 111,093,{|u| If(PCount()>0,nPD:=u,nPD)},oDlgOk,087,014,'@E 999,999.999',,CLR_HRED,CLR_WHITE,oFont1,,,.T.,"",,,.F.,.F.,,.T.,.F.,"","nPD",,)
oPanel2    := TPanel():New( 134,003,"oPanel2",oDlgOk,,.F.,.F.,,,199,001,.T.,.F. )

oCBox1     := TComboBox():New( 147,129,{|u| If(PCount()>0,cConf:=u,cConf)},{"2-Nao","1-Sim"},045,016,oDlgOk,,,{|| If(oCBox1:nAT=2,lConfirmou:=.T.,""),If(aTPDados[oComboBo1:nAT] == "S" .And. aMOTDados[oComboBo3:nAT] $ "V" .AND. nPD>0 .and. nPD>Getnewpar("MV_YDIFBAL",50) ,lEmail:=.T.,lEmail:=.F.) , if( nPD<=nParVaria , lDif := .T., lDif := .F. ),     If(aTPDados[oComboBo1:nAT] == "S" .And. aMOTDados[oComboBo3:nAT] $ "D" .AND. nPD>0 .and. nPD>Getnewpar("MV_YDIFNTA",10) ,lEmDev:=.T.,lEmDev:=.F.)          , oDlgOk:End()},CLR_BLACK,CLR_WHITE,.T.,oFont1,"",,,,,,,cConf )
//If(aTPDados[oComboBo1:nAT] == "S" .And. aMOTDados[oComboBo3:nAT] $ "D" .AND. nPD>0 .and. nPD>Getnewpar("MV_YDIFNTA",10) ,lEmDev:=.T.,lEmDev:=.F.)

// Enviar email caso diferenÁa seja maior
nPESENTR :=  nPI
nPESSAID :=  nPF
nPLIQ    :=  nPL
nPNTS    :=  nPNF
nPDIF    :=  nPD

oPI:Disable()
oPF:Disable()
oPL:Disable()
oPNF:Disable()
oCBox1:SetFocus()

oDlgOk:Activate()

Return


/*/
 Funcao:  MATA010Ex
 Data:  30/04/2011
 Descricao: Executar a Funcao MATA010 diretamente sem a necessidade de LOGIN no Protheus
 Sintaxe: 1 ) U_MATA010Ex ( Chamada diretamente na Tela de Entrada do Sistema ) ; ou
    2 ) totvsclient.exe -q -p=u_MATA010Ex -a=01;01 -c=rnp_local -e=rnp -m -l ( Chamada Via Linha de Comando )
/*/
User Function MATA010Ex( cRotina )

 Local aEmpFil    


// Local bWindowInit := { || __Execute( cRotina+"("+cNome1+")" , "xxxxxxxxxxxxxxxxxxxx" , STRTRAN(STRTRAN(cRotina,"(",""),"(","")  , "SIGAFAT" , "SIGAFAT", 1 , .T. ) }
 Local bWindowInit := { || __Execute( cRotina , "xxxxxxxxxxxxxxxxxxxx" , cRotina  , "SIGAFAT" , "SIGAFAT", 1 , .T. ) }
// Local bWindowInit := { || __Execute( "U_DIA165()" , "xxxxxxxxxxxxxxxxxxxx" , "DIA165()" , "SIGAFAT" , "SIGAFAT", 1 , .T. ) }
// Local bWindowInit := { || __Execute( "MATA140" , "xxxxxxxxxxxxxxxxxxxx" , "MATA140" , "SIGACOM" , "SIGACOM", 1 , .T. ) }
 Local cEmp
 Local cFil
 Local cMod
 Local cModName  := "SIGAFAT"
  alert("cRotina MATA010Ex temp : "+cRotina) //temp
cEmpFil  := "01;01" 
//cRotina  := "U_DIA165"    
//DEFAULT cEmpFil  := "01;01"    
//DEFAULT cRotina  := "U_DIA165"    


  
 aEmpFil    := StrTokArr( cEmpFil , ";" ) 
 cEmp    := '01'
 cFil    := '01'
 SetModulo( @cModName , @cMod )
 
// PREPARE ENVIRONMENT EMPRESA( cEmp ) FILIAL ( cFil ) USER 'fabio' PASSWORD '123' MODULO ( cMod )
PREPARE ENVIRONMENT EMPRESA( cEmp ) FILIAL ( cFil ) MODULO ( cMod )

   InitPublic()

   SetsDefault()
   
      
   SetModulo( @cModName , @cMod )

  DEFINE WINDOW oMainWnd FROM 001,001 TO 400,500 TITLE OemToAnsi( FunName() )
  ACTIVATE WINDOW oMainWnd MAXIMIZED ON INIT ( Eval( bWindowInit ) , oMainWnd:End() )
 
 RESET ENVIRONMENT

Return( NIL )

/*/
 Funcao:  SetModulo
 Descricao: Setar o Modulo em Execucao
 Sintaxe: SetModulo( @cModName , @cMod )
/*/
Static Function SetModulo( cModName , cMod )

 Local aRetModName := RetModName( .T. )
 
 Local cSvcModulo
 Local nSvnModulo
 
 IF ( Type("nModulo") == "U" )
  _SetOwnerPrvt( "nModulo" , 0 )
 Else
  nSvnModulo := nModulo
 EndIF
 
 cModName := Upper( AllTrim( cModName ) )
 IF ( nModulo <> aScan( aRetModName , { |x| Upper( AllTrim( x[2] ) ) == cModName } ) )
  nModulo := aScan( aRetModName , { |x| Upper( AllTrim( x[2] ) ) == cModName } )
  IF ( nModulo == 0 )
   cModName := "SIGAFAT"
   nModulo  := aScan( aRetModName , { |x| Upper( AllTrim( x[2] ) ) == cModName } )
  EndIF
 EndIF
 
 IF ( Type("cModulo") == "U" )
  _SetOwnerPrvt( "cModulo" , "" )
 Else
  cSvcModulo := cModulo
 EndIF
 
 cMod := SubStr( cModName , 5 )
 IF ( cModulo <> cMod )
  cModulo := cMod
 EndIF

Return( { cSvcModulo , nSvnModulo  } )

/////////////////////
// Excuta direto   //
/////////////////////
Static function ExecLink(cRot)
        alert("cRot ExecLink temp "+cRot)
	    WinExec("C:\smartclient11T\Smartclient.exe -E=TESTE11FABIO -q -P="+cRot+" -a=01;01 -C=TESTE11 -m -q")
	    
Return

/////////////////////////////////////////////////////////
// Limpa a tabela de DivergÍncia de Notas de Entrada   //
/////////////////////////////////////////////////////////
Static function fDelSZS(cPESAGEM)
	BEGIN TRANSACTION
	cSQL := " UPDATE "+RETSQLNAME("SZS")+" SET D_E_L_E_T_ ='*'"
	cSQL += " WHERE ZS_NRPESA ='"+cPESAGEM+"' AND D_E_L_E_T_=' ' "
	tcSQLExec(cSQL)
	END TRANSACTION		
Return

///////////////////////////////////////////////////////////////////////////////
// Valida QTD DEVULU«√O INFORMADA N√O PODE SER MAIOR QUE O CAMPO QUANTIDADE  //
///////////////////////////////////////////////////////////////////////////////
User Function ValQTDDEV(oObjeto,nLinha)                               

Local nQTD 		:= aScan(oBrwNotas:aHeader,{|x| AllTrim(x[2]) == Upper("C9_YPESO")})
Local nQTDdev 	:= aScan(oBrwNotas:aHeader,{|x| AllTrim(x[2]) == Upper("ZS_QTDDIF")})

cPesoDEV := 0

Default nLinha := oBrwNotas:nAt
	/////////////////////
    // Valida o acols  //
  	/////////////////////
	For Ni:=1 To Len(oBrwNotas:aCols)
    	//nQTDDEV := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)
    	nQTDINF := NwFieldGet(oBrwNotas, "C9_YPESO"	, Ni)
    	citem   := NwFieldGet(oBrwNotas, "ZS_ITEM"	, Ni)    	
    	nQTDdev := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)    	    	    	
  	
    	   If nLinha==Ni

    	     If Len(aCobrwNTS)>0  // Atualizando aCobrwNTS
    			  aCobrwNTS[Ni][10]	 :=	M->ZS_QTDDIF //nQTDdev
		     Endif

	    	 If M->ZS_QTDDIF>nQTDINF      	    	 
  	           	cCabc  := "QTD DEV. MAIOR"
	    	    cMgsAl := "N„o È permitido informar Quantidade de devoluÁ„o maior que a quantidade do item. "+CHR(13)+CHR(10)
   				cMgsAl += "Item                            :      " +alltrim(citem)+CHR(13)+CHR(10)
				cMgsAl += "Quantidade                :    " +cvaltochar(nQTDINF)+CHR(13)+CHR(10)
				cMgsAl += "QTD Dev. informada:    "+cvaltochar(M->ZS_QTDDIF)+CHR(13)+CHR(10)
			    U_fTelAviso(cCabc, cMgsAl, .F.)  	   	 	        //MsgAlert(cMgsAl)
	   	  		Return(.F.)	    	 
	    	 Endif	
	    	      // Soma todos os pesos QTD DEV informados    
	    	      cPesoDEV += M->ZS_QTDDIF
	       Else
				  cPesoDEV += nQTDdev //M->ZS_QTDDIF
		   Endif 
  	      // Soma todos os pesos QTD DEV informados    
  	      //cPesoDEV += nQTDdev
    Next Ni        
    fQTDDSum() // Atualizar o campo PESO DEV. DA TELA 
    oSayP1:Refresh() // atualiza cPesoDEV

Return(.T.)  


///////////////////////////////////////////////////////////////////////////////
// Valida QTD DEVULU«√O INFORMADA N√O PODE SER MAIOR QUE O CAMPO QUANTIDADE  //
///////////////////////////////////////////////////////////////////////////////
User Function fSumQTDDEV(oObjeto,nLinha)                               

Local nQTD 		:= aScan(oBrwNotas:aHeader,{|x| AllTrim(x[2]) == Upper("C9_YPESO")})
Local nQTDdev 	:= aScan(oBrwNotas:aHeader,{|x| AllTrim(x[2]) == Upper("ZS_QTDDIF")})

cPesoDEV := 0

Default nLinha := oBrwNotas:nAt
	/////////////////////
    // Valida o acols  //
  	/////////////////////
	For Ni:=1 To Len(oBrwNotas:aCols)
    	//nQTDDEV := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)
    	nQTDINF := NwFieldGet(oBrwNotas, "C9_YPESO"	, Ni)
    	citem   := NwFieldGet(oBrwNotas, "ZS_ITEM"	, Ni)    	
    	nQTDdev := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)    	    	    	
	    cPesoDEV += nQTDdev //M->ZS_QTDDIF	
    Next Ni        
    fQTDDSum() // Atualizar o campo PESO DEV. DA TELA 
    oSayP1:Refresh() // atualiza cPesoDEV

Return(.T.)

////////////////////////////////////////////
// Soma todos os pesos QTD DEV informados //   
////////////////////////////////////////////
Static Function fQTDDSum()                               

cPesoDEV := 0

For Ni:=1 To Len(oBrwNotas:aCols)
   	nQTDdev := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)   	
    cPesoDEV += nQTDdev
Next Ni    
oSayP1:Refresh() // atualiza cPesoDEV

Return(.T.)

//////////////////////////////////////////////////////
// Soma todos os pesos QTD DIF informada NA ENTRADA //   
//////////////////////////////////////////////////////
User Function fQTDESum()                               

cSayDifSel := 0
nLinha := oBrwNotas:nAt

For Ni:=1 To Len(oBrwNotas:aCols)
   	nQTDdevENT := NwFieldGet(oBrwNotas, "ZS_QTDDIF", Ni)   	
    If nLinha==Ni
   	    cSayDifSel += M->ZS_QTDDIF
	Else
	    cSayDifSel += nQTDdevENT
	Endif
Next Ni    
oSayDifSel:Refresh() // atualiza cSayDifSel

Return(.T.)


///////////////////////////////////////////////////////////////////
// Retorna o peso do campo OUTROS na tela de DevoluÁ„o de vendas //   
///////////////////////////////////////////////////////////////////
Static function fRetPeso(cObs)

cParPeso := alltrim(cObs) 
aPesoObs := strtokarr((ALLTRIM(cParPeso)),"#")     
nProx    :=  0 
nRet     :=  0

For nX := 1 To Len(aPesoObs)  
	If alltrim(aPesoObs[nX]) $ "PESO:" 
	   nProx := nX+1 // O prÛximo ser· o peso informado
	Endif
    If nProx>0
        If nX==nProx
	    nRet :=  val(aPesoObs[nX])
	    Return nRet
	    Endif
    Endif
Next nX

Return nRet

///////////////////////////////////////////////////////////////////////
// Envia email informando a diferenÁa de PESO na DevoluÁ„o de vendas //   
///////////////////////////////////////////////////////////////////////
Static function fEmailDev(cOutrPeso)

	  cEmail :=  GetNewPar("MY_YEMFTDI","expedicao@diaco.com.br,diretoria@diaco.com.br,financeiro@diaco.com.br,fabio.loures@diaco.com.br")	  
	  cEmpr := ""
	  If alltrim(substr(_cEmpresa,1,2))=="01"		    	
	 	cEmpr := "DIA«O"
	  Elseif alltrim(substr(_cEmpresa,1,2))=="02"		    	
		cEmpr := "CIDA"  
	  Endif		

		Msg := " " + chr(13)+chr(10)
		Msg += cEmpr+" - PESO NA DEVOLU«√O DE VENDA VEÕCULO ACIMA DE <B>"+cvaltochar(Getnewpar("MV_YDIFNTA",10))+" KG.</B>"+chr(13)+chr(10)+chr(13)+chr(10)
		Msg += "<B> VEÕCULO PLACA:       </B> "+alltrim(cGetPLACA)+""+chr(13)+chr(10)+chr(13)+chr(10)
	
		Msg += "<B>PESO ENTRADA :     </B>"+Transform(nPESENTR,"@E 99999999")+""+chr(13)+chr(10)  
		Msg += "<B>PESO SAÕDA   :     </B>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp"+Transform(nPESSAID,"@E 99999999")+""+chr(13)+chr(10)+chr(13)+chr(10)
		
		Msg += "<B>PESO LÕQUIDO :     </B>&nbsp&nbsp&nbsp"+Transform(nPLIQ,"@E 99999999")+""+chr(13)+chr(10)  		
		Msg += "<B>PESO NF'S    :     </B>&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp"+Transform(nPNTS,"@E 99999999")+""+chr(13)+chr(10)  		
		If cOutrPeso>0
			Msg += chr(13)+chr(10)+"<B>DiferenÁa encontrada foi de :     </B>&nbsp&nbsp&nbsp"+Transform(nPDIF,"@E 99999999")+" KG"+chr(13)+chr(10) 
			Msg += "<B>Outro(s) peso(s) informado  :     </B>&nbsp&nbsp&nbsp"+Transform(cOutrPeso,"@E 99999999")+" KG"+chr(13)+chr(10)
		Endif		
		Msg += "<font color='red'> EST¡ COM DIFEREN«A DE      <B>  "+Transform(nPDIF-cOutrPeso,"@E 99999999")+" KG </B> a maior. </font>"+chr(13)+chr(10)+chr(13)+chr(10)+chr(13)+chr(10)   		
		//cGetNFS := "" 
		cNFS :=  cGetNFS
		If Empty(alltrim(cNFS)) // Trazendo as notas caso esteja em branco este campo , identificado alguns casos na Cida						
			cQuery := "  	SELECT DISTINCT F2_DOC+'/'+F2_SERIE as DOC "
			cQuery += "  	FROM "+RetSqlName("SF2")+" SF2 (NOLOCK) "
			cQuery += "  	INNER JOIN "+RetSqlName("DA3")+" DA3 (NOLOCK) "
			cQuery += "     ON  DA3.DA3_FILIAL = F2_FILIAL "								
			cQuery += "     AND DA3.DA3_COD = F2_VEICUL1 AND DA3.D_E_L_E_T_='' "												
			cQuery += "  	WHERE  SF2.F2_FILIAL='"+xFilial("SF2")+"' AND SF2.F2_EMISSAO='"+DtoS(dDatabase)+"' AND SF2.D_E_L_E_T_='' "
			cQuery += "  	AND  DA3.DA3_PLACA='"+Alltrim(cGetPLACA)+"' "				
			If Select("QRY") > 0
				QRY->(DbCloseArea())
			EndIf
			TcQuery cQuery New Alias "QRY"
			WHILE !QRY->(EOF())
				cNFS += QRY->DOC+','
				QRY->(dbSkip())
			EndDO 
			cNFS := SUBSTR(Alltrim(cNFS),1,Len(cNFS)-1)
		    QRY->(DbCloseArea())	   	    
		Endif				
		Msg += " TRANSPORTANDO A(S) NF(S): "+cNFS+""+chr(13)+chr(10)+chr(13)+chr(10)
		/////////////////////////////////////////////
		// Traz os Pedidos / Cliente dessa pesagem //
		/////////////////////////////////////////////		
		cQuery := "  	SELECT DISTINCT D2_PEDIDO,D2_CLIENTE , A1_NOME , A1_NREDUZ " 
		cQuery += "  	FROM "+RetSqlName("SD2")+" A (NOLOCK) "
		cQuery += "  	JOIN "+RetSqlName("SA1")+" B (NOLOCK) ON D2_CLIENTE=A1_COD AND D2_LOJA=A1_LOJA AND B.D_E_L_E_T_='' "
		cQuery += "  	WHERE A.D2_FILIAL+A.D2_DOC+A.D2_SERIE IN "+FormatIn(Alltrim(cNFS),",")+" "
		cQuery += "  	AND A.D2_EMISSAO='"+DtoS(dDatabase)+"' AND A.D_E_L_E_T_='' "
		If Select("QRYPEDIDOS") > 0
			QRYPEDIDOS->(DbCloseArea())
		EndIf
		TcQuery cQuery New Alias "QRYPEDIDOS"
		WHILE !QRYPEDIDOS->(EOF())
			Msg += "PEDIDO : "+alltrim(QRYPEDIDOS->D2_PEDIDO)+ " Cliente :" +alltrim(QRYPEDIDOS->A1_NREDUZ)+chr(13)+chr(10)
			QRYPEDIDOS->(dbSkip())			
		EndDO
		QRYPEDIDOS->(DbCloseArea())
		u_fEmail(cEmail,cEmpr+" - PESO VEÕCULO x PESO NF DEVOLU«√O DE VENDA (SUPERIOR a "+cvaltochar(Getnewpar("MV_YDIFNTA",10))+" KG)",Msg+chr(13)+chr(10)+chr(13)+chr(10),.F.)
Return


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Ler o XML e atualizar f1_pliqui da nota                                                                                                           //
// Devido a Central XMl ainda n„o estar em produÁ„o: Identificado a necessidade de criar rotina para atuliazar o PESO LIQUIDO(f1_pliqui) da nota.    //
// Criar rotina para o usu·rio selecionar o XML da nota e atualizar o campo f1_pliqui caso esteja em branco.(Tag no XML: <pesoL>222.000</pesoL>)     //
//Mesmo usando a rotina U_CALPESO, trouxe informaÁ„o zerada. Pois os campos do produto em quest„o estavam zerados: B1_YCOMPRI,B1_YLARGUR. (DIA300)   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Static function fLexml()
 
Local cError := cWarning := cDestinatario := cDataEmissao := ""

cPath := UPPER(cGetFile("Arquivo XML ( *.xml ) |*.xml|","Selecione o Arquivo XML dessa nota de entrada.",,"C:\"))

lEnvSer :=  fEnvServ(cPath)  // Envia para o servidor , apaga primeiro antes caso exista o arquivo


If lEnvSer 
    
    nPOs   := RAT("\", cPath)
	cArqvo := substr(cPath,nPOs+1) // Traz apenas o nome do arquivo selcionado
	
	cNomearq := "\xmlnfe\Balanca\"+cArqvo
	
	oNotaxml := xmlparserfile(cNomearq, "", @cError, @cWarning)

	If cError # "" .or. cWarning # ""
	
	   	cCabc 	:= "BALAN«A - XML Erro"
		cMSg 	:= "ATEN«√O: Erro: "+cError+CHR(13)+CHR(10)
		cMSg 	+= "Aviso:"+cWarning+CHR(13)+CHR(10)	
	    U_fTelAviso(cCabc, cMSg , .F.)  		
	
	Else      
	    cNotaXml  := alltrim(oNotaxml:_nfeProc:_NFe:_infNFe:_ide:_cNF:Text)
	    cSerieXml := alltrim(oNotaxml:_nfeProc:_NFe:_infNFe:_ide:_serie:Text)
	    cFilialNT := nCBoxFilial
		
		If val(cGetNota)==val(cNotaXml)  // Se pertencer a numeraÁ„o da nota -> permite a atualizaÁ„o nesse caso apenas 
		
			cDestinatario := alltrim(oNotaxml:_nfeProc:_NFe:_infNFe:_dest:_xNome:Text)
			cPesoLiq      := alltrim(oNotaxml:_nfeProc:_NFe:_infNFe:_transp:_vol:_pesoL:Text)
			
			If !Empty(cGetNota) .and. !Empty(cFilialNT) .and. val(cPesoLiq)>0
				BEGIN TRANSACTION   
					IncProc("Processando.....")
					cSql := " UPDATE " +RetSqlName("SF1")
					cSql += " SET F1_PLIQUI ="+cPesoLiq+" 	"
					cSql += " WHERE D_E_L_E_T_ = ' ' "
					cSql += " AND F1_FILIAL = '"+cFilialNT+"'	 "
					cSql += " AND F1_DOC = '"+cGetNota+"'	 "	
					cSql += " AND F1_SERIE = '"+cGetSerie+"'	 "					
					TcSqlExec(cSql)		
				END TRANSACTION	
		   		cCabc 	:= "BALAN«A - XML"
				cMSg 	:= "Peso lÌquido :  " +cPesoLiq+" atualizado com sucesso!"+CHR(13)+CHR(10)
				cMSg 	+= "Nota : " +cGetNota+" SÈrie: "+cGetSerie+CHR(13)+CHR(10)
				cMSg 	+= "NumeraÁ„o do XML: "+cNotaXml+" SÈrie: "+cSerieXml+CHR(13)+CHR(10)
				cMSg 	+= "Clique em Incluir a nota com o peso atual."+CHR(13)+CHR(10)
				fRetInf(alltrim(nCBoxFilial),alltrim(cGetNota),cGetSerie,cGetFornec)// Busca  novo valor do peso liquido
		    	U_fTelAviso(cCabc, cMSg , .F.)  		   
	    	Endif
		Else
	   		cCabc 	:= "BALAN«A - XML"
			cMSg 	:= "ATEN«√O: Nota :" +cGetNota+" n„o refere a numeraÁ„o do XML: "+cNotaXml+CHR(13)+CHR(10)
			cMSg 	+= "Encontre o XML correto para atualizar o peso LÌquido."+CHR(13)+CHR(10)
	    	U_fTelAviso(cCabc, cMSg , .F.)  					
	   Endif 
	   
	Endif
	
Endif // Se enviou para servidor	

return(.T.)


//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥Funcao que envia arquivo para Servidor .≥
//≥        F·bio Loures Silveira          .≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
Static Function fEnvServ(cArq)

Local cCamServ   := GETNEWPAR("MV_YCAMBAL","\xmlnfe\Balanca\")  // Caminho onde salva os arquivos no SERVIDO para BalanÁa usar 
	
If Empty(cArq) .OR. !File(cArq)
	Alert('Selecione um arquivo antes de enviar.')
	Return(.F.)
EndIF
	
	nPOs := RAT("\", cArq)
	cArqSrv := cCamServ+"\"+substr(cArq,nPOs+1)  
	If File(cArqSrv)
	   FErase(cArqSrv)   						 // Se j· existir no servidor apaga primeiramente , antes de fazer nova copia
	EndIf

	If CpyT2S( cArq, cCamServ+"\", .T. )        // Copia um arquivo da m·quina onde est· sendo executado o SmartClient, para um diretÛrio no ambiente do servidor, a partir do rootpath.	
		FRENAME ( cCamServ+"\"+Substr(cArq,nPOs+1) , cCamServ+"\"+Substr(cArq,nPOs+1))  				
	Else
		Alert('Erro ao salvar arquivo no servidor.')
		Return(.F.)
	EndIf
	
	cArq := ""

Return(.T.)

///////////////////////////////////////
// Retorna a TARA do veÌculo ativo   //  
//         F·bio Loures 13/06/2017   //
///////////////////////////////////////
Static function fRetTara(cGetPLACA)

Local nTara := 0

cQuery := " SELECT TOP 1 DA3_TARA FROM "+RETSQLNAME("DA3")+" (nolock) "
cQuery += " WHERE DA3_PLACA ='"+alltrim(cGetPLACA)+"' AND	DA3_ATIVO = '1' AND D_E_L_E_T_=' ' "

TcQuery cQuery New Alias "QRYTARA"

If !QRYTARA->(EOF())
  nTara	:= QRYTARA->DA3_TARA	
Endif
QRYTARA->(DbCloseArea())
	
Return(nTara)

/////////////////////////////////////////////////////////////////////////
// Retorna SE existe entrada tempor·ria para essa placa (caso tenha)   //  
//         									F·bio Loures 27/07/2017    //
/////////////////////////////////////////////////////////////////////////
Static function fEntTEMP(cGetPLACA)

Local lRet := .F.


cQuery := " SELECT Z8_PLACA FROM "+RETSQLNAME("SZ8")+" (NOLOCK)"
cQuery += " WHERE Z8_PLACA='"+alltrim(cGetPLACA)+"' "
cQuery += " AND Z8_TPPESA='T'"
cQuery += " AND Z8_DATA BETWEEN CONVERT(varchar, GetDate()-1, 112) AND CONVERT(varchar, GetDate(), 112) " // considera 1 dia anterior atÈ a data corrente
cQuery += " AND d_e_l_e_t_=''"

TcQuery cQuery New Alias "QRYTEMP"

If !QRYTEMP->(EOF())
	  lRet := .T.
Endif
QRYTEMP->(DbCloseArea())
	
Return(lRet)


/////////////////////////////////////////////////////////////////////////
// Retorna PESO da entrada tempor·ria para essa placa (caso tenha)     //  
//         									F·bio Loures 28/07/2017    //
/////////////////////////////////////////////////////////////////////////
Static function fPesoTEMP(cGetPLACA)

Local nPeso := 0


cQuery := " SELECT Z8_PESO FROM "+RETSQLNAME("SZ8")+" (NOLOCK)"
cQuery += " WHERE Z8_PLACA='"+alltrim(cGetPLACA)+"' "
cQuery += " AND Z8_TPPESA='T'"
cQuery += " AND Z8_DATA BETWEEN CONVERT(varchar, GetDate()-1, 112) AND CONVERT(varchar, GetDate(), 112) " // considera 1 dia anterior atÈ a data corrente
cQuery += " AND d_e_l_e_t_=''"

TcQuery cQuery New Alias "QRYPESO"

If !QRYPESO->(EOF())
	  nPeso := QRYPESO->Z8_PESO
Endif
QRYPESO->(DbCloseArea())
	
Return(nPeso)


///////////////////////////////////////////////////////////////////////////////
// Retorna a NUAMERA«√O DA Entrada tempor·ria para essa placa (caso tenha)   //  
//         									F·bio Loures 28/07/2017          //
///////////////////////////////////////////////////////////////////////////////
Static function fNumTEMP(cGetPLACA)

Local nrPeso := 0


cQuery := " SELECT Z8_NRPESA FROM "+RETSQLNAME("SZ8")+" (NOLOCK)"
cQuery += " WHERE Z8_PLACA='"+alltrim(cGetPLACA)+"' "
cQuery += " AND Z8_TPPESA='T'"
cQuery += " AND Z8_DATA BETWEEN CONVERT(varchar, GetDate()-1, 112) AND CONVERT(varchar, GetDate(), 112) " // considera 1 dia anterior atÈ a data corrente
cQuery += " AND d_e_l_e_t_=''"

TcQuery cQuery New Alias "QRYPESO"

If !QRYPESO->(EOF())
	  nrPeso := QRYPESO->Z8_NRPESA
Endif
QRYPESO->(DbCloseArea())
	
Return(nrPeso)