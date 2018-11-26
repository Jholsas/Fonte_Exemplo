#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"

USER FUNCTION FIN050INC()

Local aArray := {}
Local nX := 1
Local cNum := '000016'
Local dVencto := CtoD("05/11/2018")
Local nVal:= 200

Private lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

//begin transaction

//For nX:= 1 to 2

//If nX == 2
    //cNum := '000015'
  //  nVal := 0

//EndIf

aAdd(aArray,{ "E2_PREFIXO"  , "RPA"             , NIL })
aAdd(aArray,{ "E2_NUM"      , cNum              , NIL })
aAdd(aArray,{ "E2_TIPO"     , "RPA"             , NIL })
aAdd(aArray,{ "E2_NATUREZ"  , "0000000001"      , NIL })
aAdd(aArray,{ "E2_FORNECE"  , "000005"          , NIL })
aAdd(aArray,{ "E2_EMISSAO"  , CtoD("05/11/2018"), NIL })
aAdd(aArray,{ "E2_VENCTO"   , CtoD("05/11/2018"), NIL })
aAdd(aArray,{ "E2_VENCREA"  , CtoD("05/11/2018"), NIL })
aAdd(aArray,{ "E2_VALOR"    , nVal              , NIL })
aAdd(aArray,{ "E2_EMIS1"    , CtoD("05/11/2018"), NIL })
aAdd(aArray,{ "AUTBANCO"    , "341"             , NIL })
aAdd(aArray,{ "AUTAGENCIA"  , "0001"            , NIL })
aAdd(aArray,{ "AUTCONTA"    , "000001"          , NIL })


MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aArray,, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão


If lMsErroAuto
MostraErro()
DisarmTransaction()
Else
Alert("Título de adiantamento incluído com sucesso! " + cNum)
Endif

//Next nX

//End Transaction
   RESET ENVIRONMENT

Return
