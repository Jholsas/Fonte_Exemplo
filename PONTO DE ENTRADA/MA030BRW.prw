User Function MA030BRW()
Local cFiltro := ""

//cFiltro := "SA1->A1_EST=='RJ'"
cFiltro := "SA1->A1_NOME = 'CLIENTE TESTE'
Alert("Ponto de entrada - MA030BRW")


Return ( cFiltro )


//SEM MVC
// If lMA030BRW
		// cFiltraSA1 := ExecBlock("MA030BRW",.F.,.F.)
		// If !Empty( cFiltraSA1 )
			// oMBrowse:AddFilter(STR0097,cFiltraSA1,.T.,.T.) //"Filtro de Usuário"
			// oMBrowse:ExecuteFilter()
		// EndIf
	// EndIf
//
//
//
// COM MVC
    // If lMA030BRW
		// cFiltraSA1 := ExecBlock("MA030BRW",.F.,.F.)
		// If !Empty( cFiltraSA1 )
			// oMBrowse:AddFilter(STR0097,cFiltraSA1,.T.,.T.) //"Filtro de Usuário"
			// oMBrowse:ExecuteFilter()
		// EndIf
	// EndIf
//
//
// SEM MVC ANTIGO
    // If lMa030Brw
			// cFiltraSA1 := ExecBlock("MA030BRW",.F.,.F.)
			// bFiltraBrw := {|| FilBrowse("SA1",@aIndexSA1,@cFiltraSA1)}
			// Eval(bFiltraBrw)
		// EndIf
		//
