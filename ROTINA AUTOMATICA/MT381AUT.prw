#Include "TOTVS.ch"
#Include "TBICONN.ch"

User Function MT381AUT()
    Local aCab       := {}
    Local aLine      := {}
    Local aItens     := {}


    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .T.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

    //Monta o cabeçalho com o número da OP que será utilizada para inclusão dos empenhos.
    aCab := {{"D4_OP","00001801001   ",NIL}}

    //Adiciona novo empenho
    aLine := {}
    aAdd(aLine,{"D4_OP"     ,"00001801001   "       ,NIL})
    aAdd(aLine,{"D4_COD"    ,"SERV0002       "      ,NIL})
    aAdd(aLine,{"D4_LOCAL"  ,"01"                   ,NIL})
    aAdd(aLine,{"D4_DATA"   ,CtoD("13/11/2018")     ,NIL})
    aAdd(aLine,{"D4_QTDEORI",10                     ,NIL})
    aAdd(aLine,{"D4_QUANT"  ,10                     ,NIL})
    //Adiciona a linha do empenho no array de itens.
    aAdd(aItens,aLine)



    //Executa o MATA381, com a operação de Inclusão.
    MSExecAuto({|x,y,z| mata381(x,y,z)},aCab,aItens,3)
    If (lMsErroAuto == .T.)
        //Se ocorrer erro.
        MostraErro()
		ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA381 finalizado com erro!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
    Else
        ConOut(Repl("-", 80))
		ConOut(PadC("Teste MATA381 finalizado com sucesso!", 80))
		ConOut(PadC("Fim: " + Time(), 80))
		ConOut(Repl("-", 80))
    EndIf

   RESET ENVIRONMENT
Return
