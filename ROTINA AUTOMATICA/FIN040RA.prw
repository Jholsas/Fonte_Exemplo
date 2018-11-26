#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"

USER FUNCTION FIN040RA()

LOCAL aArray := {}

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" //MODULO "FIN" TABLES "SE1","SA6","SA1","SA2","SB1"

aArray := { { "E1_PREFIXO"  , "RAA"             , NIL },;
            { "E1_NUM"      , "000123   "       , NIL },;
            { "E1_TIPO"     , "RA"              , NIL },;
            { "E1_NATUREZ"  , "0000000001"      , NIL },;
            { "E1_CLIENTE"  , "000001"          , NIL },;
            { "E1_EMISSAO"  , CtoD("13/09/2018"), NIL },;
            { "E1_VENCTO"   , CtoD("13/09/2018"), NIL },;
            { "E1_VENCREA"  , CtoD("13/09/2018"), NIL },;
            { "E1_VALOR"    , 10                , NIL },;
            { "CBCOAUTO"   	, "341"             , Nil },;
            { "CAGEAUTO" 	, "0001"            , Nil },;
            { "CCTAAUTO"    , "000001"          , Nil } }


MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão


If lMsErroAuto
MostraErro()
Else
Alert("Título incluído com sucesso!")
Endif
RESET ENVIRONMENT


Return
