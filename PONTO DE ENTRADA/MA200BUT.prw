User Function MA200BUT

// Customização de usuário conforme regra de negócio praticada

Local aButtons := {}
		aadd(aButtons, {'TESTE', {||U_TstBtn()}, 'TESTE'})
Return aButtons


User Function TstBtn()

	Alert("TESTE PE - MA200BUT ")

Return
