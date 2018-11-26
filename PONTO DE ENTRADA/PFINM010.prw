User Function FINM010()
	Local aParam := PARAMIXB
	Local lRet := .T.
	Local oSubModel := ''
	Local cIdPonto := ''
	Local cIdModel := ''
	Local cCamposE5 := ''
	Local oModelBx  := ''
	If aParam <> NIL
		oSubModel        := aParam[1] //Objeto do formul�rio ou do modelo, conforme o caso
		cIdPonto         := aParam[2] //ID do local de execu��o do ponto de entrada
		cIdModel         := aParam[3] //ID do formul�rio
		If cIdPonto == 'FORMPOS' // Na valida��o total do formul�rio.
                Alert("PE MVC FORMPOS")
			If cIdModel == 'FK1DETAIL' //Valida��o do formul�rio FK1
                //If "VL" $  oSubModel:GetValue("FK1_TPDOC") //Condi��o para altera��o de grava��o
					oSubModel:SetValue( "FK1_HISTOR", 'P.E. EM MVC,BAIXA FK1' ) // Novos valores

				//EndIF
			ElseIf cIdModel == 'FK6DETAIL' //Valida��o do formul�rio FK6
				//If "DC" $  oSubModel:GetValue("FK6_TPDOC")
					oSubModel:SetValue( "FK6_HISTOR", 'P.E. EM MVC,DESCONTO' )
				//EndIf
			ElseIf cIdModel == 'FK5DETAIL' //Valida��o do formul�rio FK5
				//If "VL" $  oSubModel:GetValue("FK5_TPDOC") //Condi��o para altera��o de grava��o
					oSubModel:SetValue( "FK5_HISTOR", 'P.E. EM MVC,BAIXA FK5' ) // Novos valores
				//EndIF
			EndIf
		EndIf
	EndIf
Return lRet
