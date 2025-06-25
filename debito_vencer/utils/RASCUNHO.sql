WITH TITULOS_PRINCIPAIS AS (
    SELECT 
        x.IdCliente,
        x.PrefTitulo,
        x.NrTitulo,
        x.ParcelaTitulo,
        x.DocumentoERP,
        a.TituloPrincipalUnificado
    FROM Titulos a
    INNER JOIN Titulos x
        ON x.PrefTitulo = SUBSTRING(a.TituloPrincipalUnificado, 1, 3)
       AND x.NrTitulo = SUBSTRING(a.TituloPrincipalUnificado, 4, 7)
       AND x.ParcelaTitulo = SUBSTRING(a.TituloPrincipalUnificado, 11, 1)
    WHERE a.TituloPrincipalUnificado IS NOT NULL
),

BOLETO_BASE AS (
    SELECT 
        a.Id,
        a.IdCliente,
        a.PrefTitulo,
        a.NrTitulo,
        a.ParcelaTitulo,
        a.MesRefTitulo,
        a.AnoRefTitulo,
        a.DtEmissao,
        a.DtVencto,
        a.VlLiquido,
        a.NrNotaFiscal,
        a.DocumentoERP,
        a.TxTipoCobranca,
        a.TituloPrincipalUnificado,
        a.CdChaveErp,
        a.CdVerificacao,
        ISNULL(p.DocumentoERP, a.DocumentoERP) AS DocUsado
    FROM Titulos a
    LEFT JOIN TITULOS_PRINCIPAIS p
        ON a.TituloPrincipalUnificado IS NOT NULL
       AND p.TituloPrincipalUnificado = a.TituloPrincipalUnificado
    WHERE a.TxTipoCobranca = 'MONITORAMENTO'
      AND a.DtBaixa IS NULL
),

BOLETO AS (
    SELECT 
        *,
        'https://boletos.adt.com.br/' +
        RIGHT('000000' + CAST(IdCliente AS VARCHAR), 6) + '_' +
        LEFT(SUBSTRING(DocUsado, 9, 2) + '__', 2) + '_' +
        RIGHT('0000000' + LTRIM(RTRIM(SUBSTRING(DocUsado, 15, 7))), 7) AS Link_Demonstrativo
    FROM BOLETO_BASE
),

TITULO AS (
    SELECT 
        IdCliente,
        NrTitulo,
        TxLinhaDigitavel
    FROM DATA_WAREHOUSE.dbo.vw_Linha_Digitavel_ERP
),

CLIENTE AS (
    SELECT
        IdCliente,
        NmCliente,
        TxFormaPagamento,
        IDCLIENTEREDE,
        COALESCE(NULLIF(TxEmail, ''), NULLIF(TxEmailCobranca1, '')) AS TxEmail,
        DDDCobranca + TelCobranca AS Tel_Cobranca,
        DDDResponsavel + TelResponsavel AS Tel_Responsavel,
        DDDInstalacao + TelInstalacao AS Tel_Instalacao
    FROM DATA_WAREHOUSE.dbo.Clientes
    WHERE IDCLIENTEREDE IS NULL OR IDCLIENTEREDE = 0
)

SELECT
    B.IdCliente AS CONTRATO,
    C.NmCliente AS NOME,
    C.TxEmail AS EMAIL,
    C.Tel_Cobranca,
    C.Tel_Responsavel,
    C.Tel_Instalacao,
    C.TxFormaPagamento AS FORMA_PAGAMENTO,
    B.NrTitulo AS TITULO,
    B.VlLiquido AS VALOR_LIQUIDO,
    B.MesRefTitulo AS MES,
    B.AnoRefTitulo AS ANO,
    DATEDIFF(DAY, GETDATE(), B.DtVencto) AS DIAS,
    B.DtVencto AS VENCIMENTO,
    B.Link_Demonstrativo AS LINK_FATURA,
    B.NrNotaFiscal AS NOTA_FISCAL,
    B.CdVerificacao AS CODIGO,
    T.TxLinhaDigitavel AS LINHA_DIGITAVEL
FROM BOLETO B
INNER JOIN TITULO T ON B.NrTitulo = T.NrTitulo AND B.IdCliente = T.IdCliente
INNER JOIN CLIENTE C ON B.IdCliente = C.IdCliente
WHERE DATEDIFF(DAY, GETDATE(), B.DtVencto) < 6
  AND B.DtVencto >= GETDATE()
ORDER BY C.NmCliente;
