#include 'protheus.ch'
#include 'parmtype.ch'
#Include "Tbiconn.ch"

USER FUNCTION FIN050INC()

Local aArray := {}

Private lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01"

aAdd(aArray,{ "E2_PREFIXO" , "ABC" , NIL })
aAdd(aArray,{ "E2_NUM" , "000250" , NIL })
aAdd(aArray,{ "E2_TIPO" , "NF" , NIL })
aAdd(aArray,{ "E2_NATUREZ" , "0000000001" , NIL })
aAdd(aArray,{ "E2_FORNECE" , "000005" , NIL })
aAdd(aArray,{ "E2_EMISSAO" , CtoD("19/07/2018"), NIL })
aAdd(aArray,{ "E2_VENCTO" , CtoD("19/07/2018"), NIL })
aAdd(aArray,{ "E2_VENCREA" , CtoD("19/07/2018"), NIL })
aAdd(aArray,{ "E2_VALOR" , 700 , NIL })

MsExecAuto( { |x,y,z| FINA050(x,y,z)}, aArray,, 3) // 3 - Inclusao, 4 - Alteração, 5 - Exclusão


If lMsErroAuto
MostraErro()
Else
Alert("Título de adiantamento incluído com sucesso!")
Endif

   RESET ENVIRONMENT

Return
