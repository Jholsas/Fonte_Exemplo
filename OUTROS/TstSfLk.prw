User Function admin()

//testa se ja esta bloqueado
While ( ! SA1->( MsRLock()) )
// mensagem apos movimentacao, para nao bloquear transacao
Alert("Registro bloqueado por outro usu�rio." )

Loop
EndDo


return
