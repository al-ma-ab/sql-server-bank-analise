INSERT INTO Clientes VALUES
(1, 'Alexandre', 'Jaboticabal', '2024-01-10'),
(2, 'Maria', 'São Paulo', '2024-02-15'),
(3, 'João', 'Ribeirão Preto', '2024-03-20');

INSERT INTO Produtos VALUES
(1, 'Notebook', 'Eletrônicos', 4500.00),
(2, 'Mouse', 'Eletrônicos', 120.00),
(3, 'Cadeira', 'Móveis', 900.00);

INSERT INTO Pedidos VALUES
(1, 1, '2024-04-01'),
(2, 2, '2024-04-03'),
(3, 1, '2024-04-05');

INSERT INTO ItensPedido VALUES
(1, 1, 1, 1),
(2, 1, 2, 2),
(3, 2, 3, 1),
(4, 3, 2, 3);
