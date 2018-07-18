#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'

user function CRMA060()
	
Local aParam     := PARAMIXB
Local xRet       := .T.
Local oObj       := ''
Local cIdPonto   := ''
Local cIdModel   := ''
Local lIsGrid    := .F.
 
Local nLinha     := 0
Local nQtdLinhas := 0
Local cClasse 	 := ''
Local cMsg       := ''
 
 
If aParam <> NIL
      
       oObj       := aParam[1]
       cIdPonto   := aParam[2]
       cIdModel   := aParam[3]
       lIsGrid    := ( Len( aParam ) > 3 )
      
      /* If lIsGrid
             nQtdLinhas := oObj:GetQtdLine()
             nLinha     := oObj:nLine
      EndIf*/
      
       If     cIdPonto == 'MODELPOS'
             cMsg := 'Chamada na valida��o total do modelo (MODELPOS).' + CRLF
             cMsg += 'ID ' + cIdModel + CRLF
            
             If !( xRet := ApMsgYesNo( cMsg + 'C ontinua ?' ) )
                    Help( ,, 'Help',, 'O MODELPOS retornou .F.', 1, 0 )
             EndIf
            
       ElseIf cIdPonto == 'FORMPOS'
             cMsg := 'Chamada na valida��o total do formul�rio (FORMPOS).' + CRLF
             cMsg += 'ID ' + cIdModel + CRLF
            
             If      cClasse == 'FWFORMGRID'
                    cMsg += '� um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + '     linha(s).' + CRLF
cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF
             ElseIf cClasse == 'FWFORMFIELD'
                    cMsg += '� um FORMFIELD' + CRLF
             EndIf
            
             If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMPOS retornou .F.', 1, 0 )
             EndIf
            
       ElseIf cIdPonto == 'FORMLINEPRE'
             If aParam[5] == 'DELETE'
             		cMsg := 'Chamada na pre valida��o da linha do formul�rio (FORMLINEPRE).' + CRLF
                    cMsg += 'Onde esta se tentando deletar uma linha' + CRLF
                    cMsg += '� um FORMGRID com ' + Alltrim( Str( nQtdLinhas)) +   ' linha(s).' + CRLF
                    cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha)) +  CRLF
                    cMsg += 'ID ' + cIdModel + CRLF
                   
                    If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                           Help( ,, 'Help',, 'O FORMLINEPRE retornou .F.', 1, 0 )
                    EndIf
             EndIf
            
       ElseIf cIdPonto == 'FORMLINEPOS'
cMsg := 'Chamada na valida��o da linha do formul�rio (FORMLINEPOS).' + CRLF
             cMsg += 'ID ' + cIdModel + CRLF
             cMsg += '� um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ' linha(s).' + CRLF
             cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF
            
             If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMLINEPOS retornou .F.', 1, 0 )
             EndIf
            
       ElseIf cIdPonto == 'MODELCOMMITTTS'
ApMsgInfo('Chamada apos a grava��o total do modelo e dentro da transa��o (MODELCOMMITTTS).' + CRLF + 'ID ' + cIdModel )
            
       ElseIf cIdPonto == 'MODELCOMMITNTTS'
ApMsgInfo('Chamada apos a grava��o total do modelo e fora da transa��o (MODELCOMMITNTTS).' + CRLF + 'ID ' + cIdModel)
            
             //ElseIf cIdPonto == 'FORMCOMMITTTSPRE'
            
       ElseIf cIdPonto == 'FORMCOMMITTTSPOS'
ApMsgInfo('Chamada apos a grava��o da tabela do formul�rio (FORMCOMMITTTSPOS).' + CRLF + 'ID ' + cIdModel)
            
       ElseIf cIdPonto == 'MODELCANCEL'
cMsg := 'Chamada no Bot�o Cancelar (MODELCANCEL).' + CRLF + 'Deseja Realmente Sair ?'
            
             If !( xRet := ApMsgYesNo( cMsg ) )
                    Help( ,, 'Help',, 'O MODELCANCEL retornou .F.', 1, 0 )
             EndIf
            
       ElseIf cIdPonto == 'BUTTONBAR'
ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
xRet := { {'Salvar', 'SALVAR', { || Alert( 'Salvou' ) }, 'Este botao Salva' } }
            
       EndIf
 
EndIf
 
Return xRet



/*

#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
 
//------------------------------------------------------------------------------
/*/{Protheus.doc} MNTA055
User Function MNTA055, para chamada dos pontos de entrada padr�es do MVC.
 
@author Guilherme Freudenburg
@since 27/03/2018
@version P12
 
@return xRet  - Valor de retorno do ponto de entrada.
/*/
//------------------------------------------------------------------------------
User Function MNTA055() // Fun��o respons�vel pela chamda dos pontos de entrada da rotina MNTA055 - Localiza��es.
 
Local aParam   := PARAMIXB //Par�metros passados pelo ponto de entrada.
Local xRet     := .T.// Retorno da fun��o.
Local oObj     := '' // Objeto que receber� o modelo.
Local cIdPonto := '' // Identificador da chamada do ponto de entrada.
Local cIdModel := '' // Identificador do modelo utilizado.
Local nOpera   := 0  // Receber� o valor da opera��o selecionada.
Local cCodLoc  := '' // Receber� o c�digo da localiza��o.
Local cNomeLoc := '' // Receber� o nome da localiza��o.
 
If aParam <> NIL // Identifica que foram enviado os par�metros.
    oObj     := aParam[1] // Modelo ativado.
    cIdPonto := aParam[2] // Determina o ponto de chamada.
    cIdModel := aParam[3] // Identificador do modelo.
 
    If cIdPonto == 'MODELCOMMITNTTS' // Ap�s a grava��o total do modelo e fora da transa��o.
 
        nOpera := oObj:GetOperation() // Receber� a opera��o selecionada.
 
        If nOpera == MODEL_OPERATION_INSERT .Or.; // Caso seja Inclus�o.
           nOpera == MODEL_OPERATION_UPDATE .Or.; // Caso seja Altera��o.
           nOpera == MODEL_OPERATION_DELETE // Caso seja Exclus�o.
 
            // Recebe o valor dos campos de C�digo e Nome.
            cCodLoc := oObj:GetValue( "MNTA055_TPS" , "TPS_CODLOC" )
            cNomeLoc := oObj:GetValue( "MNTA055_TPS" , "TPS_NOME" )
 
        EndIf
 
        xRet := .T.
     
    EndIf
 
EndIf
 
Return xRet //Retorno do ponto de entrada.*/