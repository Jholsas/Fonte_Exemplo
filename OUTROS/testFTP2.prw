//Para que o exemplo abaixo funcione, é necessário que seu computador tenha sido configurado como um servidor ftp.
#INCLUDE "protheus.ch"
#DEFINE DEFAULT_FTP 21
#DEFINE PATH "\teste\"
user Function TestFTP2()

Local aRetDir := {}

//Tenta se conectar ao servidor ftp em localhost na porta 21
//com usuário e senha anônimos
if !FTPCONNECT ( "localhost" , 21 ,"victor", "1234" )
	conout( "Nao foi possível se conectar!!" )
	Return NIL
EndIf

//Tenta mudar do diretório corrente ftp, para o diretório
//especificado como parâmetro

// if !FTPDIRCHANGE( "/test" )
    // conout( "Nao foi possível modificar diretório!!" )
    // Return NIL
// EndIf

//Retorna apenas os arquivos contidos no local

//aRetDir := FTPDIRECTORY( "*.*" , )
//Retorna os diretórios e arquivos contidos no local

aRetDir := FTPDIRECTORY( "*.*" , "D")
//Verifica se o array está vazio

If Empty( aRetDir )
    conout( "Array Vazio!!" )
    Return NIL
EndIf

Return
