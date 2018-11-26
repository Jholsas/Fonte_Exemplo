//INCLUSAO
User Function RMATA250()
Local aVetor := {}
Local dData
Local nOpc   := 3
//-Opção de execução da rotina, informado nos parametros quais as opções possiveis

lMsErroAuto := .F.
RpcSetEnv( "99","01",,,,,,,,,)

dData:=dDataBase

aVetor := {    {"D3_OP"        , "00000101001   " , NIL},;
               {"D3_TM"        , "03 "            , NIL},;
               {"D3_QUANT"  , 10               , NIL},;
               {"D3_PERDA"  , 5                , NIL},;
               {"D3_PARCTOT", "T"              , NIL}}
               //{"ATUEMP"    , "T"              , NIL}}

	MSExecAuto({|x, y| mata250(x, y)},aVetor, nOpc )

    If lMsErroAuto

     Mostraerro()

     else

     Alert("Ok")

     Endif

     Return
