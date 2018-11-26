USER FUNCTION MT103MSD()

Local lExc:=.F.
Local dData

dData := SF1->F1_DTLANC
Alert("Exclusão do Banco de Conhecimento no Estorno de Classificação do Pré-Documento de Entrada" +;
        "F1_DTLANC " + DTOC(dData))

Return lExc
