#INCLUDE "PROTHEUS.CH"
User Function  SF2460I()

Alert("PE - SF2460I")

RecLock("SF2",.F.)

Replace F2_TXMOEDA WITH 1000

MsUnLock()




Return()
