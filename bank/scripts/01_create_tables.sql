/* =========================================================
   BANCO DIGITAL - MODELO BASE (Azure SQL / SQL Server)
   ========================================================= */

-- CLIENTES
CREATE TABLE dbo.Clientes (
    ClienteID           INT IDENTITY(1,1) PRIMARY KEY,
    Nome                VARCHAR(120) NOT NULL,
    Documento           VARCHAR(20)  NOT NULL,      -- CPF/CNPJ (sem validação aqui)
    TipoPessoa          CHAR(2)      NOT NULL,      -- PF / PJ
    DataNascimento      DATE         NULL,
    Email               VARCHAR(150) NULL,
    Celular             VARCHAR(30)  NULL,
    Cidade              VARCHAR(80)  NULL,
    UF                  CHAR(2)      NULL,
    DataCadastro        DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    Status              VARCHAR(20)  NOT NULL DEFAULT 'ATIVO'
);

CREATE UNIQUE INDEX UX_Clientes_Documento ON dbo.Clientes(Documento);


-- CONTAS
CREATE TABLE dbo.Contas (
    ContaID             INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID           INT NOT NULL,
    Agencia             VARCHAR(10) NOT NULL DEFAULT '0001',
    NumeroConta         VARCHAR(20) NOT NULL,
    TipoConta           VARCHAR(20) NOT NULL,       -- CORRENTE, PAGAMENTO...
    Moeda               CHAR(3)     NOT NULL DEFAULT 'BRL',
    DataAbertura        DATETIME2   NOT NULL DEFAULT SYSDATETIME(),
    Status              VARCHAR(20) NOT NULL DEFAULT 'ATIVA',
    SaldoAtual          DECIMAL(18,2) NOT NULL DEFAULT 0,

    CONSTRAINT FK_Contas_Clientes
        FOREIGN KEY (ClienteID) REFERENCES dbo.Clientes(ClienteID)
);

CREATE UNIQUE INDEX UX_Contas_AgNum ON dbo.Contas(Agencia, NumeroConta);
CREATE INDEX IX_Contas_Cliente ON dbo.Contas(ClienteID);


-- TRANSACOES (ledger simplificado)
-- Aqui ficam PIX, TED, TARIFA, BOLETO, AJUSTE, etc.
CREATE TABLE dbo.Transacoes (
    TransacaoID         BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContaID             INT NOT NULL,
    DataHora            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Tipo                VARCHAR(30) NOT NULL,       -- PIX_OUT, PIX_IN, TED_OUT, TARIFA, DEPOSITO...
    Direcao             CHAR(1) NOT NULL,           -- D (debito) / C (credito)
    Valor               DECIMAL(18,2) NOT NULL,
    Status              VARCHAR(20) NOT NULL DEFAULT 'CONFIRMADA', -- PENDENTE, CONFIRMADA, ESTORNADA, FALHA
    Descricao           VARCHAR(200) NULL,
    ReferenciaExterna   VARCHAR(80) NULL,           -- id do provedor, endToEndId, etc.

    CONSTRAINT FK_Transacoes_Contas
        FOREIGN KEY (ContaID) REFERENCES dbo.Contas(ContaID)
);

CREATE INDEX IX_Transacoes_Conta_Data ON dbo.Transacoes(ContaID, DataHora);
CREATE INDEX IX_Transacoes_Tipo_Data ON dbo.Transacoes(Tipo, DataHora);


-- CHAVES PIX
CREATE TABLE dbo.PixChaves (
    PixChaveID          INT IDENTITY(1,1) PRIMARY KEY,
    ContaID             INT NOT NULL,
    TipoChave           VARCHAR(20) NOT NULL,       -- CPF, CNPJ, EMAIL, CELULAR, ALEATORIA
    Chave               VARCHAR(120) NOT NULL,
    Status              VARCHAR(20) NOT NULL DEFAULT 'ATIVA',
    DataCriacao         DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_PixChaves_Contas
        FOREIGN KEY (ContaID) REFERENCES dbo.Contas(ContaID)
);

CREATE UNIQUE INDEX UX_PixChaves_Chave ON dbo.PixChaves(Chave);
CREATE INDEX IX_PixChaves_Conta ON dbo.PixChaves(ContaID);


-- TRANSFERENCIAS PIX (detalhe do PIX)
-- Vincula em Transacoes quando você quiser “amarrar” o ledger ao detalhe.
CREATE TABLE dbo.PixTransferencias (
    PixTransferenciaID  BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContaOrigemID       INT NOT NULL,
    ContaDestinoID      INT NULL,                   -- pode ser fora do banco, então NULL
    ChaveDestino        VARCHAR(120) NULL,
    DataHora            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Valor               DECIMAL(18,2) NOT NULL,
    Status              VARCHAR(20) NOT NULL DEFAULT 'CONFIRMADA',
    EndToEndId          VARCHAR(60) NULL,
    TransacaoDebitoID   BIGINT NULL,
    TransacaoCreditoID  BIGINT NULL,

    CONSTRAINT FK_Pix_Origem
        FOREIGN KEY (ContaOrigemID) REFERENCES dbo.Contas(ContaID),

    CONSTRAINT FK_Pix_Destino
        FOREIGN KEY (ContaDestinoID) REFERENCES dbo.Contas(ContaID),

    CONSTRAINT FK_Pix_TxDebito
        FOREIGN KEY (TransacaoDebitoID) REFERENCES dbo.Transacoes(TransacaoID),

    CONSTRAINT FK_Pix_TxCredito
        FOREIGN KEY (TransacaoCreditoID) REFERENCES dbo.Transacoes(TransacaoID)
);

CREATE INDEX IX_Pix_Origem_Data ON dbo.PixTransferencias(ContaOrigemID, DataHora);
CREATE INDEX IX_Pix_Status_Data ON dbo.PixTransferencias(Status, DataHora);


-- CARTOES
CREATE TABLE dbo.Cartoes (
    CartaoID            INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID           INT NOT NULL,
    ContaID             INT NOT NULL,               -- cartão atrelado a uma conta (padrão)
    FinalCartao         CHAR(4) NOT NULL,
    Bandeira            VARCHAR(20) NOT NULL,       -- VISA/MASTERCARD
    Tipo                VARCHAR(20) NOT NULL,       -- DEBITO/CREDITO
    Status              VARCHAR(20) NOT NULL DEFAULT 'ATIVO',
    DataEmissao         DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT FK_Cartoes_Clientes
        FOREIGN KEY (ClienteID) REFERENCES dbo.Clientes(ClienteID),

    CONSTRAINT FK_Cartoes_Contas
        FOREIGN KEY (ContaID) REFERENCES dbo.Contas(ContaID)
);

CREATE INDEX IX_Cartoes_Cliente ON dbo.Cartoes(ClienteID);
CREATE INDEX IX_Cartoes_Conta ON dbo.Cartoes(ContaID);


-- ESTABELECIMENTOS (para compras no cartão)
CREATE TABLE dbo.Estabelecimentos (
    EstabelecimentoID   INT IDENTITY(1,1) PRIMARY KEY,
    NomeFantasia        VARCHAR(120) NOT NULL,
    MCC                 VARCHAR(10)  NULL,          -- Merchant Category Code
    Cidade              VARCHAR(80)  NULL,
    UF                  CHAR(2)      NULL
);


-- TRANSACOES DE CARTAO
CREATE TABLE dbo.TransacoesCartao (
    TransacaoCartaoID   BIGINT IDENTITY(1,1) PRIMARY KEY,
    CartaoID            INT NOT NULL,
    EstabelecimentoID   INT NOT NULL,
    DataHora            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Valor               DECIMAL(18,2) NOT NULL,
    Moeda               CHAR(3) NOT NULL DEFAULT 'BRL',
    Status              VARCHAR(20) NOT NULL DEFAULT 'APROVADA', -- NEGADA, ESTORNADA...
    Autorizacao         VARCHAR(30) NULL,

    CONSTRAINT FK_TxCartao_Cartoes
        FOREIGN KEY (CartaoID) REFERENCES dbo.Cartoes(CartaoID),

    CONSTRAINT FK_TxCartao_Estabelecimentos
        FOREIGN KEY (EstabelecimentoID) REFERENCES dbo.Estabelecimentos(EstabelecimentoID)
);

CREATE INDEX IX_TxCartao_Cartao_Data ON dbo.TransacoesCartao(CartaoID, DataHora);
CREATE INDEX IX_TxCartao_Status_Data ON dbo.TransacoesCartao(Status, DataHora);


-- CHARGEBACK (contestação)
CREATE TABLE dbo.Chargebacks (
    ChargebackID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    TransacaoCartaoID   BIGINT NOT NULL,
    DataAbertura        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Motivo              VARCHAR(80) NOT NULL,       -- FRAUDE, SERVICO_NAO_PRESTADO, DUPLICIDADE...
    Status              VARCHAR(20) NOT NULL DEFAULT 'ABERTO', -- EM_ANALISE, ACEITO, NEGADO, ENCERRADO
    ValorContestacao    DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_Chargebacks_TxCartao
        FOREIGN KEY (TransacaoCartaoID) REFERENCES dbo.TransacoesCartao(TransacaoCartaoID)
);

CREATE INDEX IX_Chargebacks_Status_Data ON dbo.Chargebacks(Status, DataAbertura);
