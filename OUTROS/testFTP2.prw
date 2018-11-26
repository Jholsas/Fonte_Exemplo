//Para que o exemplo abaixo funcione, � necess�rio que seu computador tenha sido configurado como um servidor ftp.
#INCLUDE "protheus.ch"
#DEFINE DEFAULT_FTP 21
#DEFINE PATH "\teste\"
user Function TestFTP2()

Local aRetDir := {}

//Tenta se conectar ao servidor ftp em localhost na porta 21
//com usu�rio e senha an�nimos
if !FTPCONNECT ( "localhost" , 21 ,"victor", "1234" )
	conout( "Nao foi poss�vel se conectar!!" )
	Return NIL
EndIf

//Tenta mudar do diret�rio corrente ftp, para o diret�rio
//especificado como par�metro

// if !FTPDIRCHANGE( "/test" )
    // conout( "Nao foi poss�vel modificar diret�rio!!" )
    // Return NIL
// EndIf

//Retorna apenas os arquivos contidos no local

//aRetDir := FTPDIRECTORY( "*.*" , )
//Retorna os diret�rios e arquivos contidos no local

aRetDir := FTPDIRECTORY( "*.*" , "D")
//Verifica se o array est� vazio

If Empty( aRetDir )
    conout( "Array Vazio!!" )
    Return NIL
EndIf

Return
