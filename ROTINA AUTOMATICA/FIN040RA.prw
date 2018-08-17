#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"

USER FUNCTION FIN040RA()

LOCAL aArray := {}
Local cBancoAdt     :="341"
Local cAgenciaAdt   :="0001"
Local cNumCon       :="000001"

PRIVATE lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" //MODULO "FIN" TABLES "SE1","SA6","SA1","SA2","SB1"

aArray := { { "E1_PREFIXO"  , "RAA"             , NIL },;
            { "E1_NUM"      , "01515"           , NIL },;
            { "E1_TIPO"     , "RA"              , NIL },;
            { "E1_NATUREZ"  , "0000000001"      , NIL },;
            { "E1_CLIENTE"  , "000001"          , NIL },;
            { "E1_EMISSAO"  , CtoD("17/08/2018"), NIL },;
            { "E1_VENCTO"   , CtoD("17/08/2018"), NIL },;
            { "E1_VENCREA"  , CtoD("17/08/2018"), NIL },;
            { "E1_VALOR"    , 5000              , NIL },;
            { "cBancoAdt"   , "341"             , Nil },;
            { "cAgenciaAdt" , "0001"            , Nil },;
            { "cNumCon"     , "000001"          , Nil } }


MsExecAuto( { |x,y| FINA040(x,y)} , aArray, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão


If lMsErroAuto
MostraErro()
Else
Alert("Título incluído com sucesso!")
Endif
RESET ENVIRONMENT


Return
