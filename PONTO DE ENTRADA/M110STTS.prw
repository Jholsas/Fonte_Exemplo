#include 'protheus.ch'
#include 'parmtype.ch'

user function M110STTS()


User Function M110STTS() 
	Local cNumSol	:= Paramixb[1]
	Local nOpt		:= Paramixb[2]
	
	do case	
		case  Paramixb[2] == 1
				MsgAlert("Solicita��o " + Alltrim(cNumSol) + " inclu�da com sucesso!")	
		case Paramixb[2] == 2
				msgalert("Solicita��o "+ alltrim(cNumSol) +" alterada com sucesso!")   	
		case Paramixb[2] == 3
				msgalert("Solicita��o "+ alltrim(cNumSol) +" exclu�da com sucesso!")   
	end case 

Return Nil


