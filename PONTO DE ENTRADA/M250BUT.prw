User Function M250BUT()

Local nOpc     := PARAMIXB[1]
Local aButtons := {}

If nOpc == 3 // Inclui bot�o somente se for inclus�o
    aadd(aButtons, {'TESTE', {||}, 'TESTE'})
EndIf

Return aButtons
