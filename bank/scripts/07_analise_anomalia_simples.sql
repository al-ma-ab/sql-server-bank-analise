WITH PixDia AS (
    SELECT
        ct.ClienteID,
        CAST(t.DataHora AS DATE) AS Dia,
        SUM(t.Valor) AS TotalPixOutDia
    FROM dbo.Transacoes t
    JOIN dbo.Contas ct ON ct.ContaID = t.ContaID
    WHERE t.Tipo='PIX_OUT' AND t.Status='CONFIRMADA'
    GROUP BY ct.ClienteID, CAST(t.DataHora AS DATE)
),
Stats AS (
    SELECT
        ClienteID,
        AVG(CAST(TotalPixOutDia AS DECIMAL(18,2))) AS MediaDia,
        MAX(TotalPixOutDia) AS MaxDia
    FROM PixDia
    GROUP BY ClienteID
)
SELECT
    c.ClienteID,
    c.Nome,
    p.Dia,
    p.TotalPixOutDia,
    s.MediaDia,
    CAST(p.TotalPixOutDia / NULLIF(s.MediaDia,0) AS DECIMAL(10,2)) AS MultiploDaMedia
FROM PixDia p
JOIN Stats s ON s.ClienteID = p.ClienteID
JOIN dbo.Clientes c ON c.ClienteID = p.ClienteID
WHERE p.TotalPixOutDia > 3 * s.MediaDia
ORDER BY MultiploDaMedia DESC;
