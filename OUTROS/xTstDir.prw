#Include 'Protheus.ch'
#Include "TOTVS.ch"

//não funciona mais
User Function xTstDir()
  Local aFiles := {} // O array receberá os nomes dos arquivos e do diretório
  Local aSizes := {} // O array receberá os tamanhos dos arquivos e do diretorio
  Local nX

  ADir("c:\Fonte_Exemplo\*.*", aFiles, aSizes)
  // Exibe dados dos arquivos
  nCount := Len( aFiles )
  For nX := 1 to nCount
    ConOut( 'Arquivo: ' + aFiles[nX] + ' - Size: ' + AllTrim(Str(aSizes[nX])) )
  Next nX
  ADir("c:\Fonte_Exemplo\*.*", aFiles, aSizes) //proximos 10 mil arquivos
  For nX := 1 to nCount
    ConOut( 'Arquivo: ' + aFiles[nX] + ' - Size: ' + AllTrim(Str(aSizes[nX])) )
  Next nX
Return


User Function Exemplo1()
  Local aFiles := {}
  Local nX
  local nCount
  aFiles := Directory("c:\Fonte_Exemplo\*.*", "D")
  nCount := Len( aFiles )
  For nX := 1 to nCount
      ConOut('Arquivo: ' + aFiles[nX,1] + ' - Size: ' + AllTrim(Str(aFiles[nX,2])) )
  Next nX
Return
