#Include 'Protheus.ch'

User Function MT161OK()

Local aPropostas := PARAMIXB[1] // Array contendo todos os dados da proposta da cotação

Local cTpDoc := PARAMIXB[2] // Tipo do documento

Local lContinua := .T.

Local cAux:=""

//If
//.....    Validações do usuário.
RecLock("SC7",.F.)
        C7_TESTE:='2'
        cAux:= C7_TESTE
		SC7-> (MsUnlock())
        SC7->(dbSkip())

Alert(cAux)
Return (lContinua)
