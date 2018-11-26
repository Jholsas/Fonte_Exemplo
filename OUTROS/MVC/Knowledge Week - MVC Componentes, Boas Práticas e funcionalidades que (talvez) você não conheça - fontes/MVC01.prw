#include "protheus.ch"
#include "fwmvcdef.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} MVC01
Exemplo de um modelo e view baseado em uma unica tabela.

@since 01/06/2018
/*/
//-------------------------------------------------------------------
User Function MVC01()
Local oBrowse

PRIVATE aRotina := MenuDef()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SA1')
	oBrowse:SetDescription('Cadastro de Alunos')
	oBrowse:Activate()

Return


Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.MVC01' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.MVC01' OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.MVC01' OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.MVC01' OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.MVC01' OPERATION 8 ACCESS 0
ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.MVC01' OPERATION 9 ACCESS 0
//ADD OPTION aRotina TITLE 'TESTE'      ACTION 'U_xTESTE'		 OPERATION 3 ACCESS 0

Return aRotina

Static Function ModelDef()
Local oModel
Local oStruSA1 := FWFormStruct(1,"SA1")

	oModel := MPFormModel():New("MD_ALUNO")
	oModel:SetDescription("Cadastro de Alunos")

	oModel:addFields('MASTERSA1',,oStruSA1)
	oModel:getModel('MASTERSA1'):SetDescription('Dados do Aluno')
	//oModel:addGrid('ZB6DETAIL','ZB5MASTER',oStruZB6)

Return oModel

Static Function ViewDef()
Local oModel := ModelDef()
Local oView
Local oStrSA1:= FWFormStruct(2, 'SA1')

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('FORM_ALUNO' , oStrSA1,'MASTERSA1' )
	oView:CreateHorizontalBox( 'BOX_FORM_ALUNO', 100)
	oView:SetOwnerView('FORM_ALUNO','BOX_FORM_ALUNO')
	oView:AddGrid('FORM_ALUNO' , oStrSA1,'MASTERSA1')

Return oView

/*Static Function ViewDef()
Local oModel := ModelDef()
Local oView

	oView := FWFormView():New()
	oView:SetModel(oModel)

Return oView*/


//oModel:AddGrid("ZB6DETAIL", "ZB5MASTER", FWFormStruct(1,"ZB6"))
