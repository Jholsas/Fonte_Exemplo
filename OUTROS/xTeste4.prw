User function xTeste4()
//Local cRet := ""

 //cRet := RetSem(dDatabase)

//Alert(cRet)

//Local cEAN     := "1234567890126"
//VldCodBar(cEAN)
Local cID := "LOCK_TEST"
  If GlbNmLock(cID)
     MsgInfo("Bloqueio OK")
     Glbunlock(cID)
     MsgInfo("Bloqueio liberado")
  else
     MsgStop("Falha ao obter bloqueio.")
  Endif

return

// user function mycode()
//   Local cID := "LOCK_TEST"
//   If GlbNmLock(cID)
    //  MsgInfo("Bloqueio OK")
    //  Glbunlock(cID)
    //  MsgInfo("Bloqueio liberado")
//   else
    //  MsgStop("Falha ao obter bloqueio.")
//   Endif
// return
