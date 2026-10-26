*&---------------------------------------------------------------------*
*& Include          ZREP_SD_ALV_COFFEE_TOP
*&---------------------------------------------------------------------*

************************************************************************
* Tipos - Definição de estruturas internas para pedidos e itens
************************************************************************
TYPES: BEGIN OF lty_ped, " Estrutura para cabeçalho do pedido
         id_ped          TYPE zid_ped,        " Código do pedido
         id_cliente      TYPE zid_cliente,    " Código do cliente
         nome_cliente    TYPE zcliente,       " Nome do cliente
         data_ped        TYPE zdata_ped,      " Data do pedido
         hora_ped        TYPE erzet,          " Hora do pedido
         valor_total     TYPE zvalor_total,   " Valor total do pedido
         id_func         TYPE zid_func,       " Código do funcionário
         nome_func       TYPE znome,          " Nome do funcionário
         moeda           TYPE waers,          " Moeda do pedido
         status_ped      TYPE zstatus_ped,    " Status do pedido
         status_desc(60) TYPE c,              " Descrição do status
         pm              TYPE zdeidpag,
         pm_desc(60)     TYPE c,              " Descrição da forma de pagamento
         icon(4)         TYPE c,              " Ícone SAP
         status_icon     TYPE string,
         id_fat          TYPE zdeidfat,
       END OF lty_ped.

TYPES: BEGIN OF lty_item, " Estrutura para itens do pedido
         id_ped     TYPE zid_ped,          " Código do pedido
         id_prod    TYPE zid_prod,         " Código do produto
         nome_prod  TYPE znome_prod,       " Nome do produto
         qtde       TYPE zqtde,            " Quantidade
         preco      TYPE zpreco,           " Preço unitário
         valor_item TYPE zvalor_item,      " Valor total do item
       END OF lty_item.

************************************************************************
* Dados Globais
************************************************************************
DATA: lt_ped  TYPE STANDARD TABLE OF lty_ped,
      lwa_ped TYPE lty_ped.

DATA: lt_item  TYPE STANDARD TABLE OF lty_item,
      lwa_item TYPE lty_item.

DATA: lt_rows  TYPE lvc_t_row,
      lwa_rows TYPE lvc_s_row.

DATA: lv_id_ped     TYPE zid_ped,
      gv_id_ped     TYPE zid_ped,
      gv_new_status TYPE zstatus_ped.

DATA gv_okcode TYPE sy-ucomm.

************************************************************************
* Objetos ALV - Pedidos
************************************************************************
DATA: lo_alv       TYPE REF TO cl_salv_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_columns   TYPE REF TO cl_salv_columns_table,
      lo_column    TYPE REF TO cl_salv_column,
      lo_sorts     TYPE REF TO cl_salv_sorts,
      lo_filter    TYPE REF TO cl_salv_filters,
      lo_events    TYPE REF TO cl_salv_events_table,
      lo_selection TYPE REF TO cl_salv_selections,
      lo_grid      TYPE REF TO cl_gui_alv_grid,
      lo_display   TYPE REF TO cl_salv_display_settings.


************************************************************************
* Objetos ALV - Itens
************************************************************************
DATA: lo_alv_it       TYPE REF TO cl_salv_table,
      lo_functions_it TYPE REF TO cl_salv_functions_list,
      lo_columns_it   TYPE REF TO cl_salv_columns_table,
      lo_column_it    TYPE REF TO cl_salv_column,
      lo_selection_it TYPE REF TO cl_salv_selections,
      lo_display_it   TYPE REF TO cl_salv_display_settings..

************************************************************************
* Classe de eventos ALV
************************************************************************
CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS handler
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.

    METHODS pfstatus
      FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
ENDCLASS.
