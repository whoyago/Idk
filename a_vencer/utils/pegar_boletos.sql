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
			WHERE FilialTitulo = 1
			AND TxTipoCobranca = 'MONITORAMENTO'
			--AND DtEmissao < (GETDATE() - DAY(10))
			--ORDER BY Dtemissao DESC
						
			-- https://boletos.adt.com.br/268416_DM_4111956 idcliente + _DM_ + NrNotaFiscal
			-- https://boletos.adt.com.br/268416_DM_4111956 idcliente + SUBSTRING(documentoERP)
		),

	TITULO AS 
		(
			SELECT 
				[IdCliente]      
				,[NrTitulo]      
				,[TxLinhaDigitavel]			
			FROM [DATA_WAREHOUSE].[dbo].[vw_Linha_Digitavel_ERP]
		),
