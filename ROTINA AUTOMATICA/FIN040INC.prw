#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"


USER FUNCTION FIN040INC()
LOCAL aArray := {}

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

aArray := { { "E1_PREFIXO"  , "AUT"             , NIL },;
            { "E1_NUM"      , "1299"            , NIL },;
            { "E1_TIPO"     , "NF"              , NIL },;
            { "E1_NATUREZ"  , "0000000001"      , NIL },;
            { "E1_CLIENTE"  , "000001"          , NIL },;
            { "E1_EMISSAO"  , CtoD("03/08/2018"), NIL },;
            { "E1_VENCTO"   , CtoD("03/08/2018"), NIL },;
            { "E1_VENCREA"  , CtoD("03/08/2018"), NIL },;
            { "E1_VALOR"    , 5000              , NIL },;
            { "E1_PORTADO"  , "341"             , NIL },;
            { "E1_AGEDEP"   , "0001"            , NIL },;
            { "E1_CONTA"    , "000001"          , NIL }}


  MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão


    If lMsErroAuto
        MostraErro()
    Else
        Alert("Título incluído com sucesso!")
    Endif

 RESET ENVIRONMENT

Return
