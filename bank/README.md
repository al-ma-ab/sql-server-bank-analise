# 🏦 BANK - Digital Banking Analytics Lab

Projeto desenvolvido no Azure SQL Database simulando um ambiente de **Banco Digital (Fintech)** com foco em:

- Modelagem relacional
- Ledger financeiro
- PIX e Cartão
- Chargeback
- Score de risco
- Análise comportamental
- Estrutura pronta para Power BI

---

## 🚀 Tecnologias Utilizadas

- Azure SQL Database
- T-SQL
- CTE (Common Table Expressions)
- VIEW analítica
- Modelagem relacional
- Heurísticas de risco
- Estrutura para BI (Power BI Ready)

---

# 📂 Estrutura do Projeto
script/
│
├── 01_create_tables.sql
├── 02_insert_data.sql
├── 03_queries_analise_dados.sql
├── 04_vw_resumo_cliente_fintech.sql
├── 05_score_simples_de_risco_por_cliente.sql
├── 06_analise_comportamento_mensal.sql
├── 07_analise_anomalia_simples.sql
└── 08_view_com_campos_para_dashboard.sql



---

# 🧱 Modelo de Dados

O modelo simula o core de um banco digital:

- Clientes
- Contas
- Transações (Ledger)
- PIX
- Cartões
- Estabelecimentos
- Chargebacks

Principais relacionamentos:

- Cliente → Contas
- Conta → Transações
- Conta → PIX
- Cliente → Cartões
- Cartão → Transações de cartão
- Transação de cartão → Chargeback

---

# 📊 Funcionalidades Analíticas Implementadas

## 1️⃣ Ledger Financeiro
- Total de créditos
- Total de débitos
- Saldo calculado
- Volume de PIX IN / OUT



---

# 📈 Preparado para Power BI - 08_view_com_campos_para_dashboard.sql

A view final foi estruturada para ser importada diretamente no Power BI como tabela fato consolidada por cliente.

Indicadores prontos:

- Saldo total
- Volume de PIX
- Chargeback %
- Score de risco
- Quantidade de transações

---

# 🎯 Objetivo do Projeto

Demonstrar habilidades em:

- Modelagem de banco digital
- Construção de ledger
- SQL analítico avançado
- Organização via CTE
- Criação de Views para BI
- Estruturação de projeto profissional

---

# 👨‍💻 Autor

Alexandre Martins  

Projeto de estudo focado em:
- Engenharia de Dados
- Analytics
- Fintech
- Modelagem SQL avançada


