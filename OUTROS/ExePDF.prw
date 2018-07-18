#include "PROTHEUS.CH"
#include "rwmake.ch"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"
#include "APWEBEX.CH"
#INCLUDE "FWPrintSetup.ch"
#include "ap5mail.ch"
#include "tbiconn.ch"
#include "tbicode.ch"
#include "topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณGT1649  บAutor  ณPatricia Euz้bio    บ Data ณ  12/07/2016   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Formulแrio de Declara็ใo de Devolu็ใo				      บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso Exclusivo Gertec Servi็os   			                              บฑฑ
ฑฑบInclusใo da TES 708									Patricia 27/07/17 บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

User Function GT1649()


Local aCA       :={OemToAnsi("Confirma"),OemToAnsi("Abandona")}
Local cCadastro := OemToAnsi("Impressao de solicita็ใo")
Local aSays:={}, aButtons:={}
Local nOpca     := 0
Local cMsg := ""
Local lOk := .F.

//ฺฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฟ
//ณ Variaveis tipo Private padrao de todos os relatorios         ณ
//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู
Private aReturn    := {OemToAnsi('Zebrado'), 1,OemToAnsi('Administracao'), 2, 2, 1, '',1 } // ###
Private nLastKey   := 0
Private cPerg      := "GT1649"
Private _nItem     := 0
//ValidPerg()
//ValEstrut()

Pergunte(cPerg,.F.)

//ภฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤู

AADD(aSays,OemToAnsi( "  Este programa ira imprimir a Solicita็ใo"))
AADD(aSays,OemToAnsi( "obedecendo os parametros escolhidos pelo cliente.          "))

AADD(aButtons, { 5,.T.,{|| Pergunte(cPerg,.T. ) } } )
AADD(aButtons, { 1,.T.,{|| nOpca := 1,FechaBatch() }} )
AADD(aButtons, { 2,.T.,{|| nOpca := 0,FechaBatch() }} )

FormBatch( cCadastro, aSays, aButtons )
If nOpca == 1
	Processa( { |lEnd| ImpND() })
EndIf

Return .T.


Static Function ImpND()
#DEFINE DMPAPER_A4 9 	// A4 210 x 297 mm


Local cCont := space(50)
Local cMail := space(100)
Local oDlg
Local cUpd := ""
Local cQry := ""
Local cQtde  := MV_PAR03
Loca nVlrtot := 0


Private nHeight:=15
Private lBold:= .F.
Private lUnderLine:= .F.
Private lPixel:= .T.
Private lPrint:=.F.
Private oFont1:= TFont():New( "Verdana",,26,,.t.,,,,,.f. )
Private oFont2:= TFont():New( "Times New Roman",,14,,.t.,,,,,.f. ) //Verdana 09 Normal
Private oFont3:= TFont():New( "Times New Roman",,14,,.f.,,,,,.f. ) //Verdana 09 negrito
Private oFont4:= TFont():New( "Verdana",,10,,.t.,,,,,.f. ) //verdana tamanho 12 negrito
Private oFont5:= TFont():New( "Times New Roman",,12,,.f.,,,,,.f. ) //verdana 10 negrito
Private oFont6:= TFont():New( "Verdana",,6,,.f.,,,,,.f. ) //verdana 10 negrito
Private oFont7:= TFont():New( "Verdana",,9,,.f.,,,,,.f. ) //verdana 10 negrito
Private oFont8:= TFont():New( "Times New Roman",,16,,.f.,,,,,.f. ) //verdana 10 negrito
Private oPrn
Private nPag:=1
Private nTPag:= SC5->(FCount())
Private nLin:= 80
Private nValorReparo:= 0
Private nValorTotal:= 0
Private nValorFrete:= 0
Private cQuery := ""
Private nCount := 1
Private cCodPg:= ""
Private lImp := .T.
Private nImp := 0
Private cNOs := ""
Private nValorTotal:= 0

oPrn:=FwMSPrinter():New(MV_PAR01+"_"+MV_PAR02,6,.T.,,.T.)


cNOs := SF2->F2_DOC

oPrn:SetPortrait()					// Modo retrato
oPrn:SetPaperSize(9)					// Papel A4


   	cQuery := " SELECT CASE WHEN D2_TES ='506'  THEN 'RETORNO DE CONSERTO'" +CRLF
   	cQuery += " 			WHEN D2_TES ='529'  THEN 'RETORNO REM. P/ EMPRESTIMO'   " +CRLF
  	cQuery += " 			WHEN D2_TES ='576'  THEN 'RETORNO REM.LOCACAO'  " +CRLF
  	cQuery += " 			WHEN D2_TES ='580'  THEN 'RETORNO REMESSA P/EMPRESTIMO'   " +CRLF
  	cQuery += " 			WHEN D2_TES ='620'  THEN 'RETORNO CONTRATO COMODATO' " +CRLF
    cQuery += " 			WHEN D2_TES ='627'  THEN 'RETORNO CONTRATO COMODATO'  " +CRLF
   	cQuery += " 			WHEN D2_TES ='689'  THEN 'RETORNO REM. TROCA  GARANTIA'  " +CRLF
   	cQuery += "    	    	WHEN D2_TES ='708'  THEN 'COMODATO/LOCACAO' END AS TES," +CRLF
   	cQuery += " * FROM "+RETSQLNAME("SD2")+" D2 " +CRLF
   	cQuery += " INNER JOIN " +Retsqlname("SF2")+ " SF2 " +CRLF
	cQuery += " ON SF2.F2_FILIAL = D2.D2_FILIAL " +CRLF
	cQuery += " AND SF2.F2_DOC = D2.D2_DOC " +CRLF
	cQuery += " AND SF2.F2_SERIE = D2.D2_SERIE " +CRLF
	cQuery += " AND SF2.F2_CLIENTE = D2.D2_CLIENTE " +CRLF
	cQuery += " AND SF2.F2_LOJA = D2.D2_LOJA  " +CRLF
	cQuery += " AND SF2.D_E_L_E_T_ = '' " +CRLF
	cQuery += " INNER JOIN "+RetSqlName("SA1")+" SA1 " +CRLF
	cQuery += " ON SA1.A1_COD=SF2.F2_CLIENTE  " +CRLF
	cQuery += " AND SA1.A1_LOJA=SF2.F2_LOJA  " +CRLF
	cQuery += " AND SA1.D_E_L_E_T_='' " +CRLF
	cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 " +CRLF
	cQuery += " ON B1_COD = D2_COD " +CRLF
	cQuery += " AND B1.D_E_L_E_T_ = '' " +CRLF
	cQuery += " AND B1_FILIAL = '" + xFilial("SB1") + "'" +CRLF
   	cQuery += " WHERE D2_DOC = '"+mv_par01+"' "
   	cQuery += " AND D2_SERIE =  	'"+mv_par02+"' "
	cQuery += " AND D2.D_E_L_E_T_ = ' ' "
	cQuery += " AND D2_TES IN ('620','627','506','687','576','529','580','708')	" +CRLF
	cQuery += "	ORDER BY D2_ITEM 	" +CRLF

	 If Select("TMPF") > 0
			TMPF->(DbCloseArea())
	 Endif

	 TcQuery cQuery New Alias "TMPF"

	 TMPF->(dbGoTop())

	 If nImp > 0
	 	lImp := .F.
	 EndIf

   	nPag++
	nLin := 0

	if nPag<>1	&& Fim de Pagina
		oPrn:EndPage()
		oPrn:StartPage()
	endif

	nLin := nLin + 100
	//Pego o logotipo da empresa selecionada.
   //	_cBitMap:= "lgrl02.bmp"             // Logotipo da empresa
	oPrn:Line(nLin,0010,nLin,2400)
	oPrn:Line(nLin,0010,3000,0010)
	oPrn:Line(nLin,2400,3000,2400)
	oPrn:Line(3370,0010,3370,2400)

	nLin += 50
	//oPrn:SayBitmap(nLin,0040,_cBitMap,350,250)
	nLin += 80
	oPrn:Say(nLin+40,0990,"SOLICITAวรO" ,oFont1,100)

	oPrn:Line(0400,0010,0400,2400)

	nLin += 80
  	nLin += 80
 	oPrn:Say(nLin,1900,"Data: " ,oFont2,100)
  	oPrn:Say(nLin,2030,DTOC(DDATABASE),oFont3,100)


	nLin += 80
	oPrn:Say(nLin+20,0040,"Empresa: " ,oFont2,100)
	oPrn:Say(nLin+20,0195,TMPF->A1_NOME ,oFont3,100)
	oPrn:Say(nLin+20,1095,"I.E: " ,oFont2,100)
	oPrn:Say(nLin+20,1170,TMPF->A1_INSCR ,oFont3,100)
	oPrn:Say(nLin+20,1800,"CNPJ: " ,oFont2,100)
	oPrn:Say(nLin+20,1920,Transform(TMPF->A1_CGC, "@R 99.999.999/9999-99") ,oFont3,100)
	nLin += 80
 	oPrn:Say(nLin,0040,"Estabelecida: " ,oFont2,100)
	oPrn:Say(nLin,0257,TMPF->A1_END ,oFont3,100)
	oPrn:Say(nLin,1095,"Bairro: " ,oFont2,100)
	oPrn:Say(nLin,1220,TMPF->A1_BAIRRO  ,oFont3,100)
	oPrn:Say(nLin,1800,"Municํpio: " ,oFont2,100)
	oPrn:Say(nLin,1980,TMPF->A1_MUN ,oFont3,100)
	nLin += 70
  	oPrn:Say(nLin,0040,"Cep: " ,oFont2,100)
	oPrn:Say(nLin,0120,Transform(TMPF->A1_CEP, "@R 99999-999") ,oFont3,100)
	oPrn:Say(nLin,1095,"Estado: " ,oFont2,100)
	oPrn:Say(nLin,1225,TMPF->A1_EST ,oFont3,100)

    nLin +=80

    oPrn:Line(nLin,0010,nLin,2400)

 	nLin +=80
 	nLin +=80
	oPrn:Say(nLin,0220,"A empresa Gertec Servi็os Ltda, inscrita no CNPJ sob o Nบ 35.819.226/0001-01 e Inscr. Estadual Nบ 286.146.250.119," ,oFont8,100)
	nLin += 80
	oPrn:Say(nLin,0220,"estabelecida เ Rua Guaicurus nบ 145 - Vila Concei็ใo - Diadema - SP, vem por meio desta solicitar ao Cliente," ,oFont8,100)
	nLin += 80
	oPrn:Say(nLin,0220,"a providencia do "+ALLTRIM(TMPF->TES)+" , atrav้s do documento Nota Fiscal modelo 55, 1 ou 1 A,",oFont8,100)
	nLin +=80
	oPrn:Say(nLin,0220,"dos equipamentos disponibilizado pela empresa acima citada.",oFont8,100)
   	nLin +=80

	oPrn:Line(nLin,0020,nLin,2400)

    nLin += 80


    TMPF->(dbGoTop())
	While TMPF->(!Eof())
	  nValorTotal += TMPF->D2_TOTAL
		If  nCount == 1
			nValorTotal += TMPF->D2_TOTAL
			nCount++
		EndIf
		TMPF->(DbSkip())
	EndDo


	oPrn:Say(nLin,0011,"   ITEM                 NOTA                    SษRIE        EMISSAO        QTDE.             CำDIGO                                                    DESCRIวรO                                                   VALOR UNIT.        VALOR TOTAL",oFont5,100)
	TMPF->(DbGoTop())// 0         1         2         3         4         5         6         7         8         9         10        11        12        13        14        15        16
	oPrn:Line(nLin,0010,nLin,2400)
   	oPrn:Line(3000,0010,3000,2400)
	While TMPF->(!Eof())

	    	nLin += 50
			oPrn:Say(nLin,0045,TMPF->D2_ITEM    ,oFont7,100)
		   	nLin -= 50
			oPrn:Line(nLin,0140,2000,0140)
			nLin += 50
			oPrn:Say(nLin,0220,TMPF->D2_DOC    ,oFont7,100)
		   	nLin -= 50
			oPrn:Line(nLin,0430,2000,0430)
			nLin += 50
			oPrn:Say(nLin,0480,TMPF->D2_SERIE   ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,0550,2000,0550)
			nLin += 50
			oPrn:Say(nLin,0580,substr(TMPF->D2_EMISSAO,7,8) + '/' + substr(TMPF->D2_EMISSAO,5,2) + '/' + substr(TMPF->D2_EMISSAO,1,4)   ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,0730,2000,0730)
			nLin += 50
			oPrn:Say(nLin,0750,(Transform(cQtde,"@E@ 99999")) ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,0890,2000,0890)
			nLin += 50
			oPrn:Say(nLin,0900,TMPF->D2_COD  ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,1080,2000,1080)
			nLin += 50
		  	oPrn:Say(nLin,1100,TMPF->B1_DESC ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,4000,2000,4000)

			nLin += 50
			oPrn:Say(nLin,01916,"R$ "+Alltrim(Transform(TMPF->D2_PRCVEN,"@E@ 99,999,999.99"))  ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,1900,2000,1900)

			nLin += 50
			oPrn:Say(nLin,02159,"R$ "+Alltrim(Transform((TMPF->D2_PRCVEN * cQtde),"@E@ 99,999,999.99"))  ,oFont7,100)
			nLin -= 50
			oPrn:Line(nLin,2150,2000,2150)

	       //	nVlrtot += TMPF->D2_TOTAL
	       nVlrtot += (TMPF->D2_PRCVEN * cQtde)

	    	nLin += 50
	   	TMPF->(DbSkip())
		If nLin >= 2800
			oPrn:EndPage()
			oPrn:StartPage()
		   	nLin := 50
			oPrn:Line(nLin,0010,3370,0010)
			oPrn:Line(nLin,2400,3370,2400)
		EndIf
	Enddo
	oPrn:Line(2000,0010,2000,2400)
   	nLin := 2050
   	oPrn:Say(nLin,01900,"TOTAL R$      "+Alltrim(Transform(nVlrtot,"@E@ 99,999,999.99"))  ,oFont8,100)
   	nLin += 30
   	oPrn:Line(nLin,0010,nLin,2400)
   	oPrn:Line(3000,0010,3000,2400)
  	nLin += 150
	If nLin >= 2800
		oPrn:EndPage()
		oPrn:StartPage()
		nLin := 50
		oPrn:Line(nLin,0010,3370,0010)
		oPrn:Line(nLin,2400,3370,2400)
       	nLin += 50
    	oPrn:Line(3000,0010,3000,2400)
		nLin += 100
		oPrn:Say(nLin,0220,"Na falta do documento mencionado acima, pedimos a gentileza de protocolar esta solicita็ใo e fazer a" ,oFont8,100)
	   	nLin += 80
	   	oPrn:Say(nLin,0220,"devolu็ใo da mesma, para que possamos tomar as devidas provid๊ncias, conforme artigo 136 do RICMS/SP." ,oFont8,100)
	   	nLin += 120
   		oPrn:Say(nLin,0680,"__________________________________" ,oFont8,100)
   		nLin += 80
	   	oPrn:Say(nLin,0800,"Assinatura/Data/Carimbo" ,oFont8,100)
	else

    	oPrn:Line(3000,0010,3000,2400)
		oPrn:Say(nLin,0220,"Na falta do documento mencionado acima, pedimos a gentileza de protocolar esta solicita็ใo e fazer a" ,oFont8,100)
	   	nLin += 80
	   	oPrn:Say(nLin,0220,"devolu็ใo da mesma, para que possamos tomar as devidas provid๊ncias, conforme artigo 136 do RICMS/SP." ,oFont8,100)
	   	nLin += 120
   		oPrn:Say(nLin,0680,"__________________________________" ,oFont8,100)
   		nLin += 80
	   	oPrn:Say(nLin,0800,"Assinatura/Data/Carimbo" ,oFont8,100)


	endif

//oPrn:Preview()    //ALTERADO PARA TRATAR ERRO APRESENTADO APOS ATUALIZAวรO    18/06/15 PATRICIA

makedir("c:\solicitacao\") //cria pasta recibo no c: caso nใo exista
oPrn:cPathPDF := "C:\solicitacao\"  //salva o pdf na pasta recibo
oPrn:SetViewPdf(.T.) // Nใo exibe o preview            //ALTERADO PARA .T.   //18/06/15 PATRICIA
oPrn:Preview()    //fun็ใo que gera o arquivo em pdf para salvar no diretorio c:
//CpyT2S("C:\solicitacao\"+MV_PAR01+"_"+MV_PAR02+".pdf","\system\solicitacao")  //copia de arquivo da maquina local para o servidor
//CpyS2T("\system\solicitacao\"+MV_PAR01+"_"+MV_PAR02+".pdf","X:\")


  /*	If MsgYesNo("Deseja Enviar Solicita็ใo por E-mail?")


		DEFINE MSDIALOG oDlg TITLE "Informa็๕es Contato" From 000,000 To 150,400 OF oMainWnd PIXEL //Cria Tela

			@ 010,005 Say "Contato: "
			@ 010,030 MsGet cCont Size 100,10 Of oDlg Pixel
			@ 025,005 Say "E-Mail: "
			@ 025,030 MsGet cMail  Size 100,10 Of oDlg Pixel

			@ 040,005 BUTTON "Confirmar" SIZE 026, 011 PIXEL OF oDlg ACTION Close(oDlg)

		ACTIVATE MSDIALOG oDlg CENTERED //ON INIT EnchoiceBar(oDlg,bOk,bcancel,,aBotao)

   			cMsg := "	<html>                   "
			cMsg += "		<body>               "
			cMsg += "			<div>            "
			cMsg += "				&nbsp;</div>"
		   //	cMsg += " <P><IMG src='http://www.gertec.com.br/cabecalho_field.jpg' width=594px height=127px border='0'></P> "
			cMsg += "			<div>"
			cMsg += "				<span style='font-size:18px;'>Prezado Cliente: <face='Verdana, Arial, Helvetica, sans-serif'><b>"+AllTrim(cCont)+",</b></span></div>"
			cMsg += "			<div>                                                 "
			cMsg += "				&nbsp;</div>                                     "
			cMsg += " <br></br>  "
			cMsg += "			<div>"
			cMsg += "				<span style='font-size:18px;'>Segue Solicita็ใo: <face='Verdana, Arial, Helvetica, sans-serif'><b>"+MV_PAR01+"_"+MV_PAR02+"</b></span></div>"
			cMsg += "			<div>                                                 "
			cMsg += "				&nbsp;</div>                                     "
			cMsg += " <br></br>  "
			cMsg += "			<div>                                               "
			cMsg += "				<span style='font-size:18px;'>Para aprova็ใo / reprova็ใo entrar em contato via email orcamentos.dia@gertec.com.br</span></div>"
			cMsg += "			<div>                                   "
			cMsg += "				&nbsp;</div>                       "
	   		cMsg += "			<div>                                               "
			cMsg += "				<span style='font-size:18px;'></span></div>"
			cMsg += "			<div>                                   "
			cMsg += "				&nbsp;</div>                       "
			cMsg += " <br></br>  "
			cMsg += "			<div>                                               "
			cMsg += "				<span style='font-size:18px;'>D๚vida ou esclarecimentos, entrar em contato com a equipe da Assist๊ncia T้cnica Gertec atrav้s de nosso telefone ou e-mail (Tel.: 55 11 2173-6500 ou orcamentos.dia@gertec.com.br)</span></div>"
			cMsg += "			<div>                                   "
			cMsg += "				&nbsp;</div>                       "
	   		cMsg += "			<div>                                               "
			cMsg += "				<span style='font-size:18px;'></span></div>"
			cMsg += "			<div>                                   "
			cMsg += "				&nbsp;</div>                       "
			cMsg += " <br></br>  "
			cMsg += " <br></br>  "
			cMsg += " <br></br>  "
			//cMsg += "<a href='http://www.gertec.com.br'> "
		  //	cMsg += "<IMG src='http://www.gertec.com.br/rodape_field.jpg' alt='descri็ใo' title'descri็ใo' width=599px height=242px border='0'>  "
			cMsg += "			<div>                                 "
			cMsg += "				<span style='font-size:16px;'></a> </span></div>           "
			cMsg += "			<div>                                   "
			cMsg += "				&nbsp;</div>                       "
			cMsg += "			<div>                                 "
			cMsg += "				<span style='font-size:16px;'> </span></div>           "
			cMsg += "			<div>                               "
			cMsg += "				&nbsp;</div>                   "
			cMsg += "						</tr>
			cMsg += "					</thead>


	 //	lOk := U_GT1655(cMail,cMsg,"\system\solicitacao\"+MV_PAR01+"_"+MV_PAR02+".pdf")

	EndIf  */

FERASE("\system\solicitacao\"+MV_PAR01+"_"+MV_PAR02+".pdf")

Return .T.



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
		ฑฑบPrograma  ณGT1655   บAutor Patricia Euz้bio บ Data ณ 22/07/2016 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Fun็ใo que envia email do formulแrio                       บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ Gertec Servi็os                                            บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

/*USER FUNCTION GT1655(cPara,cMsg,cArquivo)

Local cSrv 	:= GetMV("MV_RELSERV")
Local cMail := GetMV("GR_SOLIONS")  //EMAIL QUE SERม UTILIZADO PARA ENVIO
Local cPass := GetMV("GR_PASSONS")  //SENHA EMAIL
Local lAuth	:= GetMV("MV_RELAUTH")
Local cPswa	:= GetMV("MV_RELAPSW")
Local cDir := cArquivo

Local cDe		:= cMail
Local cCC      	:= "patricia.silva@gertec.com.br"
Local cCCO	    := ""	//c๓pia oculta


//Conectando ao servidor SMTP
CONNECT SMTP SERVER cSrv;  	//Nome do Servidor
		ACCOUNT cMail; 		//Conta de email
		PASSWORD cPass;    	//Senha de Conexao
		RESULT lResult    	//Resultado da conexao

lOk := MailAuth(cMail,cPass)

//MENSAGEM PARA VERIFICAR NO MONITOR ---------------------------------------------------------------------------------------------------------------
CONOUT("---------- EMAIL DE ORCAMENTO PARA CLIENTE ----------")
CONOUT("---------- ENVIANDO EMAIL PARA: ("+cPara+") ----------")

//ATRIBUI RETORNO DE ENVIO DE EMAIL NA VARIAVEL cError
GET MAIL ERROR cError

//ENVIO DO EMAIL

SEND MAIL FROM cDe TO cPara SUBJECT "SOLICITAวรO GERTEC";    //BCC cCCO copia oculta
		  BODY cMsg ATTACHMENT cDir RESULT lRetorno
//DESCONECTA DO SERVIDOR


DISCONNECT SMTP SERVER

Return .T.    */
