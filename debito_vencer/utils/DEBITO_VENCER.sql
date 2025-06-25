WITH TITULOS_FILTRADOS AS (
	SELECT 				
		  Id
		, PrefTitulo
		, NrTitulo
		, ParcelaTitulo
		, IdCliente
		, MesRefTitulo
		, AnoRefTitulo
		, DtEmissao
		, DtVencto
		, VlLiquido
		, NrNotaFiscal
		, DocumentoERP
		, TxTipoCobranca
		, TituloPrincipalUnificado
		, CdChaveErp
		, CdVerificacao
		, COUNT(*) OVER (PARTITION BY IdCliente) AS TITULOS_ABERTOS
		, MIN(DtVencto) OVER (PARTITION BY IdCliente) AS TITULO_MAIS_ANTIGO
		, ROW_NUMBER() OVER (PARTITION BY IdCliente ORDER BY DtVencto ASC) AS RN
	FROM Titulos a
	WHERE TxTipoCobranca IN ('MONITORAMENTO', 'COBR.UNIFICADA')
	  AND DtBaixa IS NULL
	  AND DATEDIFF(DAY, GETDATE(), a.DtVencto) > 0
),

TITULO AS (
	SELECT *
	FROM TITULOS_FILTRADOS
	WHERE RN = 1
),

CLIENTE AS (
	SELECT
		  IdCliente
		, NmCliente
		, TxFormaPagamento
		, IDCLIENTEREDE
		, CASE 
			WHEN LEN(TxEmail) < 8 AND LEN(TxEmailCobranca1) >= 8 THEN TxEmailCobranca1
			WHEN TxEmail IS NULL AND LEN(TxEmailCobranca1) >= 8 THEN TxEmailCobranca1
			WHEN LEN(TxEmail) >= 8 THEN TxEmail
			ELSE NULL
		  END AS TxEmail
		, DDDCobranca + TelCobranca AS TEL_COBRANCA
		, DDDResponsavel + TelResponsavel AS TEL_RESPONSAVEL
		, DDDInstalacao + TelInstalacao AS TEL_INSTALACAO
	FROM [DATA_WAREHOUSE].[dbo].[Clientes]
	WHERE (IDCLIENTEREDE IS NULL OR IDCLIENTEREDE = 0)
	  AND TxFormaPagamento = 'DÉBITO AUTOMÁTICO'
)

SELECT
	  TITULO.IdCliente AS CONTRATO
	, CLIENTE.NmCliente AS NOME
	, CLIENTE.TxEmail AS EMAIL
	, CLIENTE.TEL_COBRANCA
	, CLIENTE.TEL_RESPONSAVEL
	, CLIENTE.TEL_INSTALACAO
	, CLIENTE.TxFormaPagamento AS FORMA_PAGAMENTO
	, TITULO.NrTitulo AS TITULO	
	, TITULO.VlLiquido AS VALOR_LIQUIDO
	, TITULO.MesRefTitulo AS MES
	, 0,TITULO.AnoRefTitulo AS ANO
	, DATEDIFF(DAY, GETDATE(), TITULO.DtVencto) AS DIAS
	, TITULO.DtVencto AS VENCIMENTO	
	, TITULO.NrNotaFiscal AS NOTA_FISCAL	
	, TITULO.CdVerificacao AS CODIGO
FROM TITULO
INNER JOIN CLIENTE ON TITULO.IdCliente = CLIENTE.IdCliente
-- PEGA TÍTULOS ATÉ 10 DIAS ANTES DO VENCIMENTO
WHERE DATEDIFF(DAY, GETDATE(), TITULO.DtVencto) <= 10
ORDER BY VENCIMENTO;
