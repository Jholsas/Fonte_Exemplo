#include "protheus.ch"

User Function MT161CPO()

Local aPropostas := PARAMIXB[1] // Array com os dados das propostas dos Fornecedores
Local aItens := PARAMIXB[2] // Array com os dados da grid "Produtos"
Local aCampos := {"C8_OBS03"} // Array com os campos adicionados na grid "Item da Proposta"
Local aCposProd := {"C8_OBS03"} // Array com os campos adicionados na grid "Produtos"
Local aRetorno := {}
Local nX := 0
Local nY := 0
Local nZ := 0
Local nCount := 0

For nX := 1 To Len(aPropostas)
For nY := 1 To Len(aPropostas[nX])
For nZ := 1 To Len(aPropostas[nX][nY][2])
nCount++
AADD(aPropostas[nX][nY][2][nZ],"TESTE "+Str(nCount,2))
next nZ
Next nY
Next nX

For nX := 1 To Len(aItens)
AADD(aItens[nX],nX)
Next nX

AADD(aRetorno,aPropostas)
AADD(aRetorno,aCampos)
AADD(aRetorno,aItens)
AADD(aRetorno,aCposProd)

Return aRetorno
