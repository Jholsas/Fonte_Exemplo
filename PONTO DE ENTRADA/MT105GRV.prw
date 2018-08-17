#INCLUDE 'PROTHEUS.CH'

User Function MT105FIM()
Local nOpcap := PARAMIXB
Alert("Ponto de Entrada - MT105GRV ")
ConOut( "Ponto de Entrada - MT105GRV ")


EVAL({||_RET:=POSICIONE("SBM",1,XFILIAL("SBM")+M->B1_GRUPO,"BM_DESC"), !EMPTY(M->B1_TIPO) .OR. M->B1_TIPO$_RET})


Return
