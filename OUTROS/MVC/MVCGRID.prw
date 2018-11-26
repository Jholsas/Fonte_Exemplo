#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'

User Function CMVC_07()
Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('SA1')
	oBrowse:SetDescription('Cadastro de Turma x Aluno')
	oBrowse:Activate()
Return

Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.CMVC_07' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.CMVC_07' OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.CMVC_07' OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.CMVC_07' OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE 'Imprimir'   ACTION 'VIEWDEF.CMVC_07' OPERATION 8 ACCESS 0
ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.CMVC_07' OPERATION 9 ACCESS 0

Return aRotina

Static Function ModelDef()
Local oModel
Local oStruSA1 := FWFormStruct(1,"SA1")
Local oStruSA2 := FWFormStruct(1,"SA1")

	oModel := MPFormModel():New("MD_TURMA_ALUNO")
	oModel:SetDescription("Cadastro de Turma x Aluno x Nota")
	oModel:addFields('SA1MASTER',,oStruSA1)
	oModel:addGrid('SA1MASTER','SA1MASTER',oStruSA2)

	oModel:SetRelation("SA2DETAIL", ;
	 					{{"SA2_FILIAL",'xFilial("SA2")'},;
						{"SA2_CODTUR","SA1_CODTUR"  }}, ;
						SA2->(IndexKey(1)))

Return oModel

Static Function ViewDef()
Local oModel := ModelDef()
Local oView
Local oStrSA1:= FWFormStruct(2, 'SA1')
Local SA1:= FWFormStruct(2, 'SA1', {|cField| !(AllTrim(Upper(cField)) $ "A1_COD")})

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('FORM_TURMA' , oStrSA1,'SA1MASTER' )
	oView:AddGrid('FORM_ALUNOS' , SA1,'SA1DETAIL')

	oView:CreateHorizontalBox( 'BOX_FORM_TURMA', 30)
	oView:CreateHorizontalBox( 'BOX_FORM_ALUNOS', 70)

 	oView:SetOwnerView('FORM_ALUNOS','BOX_FORM_ALUNOS')
 	oView:SetOwnerView('FORM_TURMA','BOX_FORM_TURMA')

Return oView
