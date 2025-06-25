WITH
	BOLETO AS 
		(
			SELECT 
				CASE 
					WHEN TituloPrincipalUnificado IS NULL 
						THEN
							'https://boletos.adt.com.br/' + 
							RIGHT('000000' + CAST(CAST(idCliente AS NUMERIC) AS NVARCHAR), 6) +
							'_' +	
							LEFT(SUBSTRING(documentoERP, 9, 2) + '__', 2) +  
							'_' + 	
							RIGHT('0000000' + LTRIM(RTRIM(SUBSTRING(documentoERP, 15, 7))), 7)
					ELSE
						(
							SELECT 
								'https://boletos.adt.com.br/' + 
								RIGHT('000000' + CAST(CAST(x.idCliente AS NUMERIC) AS NVARCHAR), 6) +  
								'_' +	
								LEFT(SUBSTRING(x.documentoERP, 9, 2) + '__', 2) +  
								'_' + 	
								RIGHT('0000000' + LTRIM(RTRIM(SUBSTRING(x.documentoERP, 15, 7))), 7)
							FROM Titulos x
							WHERE x.PrefTitulo = SUBSTRING(a.TituloPrincipalUnificado, 1, 3)
							AND x.NrTitulo = SUBSTRING(a.TituloPrincipalUnificado, 4, 7)
							AND x.ParcelaTitulo = SUBSTRING(a.TituloPrincipalUnificado, 11, 1)
						)
				END AS Link_Demonstrativo
				, Id
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
			FROM Titulos a
			WHERE TxTipoCobranca = 'MONITORAMENTO'
			AND DtBaixa IS NULL
			--AND DtEmissao < (GETDATE() - DAY(6))
			--ORDER BY Dtemissao DESC
						
			-- Duas opções de como montar o link do boleto
			-- https://boletos.adt.com.br/268416_DM_4111956 idcliente + _DM_ + NrNotaFiscal
			-- https://boletos.adt.com.br/268416_DM_4111956 idcliente + SUBSTRING(documentoERP)
			
			-- Como montar o link da nota fiscal
			-- "https://nfe.prefeitura.sp.gov.br/contribuinte/notaprint.aspx?ccm=47687347&nf=" + Titulos.CdVerificacao
		),

	TITULO AS 
		(
			SELECT 
				[IdCliente]      
				,[NrTitulo]      
				,[TxLinhaDigitavel]			
			FROM [DATA_WAREHOUSE].[dbo].[vw_Linha_Digitavel_ERP]
		),

	CLIENTE AS 
		(
			SELECT
				IdCliente,
				NmCliente,
				TxFormaPagamento,
				IDCLIENTEREDE,
				CASE 
					WHEN LEN(TxEmail) < 8 AND LEN(TXEMAILCOBRANCA1) < 8 THEN NULL					
					WHEN LEN(TxEmail) < 8 AND TXEMAILCOBRANCA1 IS NULL THEN NULL
					WHEN LEN(TxEmail) < 8 AND LEN(TXEMAILCOBRANCA1) >= 8 THEN TXEMAILCOBRANCA1
					WHEN TxEmail IS NULL AND LEN(TXEMAILCOBRANCA1) < 8 THEN NULL
					WHEN TxEmail IS NULL AND TXEMAILCOBRANCA1 IS NULL THEN NULL
					WHEN TxEmail IS NULL AND LEN(TXEMAILCOBRANCA1) >= 8 THEN TXEMAILCOBRANCA1
					ELSE TxEmail					
				END AS TxEmail,
				DDDCobranca + TelCobranca AS TEL_COBRANCA,
				DDDResponsavel + TelResponsavel AS TEL_RESPONSAVEL,
				DDDInstalacao + TelInstalacao AS TEL_INSTALACAO
			FROM [DATA_WAREHOUSE].[dbo].[Clientes]
			WHERE IDCLIENTEREDE IS NULL OR IDCLIENTEREDE = 0
		)
SELECT
	  BOLETO.IdCliente AS CONTRATO
	, CLIENTE.NmCliente AS NOME
	-- , CLIENTE.IdClienteRede
	, CLIENTE.TxEmail AS EMAIL
	, CLIENTE.TEL_COBRANCA
	, CLIENTE.TEL_RESPONSAVEL
	, CLIENTE.TEL_INSTALACAO
	-- , BOLETO.TxTipoCobranca
	, CLIENTE.TxFormaPagamento AS FORMA_PAGAMENTO
	-- , BOLETO.PrefTitulo
	, BOLETO.NrTitulo AS TITULO	
	, BOLETO.VlLiquido AS VALOR_LIQUIDO
	, BOLETO.MesRefTitulo AS MES
	, BOLETO.AnoRefTitulo AS ANO
	-- , BOLETO.ParcelaTitulo
	-- , BOLETO.DtEmissao
	, DATEDIFF(DAY, GETDATE(), BOLETO.DtVencto) AS DIAS
	, BOLETO.DtVencto AS VENCIMENTO
	, BOLETO.Link_Demonstrativo AS LINK_FATURA
	, BOLETO.NrNotaFiscal AS NOTA_FISCAL
	-- , BOLETO.DocumentoERP
	-- , BOLETO.TituloPrincipalUnificado
	-- , BOLETO.CdChaveErp
	, BOLETO.CdVerificacao AS CODIGO
	-- , TITULO.NrTitulo   
	, TITULO.TxLinhaDigitavel AS LINHA_DIGITAVEL
FROM
	BOLETO 
	INNER JOIN TITULO 	ON BOLETO.NrTitulo = TITULO.NrTitulo
	INNER JOIN CLIENTE 	ON BOLETO.IdCliente = CLIENTE.IdCliente
	WHERE DATEDIFF(DAY, GETDATE(), DtVencto) < 6
	AND DtVencto >= GETDATE()
	ORDER BY NOME
