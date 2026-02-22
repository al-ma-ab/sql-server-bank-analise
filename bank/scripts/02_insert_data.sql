/* =========================================================
   BANCO DIGITAL - DADOS FAKE (SEED)
   ========================================================= */

-- 1) LIMPEZA (ordem por FK)
DELETE FROM dbo.Chargebacks;
DELETE FROM dbo.TransacoesCartao;
DELETE FROM dbo.Estabelecimentos;

DELETE FROM dbo.PixTransferencias;
DELETE FROM dbo.PixChaves;

DELETE FROM dbo.Transacoes;
DELETE FROM dbo.Cartoes;
DELETE FROM dbo.Contas;
DELETE FROM dbo.Clientes;

-- (Opcional) reset identity
-- DBCC CHECKIDENT ('dbo.Clientes', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.Contas', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.Transacoes', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.PixChaves', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.PixTransferencias', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.Cartoes', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.Estabelecimentos', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.TransacoesCartao', RESEED, 0);
-- DBCC CHECKIDENT ('dbo.Chargebacks', RESEED, 0);

------------------------------------------------------------
-- 2) CLIENTES
------------------------------------------------------------
INSERT INTO dbo.Clientes (Nome, Documento, TipoPessoa, DataNascimento, Email, Celular, Cidade, UF, Status)
VALUES
('Alexandre Martins', '12345678901', 'PF', '1990-05-10', 'alexandre@email.com', '+55-16-99999-0001', 'Jaboticabal', 'SP', 'ATIVO'),
('Maria Souza',       '23456789012', 'PF', '1992-09-20', 'maria@email.com',     '+55-11-99999-0002', 'São Paulo',   'SP', 'ATIVO'),
('João Lima',         '34567890123', 'PF', '1987-02-15', 'joao@email.com',      '+55-16-99999-0003', 'Ribeirão Preto','SP','ATIVO'),
('Ana Ferreira',      '45678901234', 'PF', '1995-12-01', 'ana@email.com',       '+55-21-99999-0004', 'Rio de Janeiro','RJ','ATIVO'),
('Mercado Bom Preço', '11222333000199', 'PJ', NULL,      'contato@mercado.com', '+55-16-99999-0005', 'Araraquara', 'SP', 'ATIVO'),
('Carlos Silva',      '56789012345', 'PF', '1998-07-07', 'carlos@email.com',    '+55-19-99999-0006', 'Campinas',  'SP', 'ATIVO');

------------------------------------------------------------
-- 3) CONTAS
------------------------------------------------------------
-- Vamos criar contas (1 ou mais por cliente)
INSERT INTO dbo.Contas (ClienteID, Agencia, NumeroConta, TipoConta, Moeda, Status, SaldoAtual)
SELECT ClienteID, '0001',
       CONCAT('10', RIGHT('0000' + CAST(ClienteID AS VARCHAR(10)), 4)),
       'PAGAMENTO', 'BRL', 'ATIVA', 0
FROM dbo.Clientes;

-- Cliente PJ ganha uma segunda conta (ex: CORRENTE)
DECLARE @ClientePJ INT = (SELECT ClienteID FROM dbo.Clientes WHERE TipoPessoa = 'PJ');
INSERT INTO dbo.Contas (ClienteID, Agencia, NumeroConta, TipoConta, Moeda, Status, SaldoAtual)
VALUES (@ClientePJ, '0001', '200001', 'CORRENTE', 'BRL', 'ATIVA', 0);

------------------------------------------------------------
-- 4) CHAVES PIX
------------------------------------------------------------
-- Uma chave por conta (simplificação)
-- Uma chave PIX principal por CLIENTE (evita duplicar se o cliente tiver mais de uma conta)
;WITH PrimeiraConta AS (
    SELECT
        c.ClienteID,
        c.Documento,
        c.TipoPessoa,
        ct.ContaID,
        ROW_NUMBER() OVER (PARTITION BY c.ClienteID ORDER BY ct.ContaID) AS rn
    FROM dbo.Clientes c
    JOIN dbo.Contas ct ON ct.ClienteID = c.ClienteID
)
INSERT INTO dbo.PixChaves (ContaID, TipoChave, Chave, Status)
SELECT
    ContaID,
    CASE WHEN TipoPessoa='PJ' THEN 'CNPJ' ELSE 'CPF' END,
    Documento,
    'ATIVA'
FROM PrimeiraConta
WHERE rn = 1;

-- Chaves extras para alguns clientes (email / celular)
DECLARE @ContaAlex INT = (SELECT TOP 1 ContaID FROM dbo.Contas WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='12345678901'));
DECLARE @ContaMaria INT = (SELECT TOP 1 ContaID FROM dbo.Contas WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='23456789012'));

INSERT INTO dbo.PixChaves (ContaID, TipoChave, Chave, Status)
VALUES
(@ContaAlex, 'EMAIL', 'alexandre@email.com', 'ATIVA'),
(@ContaMaria,'CELULAR', '+55-11-99999-0002', 'ATIVA');

------------------------------------------------------------
-- 5) CARTOES
------------------------------------------------------------
-- Cartão de débito para todos os clientes PF (1 por cliente)
INSERT INTO dbo.Cartoes (ClienteID, ContaID, FinalCartao, Bandeira, Tipo, Status)
SELECT
    c.ClienteID,
    (SELECT TOP 1 ContaID FROM dbo.Contas ct WHERE ct.ClienteID = c.ClienteID ORDER BY ct.ContaID),
    RIGHT('0000' + CAST(ABS(CHECKSUM(NEWID())) % 10000 AS VARCHAR(4)), 4),
    'VISA',
    'DEBITO',
    'ATIVO'
FROM dbo.Clientes c
WHERE c.TipoPessoa = 'PF';

-- Um cartão crédito para Alexandre e Maria
INSERT INTO dbo.Cartoes (ClienteID, ContaID, FinalCartao, Bandeira, Tipo, Status)
VALUES
((SELECT ClienteID FROM dbo.Clientes WHERE Documento='12345678901'), @ContaAlex, '7788', 'MASTERCARD', 'CREDITO', 'ATIVO'),
((SELECT ClienteID FROM dbo.Clientes WHERE Documento='23456789012'), @ContaMaria,'1122', 'VISA',       'CREDITO', 'ATIVO');

------------------------------------------------------------
-- 6) ESTABELECIMENTOS
------------------------------------------------------------
INSERT INTO dbo.Estabelecimentos (NomeFantasia, MCC, Cidade, UF)
VALUES
('Uber',              '4121', 'São Paulo', 'SP'),
('iFood',             '5812', 'São Paulo', 'SP'),
('Posto Avenida',     '5541', 'Jaboticabal','SP'),
('Mercado Bom Preço', '5411', 'Araraquara','SP'),
('Loja Tech',         '5732', 'Campinas',  'SP');

------------------------------------------------------------
-- 7) TRANSACOES (LEDGER) - entradas, saidas, tarifas
------------------------------------------------------------
DECLARE @ContaJoao INT = (SELECT TOP 1 ContaID FROM dbo.Contas WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='34567890123'));
DECLARE @ContaAna  INT = (SELECT TOP 1 ContaID FROM dbo.Contas WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='45678901234'));
DECLARE @ContaCarlos INT = (SELECT TOP 1 ContaID FROM dbo.Contas WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='56789012345'));

-- Depósitos/Salário (créditos)
INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaAlex,  '2026-02-01T09:10:00', 'DEPOSITO', 'C', 5000.00, 'CONFIRMADA', 'Salário', 'DEP-0001'),
(@ContaMaria, '2026-02-01T09:15:00', 'DEPOSITO', 'C', 6200.00, 'CONFIRMADA', 'Salário', 'DEP-0002'),
(@ContaJoao,  '2026-02-01T09:20:00', 'DEPOSITO', 'C', 4200.00, 'CONFIRMADA', 'Salário', 'DEP-0003'),
(@ContaAna,   '2026-02-01T09:25:00', 'DEPOSITO', 'C', 3800.00, 'CONFIRMADA', 'Salário', 'DEP-0004'),
(@ContaCarlos,'2026-02-01T09:30:00', 'DEPOSITO', 'C', 2500.00, 'CONFIRMADA', 'Salário', 'DEP-0005');

-- Tarifas (débitos)
INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaAlex,  '2026-02-02T10:00:00', 'TARIFA', 'D',  15.90, 'CONFIRMADA', 'Tarifa mensal', 'FEE-0001'),
(@ContaMaria, '2026-02-02T10:00:00', 'TARIFA', 'D',  15.90, 'CONFIRMADA', 'Tarifa mensal', 'FEE-0002');

------------------------------------------------------------
-- 8) PIX TRANSFERENCIAS + amarrar no ledger (Transacoes)
------------------------------------------------------------
-- Exemplo: Alexandre faz PIX para Maria (200)
DECLARE @TxDebito1 BIGINT;
DECLARE @TxCredito1 BIGINT;

INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaAlex,  '2026-02-03T12:00:00', 'PIX_OUT', 'D', 200.00, 'CONFIRMADA', 'PIX para Maria', 'E2E-PIX-0001');

SET @TxDebito1 = SCOPE_IDENTITY();

INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaMaria, '2026-02-03T12:00:00', 'PIX_IN',  'C', 200.00, 'CONFIRMADA', 'PIX de Alexandre', 'E2E-PIX-0001');

SET @TxCredito1 = SCOPE_IDENTITY();

INSERT INTO dbo.PixTransferencias
(ContaOrigemID, ContaDestinoID, ChaveDestino, DataHora, Valor, Status, EndToEndId, TransacaoDebitoID, TransacaoCreditoID)
VALUES
(@ContaAlex, @ContaMaria, '+55-11-99999-0002', '2026-02-03T12:00:00', 200.00, 'CONFIRMADA', 'E2E-PIX-0001', @TxDebito1, @TxCredito1);

-- Maria faz PIX para Joao (120)
DECLARE @TxDebito2 BIGINT;
DECLARE @TxCredito2 BIGINT;

INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaMaria, '2026-02-04T08:40:00', 'PIX_OUT', 'D', 120.00, 'CONFIRMADA', 'PIX para João', 'E2E-PIX-0002');
SET @TxDebito2 = SCOPE_IDENTITY();

INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaJoao,  '2026-02-04T08:40:00', 'PIX_IN',  'C', 120.00, 'CONFIRMADA', 'PIX de Maria', 'E2E-PIX-0002');
SET @TxCredito2 = SCOPE_IDENTITY();

INSERT INTO dbo.PixTransferencias
(ContaOrigemID, ContaDestinoID, ChaveDestino, DataHora, Valor, Status, EndToEndId, TransacaoDebitoID, TransacaoCreditoID)
VALUES
(@ContaMaria, @ContaJoao, (SELECT TOP 1 Chave FROM dbo.PixChaves WHERE ContaID=@ContaJoao AND TipoChave IN ('CPF','CNPJ')), 
 '2026-02-04T08:40:00', 120.00, 'CONFIRMADA', 'E2E-PIX-0002', @TxDebito2, @TxCredito2);

-- Carlos faz PIX para chave externa (fora do banco)
DECLARE @TxDebito3 BIGINT;
INSERT INTO dbo.Transacoes (ContaID, DataHora, Tipo, Direcao, Valor, Status, Descricao, ReferenciaExterna)
VALUES
(@ContaCarlos,'2026-02-05T20:10:00','PIX_OUT','D', 300.00,'CONFIRMADA','PIX para chave externa','E2E-PIX-0003');
SET @TxDebito3 = SCOPE_IDENTITY();

INSERT INTO dbo.PixTransferencias
(ContaOrigemID, ContaDestinoID, ChaveDestino, DataHora, Valor, Status, EndToEndId, TransacaoDebitoID, TransacaoCreditoID)
VALUES
(@ContaCarlos, NULL, 'email@externo.com', '2026-02-05T20:10:00', 300.00, 'CONFIRMADA', 'E2E-PIX-0003', @TxDebito3, NULL);

------------------------------------------------------------
-- 9) TRANSACOES DE CARTAO + (opcional) refletir no ledger
------------------------------------------------------------
DECLARE @CartaoAlexCredito INT = (
    SELECT TOP 1 CartaoID FROM dbo.Cartoes 
    WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='12345678901')
      AND Tipo='CREDITO'
);

DECLARE @CartaoMariaCredito INT = (
    SELECT TOP 1 CartaoID FROM dbo.Cartoes 
    WHERE ClienteID = (SELECT ClienteID FROM dbo.Clientes WHERE Documento='23456789012')
      AND Tipo='CREDITO'
);

DECLARE @EstabIFood INT = (SELECT EstabelecimentoID FROM dbo.Estabelecimentos WHERE NomeFantasia='iFood');
DECLARE @EstabUber  INT = (SELECT EstabelecimentoID FROM dbo.Estabelecimentos WHERE NomeFantasia='Uber');
DECLARE @EstabPosto INT = (SELECT EstabelecimentoID FROM dbo.Estabelecimentos WHERE NomeFantasia='Posto Avenida');
DECLARE @EstabTech  INT = (SELECT EstabelecimentoID FROM dbo.Estabelecimentos WHERE NomeFantasia='Loja Tech');

INSERT INTO dbo.TransacoesCartao (CartaoID, EstabelecimentoID, DataHora, Valor, Status, Autorizacao)
VALUES
(@CartaoAlexCredito, @EstabIFood, '2026-02-06T19:30:00', 89.90,  'APROVADA', 'AUTH-0001'),
(@CartaoAlexCredito, @EstabUber,  '2026-02-07T08:10:00', 32.50,  'APROVADA', 'AUTH-0002'),
(@CartaoMariaCredito,@EstabPosto, '2026-02-07T18:00:00', 210.00, 'APROVADA', 'AUTH-0003'),
(@CartaoMariaCredito,@EstabTech,  '2026-02-08T11:00:00', 1999.90,'APROVADA', 'AUTH-0004');

------------------------------------------------------------
-- 10) CHARGEBACK (2 casos)
------------------------------------------------------------
DECLARE @TxCartaoFraude BIGINT = (
    SELECT TOP 1 TransacaoCartaoID 
    FROM dbo.TransacoesCartao
    WHERE Autorizacao='AUTH-0004'
);

INSERT INTO dbo.Chargebacks (TransacaoCartaoID, DataAbertura, Motivo, Status, ValorContestacao)
VALUES
(@TxCartaoFraude, '2026-02-10T09:00:00', 'FRAUDE', 'ABERTO', 1999.90);

DECLARE @TxCartaoServico BIGINT = (
    SELECT TOP 1 TransacaoCartaoID 
    FROM dbo.TransacoesCartao
    WHERE Autorizacao='AUTH-0001'
);

INSERT INTO dbo.Chargebacks (TransacaoCartaoID, DataAbertura, Motivo, Status, ValorContestacao)
VALUES
(@TxCartaoServico, '2026-02-11T10:30:00', 'SERVICO_NAO_PRESTADO', 'EM_ANALISE', 89.90);

------------------------------------------------------------
-- 11) Atualizar saldo atual (simplificado)
-- Saldo = Créditos - Débitos (apenas tabela Transacoes)
------------------------------------------------------------
UPDATE c
SET SaldoAtual =
    ISNULL((
        SELECT
            SUM(CASE WHEN t.Direcao='C' THEN t.Valor ELSE -t.Valor END)
        FROM dbo.Transacoes t
        WHERE t.ContaID = c.ContaID
          AND t.Status = 'CONFIRMADA'
    ), 0)
FROM dbo.Contas c;

-- Verificação rápida
SELECT TOP 20 * FROM dbo.Clientes ORDER BY ClienteID;
SELECT TOP 20 * FROM dbo.Contas ORDER BY ContaID;
SELECT TOP 50 * FROM dbo.Transacoes ORDER BY DataHora;
SELECT TOP 50 * FROM dbo.PixTransferencias ORDER BY DataHora;
SELECT TOP 50 * FROM dbo.TransacoesCartao ORDER BY DataHora;
SELECT TOP 20 * FROM dbo.Chargebacks ORDER BY DataAbertura;
