#include 'protheus.ch'
#include 'parmtype.ch'

user function MT110CFM ()

	Local ExpC1  := PARAMIXB[1]
	Local ExpN1  := PARAMIXB[2]
	// Valida��es do Usu�rioReturn Nil

		RecLock("SC1",.F.)
		
		IF SC1->C1_APROV == 'L'
		
		C1_DTLIBSC:= DATE()

		SC1-> (MsUnlock())

	EndIf

return