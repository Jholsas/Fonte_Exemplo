#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

User Function MyMata920()
Local aCabec := {}
Local aItens := {}
Local aLinha := {}
Local nX     := 0
Local nY     := 0
Local cDoc   := ""
Local lOk    := .T.
PRIVATE lMsErroAuto := .F.

//-- Abertura do ambiente
ConOut(Repl("-",80))
ConOut(PadC("Teste de Inclusao de 10 documentos de entrada com 30 itens cada",80))

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FIS" TABLES "SF2","SD2","SA1","SA2","SB1","SB2","SF4"

dbSelectArea("SB1")
dbSetOrder(1)
If !SB1->(MsSeek(xFilial("SB1")+"PA001"))
 lOk := .F.
 ConOut("Cadastrar produto: PA001")
EndIf
dbSelectArea("SF4")
dbSetOrder(1)
If !SF4->(MsSeek(xFilial("SF4")+"501"))
 lOk := .F.
 ConOut("Cadastrar TES: 501")
EndIf
dbSelectArea("SE4")
dbSetOrder(1)
If !SE4->(MsSeek(xFilial("SE4")+"001"))
 lOk := .F.
 ConOut("Cadastrar condicao de pagamento: 001")
EndIf
dbSelectArea("SA1")
dbSetOrder(1)
If !SA1->(MsSeek(xFilial("SA1")+PADR("CL0001",Len(SA1->A1_COD))+"01"))
 lOk := .F.
 ConOut("Cadastrar cliente: CL000101")
EndIf
If lOk
 ConOut("Inicio: "+Time())
 //-- Verifica o ultimo documento valido para um fornecedor
 dbSelectArea("SF2")
 dbSetOrder(2)
 MsSeek(xFilial("SF2")+Padr("CL0001",Len(SA1->A1_COD))+"01z",.T.)
 dbSkip(-1)
 cDoc := SF2->F2_DOC
 For nY := 1 To 10
  aCabec := {}
  aItens := {}

  If Empty(cDoc)
   cDoc := StrZero(1,Len(SD2->D2_DOC))
  Else
   cDoc := Soma1(cDoc)
  EndIf
  aadd(aCabec,{"F2_TIPO"   ,"N"})
  aadd(aCabec,{"F2_FORMUL" ,"N"})
  aadd(aCabec,{"F2_DOC"    ,(cDoc)})
  aadd(aCabec,{"F2_SERIE"  ,"UNI"})
  aadd(aCabec,{"F2_EMISSAO",dDataBase})
  aadd(aCabec,{"F2_CLIENTE",Padr("CL0001",Len(SA1->A1_COD))})
  aadd(aCabec,{"F2_LOJA"   ,"01"})
  aadd(aCabec,{"F2_ESPECIE","NF"})
  aadd(aCabec,{"F2_COND","001"})
  aadd(aCabec,{"F2_DESCONT",0})
  aadd(aCabec,{"F2_FRETE",0})
  aadd(aCabec,{"F2_SEGURO",0})
  aadd(aCabec,{"F2_DESPESA",0})
  If cPaisLoc == "PTG"
   aadd(aCabec,{"F2_DESNTRB",0})
   aadd(aCabec,{"F2_TARA",0})
  Endif
  For nX := 1 To 30
   aLinha := {}
   aadd(aLinha,{"D2_COD"  ,"PA001",Nil})
   aadd(aLinha,{"D2_ITEM" ,StrZero(nX,2),Nil})
   aadd(aLinha,{"D2_QUANT",1,Nil})
   aadd(aLinha,{"D2_PRCVEN",100,Nil})
   aadd(aLinha,{"D2_TOTAL",100,Nil})
   aadd(aLinha,{"D2_TES","501",Nil})
   aadd(aItens,aLinha)
  Next nX
  //-- Teste de Inclusao
  MATA920(aCabec,aItens)
  If !lMsErroAuto
   ConOut("Incluido com sucesso! "+cDoc)
  Else
   MostraErro()
   ConOut("Erro na inclusao!")
  EndIf
 Next nY
 ConOut("Fim  : "+Time())
 //-- Teste de exclusao
 /*aCabec := {}
 aItens := {}
 aadd(aCabec,{"F2_TIPO"   ,"N"})
 aadd(aCabec,{"F2_FORMUL" ,"N"})
 aadd(aCabec,{"F2_DOC"    ,(cDoc)})
 aadd(aCabec,{"F2_SERIE"  ,"UNI"})
 aadd(aCabec,{"F2_EMISSAO",dDataBase})
 aadd(aCabec,{"F2_FORNECE","F00001"})
 aadd(aCabec,{"F2_LOJA"   ,"01"})
 aadd(aCabec,{"F2_ESPECIE","NFE"})
 aadd(aCabec,{"F2_DESCONT",0})
 aadd(aCabec,{"F2_FRETE",10})
 aadd(aCabec,{"F2_SEGURO",20})
 aadd(aCabec,{"F2_DESPESA",30})
 If cPaisLoc == "PTG"
  aadd(aCabec,{"F2_DESNTRB",40})
  aadd(aCabec,{"F2_TARA",50})
 Endif
 For nX := 1 To 30
  aLinha := {}
  aadd(aLinha,{"D2_ITEM",StrZero(nX,Len(SD1->D1_ITEM)),Nil})
  aadd(aLinha,{"D2_COD","PA002",Nil})
  aadd(aLinha,{"D2_QUANT",2,Nil})
  aadd(aLinha,{"D2_PRCVEN",100,Nil})
  aadd(aLinha,{"D2_TOTAL",200,Nil})
  aadd(aItens,aLinha)
 Next nX
 //-- Teste de Exclusao
 ConOut(PadC("Teste de exclusao",80))
 ConOut("Inicio: "+Time())
 MATA920(aCabec,aItens,5)
 If !lMsErroAuto
  ConOut("Exclusao com sucesso! "+cDoc)
 Else
  MostraErro()
  ConOut("Erro na exclusao!")
 EndIf
 ConOut("Fim  : "+Time())
 ConOut(Repl("-",80))
EndIf*/

RESET ENVIRONMENT

Return(.T.)

Static Function ProcH(cCampo)
Return aScan(aAutoCab,{|x|Trim(x[1])== cCampo })
