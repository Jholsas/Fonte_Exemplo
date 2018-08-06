#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'

User Function FINA460A()

Local aParam := PARAMIXB
Local xRet := .T.
Local oObj := ''
Local cIdPonto := ''
Local cIdModel := ''
Local nLinha := 0
Local nQtdLinhas:= 0
Local cMsg := ''
Local cClasse := ""

If aParam <> NIL
    oObj := aParam[1]
    cIdPonto := aParam[2]
    cIdModel := aParam[3]

    /*If cIdPonto == 'MODELPOS' // Bloco substitui o ponto de entrada F460TOK e FA460CON
        cMsg := 'Chamada na validação total do formulário (MODELPOS).' + CRLF
        cMsg += 'ID ' + cIdModel + CRLF
        If cClasse == 'FWFORMGRID' // Bloco substitui o ponto de entrada FA460LOK, validação do Grid, utilizar o ID de Model 'TITGERFO2'
            nQtdLinhas := oObj:Length()
             nLinha := oObj:GetLine()

            cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ' linha(s).' + CRLF
            cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha ) ) + CRLF

        EndIf*/

      /*  If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
            Help( ,, 'Help',, 'O MODELPOS retornou .F.', 1, 0 )
        EndIf
    ElseIf cIdPonto == 'MODELCANCEL' // Bloco substitui os pontos de entrada F460CAN, F460CON e F460SAID no cancelamento da tela de geração de liquidação.
        cMsg := 'Chamada no Botão Cancelar (MODELCANCEL).' + CRLF + 'Deseja Realmente Sair ?'
        If !( xRet := ApMsgYesNo( cMsg ) )
            Help( ,, 'Help',, 'O MODELCANCEL retornou .F.', 1, 0 )
        EndIf
    ElseIf cIdPonto == 'FORMLINEPRE' // Bloco substitui o ponto de entrada A460VALLIN.
        If cIdModel == 'TITGERFO2'
            nQtdLinhas := oObj:Length()
            nLinha := oObj:GetLine()
            If aParam[5] == 'DELETE' // Deleção de Linha do Grid
                cMsg := 'Chamada na pre validação da linha do formulário (FORMLINEPRE).' + CRLF
                cMsg += 'Onde esta se tentando deletar uma linha' + CRLF
                cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ' linha(s).' + CRLF
                cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha ) ) + CRLF
                cMsg += 'ID ' + cIdModel + CRLF

                If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMLINEPRE retornou .F.', 1, 0 )
                EndIf
            EndIf
        EndIf
    ElseIf cIdPonto == 'FORMLINEPOS' // Substitui o ponto de entrada FA460LOK
        If cIdModel == 'TITGERFO2'
            nQtdLinhas := oObj:Length()
            nLinha := oObj:GetLine()
            cMsg := 'Chamada na validação da linha do formulário (FORMLINEPOS).' + CRLF
            cMsg += 'ID ' + cIdModel + CRLF
            cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ' linha(s).' + CRLF
            cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha ) ) + CRLF

            If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                Help( ,, 'Help',, 'O FORMLINEPOS retornou .F.', 1, 0 )
            EndIf
        EndIf*/
    /*  Else*/ If cIdPonto == 'MODELCOMMITNTTS' // Bloco substitui o ponto de entrada F460GRV.
        ApMsgInfo('Chamada apos a gravação total do modelo e fora da transação (MODELCOMMITNTTS).' + CRLF + 'ID ' + cIdModel)
   /* ElseIf cIdPonto == 'BUTTONBAR' // Bloco substitui o ponto de entrada F460BOT.
        ApMsgInfo('Adicionando Botao na Barra de Botoes (BUTTONBAR).' + CRLF + 'ID ' + cIdModel )
        xRet := { {'Salvar', 'SALVAR', { || Alert( 'Salvou' ) }, 'Este botao Salva' } }
    EndIf*/
    EndIf
EndIf

Return xRet
