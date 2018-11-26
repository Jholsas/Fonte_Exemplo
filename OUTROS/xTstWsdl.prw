
#Include "TOTVS.ch"
#Include "PARMTYPE.ch"
#Include "APWEBSRV.ch"

#Define ENTER Chr(10) + Chr(13)  // TODO: REMOVER
#Define TAB   Chr(9)             // TODO: REMOVER


User Function TstWsld()
    Local nPOs     As Numeric
    Local oWSDL    As Object
    Local aOper    As Array
    Local aSimple  As Array
    Local aComplex As Array

    Local xRet := .T. // TODO: REMOVER

    oWSDL := TWSDLManager():New()

    oWSDL:lSSLInsecure := .T.
    oWSDL:lUseNSPrefix := .T.
    oWSDL:nTimeout     := 120

    oWSDL:SetAuthentication("protheus", "protheus")

    If (!oWSDL:ParseURL("https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl"))
        ConOutErr(oWSDL)
    Else
        aOper := oWSDL:ListOperations()
        xRet := oWSDL:SetOperation(aOper[1][1])

        If (xRet == .F.)
            ConOut("Erro: " + oWSDL:cError)
           Return (NIL)
        Else
            ConOut(" Parse OK")

        EndIf

        aSimple  := oWSDL:SimpleInput()
        aComplex := oWSDL:ComplexInput()
    EndIf


Return (NIL)
