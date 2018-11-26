#INCLUDE "protheus.ch"

#DEFINE DEFAULT_FTP 21

User Function TestFTP()


//Tenta se conectar ao servidor ftp
if !FTPCONNECT ( "localhost" , 21 ,"victor", "1234" )
	conout( "Nao foi possível se conectar!!" )
	Return NIL
EndIf

//Tenta mudar do diretório corrente ftp, para o diretório
//especificado como parâmetro
/*if !FTPDIRCHANGE( "\TESTE_FTP" )
	conout( "Nao foi possível modificar diretório!!" )
	Return NIL
EndIf*/

//Tenta realizar o upload de um item qualquer no array
if !FTPUPLOAD("\FTP\Testfile4.txt", "Testfile4.txt")
	conout( "Nao foi possivel realizar o upload!!" )
	Return NIL
EndIf

//Tenta desconectar do servidor ftp
FTPDISCONNECT ()

Return NIL
