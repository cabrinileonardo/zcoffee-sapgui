* Tabelas de Banco de Dados (Para INSERT/UPDATE)
TABLES: ztb_ped,   " Cabeçalho do Pedido
        ztb_pedit, " Itens do Pedido
        ztb_prod,
        ztb_clientes.  " Produtos (usada para ler preço/estoque e UPDATE)

* Estruturas de Apoio (Criadas na SE11)
TYPE-POOLS: slis.  " Necessário se for usar o ALV (future-proof)

* Estruturas de Trabalho
* Estrutura que espelha o cabeçalho do pedido
TYPES: BEGIN OF ty_pedido_header,
         mandt       TYPE ztb_ped-mandt,
         id_ped      TYPE ztb_ped-id_ped,
         cpf         TYPE ztb_ped-cpf,
         cliente     TYPE ztb_ped-nome_cliente,
         data_ped    TYPE ztb_ped-data_ped,
         valor_total TYPE ztb_ped-valor_total,
         id_func     TYPE ztb_ped-id_func,
         funcionario TYPE ztb_ped-id_func,
         moeda       TYPE ztb_ped-moeda,
         status      TYPE ztb_ped-status_ped,
         status_desc type ztb_ped-status_desc,
       END OF ty_pedido_header.

* Estrutura que espelha os itens do pedido
TYPES: BEGIN OF ty_pedido_item,
         mandt        TYPE ztb_pedit-mandt,
         id_ped       TYPE ztb_pedit-id_ped,
         id_prod      TYPE ztb_pedit-id_prod,
         qtde         TYPE ztb_pedit-qtde,
         preco_unit   TYPE zpreco, " Adicionado para cálculo
         moeda        TYPE ztb_pedit22-moeda,
         valor_item   TYPE ztb_pedit22-valor_item,
*         qtde_estoque TYPE ztb_prod-qtde_estoque, " Adicionado para validação
       END OF ty_pedido_item.

* Variáveis de Controle
data: gs_pedido_header type ztb_ped, " Armazena dados do cabeçalho
gv_valor_total   type ztb_ped-valor_total,  " Acumulador do valor total
gv_id_ped        type ztb_ped-id_ped.     " Novo número do pedido

* Tabela Interna para os Itens
DATA: gt_pedido_itens TYPE STANDARD TABLE OF ztb_pedit
                        WITH KEY id_prod, " Tabela onde acumulamos todos os itens
      gs_pedido_item  TYPE ztb_pedit. " Estrutura de trabalho para um item


* Variável para o elemento da tela
DATA: gv_cod_cliente TYPE ztb_ped-cpf. " Mapeia o campo "Cod. Cliente" da tela

* Variáveis de Status e Exceção
DATA: lv_sucesso       TYPE char1.   " Flag de retorno da ZF_ATUALIZA_ESTOQUE

DATA gd_okcode TYPE sy-ucomm.

DATA: gv_id_ped_temp TYPE ztb_ped-id_ped.  " Usado para exibir o próximo ID
