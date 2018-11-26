#INCLUDE "TOTVS.CH"
User Function tstGet()
  Local cHtmlPage

  // Buscar página
  cHtmlPage := Httpget('https://www4.bcb.gov.br/download/fechamento')
  conout("WebPage", cHtmlPage)

//   // Chamar página passando parâmetros
//   cHtmlPage := Httpget('http://www4.bcb.gov.br/download/fechamento')
//   conout("WebPage", cHtmlPage)

//   // ou
//   cHtmlPage := Httpget('http://www4.bcb.gov.br/download/fechamento')
//   conout("WebPage", cHtmlPage)

  // ou utilizando a função Escape (recomendado)
  //cHtmlPage := Httpget('http://www.servidor.com.br/funteste.asp','Id=' + Escape('123') + '&Nome=' + Escape('Ana Silva'))
  //conout("WebPage", cHtmlPage)
Return



User Function T42HTTPGET()
	Local cURL        := "https://www4.bcb.gov.br/Download/fechamento/20180727.csv"
	Local cWebPage    := ""
	Local nHandle     := 0
	Local aHeader     := {}
	Local cHttpHeader := ""

	AAdd(aHeader, "content-type: text/html")
	nHandle := FCreate("C:\Users\vieira.victor\Documents\arquivo.csv")
	cWebPage := HttpGet(cURL)

	FWrite(nHandle, cWebPage)
Return (NIL)
