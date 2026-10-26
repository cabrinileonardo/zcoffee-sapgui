FORM f_buscar_det.
  SELECT
              b~id_fat,
              a~id_ped,
              b~seq_fat,
              a~data_fat,
              b~data_venc,
              b~data_pag,
              b~valor,
              b~moeda,
              b~status,
              d~ddtext AS status_desc
         FROM ztb_fatura             AS a
         INNER JOIN ztb_fatura_itens AS b
           ON a~id_fat = b~id_fat
         INNER JOIN ztb_ped          AS e
           ON e~id_ped = a~id_ped
         INNER JOIN dd07t            AS d
           ON d~ddlanguage = @sy-langu
          AND d~domname    = 'ZDOSTSFATIT'
          AND d~domvalue_l = b~status
         WHERE e~id_cliente = @gs_cli-id_cliente
          AND b~id_fat = @gs_cli-id_fat
         INTO TABLE @gt_det.

  IF sy-subrc <> 0.
    MESSAGE 'Sem detalhes para esse linha' TYPE 'E'.
    RETURN.
  ENDIF.
ENDFORM.

FORM f_montar_alv_det.
  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = lo_alv_det
        CHANGING
          t_table      = gt_det.
    CATCH cx_salv_msg.
  ENDTRY.

  CALL METHOD lo_alv_det->if_salv_gui_om_table_action~display.
ENDFORM.


FORM f_buscar_dados .
  " Seleção dos dados consolidados por cliente
  SELECT DISTINCT
      e~id_cliente,
      f~nome_cli AS nome_cliente,
      a~id_fat,
      c~descricao AS forma_pag,
      SUM( b~valor ) AS total_faturado,
      SUM( CASE WHEN b~status = 'P'
                THEN b~valor ELSE 0 END ) AS total_pago,
      SUM( CASE WHEN b~status = 'A'
                THEN b~valor ELSE 0 END ) AS total_aberto
    FROM ztb_fatura AS a
    INNER JOIN ztb_fatura_itens AS b
      ON b~id_fat = a~id_fat
    INNER JOIN ztb_ped AS e
      ON e~id_ped = a~id_ped
    INNER JOIN ztb_clientes AS f
      ON f~id_cliente = e~id_cliente
    LEFT JOIN ztb_pagamento AS c
      ON c~id = a~id_pagamento
    WHERE a~data_fat IN @s_datfat
      AND b~moeda    = @p_moeda
      AND e~id_cliente IN @s_idcli
    GROUP BY e~id_cliente, c~descricao, nome_cli, a~id_fat
    INTO CORRESPONDING FIELDS OF TABLE @gt_cli.

  " Verifica se houve retorno
  IF sy-subrc <> 0.
    MESSAGE 'Sem dados para essa seleção' TYPE 'I' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Ordena os dados por cliente
  SORT gt_cli BY id_cliente.
ENDFORM.


FORM f_montar_alv .

  DATA: lv_colname TYPE lvc_fname,
        lv_mtext   TYPE scrtext_m.
*----------------------------------------------------------------------
* Exibição em ALV
*----------------------------------------------------------------------

  " Criação do ALV
  cl_salv_table=>factory(
    IMPORTING r_salv_table = lo_alv
    CHANGING  t_table      = gt_cli
  ).

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_columns
    RECEIVING
      value = lo_cols.

  CALL METHOD lo_cols->set_optimize
    EXPORTING
      value = abap_true.

  PERFORM f_set_text_column USING 'TOTAL_FATURADO' 'Total Faturado' CHANGING lv_mtext.
  PERFORM f_set_text_column USING 'TOTAL_PAGO' 'Total Pago' CHANGING lv_mtext.
  PERFORM f_set_text_column USING 'TOTAL_ABERTO' 'Total em Aberto' CHANGING lv_mtext.

  " Configurações gerais do ALV
  lo_alv->get_functions( )->set_all( abap_true ).

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_selections
    RECEIVING
      value = lo_sel.

  CALL METHOD lo_sel->set_selection_mode
    EXPORTING
      value = if_salv_c_selection_mode=>row_column.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_event
    RECEIVING
      value = lo_events.

  DATA lo_handler TYPE REF TO lcl_events.
  CREATE OBJECT lo_handler.

  SET HANDLER lo_handler->handler FOR lo_events.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_display_settings
    RECEIVING
      value  = lo_display
      .

  CALL METHOD lo_display->set_striped_pattern
    EXPORTING
      value  = abap_true
      .

  CALL METHOD lo_cols->set_optimize
    EXPORTING
      value  = abap_true
      .

  CALL METHOD lo_alv->if_salv_gui_om_table_action~display
*  IMPORTING
*    exit_caused_by_caller =
*    exit_caused_by_user   =
    .
ENDFORM.

FORM f_set_text_column USING uv_colname TYPE lvc_fname
                             uv_mtext TYPE scrtext_m
                       CHANGING cv_mtext TYPE scrtext_m.
  TRY.
      CALL METHOD lo_cols->get_column
        EXPORTING
          columnname = uv_colname
        RECEIVING
          value      = lo_col.
    CATCH cx_salv_not_found.
  ENDTRY.


  CALL METHOD lo_col->set_medium_text
    EXPORTING
      value = uv_mtext.

  cv_mtext = cv_mtext.
ENDFORM.
