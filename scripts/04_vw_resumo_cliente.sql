CREATE OR ALTER VIEW vw_resumo_cliente AS
WITH Base AS (
    SELECT
        c.ClienteID,
        c.Nome,
        p.PedidoID,
        p.DataPedido,
        pr.Preco,
        i.Quantidade
    FROM Clientes c
    LEFT JOIN Pedidos p      ON p.ClienteID = c.ClienteID
    LEFT JOIN ItensPedido i  ON i.PedidoID  = p.PedidoID
    LEFT JOIN Produtos pr    ON pr.ProdutoID = i.ProdutoID
),
Resumo AS (
    SELECT
        ClienteID,
        Nome,
        CAST(ISNULL(SUM(Preco * Quantidade), 0) AS DECIMAL(12,2)) AS Total_gasto,
        COUNT(DISTINCT PedidoID) AS Qtde_pedidos,
        MIN(DataPedido) AS primeiroPedido,
        MAX(DataPedido) AS ultimoPedido
    FROM Base
    GROUP BY ClienteID, Nome
)
SELECT
    ClienteID,
    Nome,
    Total_gasto,
    Qtde_pedidos,
    primeiroPedido,
    ultimoPedido,
    ROUND(ISNULL(Total_gasto / NULLIF(Qtde_pedidos, 0), 0), 2) AS Ticket_medio
FROM Resumo;




-- fazendo uso da view criada.
SELECT *
FROM vw_resumo_cliente
ORDER BY Total_gasto DESC;
