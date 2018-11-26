#INCLUDE "PROTHEUS.CH"
#include "rwmake.ch"
#include "TbiConn.ch"

User Function auto380()

Local aVetor := {}
Local aEmpen := {}
Local nOpc   := 4 //Inclusao

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "EST"

lMsErroAuto := .F.
dbselectArea("SD4")
DbSetOrder(1)
MsSeek(xFilial("SD4")+"SERV0001       "+"00001901001   " )

aVetor:={   {"D4_COD"     ,SD4->D4_COD        ,Nil},; //COM O TAMANHO EXATO DO CAMPO
            {"D4_LOCAL"   ,SD4->D4_LOCAL      ,Nil},;
            {"D4_OP"      ,SD4->D4_OP         ,Nil},;
            {"D4_DATA"    ,SD4->D4_DATA       ,Nil},;
            {"D4_QTDEORI" ,30                 ,Nil},;
            {"D4_QUANT"   ,30                 ,Nil},;
            {"D4_TRT"     ,SD4->D4_TRT        ,Nil},;
            {"D4_QTSEGUM" ,SD4->D4_QTSEGUM    ,Nil}}

AADD(aEmpen,{   30                 ,;   // SD4->D4_QUANT
                "01          "     ,;  // DC_LOCALIZ
                ""                 ,;  // DC_NUMSERI
                0                  ,;  // D4_QTSEGUM
                .F.})

MSExecAuto({|x,y,z| mata380(x,y,z)},aVetor,nOpc,aEmpen)

If (lMsErroAuto == .T.)
        //Se ocorrer erro.
        MostraErro()
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA380 finalizado com erro!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA380 finalizado com sucesso!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
    EndIf
 RESET ENVIRONMENT
Return
