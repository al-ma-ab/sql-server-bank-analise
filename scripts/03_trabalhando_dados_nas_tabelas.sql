--Qual cliente gastou mais dinheiro
select Top 1 c.ClienteID, c.Nome, sum(pr.Preco * i.Quantidade) as vl_total_pedido
from Clientes c
inner join Pedidos p on c.ClienteID = p.ClienteID
inner join ItensPedido i on p.PedidoID = i.PedidoID
inner join Produtos pr on i.ProdutoID = pr.ProdutoID
group by c.ClienteID, c.Nome
order by vl_total_pedido desc


-- Ticket médio por cliente = (total gasto) / (quantidade de pedidos)
select c.ClienteID, c.Nome, 
(CAST(sum(pr.Preco * i.Quantidade) AS DECIMAL(10,2)) / NULLIF(count(DISTINCT p.PedidoID), 0 )) as Ticket_medio
from Clientes c
inner join Pedidos p on c.ClienteID = p.ClienteID
inner join ItensPedido i on p.PedidoID = i.PedidoID
inner join Produtos pr on i.ProdutoID = pr.ProdutoID
group by c.ClienteID,c.Nome
order by Ticket_medio DESC;


-- Ticket médio por cliente , listando inclusive quem nunca comprou
SELECT 
    c.ClienteID,
    c.Nome,
    ISNULL(SUM(pr.Preco * i.Quantidade), 0) AS Total_gasto,
    COUNT(DISTINCT p.PedidoID) AS Qtde_pedidos,
    ISNULL(
        CAST(SUM(pr.Preco * i.Quantidade) AS DECIMAL(10,2)) 
        / NULLIF(COUNT(DISTINCT p.PedidoID), 0),
    0) AS Ticket_medio

FROM Clientes c
LEFT JOIN Pedidos p      ON c.ClienteID = p.ClienteID
LEFT JOIN ItensPedido i  ON p.PedidoID  = i.PedidoID
LEFT JOIN Produtos pr    ON i.ProdutoID = pr.ProdutoID

GROUP BY c.ClienteID, c.Nome
ORDER BY Total_gasto DESC;






-- fazendo uma CTE pratica.
WITH Base AS (
    SELECT
        c.ClienteID,
        c.Nome,
        p.PedidoID,
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
        ISNULL(SUM(Preco * Quantidade), 0) AS Total_gasto,
        COUNT(DISTINCT PedidoID) AS Qtde_pedidos
    FROM Base
    GROUP BY ClienteID, Nome
)
SELECT
    ClienteID,
    Nome,
    Total_gasto,
    Qtde_pedidos,
    ISNULL(CAST(Total_gasto AS DECIMAL(10,2)) / NULLIF(Qtde_pedidos, 0), 0) AS Ticket_medio
FROM Resumo
ORDER BY Total_gasto DESC;



-- fazendo uma CTE - Recuperando o PRIMEIRO pedido e o ULTIMO pedido. 
-- MIN(DataPedido)
-- MAX(DataPedido)

WITH Base AS (
    SELECT
        c.ClienteID,
        c.Nome,
        p.PedidoID,
        pr.Preco,
        i.Quantidade,
        p.DataPedido
    FROM Clientes c
    LEFT JOIN Pedidos p      ON p.ClienteID = c.ClienteID
    LEFT JOIN ItensPedido i  ON i.PedidoID  = p.PedidoID
    LEFT JOIN Produtos pr    ON pr.ProdutoID = i.ProdutoID
),
Resumo AS (
    SELECT
        ClienteID,
        Nome,
        ISNULL(SUM(Preco * Quantidade), 0) AS Total_gasto,
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
    ISNULL(CAST(Total_gasto AS DECIMAL(10,2)) / NULLIF(Qtde_pedidos, 0), 0) AS Ticket_medio
FROM Resumo
ORDER BY Total_gasto DESC;
