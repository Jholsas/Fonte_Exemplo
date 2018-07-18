#include 'protheus.ch'
#include 'parmtype.ch'

User Function FA060VLD
	Local cMarca := ParamIxb[1]
	Local cAlias := ParamIxb[2]

	//if procname(3) == "{||Fa060bAval(cMarca,oValor,oQtda,oPrazoMed,nLimite,lMarkAbt,aChaveLbn,lF060Mark)}"S

	lRet := Aviso (	"FA060VLD", "Titulo " + Iif( Empty( cMarca ), "Desmarcado.","Marcado." ) + CRLF + ;		
	"Prefixo: " + RTrim( (cAlias)->E1_PREFIXO ) + " / Número: " + RTrim( (cAlias)->E1_NUM )  + " / " + ;		
	"Parcela: " + RTrim( (cAlias)->E1_PARCELA ) + " / Tipo: "   + RTrim( (cAlias)->E1_TIPO ) , ;
	{"Confirmar", "Cancelar"}, 3 ) == 1 

	Alert("Chamou o Ponto FA060VLD ") 
	/*else
	lret := .T.
	endIf	*/						



return lRet

