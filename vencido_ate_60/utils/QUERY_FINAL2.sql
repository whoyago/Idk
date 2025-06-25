WITH
	INADIMPLENTE
	AS
	(
		-- Contagem de títulos em aberto
		SELECT 
			IdCliente
			,DTVENCTO
			,NrTitulo
			,NrNotaFiscal
			,CdVerificacao
			,TITULOS_ABERTOS
			,TITULO_MAIS_ANTIGO
			,RN
		FROM (
			SELECT 
				IdCliente
				,DTVENCTO
				,NrTitulo
				,NrNotaFiscal
				,CdVerificacao
				,COUNT(*) OVER (PARTITION BY IdCliente) AS TITULOS_ABERTOS
				,MAX(DTVENCTO) OVER (PARTITION BY IdCliente) AS TITULO_MAIS_ANTIGO --MAX A PEDIDO DA TATI (2 EM ABERTO)
				,ROW_NUMBER() OVER (PARTITION BY IDCLIENTE ORDER BY IDCLIENTE) AS RN
			FROM [DATA_WAREHOUSE].[dbo].[Titulos]
			WHERE ([TipoRecebimento] is null)
				AND [DtRecebimento] is null
				AND (MotivoBaixa is null or MotivoBaixa = 'LUCROS E PERDAS')
				AND DTVENCTO < GETDATE()
				AND TXTIPOCOBRANCA IN ('MONITORAMENTO', 'COBR.UNIFICADA')
			) AS B
		WHERE RN = 1 		
	),

	TITULO AS 
	(
		SELECT 
			[IdCliente]      
			,[NrTitulo]      
			,[TxLinhaDigitavel]			
		FROM [DATA_WAREHOUSE].[dbo].[vw_Linha_Digitavel_ERP]
	),

	CLIENTES
	AS
	(
		SELECT
			IdCliente,
			NmCliente,
            CASE 
				WHEN LEN(TxEmail) < 8 AND LEN(TXEMAILCOBRANCA1) < 8 THEN NULL					
				WHEN LEN(TxEmail) < 8 AND TXEMAILCOBRANCA1 IS NULL THEN NULL
				WHEN LEN(TxEmail) < 8 AND LEN(TXEMAILCOBRANCA1) >= 8 THEN TXEMAILCOBRANCA1
				WHEN TxEmail IS NULL AND LEN(TXEMAILCOBRANCA1) < 8 THEN NULL
				WHEN TxEmail IS NULL AND TXEMAILCOBRANCA1 IS NULL THEN NULL
				WHEN TxEmail IS NULL AND LEN(TXEMAILCOBRANCA1) >= 8 THEN TXEMAILCOBRANCA1
				ELSE TxEmail					
			END AS TxEmail,
			IdSituacao,
			IDCLIENTEREDE,
			DDDCobranca + TelCobranca AS TEL_COBRANCA,
			DDDResponsavel + TelResponsavel AS TEL_RESPONSAVEL,
			DDDInstalacao + TelInstalacao AS TEL_INSTALACAO,
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
        WHERE IDSITUACAO IN (1, 11, 17, 20)
		AND (IDCLIENTEREDE IS NULL OR IDCLIENTEREDE = 0)
		AND TxFormaPagamento <> 'Débito Automático'
	)
	
SELECT
	CLIENTES.IDCLIENTE AS CONTRATO,
	INADIMPLENTE.TITULOS_ABERTOS,
	CLIENTES.NMCLIENTE AS NOME,
    CLIENTES.TxEmail AS EMAIL,
	CLIENTES.VlMensalidadeCliente AS TICKET,
	CLIENTES.TEL_COBRANCA,
	CLIENTES.TEL_RESPONSAVEL,
	CLIENTES.TEL_INSTALACAO,
	CLIENTES.TpCobranca AS TIPO_COBRANÇA,
	CLIENTES.TxFormaPagamento AS FORMA_PAGAMENTO,	
	INADIMPLENTE.NrTitulo AS TITULO,
	INADIMPLENTE.NrNotaFiscal AS NOTA_FISCAL,
	INADIMPLENTE.DTVENCTO AS VENCIMENTO,
	TITULO.TxLinhaDigitavel AS LINHA_DIGITAVEL,
	INADIMPLENTE.CdVerificacao AS CODIGO
FROM CLIENTES
	INNER JOIN INADIMPLENTE 		ON INADIMPLENTE.IDCLIENTE 					= CLIENTES.IDCLIENTE
	LEFT JOIN TITULO				ON TITULO.NrTitulo							= INADIMPLENTE.NrTitulo
WHERE DATEDIFF(DAY, INADIMPLENTE.TITULO_MAIS_ANTIGO, GETDATE()) BETWEEN 5 AND 60
--AND TITULOS_ABERTOS <= 1
AND TITULO.TxLinhaDigitavel IS NOT NULL