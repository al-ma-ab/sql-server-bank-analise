CREATE OR ALTER VIEW dbo.vw_resumo_cliente_fintech AS
WITH Mov AS (
    SELECT
        c.ClienteID,
        c.Nome,
        t.Direcao,
        t.Valor,
        t.Tipo,
        CAST(t.DataHora AS DATE) AS Dia
    FROM dbo.Clientes c
    JOIN dbo.Contas ct     ON ct.ClienteID = c.ClienteID
    LEFT JOIN dbo.Transacoes t ON t.ContaID = ct.ContaID AND t.Status='CONFIRMADA'
),
Agg AS (
    SELECT
        ClienteID,
        Nome,
        SUM(CASE WHEN Direcao='C' THEN Valor ELSE 0 END) AS Total_Creditos,
        SUM(CASE WHEN Direcao='D' THEN Valor ELSE 0 END) AS Total_Debitos,
        SUM(CASE WHEN Tipo='PIX_OUT' THEN Valor ELSE 0 END) AS Total_PixOut,
        COUNT(*) AS Qtde_Transacoes,
        MIN(Dia) AS Primeira_Mov,
        MAX(Dia) AS Ultima_Mov
    FROM Mov
    GROUP BY ClienteID, Nome
)
SELECT
    ClienteID,
    Nome,
    Total_Creditos,
    Total_Debitos,
    (Total_Creditos - Total_Debitos) AS Saldo_Calculado,
    Total_PixOut,
    Qtde_Transacoes,
    Primeira_Mov,
    Ultima_Mov
FROM Agg;


SELECT * FROM dbo.vw_resumo_cliente_fintech ORDER BY Saldo_Calculado DESC;
