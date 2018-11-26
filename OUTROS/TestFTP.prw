#INCLUDE "protheus.ch"

#DEFINE DEFAULT_FTP 21

User Function TestFTP()


//Tenta se conectar ao servidor ftp
if !FTPCONNECT ( "localhost" , 21 ,"victor", "1234" )
	conout( "Nao foi poss�vel se conectar!!" )
	Return NIL
EndIf

//Tenta mudar do diret�rio corrente ftp, para o diret�rio
//especificado como par�metro
/*if !FTPDIRCHANGE( "\TESTE_FTP" )
	conout( "Nao foi poss�vel modificar diret�rio!!" )
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
