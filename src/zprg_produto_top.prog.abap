*---------------------------------------------------------------------*
* Tabelas e Includes Globais
*---------------------------------------------------------------------*
TABLES: ztb_prod.          "Tabela de produtos
INCLUDE <icon>.            "Constantes de ícones SAP

*---------------------------------------------------------------------*
* Variáveis Globais
*---------------------------------------------------------------------*

"Variável auxiliar para controle temporário de ID do produto
DATA gv_id_prod_temp TYPE ztb_prod-id_prod.

*---------------------------------------------------------------------*
* 1. Estruturas e Tabelas Internas
*---------------------------------------------------------------------*

"Tabela interna principal de produtos
DATA: lt_prod TYPE STANDARD TABLE OF ztb_prod,
      ls_prod TYPE ztb_prod.

"Dados selecionados no ALV (linha clicada)
DATA ls_dados_selecionados LIKE LINE OF lt_prod.

*---------------------------------------------------------------------*
* 2. Controle de Tela e Fluxo
*---------------------------------------------------------------------*

"OKCODE (comandos de tela / botões)
DATA gd_okcode TYPE sy-ucomm.

"Resposta de mensagens de confirmação (POPUP)
DATA gd_resposta TYPE char1.

"Ícone de status do produto (ativo/inativo)
DATA status_icon TYPE icon_d.

*---------------------------------------------------------------------*
* 3. Declarações para ALV (List Viewer)
*---------------------------------------------------------------------*

TYPE-POOLS: slis, kkblo.

"Identificação do programa e variante
DATA: v_repid LIKE sy-repid,
      v_save  TYPE c.

"Catálogo de campos, cabeçalho e ordenação
DATA: it_fcat     TYPE slis_t_fieldcat_alv,
      it_fieldcat TYPE kkblo_t_fieldcat,
      it_header   TYPE kkblo_t_listheader,
      it_sort     TYPE slis_t_sortinfo_alv.

"Work areas auxiliares do ALV
DATA: wa_variant TYPE disvariant,
      wa_afield  TYPE kkblo_fieldcat,
      wa_colinfo TYPE kkblo_specialcol,
      wa_layout  TYPE kkblo_layout,
      wa_header  TYPE kkblo_listheader,
      wa_lay     TYPE slis_layout_alv,
      wa_sort    LIKE LINE OF it_sort.

*---------------------------------------------------------------------*
* 4. Tela de Seleção
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* Bloco 1 – Dados do Produto
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  "Dados básicos para inserção ou alteração
  PARAMETERS:
    p_idprod TYPE ztb_prod-id_prod,     "ID do produto
    p_nome   TYPE ztb_prod-nome_prod.   "Nome do produto

SELECTION-SCREEN END OF BLOCK b1.

*---------------------------------------------------------------------*
* Bloco 2 – Ações do Programa
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    rb_ins RADIOBUTTON GROUP act DEFAULT 'X',  "Inserir produto
    rb_alt RADIOBUTTON GROUP act,              "Alterar produto
    rb_exi RADIOBUTTON GROUP act,              "Listar produtos
    rb_del RADIOBUTTON GROUP act.              "Excluir produto

SELECTION-SCREEN END OF BLOCK b2.

*---------------------------------------------------------------------*
* Bloco 3 – Filtros Avançados (Listagem)
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.

  "Filtros utilizados apenas na exibição/listagem
  SELECT-OPTIONS:
    s_id     FOR ztb_prod-id_prod,        "Filtro por ID
    s_nome   FOR ztb_prod-nome_prod,      "Filtro por nome
    s_cat    FOR ztb_prod-categoria,      "Filtro por categoria
    s_qtde   FOR ztb_prod-qtde_estoque,   "Filtro por quantidade
    s_preco FOR ztb_prod-preco.           "Filtro por preço

  PARAMETERS:
    p_ativo TYPE ztb_prod-status_prod,      "Exibir somente produtos ativos
    p_all AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b3.
