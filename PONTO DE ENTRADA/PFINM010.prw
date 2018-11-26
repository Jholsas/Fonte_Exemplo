User Function FINM010()
	Local aParam := PARAMIXB
	Local lRet := .T.
	Local oSubModel := ''
	Local cIdPonto := ''
	Local cIdModel := ''
	Local cCamposE5 := ''
	Local oModelBx  := ''
	If aParam <> NIL
		oSubModel        := aParam[1] //Objeto do formulário ou do modelo, conforme o caso
		cIdPonto         := aParam[2] //ID do local de execução do ponto de entrada
		cIdModel         := aParam[3] //ID do formulário
		If cIdPonto == 'FORMPOS' // Na validação total do formulário.
                Alert("PE MVC FORMPOS")
			If cIdModel == 'FK1DETAIL' //Validação do formulário FK1
                //If "VL" $  oSubModel:GetValue("FK1_TPDOC") //Condição para alteração de gravação
					oSubModel:SetValue( "FK1_HISTOR", 'P.E. EM MVC,BAIXA FK1' ) // Novos valores

				//EndIF
			ElseIf cIdModel == 'FK6DETAIL' //Validação do formulário FK6
				//If "DC" $  oSubModel:GetValue("FK6_TPDOC")
					oSubModel:SetValue( "FK6_HISTOR", 'P.E. EM MVC,DESCONTO' )
				//EndIf
			ElseIf cIdModel == 'FK5DETAIL' //Validação do formulário FK5
				//If "VL" $  oSubModel:GetValue("FK5_TPDOC") //Condição para alteração de gravação
					oSubModel:SetValue( "FK5_HISTOR", 'P.E. EM MVC,BAIXA FK5' ) // Novos valores
				//EndIF
			EndIf
		EndIf
	EndIf
Return lRet
