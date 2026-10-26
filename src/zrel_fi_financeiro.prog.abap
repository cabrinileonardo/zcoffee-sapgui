REPORT zrel_fi_financeiro.

INCLUDE zrel_fi_financeiro_top.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS handler
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.
  METHOD handler.
    READ TABLE gt_cli INTO gs_cli INDEX row.
    IF sy-subrc = 0.
      PERFORM f_buscar_det.
      PERFORM f_montar_alv_det.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: gs_sel_fatura TYPE ztb_fatura,
      gs_sel_ped    TYPE ztb_ped.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_datfat FOR gs_sel_fatura-data_fat,
    s_idcli  FOR gs_sel_ped-id_cliente.
  PARAMETERS:
    p_moeda TYPE ztb_fatura_itens-moeda DEFAULT 'BRL'.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  PERFORM f_buscar_dados.
  PERFORM f_montar_alv.

INCLUDE zrel_fi_financeiro_f01.
