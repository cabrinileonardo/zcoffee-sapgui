# ☕ ZCOFFEE — v1 SAP GUI (ABAP clássico)

Primeira versão do **ZCOFFEE**, um ERP simplificado de cafeteria que eu desenvolvi como projeto de estudo em **ABAP**,
toda em **SAP GUI**: um cockpit em module pool que integra os módulos SD, MM, FI e RH em transações Z.

> A versão 2 do projeto é um app Fiori: [zcoffee-ui5](https://github.com/cabrinileonardo/zcoffee-ui5) (front) e [zcoffee-abap](https://github.com/cabrinileonardo/zcoffee-abap) (back-end OData).

## Cockpit

Transação `ZCOFFEE` → module pool `SAPMZ_ZCOFFEE_COCKPIT`, que funciona como hub de navegação entre os módulos.

| Tela | Função |
|---|---|
| 0100 | Menu principal, com os botões RH, Compras, Vendas e Financeiro |
| 0200 | Menu de Vendas (SD) |
| 0300 | Menu de Financeiro (FI) |
| 0400 | Menu de Compras (MM) |
| 0500 | Menu de RH |

- PBO/PAI, GUI status e title bar próprios em cada tela
- **6 classes locais** organizando a navegação: `lcl_app` como classe central e uma classe por módulo, que abre o menu e chama as transações daquele módulo
- Popup de confirmação ao sair ou voltar (`POPUP_TO_CONFIRM`), encapsulado em `lcl_popup`

## Transações chamadas pelo cockpit

| Transação | Módulo | Destaques |
|---|---|---|
| `ZSDPED` | SD | Module pool de pedidos com 4 telas, 2 ALVs OO (`CL_GUI_ALV_GRID` em custom container) e function modules para total e baixa de estoque |
| `ZSDMP` | SD | Monitor de pedidos com `CL_SALV_TABLE`, do cabeçalho para os itens no duplo clique |
| `ZCLIENTES` | SD | CRUD de clientes |
| `ZPRODUTOS` | MM | CRUD de produtos |
| `ZREL_ESTOQUE` | MM | Relatório de estoque com `REUSE_ALV_GRID_DISPLAY` |
| `ZRELFI` | FI | Relatório financeiro com `CL_SALV_TABLE` e ALV de detalhe no duplo clique |
| `ZFIMENUPAG` / `ZFIBAIXAFAT` | FI | Formas de pagamento e baixa de faturas |
| `ZFUNCIONARIOS` | RH | CRUD de funcionários |

O projeto usa as **três abordagens de ALV**: `REUSE_ALV_GRID_DISPLAY`, `CL_SALV_TABLE` e `CL_GUI_ALV_GRID`.

## Outros objetos

- Tabelas Z, function groups, number ranges e search helps
- Classes globais `ZCL_POPUP` e `ZCL_PEDIDO_SERVICE`
- **Adobe Forms** de fatura e nota fiscal

## Em aberto

- Fatura em Vendas, pedidos cancelados e reimpressão de fatura em FI ainda não foram implementados

## Como importar

1. Instale o [abapGit](https://abapgit.org) no seu sistema
2. Crie um pacote Z e faça *clone* deste repositório nele
3. Ative os objetos e rode a transação `ZCOFFEE`

## Tecnologias

ABAP procedural e OO · module pool (dynpro) · ALV (REUSE, SALV, GUI_ALV_GRID) · function modules · Adobe Forms · abapGit

---

Projeto de estudo feito por **Leonardo Cabrini Mauro** · [LinkedIn](https://www.linkedin.com/in/leonardo-cabrini-mauro-79b292355/)
