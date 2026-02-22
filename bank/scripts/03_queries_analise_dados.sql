--verificando dados e transações por cliente

WITH Movimentacao AS (
    SELECT
        c.ClienteID,
        c.Nome,
        t.Valor,
        t.Direcao
    FROM dbo.Clientes c
    JOIN dbo.Contas ct ON ct.ClienteID = c.ClienteID
    JOIN dbo.Transacoes t ON t.ContaID = ct.ContaID
    WHERE t.Status = 'CONFIRMADA'
),
Resumo AS (
    SELECT
        ClienteID,
        Nome,
        SUM(CASE WHEN Direcao = 'C' THEN Valor ELSE 0 END) AS Total_Creditos,
        SUM(CASE WHEN Direcao = 'D' THEN Valor ELSE 0 END) AS Total_Debitos,
        COUNT(*) AS Qtde_Transacoes
    FROM Movimentacao
    GROUP BY ClienteID, Nome
)
SELECT
    ClienteID,
    Nome,
    Total_Creditos,
    Total_Debitos,
    Total_Creditos - Total_Debitos AS Saldo_Calculado,
    Qtde_Transacoes
FROM Resumo
ORDER BY Saldo_Calculado DESC;


-- Detecção simples de possível fraude PIX

WITH Movimentacao AS (
    SELECT
        c.ClienteID,
        c.Nome,
        t.Valor,
        t.Direcao
    FROM dbo.Clientes c
    JOIN dbo.Contas ct ON ct.ClienteID = c.ClienteID
    JOIN dbo.Transacoes t ON t.ContaID = ct.ContaID
    WHERE t.Status = 'CONFIRMADA'
),
Resumo AS (
    SELECT
        ClienteID,
        Nome,
        SUM(CASE WHEN Direcao = 'C' THEN Valor ELSE 0 END) AS Total_Creditos,
        SUM(CASE WHEN Direcao = 'D' THEN Valor ELSE 0 END) AS Total_Debitos,
        COUNT(*) AS Qtde_Transacoes
    FROM Movimentacao
    GROUP BY ClienteID, Nome
)
SELECT
    ClienteID,
    Nome,
    Total_Creditos,
    Total_Debitos,
    Total_Creditos - Total_Debitos AS Saldo_Calculado,
    Qtde_Transacoes
FROM Resumo
ORDER BY Saldo_Calculado DESC;







-- Chargeback Rate por Cliente

WITH Base AS (
    SELECT
        c.ClienteID,
        c.Nome,
        tc.TransacaoCartaoID,
        cb.ChargebackID
    FROM dbo.Clientes c
    JOIN dbo.Cartoes ca ON ca.ClienteID = c.ClienteID
    JOIN dbo.TransacoesCartao tc ON tc.CartaoID = ca.CartaoID
    LEFT JOIN dbo.Chargebacks cb ON cb.TransacaoCartaoID = tc.TransacaoCartaoID
)
SELECT
    ClienteID,
    Nome,
    COUNT(DISTINCT TransacaoCartaoID) AS Total_Compras,
    COUNT(DISTINCT ChargebackID) AS Total_Chargebacks,
    CAST(
        100.0 * COUNT(DISTINCT ChargebackID)
        / NULLIF(COUNT(DISTINCT TransacaoCartaoID), 0)
    AS DECIMAL(5,2)) AS Chargeback_Rate_Percent
FROM Base
GROUP BY ClienteID, Nome
ORDER BY Chargeback_Rate_Percent DESC;









