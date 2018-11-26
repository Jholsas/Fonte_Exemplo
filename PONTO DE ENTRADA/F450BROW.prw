#Include "TOTVS.ch"

User Function F450BROW()
    Local aParam  := PARAMIXB
    Local aCampos := {}
    Local aCpoBro := {}

    MsgInfo("PE F450BROW")

    AAdd(aParam[1], {"TESTE", "C", 20, 0})
    AAdd(aParam[2], {"TESTE",, "TESTE", "@X"})

Return (aParam)


MovConta("CC","dd/mm/aaaa","dd/mm/aaaa","moeda","TpSaldo","Retorno")
