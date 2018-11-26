#include "protheus.ch"
User Function Teste()
Local cRet
Local oModel    := FWModelActive()//  pegando o modelo que está ativo


    If oModel:GetValue('SB1MASTER','B1_INI') == 'AI' // aqui estou pegando(GetValue) o valor(digitado) de onde o gatilho é acionado e verifico qual o conteudo
        cRet := "AI0002"// aqui armazenei um valor a variavel
        oModel:SetValue('SB1MASTER','B1_COD',cRet)// aqui estou colocando(SetValue) valor no campo que meu gatilho preenche
    ElseIf oModel:GetValue('SB1MASTER','B1_INI') == 'PA'
        cRet := "PA0002"
        oModel:SetValue('SB1MASTER','B1_COD',cRet)
    ElseIf oModel:GetValue('SB1MASTER','B1_INI') == 'XX'
        cRet := "XX0002"
        oModel:SetValue('SB1MASTER','B1_COD',cRet)
    EndIf

Return


IF dbSeek( xFilial("SA2") + SA1->A1_COD + SA1->A1_LOJA)
//    	If  SA2->A2_COD + SA2->A2_LOJA == SA1->A1_COD + SA1->A1_LOJA
    		M->A2_Nome    := SA1->A1_Nome // antigo
            // novo
            oModel:GetValue('SA1MASTER','A1_COD') == '00001'
            cRet := "Cliente TESTE"
            oModel:SetValue('SA1MASTER','A1_NOME',cRet)

//		    Obs.: Os dados acima são só exemplos, então seria necessário
 //               validar qual é o modelo que está sendo utilizado no momento de atuação do gatilho.
 //               SA1MASTER é um exemplo teria que verificar se realmente esse é o nome do modelo
 //               através de debug
