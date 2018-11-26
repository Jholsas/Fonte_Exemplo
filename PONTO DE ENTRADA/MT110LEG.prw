User Function MT110LEG()
// aCores     = Array contendo as Legendas para a apresentação das
// cores do status da SC na mbrowse.
// lGspInUseM = Indica se há integração com o modulo GSP

Local aNewLegenda  := aClone(PARAMIXB[1])
// aLegenda
aAdd(aNewLegenda,{'BR_AMARELO'  , 'SC Parcialmente Atendido'})
aAdd(aNewLegenda,{'BR_AZUL'     , 'SC Bloqueada'})
aAdd(aNewLegenda,{'BR_CINZA'    , 'Elim. Residuo' })

Return (aNewLegenda)
