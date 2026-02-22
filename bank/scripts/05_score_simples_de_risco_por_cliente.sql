WITH PixDia AS (
    SELECT
        ct.ClienteID,
        CAST(t.DataHora AS DATE) AS Dia,
        COUNT(*) AS QtdePixOut,
        SUM(t.Valor) AS ValorPixOut
    FROM dbo.Transacoes t
    JOIN dbo.Contas ct ON ct.ContaID = t.ContaID
    WHERE t.Tipo='PIX_OUT' AND t.Status='CONFIRMADA'
    GROUP BY ct.ClienteID, CAST(t.DataHora AS DATE)
),
Cb AS (
    SELECT
        ca.ClienteID,
        COUNT(*) AS QtdeChargebacks
    FROM dbo.Chargebacks cb
    JOIN dbo.TransacoesCartao tc ON tc.TransacaoCartaoID = cb.TransacaoCartaoID
    JOIN dbo.Cartoes ca ON ca.CartaoID = tc.CartaoID
    GROUP BY ca.ClienteID
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
Score AS (
    SELECT
        c.ClienteID,
        c.Nome,
        /* score base */
        0
        + CASE WHEN EXISTS (
            SELECT 1 FROM PixDia p
            WHERE p.ClienteID=c.ClienteID AND (p.ValorPixOut >= 500 OR p.QtdePixOut >= 3)
          ) THEN 30 ELSE 0 END
        + CASE WHEN ISNULL(cb.QtdeChargebacks,0) >= 1 THEN 40 ELSE 0 END
        + CASE WHEN EXISTS (
            SELECT 1 FROM TxDia d
            WHERE d.ClienteID=c.ClienteID AND d.QtdeTxDia >= 8
          ) THEN 20 ELSE 0 END
        + CASE WHEN c.DataCadastro >= DATEADD(DAY,-30, SYSDATETIME()) THEN 10 ELSE 0 END
        AS RiskScore
    FROM dbo.Clientes c
    LEFT JOIN Cb cb ON cb.ClienteID = c.ClienteID
)
SELECT *
FROM Score
ORDER BY RiskScore DESC, ClienteID;
