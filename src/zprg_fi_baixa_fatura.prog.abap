*&---------------------------------------------------------------------*
*& Report ZPRG_FI_BAIXA_FATURA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zprg_fi_baixa_fatura.

DATA: gt_fat_abertas TYPE STANDARD TABLE OF zstrfaturait_01,
      gs_fat_abertas TYPE zstrfaturait_01.

DATA lv_id_fat TYPE zdeidfat.

DATA: lt_rows TYPE lvc_t_row,
      ls_row  TYPE lvc_s_row.

DATA gv_recarregar TYPE abap_bool.


DATA: lo_alv        TYPE REF TO cl_salv_table,
      lo_functions  TYPE REF TO cl_salv_functions_list,
      lo_selections TYPE REF TO cl_salv_selections,
      lo_set        TYPE REF TO cl_salv_display_settings,
      lo_toolbar    TYPE REF TO cl_salv_function,
      lo_events     TYPE REF TO cl_salv_events_table,
      lo_grid       TYPE REF TO cl_gui_alv_grid.

SELECT-OPTIONS: s_idfat FOR lv_id_fat.
PARAMETERS: p_data TYPE sy-datum DEFAULT sy-datum.

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: on_user_command
      FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_user_command.
    CASE e_salv_function.
      WHEN 'QUIT'.

        CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
          IMPORTING
            e_grid = lo_grid.

        CALL METHOD lo_grid->get_selected_rows
          IMPORTING
            et_index_rows = lt_rows.

        READ TABLE lt_rows INTO ls_row INDEX 1.

        IF lines( lt_rows ) <> 1.
          MESSAGE 'Selecione exatamente 1 linha!' TYPE 'E'.
          RETURN.
        ENDIF.

        IF sy-subrc = 0.

          READ TABLE gt_fat_abertas INTO gs_fat_abertas INDEX ls_row-index.

          IF sy-subrc <> 0.
            MESSAGE 'Sem dados para essa seleção' TYPE 'I'.
            RETURN.
          ELSE.

            DATA lv_answer TYPE c.

            CALL FUNCTION 'POPUP_TO_CONFIRM'
              EXPORTING
                text_question = 'Deseja quitar esta parcela?'
                text_button_1 = 'Sim'
                text_button_2 = 'Não'
              IMPORTING
                answer        = lv_answer.

            IF lv_answer <> '1'.
              RETURN.
            ENDIF.

            IF p_data > sy-datum.
              MESSAGE 'Data de pagamento não pode ser futura.' TYPE 'I'. RETURN.
            ENDIF.

            UPDATE ztb_fatura_itens
              SET status   = 'P',
                  data_pag = @p_data
              WHERE id_fat  = @gs_fat_abertas-id_fat
                AND seq_fat = @gs_fat_abertas-seq_fat.

            MESSAGE |{ gs_fat_abertas-seq_fat }° Parcela da fatura N°{ gs_fat_abertas-id_fat } paga com sucesso| TYPE 'S'.

            COMMIT WORK.

            SELECT COUNT( seq_fat )
              FROM ztb_fatura_itens
              WHERE id_fat = @gs_fat_abertas-id_fat
              AND status = 'A'
            INTO @DATA(lv_seqfat).

            IF sy-subrc = 0 AND lv_seqfat = 0.
              UPDATE ztb_fatura
              SET status = 'P'
             WHERE id_fat = gs_fat_abertas-id_fat.

              COMMIT WORK.

              e_salv_function = 'REF'.

              gv_recarregar = abap_true.

              MESSAGE |Fatura N°{ gs_fat_abertas-id_fat } teve todas as parcelas pagas | TYPE 'S'.

              CLEAR gt_fat_abertas.

              CLEAR gt_fat_abertas.

            ENDIF.

          ENDIF.

        ENDIF.
      WHEN 'REF'.
        PERFORM f_buscar_itens.
        PERFORM f_montar_alv_itens.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

DATA lo_handler TYPE REF TO lcl_event_handler.

START-OF-SELECTION.

  PERFORM f_buscar_itens.
  PERFORM f_montar_alv_itens.

  IF gv_recarregar = abap_true.
    PERFORM f_buscar_itens.
    PERFORM f_montar_alv_itens.
  ENDIF.


FORM f_buscar_itens.

  SELECT a~id_fat,
         a~seq_fat,
         a~data_venc,
         a~valor,
         a~moeda,
         a~status,
         b~ddtext AS status_desc,
         a~data_pag
    FROM ztb_fatura_itens AS a
    INNER JOIN dd07t AS b
      ON b~ddlanguage = @sy-langu
     AND b~domname    = 'ZDOSTSFATIT'
     AND b~domvalue_l = a~status
    INTO CORRESPONDING FIELDS OF TABLE @gt_fat_abertas
    WHERE a~status = 'A'
      AND a~id_fat IN @s_idfat.

  IF sy-subrc <> 0.
    MESSAGE 'Sem dados para essa seleção' TYPE 'E'.
    RETURN.
  ENDIF.

  SORT gt_fat_abertas BY id_fat.

ENDFORM.

FORM f_montar_alv_itens.

  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = gt_fat_abertas.
    CATCH cx_salv_msg.
  ENDTRY.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_functions
    RECEIVING
      value = lo_functions.

  CALL METHOD lo_functions->set_all
    EXPORTING
      value = if_salv_c_bool_sap=>true.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_selections
    RECEIVING
      value = lo_selections.

  CALL METHOD lo_selections->set_selection_mode
    EXPORTING
      value = if_salv_c_selection_mode=>row_column.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_display_settings
    RECEIVING
      value = lo_set.

  CALL METHOD lo_set->set_striped_pattern
    EXPORTING
      value = 'X'.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~set_screen_status
    EXPORTING
      report   = sy-repid
      pfstatus = 'STANDARD'
*     set_functions = CL_SALV_MODEL_BASE=>c_functions_all
    .

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_event
    RECEIVING
      value = lo_events.

  CREATE OBJECT lo_handler.

  SET HANDLER lo_handler->on_user_command FOR lo_events.


  CALL METHOD lo_alv->if_salv_gui_om_table_action~display.

ENDFORM.
