#INCLUDE "Topconn.ch"
#INCLUDE "Protheus.ch"



/*BEGINDOC
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Exemplo de relatorio usando tReport com uma Section
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
ENDDOC*/


User Function RCOMR02()

local oReport
local cPerg := 'RCOMR02'
local cAlias := getNextAlias()


Pergunte(cPerg, .f.)

oReport := reportDef(cAlias, cPerg)
oReport:printDialog()

return

//+-----------------------------------------------------------------------------------------------+
//! Rotina para montagem dos dados do relatório. !
//+-----------------------------------------------------------------------------------------------+
Static Function ReportPrint(oReport,cAlias)

local oSecao1 := oReport:Section(1)

oSecao1:BeginQuery()

BeginSQL Alias cAlias

select E1_NUM, E1_VALOR, * from SE1990

EndSQL

IF(RAT(".prt", oreport:cfile) > 0)
alert("Impressão via .prt")
ELSEIF(RAT(".xml", oreport:cfile) > 0)
alert("Impressão via .xml")
ENDIF

oSecao1:EndQuery()
oReport:SetMeter((cAlias)->(RecCount()))
oSecao1:Print()

return

//+-----------------------------------------------------------------------------------------------+
//! Função para criação da estrutura do relatório. !
//+-----------------------------------------------------------------------------------------------+
Static Function ReportDef(cAlias, cPerg)

local cTitle := "Relatório de Conta Corrente"
local cHelp := "Permite gerar relatório de Conta Corrente de Fornecedores"
local oReport
local oSection1
local cPosit    := "E1_VALOR > 100"


Pergunte(cPerg, .f.)

oReport := TReport():New('RCOMR02',cTitle,cPerg,{|oReport|ReportPrint(oReport,cAlias)},cHelp)

//Primeira seção
oSection1 := TRSection():New(oReport,"Conta Corrente",{cAlias})

ocell2:= TRCell():New(oSection1,"E1_NUM", cAlias, "Número")
ocell:= TRCell():New(oSection1,"E1_VALOR", cAlias, "Valor")

//aAdd(oSection1:Cell("E1_VALOR"):aFormatCond, {"E1_VALOR > 100 .and. E1_VALOR < 1000" ,,CLR_GREEN})
//aAdd(oSection1:Cell("E1_VALOR"):aFormatCond, {"E1_VALOR >= 1000" ,,CLR_RED})
aAdd(oSection1:Cell("E1_VALOR"):aFormatCond, {"E1_VALOR >= "+cvaltochar(MV_PAR01) ,,CLR_RED})


Return(oReport)
