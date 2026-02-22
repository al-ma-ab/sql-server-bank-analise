WITH M AS (
    SELECT
        ct.ClienteID,
        DATEFROMPARTS(YEAR(t.DataHora), MONTH(t.DataHora), 1) AS Mes,
        SUM(CASE WHEN t.Direcao='C' THEN t.Valor ELSE 0 END) AS Creditos,
        SUM(CASE WHEN t.Direcao='D' THEN t.Valor ELSE 0 END) AS Debitos,
        SUM(CASE WHEN t.Tipo='PIX_OUT' THEN t.Valor ELSE 0 END) AS PixOut
    FROM dbo.Transacoes t
    JOIN dbo.Contas ct ON ct.ContaID = t.ContaID
    WHERE t.Status='CONFIRMADA'
    GROUP BY ct.ClienteID, DATEFROMPARTS(YEAR(t.DataHora), MONTH(t.DataHora), 1)
)
SELECT
    c.ClienteID,
    c.Nome,
    m.Mes,
    m.Creditos,
    m.Debitos,
    (m.Creditos - m.Debitos) AS SaldoLiquido,
    m.PixOut
FROM M m
JOIN dbo.Clientes c ON c.ClienteID = m.ClienteID
ORDER BY m.Mes DESC, SaldoLiquido DESC;
