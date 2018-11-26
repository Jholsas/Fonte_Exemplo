User Function FA460CMC7
   Local aCols := ParamIxb[1]

aCols[Len(aCols)][1] := 'CHQ'

   Alert("Ponto de entrada - FA460CMC7 ")
Return aCols






















// codigo cmc7
//<23728016<0010002185>777500568207C
//<23701348<018 0001265<577508114673

   /*     <23701348<018 0001265<577508114673 :

           --- ---- -  --- ------ -   - ---------- -

        |   |   |   |    |    |   |     |    
        |   |   |   |    |    |   |     |       -> digito verificado
        |   |   |   |    |    |   |      -------> conta corre
        |   |   |   |    |    |    --------------> digito verificado
        |   |   |   |    |     ------------------> Tipificação ( 5 padrão/normal, 8 ch tributário, 9 administrativ
        |   |   |   |     ----------------------> che
        |   |   |    ----------------------------> compe ( camara de compensaçã
        |   |    --------------------------------> digito verificado
        |    -----------------------------------> agên
         ----------------------------------------> banco */



/* aCols[n][1] = Prefixo do titulo,
 aCols[n][2] = Tipo,
 aCols[n][3] = Banco,
 aCols[n][4] = Agencia,
 aCols[n][5] = Conta,
 aCols[n][6] = Numero do Cheque,
 aCols[n][7] = Data de vencimento do cheque,
 aCols[n][8] = Nome do emitente,
 aCols[n][9] = Valor do cheque,
 aCols[n][10] = Acrescimo,
 aCols[n][11] = Decrescimo,
 aCols[n][12] = Valor total dos cheques
*/
