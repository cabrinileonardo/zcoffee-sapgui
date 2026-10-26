*----------------------------------------------------------------------
* Declaração de Tipos
*----------------------------------------------------------------------
DATA lv_id_cliente TYPE zid_cliente.

TYPES: BEGIN OF ty_det,
         id_fat      TYPE zdeidfat,
         id_ped      TYPE zid_ped,
         seq_fat     TYPE zdeseqfat,
         data_fat    TYPE erdat,
         data_venc   TYPE zdedatavenc,
         data_pag    TYPE zdedatfat,
         valor       TYPE zvalor_total,
         moeda       TYPE waers,
         status      TYPE zdestsfatit,
         status_desc TYPE ddtext,
       END OF ty_det.

TYPES: BEGIN OF ty_cli,
         id_cliente     TYPE zid_cliente,
         id_fat         TYPE zdeidfat,
         nome_cliente   TYPE znome_cli_e,
         forma_pag      TYPE zdedescpag,
         total_faturado TYPE p DECIMALS 2,
         total_pago     TYPE p DECIMALS 2,
         total_aberto   TYPE p DECIMALS 2,
       END OF ty_cli.

*----------------------------------------------------------------------
* Declaração de Variáveis Globais
*----------------------------------------------------------------------
DATA: gt_det TYPE STANDARD TABLE OF ty_det,
      gt_cli TYPE STANDARD TABLE OF ty_cli,
      gs_cli TYPE ty_cli.

DATA lt_rows TYPE lvc_t_row.
DATA ls_row TYPE lvc_s_row.

DATA lo_alv   TYPE REF TO cl_salv_table.
DATA lo_col   TYPE REF TO cl_salv_column.
DATA lo_funcs TYPE REF TO cl_salv_functions_list.
DATA lo_cols TYPE REF TO cl_salv_columns_table.
DATA lo_sel TYPE REF TO cl_salv_selections.
DATA lo_events TYPE REF TO cl_salv_events_table.
DATA lo_grid TYPE REF TO cl_gui_alv_grid.
DATA lo_display TYPE REF TO CL_SALV_DISPLAY_SETTINGS.

DATA lo_alv_det TYPE REF TO cl_salv_table.
