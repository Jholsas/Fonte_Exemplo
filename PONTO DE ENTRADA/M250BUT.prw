User Function M250BUT()

Local nOpc     := PARAMIXB[1]
Local aButtons := {}

If nOpc == 3 // Inclui botão somente se for inclusão
    aadd(aButtons, {'TESTE', {||}, 'TESTE'})
EndIf

Return aButtons
