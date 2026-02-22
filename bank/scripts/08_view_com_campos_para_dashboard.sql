-- view com campos para dashboard - Power BI , entre outros

CREATE OR ALTER VIEW dbo.vw_powerbi_clientes_fintech AS
WITH
-- 1) Ledger (Transacoes) consolidado por Cliente
Ledger AS (
    SELECT
        c.ClienteID,
        SUM(CASE WHEN t.Status='CONFIRMADA' AND t.Direcao='C' THEN t.Valor ELSE 0 END) AS Total_Creditos,
        SUM(CASE WHEN t.Status='CONFIRMADA' AND t.Direcao='D' THEN t.Valor ELSE 0 END) AS Total_Debitos,
        SUM(CASE WHEN t.Status='CONFIRMADA' AND t.Tipo='PIX_OUT' THEN t.Valor ELSE 0 END) AS Total_PixOut,
        SUM(CASE WHEN t.Status='CONFIRMADA' AND t.Tipo='PIX_IN'  THEN t.Valor ELSE 0 END) AS Total_PixIn,
        COUNT(CASE WHEN t.Status='CONFIRMADA' THEN 1 END) AS Qtde_Transacoes,
        MIN(CASE WHEN t.Status='CONFIRMADA' THEN CAST(t.DataHora AS DATE) END) AS Primeira_Mov,
        MAX(CASE WHEN t.Status='CONFIRMADA' THEN CAST(t.DataHora AS DATE) END) AS Ultima_Mov
    FROM dbo.Clientes c
    JOIN dbo.Contas ct ON ct.ClienteID = c.ClienteID
    LEFT JOIN dbo.Transacoes t ON t.ContaID = ct.ContaID
    GROUP BY c.ClienteID
),

-- 2) Cartão: compras e chargeback por Cliente
Cartao AS (
    SELECT
        c.ClienteID,
        COUNT(DISTINCT tc.TransacaoCartaoID) AS Total_Compras_Cartao,
        COUNT(DISTINCT cb.ChargebackID)      AS Total_Chargebacks,
        CAST(
            100.0 * COUNT(DISTINCT cb.ChargebackID) /
            NULLIF(COUNT(DISTINCT tc.TransacaoCartaoID), 0)
        AS DECIMAL(7,2)) AS Chargeback_Rate_Pct
    FROM dbo.Clientes c
    LEFT JOIN dbo.Cartoes ca ON ca.ClienteID = c.ClienteID
    LEFT JOIN dbo.TransacoesCartao tc ON tc.CartaoID = ca.CartaoID
    LEFT JOIN dbo.Chargebacks cb ON cb.TransacaoCartaoID = tc.TransacaoCartaoID
    GROUP BY c.ClienteID
),

-- 3) Features de risco (heurísticas)
PixDia AS (
    SELECT
        ct.ClienteID,
        CAST(t.DataHora AS DATE) AS Dia,
        COUNT(*) AS QtdePixOutDia,
        SUM(t.Valor) AS ValorPixOutDia
    FROM dbo.Transacoes t
    JOIN dbo.Contas ct ON ct.ContaID = t.ContaID
    WHERE t.Status='CONFIRMADA'
      AND t.Tipo='PIX_OUT'
    GROUP BY ct.ClienteID, CAST(t.DataHora AS DATE)
),
TxDia AS (
    SELECT
        ct.ClienteID,
        CAST(t.DataHora AS DATE) AS Dia,
        COUNT(*) AS QtdeTxDia
    FROM dbo.Transacoes t
    JOIN dbo.Contas ct ON ct.ContaID = t.ContaID
    WHERE t.Status='CONFIRMADA'
    GROUP BY ct.ClienteID, CAST(t.DataHora AS DATE)
),
Risco AS (
    SELECT
        c.ClienteID,
        /* Score simples e explicável (bom para demo) */
        CAST(
            0
            + CASE WHEN EXISTS (
                SELECT 1 FROM PixDia p
                WHERE p.ClienteID = c.ClienteID
                  AND (p.ValorPixOutDia >= 500 OR p.QtdePixOutDia >= 3)
              ) THEN 30 ELSE 0 END
            + CASE WHEN ISNULL(cart.Total_Chargebacks,0) >= 1 THEN 40 ELSE 0 END
            + CASE WHEN EXISTS (
                SELECT 1 FROM TxDia d
                WHERE d.ClienteID = c.ClienteID AND d.QtdeTxDia >= 8
              ) THEN 20 ELSE 0 END
            + CASE WHEN c.DataCadastro >= DATEADD(DAY,-30, SYSDATETIME()) THEN 10 ELSE 0 END
        AS INT) AS RiskScore
    FROM dbo.Clientes c
    LEFT JOIN Cartao cart ON cart.ClienteID = c.ClienteID
)

SELECT
    c.ClienteID,
    c.Nome,
    c.Documento,
    c.TipoPessoa,
    c.Cidade,
    c.UF,
    c.Status AS StatusCliente,
    CAST(c.DataCadastro AS DATE) AS DataCadastro,

    CAST(ISNULL(l.Total_Creditos,0) AS DECIMAL(18,2)) AS Total_Creditos,
    CAST(ISNULL(l.Total_Debitos,0)  AS DECIMAL(18,2)) AS Total_Debitos,
    CAST(ISNULL(l.Total_Creditos,0) - ISNULL(l.Total_Debitos,0) AS DECIMAL(18,2)) AS Saldo_Calculado,

    CAST(ISNULL(l.Total_PixOut,0) AS DECIMAL(18,2)) AS Total_PixOut,
    CAST(ISNULL(l.Total_PixIn,0)  AS DECIMAL(18,2)) AS Total_PixIn,

    ISNULL(l.Qtde_Transacoes,0) AS Qtde_Transacoes,
    l.Primeira_Mov,
    l.Ultima_Mov,

    ISNULL(cart.Total_Compras_Cartao,0) AS Total_Compras_Cartao,
    ISNULL(cart.Total_Chargebacks,0)    AS Total_Chargebacks,
    ISNULL(cart.Chargeback_Rate_Pct,0)  AS Chargeback_Rate_Pct,

    ISNULL(r.RiskScore,0) AS RiskScore
FROM dbo.Clientes c
LEFT JOIN Ledger l ON l.ClienteID = c.ClienteID
LEFT JOIN Cartao cart ON cart.ClienteID = c.ClienteID
LEFT JOIN Risco r ON r.ClienteID = c.ClienteID;


SELECT TOP 50 *
FROM dbo.vw_powerbi_clientes_fintech
ORDER BY RiskScore DESC, Saldo_Calculado DESC;
