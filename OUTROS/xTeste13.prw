User function xTeste13()

dbSelectArea("SM0")
dbSeek(cEmpAnt,.T.)

IF M0_CODIGO == cEmpAnt //.AND. FWGETCODFILIAL <= cFilAte
    cFilAnt := FWGETCODFILIAL()
ENDIF

Alert("FILIAL LOGADA: " + cFilAnt )


/*Local oExcel := FWMSEXCEL():New()
Local nDir:=cGetFile( '*.*' , 'Escolha diret�rio para salvar arquivo', 0, 'C:\', .F., ( GETF_LOCALHARD+GETF_RETDIRECTORY+GETF_OVERWRITEPROMPT ),.F., .F.)
Local nArq:="TESTE.XLS"
oExcel:AddworkSheet("Teste - 1")
oExcel:AddTable ("Teste - 1","Titulo de teste 1")
oExcel:AddColumn("Teste - 1","Titulo de teste 1","Col1",1,1)
oExcel:AddColumn("Teste - 1","Titulo de teste 1","Col2",2,2)
oExcel:AddColumn("Teste - 1","Titulo de teste 1","Col3",3,3)
oExcel:AddColumn("Teste - 1","Titulo de teste 1","Col4",1,1)
oExcel:AddRow("Teste - 1","Titulo de teste 1",{11,12,13,14})
oExcel:AddRow("Teste - 1","Titulo de teste 1",{21,22,23,24})
oExcel:AddRow("Teste - 1","Titulo de teste 1",{31,32,33,34})
oExcel:AddRow("Teste - 1","Titulo de teste 1",{41,42,43,44})
oExcel:AddworkSheet("Teste - 2")
oExcel:AddTable("Teste - 2","Titulo de teste 1")
oExcel:AddColumn("Teste - 2","Titulo de teste 1","Col1",1)
oExcel:AddColumn("Teste - 2","Titulo de teste 1","Col2",2)
oExcel:AddColumn("Teste - 2","Titulo de teste 1","Col3",3)
oExcel:AddColumn("Teste - 2","Titulo de teste 1","Col4",1)
oExcel:AddRow("Teste - 2","Titulo de teste 1",{11,12,13,stod("20121212")})
oExcel:AddRow("Teste - 2","Titulo de teste 1",{21,22,23,stod("20121212")})
oExcel:AddRow("Teste - 2","Titulo de teste 1",{31,32,33,stod("20121212")})
oExcel:AddRow("Teste - 2","Titulo de teste 1",{41,42,43,stod("20121212")})
oExcel:AddRow("Teste - 2","Titulo de teste 1",{51,52,53,stod("20121212")})
oExcel:Activate()
oExcel:GetXMLFile(nDir+nArq)*/


Return
