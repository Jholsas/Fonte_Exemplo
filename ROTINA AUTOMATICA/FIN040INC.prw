#INCLUDE "PROTHEUS.CH"

#INCLUDE "TBICONN.CH"

User Function FIN040INC()

LOCAL aArray := {}

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "FIN" TABLES "SE1","SE5","SA1","SA2"

Conout("----Inicio da Rotina Automatica!------")

aArray := { { "E1_PREFIXO"  , "AUT"             , NIL },;
            { "E1_NUM"      , "000124"          , NIL },;
            { "E1_TIPO"     , "RA"              , NIL },;
            { "E1_NATUREZ"  , "0000000001"      , NIL },;
            { "E1_CLIENTE"  , "000001"          , NIL },;
            { "E1_LOJA"     , "01"              , NIL },;
            { "E1_EMISSAO"  , CtoD("06/07/2018"), NIL },;
            { "E1_VENCTO"   , CtoD("06/07/2018"), NIL },;
            { "E1_VENCREA"  , CtoD("06/07/2018"), NIL },;
            { "CBCOAUTO"    , "341"             , NIL },;
            { "CAGEAUTO"    , "0001"            , NIL },;
            { "CCTAAUTO"    , "000001    "          , NIL },;
            { "E1_VALOR"    , 600               , NIL }}

MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

If lMsErroAuto

    MostraErro()

Else

    Conout("Título incluído com sucesso!")

Endif

RESET ENVIRONMENT

Return



/*#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"


USER FUNCTION FIN040INC()
LOCAL aArray := {}

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"  MODULO "FIN" TABLES "SE1","SE5","SA1","SA2", "SA6"
/*
aArray := { { "E1_PREFIXO"  , "AUT"             , NIL },;
            { "E1_NUM"      , "000123"          , NIL },;
            { "E1_TIPO"     , "RA"              , NIL },;
            { "E1_NATUREZ"  , "0000000001"      , NIL },;
            { "E1_CLIENTE"  , "000001"          , NIL },;
            { "E1_EMISSAO"  , CtoD("13/09/2018"), NIL },;
            { "E1_VENCTO"   , CtoD("13/09/2018"), NIL },;
            { "E1_VENCREA"  , CtoD("13/09/2018"), NIL },;
            { "E1_VALOR"    , 50                , NIL },;
            { "cBancoAdt"   , "341"             , Nil },;
            { "cAgenciaAdt" , "0001"            , Nil },;
            { "cNumCon"     , "000001"          , Nil } }


aArray := { { "E1_PREFIXO"  , "AUT"             , NIL },;
            { "E1_NUM"      , "000123"          , NIL },;
            { "E1_TIPO"     , "RA"              , NIL },;
            { "E1_NATUREZ"  , "0000000001"      , NIL },;
            { "E1_CLIENTE"  , "000001"          , NIL },;
            { "E1_LOJA"     , "01"              , NIL },;
            { "E1_EMISSAO"  , CtoD("09/11/2018"), NIL },;
            { "E1_VENCTO"   , CtoD("09/11/2018"), NIL },;
            { "E1_VENCREA"  , CtoD("09/11/2018"), NIL },;
            { "CBCOAUTO"    , "341"             , NIL },;
            { "CAGEAUTO"    , "0001"            , NIL },;
            { "CCTAAUTO"    , "00001"           , NIL },;
            { "E1_VALOR"    , 600               , NIL }}

  MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
  

    If lMsErroAuto
        MostraErro()
    Else
        Alert("Título incluído com sucesso!")
    Endif

 RESET ENVIRONMENT

Return/*
