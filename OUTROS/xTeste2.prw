

#Include "protheus.ch"

User Function Sample()
Local oDlg
Local oSay1
Local oCombo
Local cCombo
Local aRet := AllUsers()
Local nI
Local aUsers := {}
Local aAcessos := GetAccessList()
For nI := 1 to Len(aRet)
Aadd(aUsers, aRet[nI][1][2],aAcessos)

Next nI
                DEFINE MSDIALOG oDlg TITLE "Teste" From 000,0 TO 100,300 PIXEL
                @ 12, 05 SAY oSay1 VAR "Usuários: " OF oDlg PIXEL
                @ 12, 30 COMBOBOX oCombo VAR cCombo ITEMS aUsers SIZE 100, 009 OF oDlg PIXEL
                @ 25, 80 BUTTON "Fechar" PIXEL SIZE 40,12 OF oDlg ACTION oDlg:End()
                ACTIVATE MSDIALOG oDlg CENTERED

Return
