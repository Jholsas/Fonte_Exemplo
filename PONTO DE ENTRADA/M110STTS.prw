#include 'protheus.ch'
#include 'parmtype.ch'

user function M110STTS()


User Function M110STTS() 
	Local cNumSol	:= Paramixb[1]
	Local nOpt		:= Paramixb[2]
	
	do case	
		case  Paramixb[2] == 1
				MsgAlert("Solicitação " + Alltrim(cNumSol) + " incluída com sucesso!")	
		case Paramixb[2] == 2
				msgalert("Solicitação "+ alltrim(cNumSol) +" alterada com sucesso!")   	
		case Paramixb[2] == 3
				msgalert("Solicitação "+ alltrim(cNumSol) +" excluída com sucesso!")   
	end case 

Return Nil


