#include 'rwmake.ch'

User Function Mt410Ace()

Local lContinua := MsgYesNo("Continua?", "Mt410Ace")
Local nOpc  := PARAMIXB [1]



    IF nOpc == 1 // excluir
        Alert("##EXCLUIR##")
    ElseIf nOpc == 4 // Alterar
        Alert("##ALTERAR##")
    ElseIf nOpc == 2 // Alterar
        Alert("##VISUALIZARO##")
    Endif


Return(lContinua)
