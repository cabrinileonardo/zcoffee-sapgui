*&---------------------------------------------------------------------*
*& Report ZPRG_FI_MENU_PAG
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zprg_fi_menu_pag.

TYPES: BEGIN OF ty_pgto,
         id          TYPE zdeidpag,
         descricao   TYPE  zdedescpag,
         parcela     TYPE  zdeparc,
         status      TYPE  zdestatus,
         status_desc TYPE ddtext,
         tipo_pag    TYPE  zdetipopag,
         desc_tipo   TYPE ddtext,
       END OF ty_pgto.

DATA: lo_alv        TYPE REF TO cl_salv_table,
      lo_functions  TYPE REF TO cl_salv_functions_list,
      lo_columns    TYPE REF TO cl_salv_columns_table,
      lo_column     TYPE REF TO cl_salv_column,
      lo_sorts      TYPE REF TO cl_salv_sorts,
      lo_sort       TYPE REF TO cl_salv_sort,
      lo_selections TYPE REF TO cl_salv_selections,
      lo_events     TYPE REF TO cl_salv_events_table,
      lo_grid       TYPE REF TO cl_gui_alv_grid.

DATA: lt_pgto TYPE STANDARD TABLE OF ty_pgto,
      ls_pgto TYPE ty_pgto.

DATA: lt_rows TYPE lvc_t_row,
      ls_row  TYPE lvc_s_row.

DATA gv_id_pgto TYPE zdeidpag.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    p_all  AS CHECKBOX DEFAULT 'X'.

  SELECT-OPTIONS:
    s_pag   FOR ls_pgto-id.

  PARAMETERS:
    p_tipo TYPE zdetipopag,
    p_stat TYPE zdestatus.

SELECTION-SCREEN END OF BLOCK b1.

CLASS lcl_event DEFINITION.
  PUBLIC SECTION.
    METHODS handler FOR EVENT added_function OF cl_salv_events_table IMPORTING e_salv_function.
ENDCLASS.

CLASS lcl_event IMPLEMENTATION.
  METHOD handler.
    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      IMPORTING
        e_grid = lo_grid.

    CALL METHOD lo_grid->get_selected_rows
      IMPORTING
        et_index_rows = lt_rows.

    READ TABLE lt_rows INTO ls_row INDEX 1.
    IF sy-subrc = 0.
      READ TABLE lt_pgto INTO ls_pgto INDEX ls_row-index.
      IF sy-subrc = 0.
        CASE e_salv_function.
          WHEN 'CREATE'.
            CALL TRANSACTION 'ZFINEWPAG'.
          WHEN 'EDIT'.
            EXPORT gv_id_pgto = ls_pgto-id TO MEMORY ID 'ZPGTO_ID'.
            CALL TRANSACTION 'ZFIEDITPAG'.
          WHEN 'DELETE'.

            IF ls_pgto-status = 9.
              MESSAGE 'Pagamento já está inativo' TYPE 'S'.
              RETURN.
            ENDIF.

            UPDATE ztb_pagamento
               SET status = 9
             WHERE id     = ls_pgto-id.

            IF sy-subrc = 0.
              COMMIT WORK AND WAIT.
              MESSAGE 'Pagamento inativado com sucesso' TYPE 'S'.
            ELSE.
              ROLLBACK WORK.
              MESSAGE 'Erro ao inativar pagamento' TYPE 'E'.
              RETURN.
            ENDIF.

            SUBMIT (sy-repid) AND RETURN.

        ENDCASE.
      ENDIF.
    ENDIF.



  ENDMETHOD.
ENDCLASS.

DATA lo_handler TYPE REF TO lcl_event.

START-OF-SELECTION.
  PERFORM f_buscar_dados.
  PERFORM f_show_alv.

FORM f_buscar_dados.
  IF p_all = abap_true.

    SELECT  a~id,
            a~descricao,
            a~parcela,
            a~status,
            b~ddtext AS status_desc,
            a~tipo_pag,
            c~ddtext AS desc_tipo
      FROM ztb_pagamento AS a
      INNER JOIN dd07t AS b
       ON  b~domname = 'ZDOSTATUS'
       AND b~domvalue_l = a~status
       AND b~ddlanguage = @sy-langu
      INNER JOIN dd07t AS c
       ON  c~domname = 'ZDETIPOPAG'
       AND c~domvalue_l = a~tipo_pag
       AND c~ddlanguage = @sy-langu
      INTO CORRESPONDING FIELDS OF TABLE @lt_pgto.

  ELSE.

    SET PF-STATUS 'STANDARD'.

    SELECT  a~id,
            a~descricao,
            a~parcela,
            a~status,
            b~ddtext AS status_desc,
            a~tipo_pag,
            c~ddtext AS desc_tipo
      FROM ztb_pagamento AS a
      INNER JOIN dd07t AS b
       ON  b~domname = 'ZDOSTATUS'
       AND b~domvalue_l = a~status
       AND b~ddlanguage = @sy-langu
      INNER JOIN dd07t AS c
       ON  c~domname = 'ZDETIPOPAG'
       AND c~domvalue_l = a~tipo_pag
       AND c~ddlanguage = @sy-langu
      WHERE id IN @s_pag
        AND ( @p_tipo IS INITIAL OR tipo_pag = @p_tipo )
        AND ( @p_stat IS INITIAL OR status = @p_stat )
      INTO CORRESPONDING FIELDS OF TABLE @lt_pgto.

  ENDIF.

  IF sy-subrc = 0.
    SORT lt_pgto BY id.
  ELSE.
    MESSAGE 'Sem dados para essa seleção' TYPE 'E'.
    RETURN.
  ENDIF.

ENDFORM.


FORM f_show_alv.
  TRY.
      CALL METHOD cl_salv_table=>factory
        EXPORTING
          list_display = if_salv_c_bool_sap=>false
*         r_container  =
*         container_name =
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_pgto.
    CATCH cx_salv_msg.
  ENDTRY.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~set_screen_status
    EXPORTING
      report   = sy-repid
      pfstatus = 'STANDARD'
*     set_functions = CL_SALV_MODEL_BASE=>C_FUNCTIONS_NONE
    .

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_event
    RECEIVING
      value = lo_events.


  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_functions
    RECEIVING
      value = lo_functions.

  CALL METHOD lo_functions->set_all
    EXPORTING
      value = if_salv_c_bool_sap=>true.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_columns
    RECEIVING
      value = lo_columns.

  CALL METHOD lo_columns->set_optimize
    EXPORTING
      value = 'X'.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'STATUS'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_visible
    EXPORTING
      value = abap_false.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'TIPO_PAG'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_visible
    EXPORTING
      value = abap_false.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'STATUS_DESC'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_long_text
    EXPORTING
      value = 'Status'.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'DESC_TIPO'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_long_text
    EXPORTING
      value = 'Tipo'.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_sorts
    RECEIVING
      value = lo_sorts.

  TRY.
      CALL METHOD lo_sorts->add_sort
        EXPORTING
          columnname = 'ID'
        RECEIVING
          value      = lo_sort.
    CATCH cx_salv_not_found.
    CATCH cx_salv_existing.
    CATCH cx_salv_data_error.
  ENDTRY.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_selections
    RECEIVING
      value = lo_selections.

  CALL METHOD lo_selections->set_selection_mode
    EXPORTING
      value = if_salv_c_selection_mode=>row_column.

  CREATE OBJECT lo_handler.

  SET HANDLER lo_handler->handler FOR lo_events.

  CALL METHOD lo_alv->if_salv_gui_om_table_action~display.
ENDFORM.
