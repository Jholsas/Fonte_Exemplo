#include "protheus.ch"
#include "parmtype.ch"
 
User Function ITEM ()
    Local aParam   := PARAMIXB
    Local oModel   := FwModelActive()
    Local oObj     := ""
    Local cIdPonto := ""
    Local cIdModel := ""
    Local lIsGrid  := .F.
    Local xRet     := .T.
    
         
    // VERIFICA SE APARAM NÃO ESTÁ NULO
    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)
         
        //  VERIFICA SE O PONTO EM QUESTÃO É O FORMPOS
        If cIdPonto == "MODELPRE"
         
         	
            // VERIFICA SE OMODEL NÃO ESTÁ NULO
           
             
                  oModel:GetModel("SB5MASTER"):SetValue("B5_CEME","") // ATRIBUI VALOR A VARIÁVEL POR MEIO DO MODELO DE DADOS
                  oModel:GetModel("SB5MASTER"):SetValue("B5_DES","") // ATRIBUI VALOR A VARIÁVEL POR MEIO DO MODELO DE DADOS
                
            
             
        EndIf
     
    EndIf
Return xRet




















