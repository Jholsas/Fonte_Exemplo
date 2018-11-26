#INCLUDE "RWMAKE.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "tbiconn.CH"

User Function MyMata120()

Local aCabec  := {}
Local aItens  := {}
Local aLinha  := {}
Local aLinRat := {}
Local aRatCC  := {}
Local aItemCC := {}
Local aRateio := {}
Local nX := 0
Local nY := 0
Local cDoc := ""
Local lOk := .T.

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FAT" TABLES "SC7","SCH"

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Abertura do ambiente |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
ConOut(Repl("-",80))
ConOut(PadC("Teste de Inclusao de 10 pedidos de compra com 30 itens cada",80))


//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Verificacao do ambiente para teste |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
dbSelectArea("SB1")
dbSetOrder(1)
If !SB1->(MsSeek(xFilial("SB1")+"PA0001         "))
lOk := .F.
ConOut("Cadastrar produto: PA0001         ")
EndIf
dbSelectArea("SF4")
dbSetOrder(1)
If !SF4->(MsSeek(xFilial("SF4")+"001"))
lOk := .F.
ConOut("Cadastrar TES: 001")
EndIf
dbSelectArea("SE4")
dbSetOrder(1)
If !SE4->(MsSeek(xFilial("SE4")+"001"))
lOk := .F.
ConOut("Cadastrar condicao de pagamento: 001")
EndIf
If !SB1->(MsSeek(xFilial("SB1")+"PA0001         "))
lOk := .F.
ConOut("Cadastrar produto: PA0001         ")
EndIf
dbSelectArea("SA2")
dbSetOrder(1)
If !SA2->(MsSeek(xFilial("SA2")+"000001"))
lOk := .F.
ConOut("Cadastrar fornecedor: 000001")
EndIf
If lOk
ConOut("Inicio: "+Time())
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Verifica o ultimo documento valido para um fornecedor |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
dbSelectArea("SC7")
dbSetOrder(1)
MsSeek(xFilial("SC7")+"zzzzzz",.T.)
dbSkip(-1)
cDoc := SC7->C7_NUM
For nY := 1 To 1
aCabec := {}
aItens := {}

If Empty(cDoc)
cDoc := StrZero(1,Len(SC7->C7_NUM))
Else
cDoc := Soma1(cDoc)
EndIf

aadd(aCabec,{"C7_NUM" ,cDoc})
aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
aadd(aCabec,{"C7_FORNECE" ,"000001"})
aadd(aCabec,{"C7_LOJA" ,"01"})
aadd(aCabec,{"C7_COND" ,"001"})
aadd(aCabec,{"C7_CONTATO" ,"AUTO"})
aadd(aCabec,{"C7_FILENT" ,cFilAnt})

For nX := 1 To 1
aLinha := {}
aadd(aLinha,{"C7_PRODUTO" ,"PA0001",Nil})
aadd(aLinha,{"C7_QUANT" ,1 ,Nil})
aadd(aLinha,{"C7_PRECO" ,100 ,Nil})
aadd(aLinha,{"C7_TOTAL" ,100 ,Nil})
aadd(aLinha,{"C7_TES" ,"001" ,Nil})
aadd(aItens,aLinha)
Next nX

// Monta itens rateio
aAdd(aRatCC,{"0001",{ }})

// Primeiro item do rateio
aAdd(aItemCC,{"CH_ITEM",StrZero(1,Len(SCH->CH_ITEM)),NIL})
aAdd(aItemCC,{"CH_PERC",100,NIL}) // Percentual a ser ratiado.
aAdd(aItemCC,{"CH_CC","000000001",NIL}) //centro de custo do primeiro Item.
aAdd(aRatCC[1][2],aItemCC)

// Segundo item do rateio
//aItemCC :={ }
//aAdd(aItemCC,{"CH_ITEM",StrZero(2,Len(SCH->CH_ITEM)),NIL})
//aAdd(aItemCC,{"CH_PERC",40,NIL}) // Percentual a ser ratiado.
//aAdd(aItemCC,{"CH_CC","222222",NIL}) //centro de custo do segundo Item.
//aAdd(aRatCC[1][2],aItemCC)

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Teste de Inclusao |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
MSExecAuto({|k,v,w,x,y,z| MATA120(k,v,w,x,y,z)},1,aCabec,aItens,3,,aRatCC)

If !lMsErroAuto
ConOut("Incluido com sucesso! "+cDoc)
Else
ConOut("Erro na inclusao!")
MostraErro()
EndIf
Next nY
ConOut("Fim : "+Time())

//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Teste de Alteracao |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
/*aCabec := {}
aItens := {}
aadd(aCabec,{"C7_NUM" ,cDoc})
aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
aadd(aCabec,{"C7_FORNECE" ,"F00001"})
aadd(aCabec,{"C7_LOJA" ,"01"})
aadd(aCabec,{"C7_COND" ,"001"})
aadd(aCabec,{"C7_CONTATO" ,"AUTO"})
aadd(aCabec,{"C7_FILENT" ,cFilAnt})

For nX := 1 To 1
aLinha := {}
aadd(aLinha,{"C7_ITEM",StrZero(nX,Len(SC7->C7_ITEM)),Nil})
aadd(aLinha,{"C7_PRODUTO","PA001",Nil})
aadd(aLinha,{"C7_QUANT",2,Nil})
aadd(aLinha,{"C7_PRECO",200,Nil})
aadd(aLinha,{"C7_TOTAL",400,Nil})

aadd(aLinha,{"C7_REC_WT" ,SC7->(RECNO()) ,Nil})

aadd(aItens,aLinha)
Next nX
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Teste de alteracao |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
/*ConOut(PadC("Teste de alteracao",80))
ConOut("Inicio: "+Time())
MATA120(1,aCabec,aItens,4)

If !lMsErroAuto
ConOut("Alteracao com sucesso! "+cDoc)
Else
ConOut("Erro na Alteracao!")
EndIf
ConOut("Fim : "+Time())
ConOut(Repl("-",80))
*/
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Teste de exclusao |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
/*aCabec := {}
aItens := {}
aadd(aCabec,{"C7_NUM" ,cDoc})
aadd(aCabec,{"C7_EMISSAO" ,dDataBase})
aadd(aCabec,{"C7_FORNECE" ,"F00001"})
aadd(aCabec,{"C7_LOJA" ,"01"})
aadd(aCabec,{"C7_COND" ,"001"})
aadd(aCabec,{"C7_CONTATO" ,"AUTO"})
aadd(aCabec,{"C7_FILENT" ,cFilAnt})

For nX := 1 To 10
aLinha := {}
aadd(aLinha,{"C7_ITEM",StrZero(nX,Len(SC7->C7_ITEM)),Nil})
aadd(aLinha,{"C7_PRODUTO","PA001",Nil})
aadd(aLinha,{"C7_QUANT",2,Nil})
aadd(aLinha,{"C7_PRECO",100,Nil})
aadd(aLinha,{"C7_TOTAL",200,Nil})

aadd(aLinha,{"C7_REC_WT" ,SC7->(RECNO()) ,Nil})
aadd(aItens,aLinha)
Next nX
//旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커
//| Teste de Exclusao |
//읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
ConOut(PadC("Teste de exclusao",80))
ConOut("Inicio: "+Time())
MATA120(1,aCabec,aItens,5)

If !lMsErroAuto
ConOut("Exclusao com sucesso! "+cDoc)
Else
ConOut("Erro na exclusao!")
EndIf
ConOut("Fim : "+Time())
ConOut(Repl("-",80))*/
EndIf

RESET ENVIRONMENT

Return (.T.)
