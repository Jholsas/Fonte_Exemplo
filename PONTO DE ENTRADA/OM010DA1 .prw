#include 'protheus.ch'
#include 'parmtype.ch'

user function OM010DA1 ()

	Local nTipo:= Paramixb[1]
	Local nOpt	:= Paramixb[2]

	do case
		case  nOpt == 3
		MsgAlert( Alltrim(nOpt) + " incluída com sucesso!")
		case nOpt == 4
		msgalert( alltrim(nOpt) +" alterada com sucesso!")
		case nOpt == 5
		msgalert( alltrim(nOpt) +" excluída com sucesso!")
	end case

return
