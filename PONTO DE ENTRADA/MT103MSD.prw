USER FUNCTION MT103MSD()

Local lExc:=.F.
Local dData

dData := SF1->F1_DTLANC
Alert("Exclus�o do Banco de Conhecimento no Estorno de Classifica��o do Pr�-Documento de Entrada" +;
        "F1_DTLANC " + DTOC(dData))

Return lExc
