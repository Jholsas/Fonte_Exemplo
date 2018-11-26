#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
User Function RMATA681()
Local aVetor := {}
Local dData

lMsErroAuto := .F.

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" MODULO "COM" TABLES "SH6"

dData:= dDataBase

aVetor := { {"H6_OP"	    ,"00000101001  "    ,NIL},;
            {"H6_PRODUTO"   ,"PA01          "   ,NIL},;
            {"H6_OPERAC"    ,"01"               ,NIL},;
            {"H6_RECURSO"   ,"1"                ,NIL},;
            {"H6_DTAPONT"   ,dData              ,NIL},;
            {"H6_DATAINI"   ,dData              ,NIL},;
            {"H6_HORAINI"   ,"19:11"            ,NIL},;
            {"H6_DATAFIN"   ,dData              ,NIL},;
            {"H6_HORAFIN"   ,"19:20"            ,NIL},;
            {"H6_PT"        ,'P'                ,NIL},;
            {"H6_LOCAL"     ,"01"               ,NIL},;
            {"H6_QTDPROD"   ,7                  ,NIL}}

            MSExecAuto({|x| mata681(x)},aVetor)
             // inclusão///////////////////////////////////////////////////////////////////////////////////////////////////////////////

             If lMsErroAuto
                Mostraerro()
            else
                alert("ok")
            Endif
Return
