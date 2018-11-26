#Include 'Protheus.ch'
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"

User Function MyMata150Atualiza()

Local aCabec := {}
Local aItens := {}

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM"

ConOut(Repl("-",80))
ConOut("Inicio: "+Time())
ConOut(PadC("Rotina Automática ALTERAÇÃO DE UMA COTAÇÃO JÁ EXISTENTE MATA150 P11",80))
ConOut(Repl("-",80))

// ---- EXEMPLO ALTERACAO DE UMA COTACAO JA EXISTENTE ----

aCabec:={}
aItens:={}
aLinha:={}

dbSelectArea("SC8")
dbSetOrder(1)
dbSeek(xFilial("SC8")+"000001")

aadd(aCabec,{"C8_FORNECE" ,"000000"})
aadd(aCabec,{"C8_LOJA" ,"01" })
aadd(aCabec,{"C8_COND" ,"001" })
aadd(aCabec,{"C8_CONTATO" ,"EXECAUTO ALTERA " })
aadd(aCabec,{"C8_FILENT" ,"01" })
aadd(aCabec,{"C8_MOEDA" ,0 })
aadd(aCabec,{"C8_EMISSAO" ,dDataBase})
aadd(aCabec,{"C8_SEGURO" ,0 })


aadd(aLinha,{"C8_NUMPRO","01" , Nil})
aadd(aLinha,{"C8_PRODUTO","000000000000000" ,Nil})
aadd(aLinha,{"C8_ITEM" ,"0001" , Nil})
aadd(aLinha,{"C8_UM" ,"UN" , Nil})
aadd(aLinha,{"C8_QUANT",10000 , Nil})
aadd(aLinha,{"C8_PRECO",8.00 , Nil})
aadd(aLinha,{"C8_TOTAL",80000.00 , Nil})
aadd(aItens,aLinha)

MSExecAuto({|v,x,y| MATA150(v,x,y)},aCabec,aItens,3)

If !lMsErroAuto
ConOut("**** Alterado com sucesso! ****")

Else
MostraErro()
ConOut("Erro na Alteração!")

EndIf

ConOut("Fim : "+Time())

RESET ENVIRONMENT


Return(.T.)
