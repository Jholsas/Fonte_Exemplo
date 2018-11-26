#include "protheus.ch"
#include "fwmvcdef.ch"
#include "tbiconn.ch"

#define enter chr(13) + chr(10)

function u_MVCMT020()

local oModelA2 := nil
local oA2Master := nil
local cCodigo := ""
Private aFornNovo :={"",""}

PREPARE ENVIRONMENT EMPRESA "99" FILIAL "01" TABLES "SA2" MODULO "COM"

private inclui := .t.
private altera := .f.

oModelA2 := fwLoadModel("MATA020M")

oModelA2:setOperation(3)
oModelA2:activate()

oA2Master := oModelA2:getModel("SA2MASTER")

cCodigo := getSxeNum("SA2", "A2_COD")

oA2Master:setValue("A2_COD" , cCodigo )
oA2Master:setValue("A2_LOJA" , "01" )
oA2Master:setValue("A2_NOME" , "Forncedor " + cvaltochar(cCodigo) )
//oA2Master:setValue("A2_NREDUZ" , "Forncedor " + cvaltochar(cCodigo) )
oA2Master:setValue("A2_END" , "Endereco teste" )
oA2Master:setValue("A2_EST" , "SP" )
oA2Master:setValue("A2_MUN" , "SO PAULO " )
oA2Master:setValue("A2_COD_MUN" , "99999" )
oA2Master:setValue("A2_TIPO" , "J" )

if oModelA2:vldData()
if oModelA2:commitData()
conOut("Processo executado com sucesso (MATA020)" + enter + "Fornecedor : " + SA2->A2_NOME)
else
aErro := oModelA2:getErrorMessage()

varInfo("Erro durante o commit (MATA020)", aErro)
endIf
else
aErro := oModelA2:getErrorMessage()

varInfo("Erro durante a validacao (MATA020)", aErro)
endIf

oA2Master:destroy()

//RESET ENVIRONMENT

return
