WITH TITULOS_INADIMPLENTES AS (
	SELECT 
		IdCliente,
		DTVENCTO,
		NrTitulo,
		NrNotaFiscal,
		CdVerificacao,
		COUNT(*) OVER (PARTITION BY IdCliente) AS TITULOS_ABERTOS,
		MIN(DTVENCTO) OVER (PARTITION BY IdCliente) AS TITULO_MAIS_ANTIGO,
		ROW_NUMBER() OVER (PARTITION BY IdCliente ORDER BY DTVENCTO ASC) AS RN
	FROM [DATA_WAREHOUSE].[dbo].[Titulos]
	WHERE TipoRecebimento IS NULL
	  AND DtRecebimento IS NULL
	  AND (MotivoBaixa IS NULL OR MotivoBaixa = 'LUCROS E PERDAS')
	  AND DTVENCTO < GETDATE()
	  AND DATEDIFF(DAY, DTVENCTO, GETDATE()) BETWEEN 4 AND 58
	  AND TxTipoCobranca IN ('MONITORAMENTO', 'COBR.UNIFICADA')
),

LINHA_DIGITAVEL AS (
	SELECT 
		IdCliente, NrTitulo, TxLinhaDigitavel
	FROM [DATA_WAREHOUSE].[dbo].[vw_Linha_Digitavel_ERP]
),

CLIENTES_FILTRADOS AS (
	SELECT
		IdCliente,
		NmCliente,
		COALESCE(NULLIF(TxEmail, ''), NULLIF(TxEmailCobranca1, '')) AS TxEmail,
		IdSituacao,
		IdClienteRede,
		DDDCobranca + TelCobranca AS Tel_Cobranca,
		DDDResponsavel + TelResponsavel AS Tel_Responsavel,
		DDDInstalacao + TelInstalacao AS Tel_Instalacao,
		VlMensalidadeCliente,
		TxCanalVendasOrigem,
		TpCobranca,
		TxFormaPagamento,
		DtAtivacaoInicial,
		TpVenda,
		TxCanalVendasAtual,
		TxTipoCanalAtual,
		TxOrigemCliente
	FROM [DATA_WAREHOUSE].[dbo].[Clientes]
	WHERE IdSituacao IN (1, 11, 17, 20)
	  AND ISNULL(IdClienteRede, 0) = 0
	  AND TxFormaPagamento = 'Débito Automático'
)

SELECT
	c.IdCliente AS CONTRATO,
	t.TITULOS_ABERTOS,
	c.NmCliente AS NOME,
	c.TxEmail AS EMAIL,
	c.VlMensalidadeCliente AS TICKET,
	c.Tel_Cobranca AS TEL_COBRANCA,
	c.Tel_Responsavel AS TEL_RESPONSAVEL,
	c.Tel_Instalacao AS TEL_INSTALACAO,
	c.TpCobranca AS TIPO_COBRANCA,
	c.TxFormaPagamento AS FORMA_PAGAMENTO,
	t.NrTitulo AS TITULO,
	t.NrNotaFiscal AS NOTA_FISCAL,
	t.DTVENCTO AS VENCIMENTO,
	COALESCE(ld.TxLinhaDigitavel, '0') AS LINHA_DIGITAVEL,
	COALESCE(t.CdVerificacao, '0') AS CODIGO
FROM TITULOS_INADIMPLENTES t
JOIN CLIENTES_FILTRADOS c ON c.IdCliente = t.IdCliente
LEFT JOIN LINHA_DIGITAVEL ld ON ld.NrTitulo = t.NrTitulo
WHERE t.RN = 1
ORDER BY c.IdCliente;
