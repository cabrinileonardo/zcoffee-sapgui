*&---------------------------------------------------------------------*
*& Report ZFI_CAD_FORMA_PAG
*&---------------------------------------------------------------------*
*& Cadastro e exibição de formas de pagamento via ALV (SALV)
*&---------------------------------------------------------------------*
REPORT zfi_cad_forma_pag.

"--- Estrutura para armazenar dados da tabela ZTFI_FORMA_PAG
TYPES: BEGIN OF ty_forma_pag,
         id_forma  TYPE ztfi_forma_pag-id_forma,
         descricao TYPE ztfi_forma_pag-descricao,
         tipo      TYPE ztfi_forma_pag-tipo,
         ativo     TYPE ztfi_forma_pag-ativo,
       END OF ty_forma_pag.

"--- Tabelas internas e variáveis de trabalho
DATA: gt_forma_pag TYPE STANDARD TABLE OF ty_forma_pag,
      gs_forma_pag TYPE ty_forma_pag.

"--- Variáveis de controle
DATA: gd_okcode TYPE sy-ucomm,
      gd_mode   TYPE char1.

"--- Objetos ALV
DATA: lo_alv       TYPE REF TO cl_salv_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_columns   TYPE REF TO cl_salv_columns_table,
      lo_column    TYPE REF TO cl_salv_column,
      lo_sorts     TYPE REF TO cl_salv_sorts,
      lo_filter   TYPE REF TO CL_SALV_FILTERS.

"--- Seleção de dados da tabela ZTFI_FORMA_PAG
SELECT id_forma,
       descricao,
       tipo,
       ativo
  FROM ztfi_forma_pag
  INTO TABLE @gt_forma_pag.

"--- Criação do objeto ALV
TRY.
    CALL METHOD cl_salv_table=>factory
      IMPORTING
        r_salv_table = lo_alv
      CHANGING
        t_table      = gt_forma_pag.
  CATCH cx_salv_msg.
    " Tratar exceção caso ALV não seja criado
ENDTRY.

"--- Ativar todas as funções padrão do ALV (filtros, exportar, etc.)
CALL METHOD lo_alv->if_salv_gui_om_table_info~get_functions
  RECEIVING
    value = lo_functions.

CALL METHOD lo_functions->set_all
  EXPORTING
    value = if_salv_c_bool_sap=>true.

"--- Configuração das colunas
CALL METHOD lo_alv->if_salv_gui_om_table_info~get_columns
  RECEIVING
    value = lo_columns.

"--- Definir ordem das colunas
CALL METHOD lo_columns->set_column_position
  EXPORTING
    columnname = 'ID_FORMA'
    position   = 1.

CALL METHOD lo_columns->set_column_position
  EXPORTING
    columnname = 'DESCRICAO'
    position   = 2.

"--- Alterar texto longo da coluna ID_FORMA
TRY.
    CALL METHOD lo_columns->get_column
      EXPORTING
        columnname = 'ID_FORMA'
      RECEIVING
        value      = lo_column.
  CATCH cx_salv_not_found.
    " Caso a coluna não seja encontrada
ENDTRY.

CALL METHOD lo_column->set_long_text
  EXPORTING
    value = 'Código da forma de pagamento'.

CALL METHOD lo_alv->if_salv_gui_om_table_info~get_sorts
  RECEIVING
    value = lo_sorts.

TRY.
CALL METHOD lo_sorts->add_sort
  EXPORTING
    columnname = 'ID_FORMA'
    sequence   = IF_SALV_C_SORT=>SORT_UP
    .
  CATCH cx_salv_not_found.
  CATCH cx_salv_existing.
  CATCH cx_salv_data_error.
ENDTRY.


"--- Exibir ALV
CALL METHOD lo_alv->if_salv_gui_om_table_action~display.
