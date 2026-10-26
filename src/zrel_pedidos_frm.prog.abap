FORM f_exibir_pedidos.

  " Validação de período
  IF p_date_f IS INITIAL.
    p_date_f = p_date.
  ENDIF.

  IF p_date IS INITIAL.
    p_date = p_date_f.
  ENDIF.

  IF p_date_f > p_date.
    DATA(lv_temp) = p_date.
    p_date = p_date_f.
    p_date_f = lv_temp.
  ENDIF.

  " Limpar tabela de saída antes do select
  CLEAR lt_out.
  REFRESH lt_out.

  SELECT
    a~id_ped,
    a~cpf,
    a~data_ped,
    a~nome_cliente,
    a~valor_total,
    a~id_func,

    b~id_prod,
    b~qtde,
    b~valor_item,

    c~nome_prod,
    d~nome AS nome_func

  FROM ztb_ped AS a
  INNER JOIN ztb_pedit AS b ON a~id_ped = b~id_ped
  LEFT JOIN ztb_prod  AS c  ON b~id_prod = c~id_prod
  LEFT JOIN ztb_func  AS d  ON a~id_func = d~id_func
  WHERE a~id_ped IN @s_idped
    AND a~cpf     IN @s_cpf
    AND a~data_ped BETWEEN @p_date_f AND @p_date
    AND a~id_func IN @s_func
    " inclui filtro de produto se informado
    AND ( b~id_prod IN @s_prod )
  INTO CORRESPONDING FIELDS OF TABLE @lt_out.


  PERFORM show_alv.


*  SELECT
*  a~id_ped,
*  a~cpf,
*  a~data_ped,
*  a~nome_cliente,
*  a~valor_total,
*  a~id_func,
*
*  b~id_prod,
*  b~qtde,
*  b~valor_item,
*
*  c~nome_prod,
*  d~nome AS nome_func
*
*FROM ztb_ped AS a
*INNER JOIN ztb_pedit AS b ON a~id_ped = b~id_ped
*LEFT JOIN ztb_prod  AS c  ON b~id_prod = c~id_prod
*LEFT JOIN ztb_func  AS d  ON a~id_func = d~id_func
*
*    WHERE a~id_ped IN @s_idped
*    AND a~cpf IN @s_cpf
*    AND a~data_ped BETWEEN @p_date_f AND @p_date
*    AND a~id_func IN @s_func
*
*INTO CORRESPONDING FIELDS OF TABLE @lt_out.
*
*  PERFORM show_alv.
ENDFORM.



FORM show_alv.
  DATA: ls_fieldcat TYPE slis_fieldcat_alv,
        lt_fieldcat TYPE STANDARD TABLE OF slis_fieldcat_alv.

  CLEAR lt_fieldcat.

  wa_lay-zebra = 'X'.
  wa_lay-colwidth_optimize = 'X'.
  wa_lay-box_fieldname = ''.



  "============================
  " Ordenação
  "============================
  CLEAR wa_sort.
  wa_sort-fieldname = 'ID_PED'.
  wa_sort-up = 'X'.
  APPEND wa_sort TO it_sort.

  CLEAR wa_sort.
  wa_sort-fieldname = 'ID_PROD'.
  wa_sort-up = 'X'.
  APPEND wa_sort TO it_sort.


  "============================
  " Campos do Cabeçalho
  "============================

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'ID_PED'.
  ls_fieldcat-seltext_m   = 'Código Pedido'.
  ls_fieldcat-ref_tabname = 'ZTB_PED'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'DATA_PED'.
  ls_fieldcat-seltext_m   = 'Data Pedido'.
  ls_fieldcat-ref_tabname = 'ZTB_PED'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'NOME_CLIENTE'.
  ls_fieldcat-seltext_m   = 'Cliente'.
  ls_fieldcat-ref_tabname = 'ZTB_PED'.
  APPEND ls_fieldcat TO lt_fieldcat.

*  CLEAR ls_fieldcat.
*  ls_fieldcat-fieldname   = 'VALOR_TOTAL'.
*  ls_fieldcat-seltext_m   = 'Valor Total'.
*  ls_fieldcat-datatype    = 'CURR'.
*  ls_fieldcat-cfieldname  = 'WAERS'.
*  ls_fieldcat-just        = 'R'.
*  ls_fieldcat-ref_tabname = 'ZTB_PED'.
*  APPEND ls_fieldcat TO lt_fieldcat.


  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'ID_FUNC'.
  ls_fieldcat-seltext_m   = 'ID Funcionário'.
  ls_fieldcat-ref_tabname = 'ZTB_PED'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'NOME_FUNC'.
  ls_fieldcat-seltext_m   = 'Nome Funcionário'.
  ls_fieldcat-ref_tabname = 'ZTB_FUNC'.
  APPEND ls_fieldcat TO lt_fieldcat.


  "============================
  " Campos dos Itens do Pedido
  "============================

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'ID_PROD'.
  ls_fieldcat-seltext_m   = 'Produto'.
  ls_fieldcat-ref_tabname = 'ZTB_PEDIT'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'NOME_PROD'.
  ls_fieldcat-seltext_m   = 'Nome Produto'.
  ls_fieldcat-ref_tabname = 'ZTB_PROD'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'QTDE'.
  ls_fieldcat-seltext_m   = 'Quantidade'.
  ls_fieldcat-ref_tabname = 'ZTB_PEDIT'.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname   = 'VALOR_ITEM'.
  ls_fieldcat-seltext_m   = 'Valor Item'.
  ls_fieldcat-datatype    = 'CURR'.
  ls_fieldcat-cfieldname  = 'WAERS'.
  ls_fieldcat-just        = 'R'.
  ls_fieldcat-ref_tabname = 'ZTB_PEDIT'.
  APPEND ls_fieldcat TO lt_fieldcat.




  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      it_fieldcat              = lt_fieldcat
      it_sort                  = it_sort
      is_layout                = wa_lay
      i_grid_title             = 'Relatório de pedidos'
      i_callback_pf_status_set = 'SET_PF_STATUS'
    TABLES
      t_outtab                 = lt_out
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.


ENDFORM.

FORM top_page USING p_list TYPE slis_t_listheader.

  DATA: ls_header TYPE slis_listheader.

  CLEAR ls_header.
  ls_header-typ  = 'H'.
  ls_header-info = 'Relatório de Pedidos - ZCOFFEE'.
  APPEND ls_header TO p_list.

  CLEAR ls_header.
  ls_header-typ  = 'S'.
  ls_header-key  = 'Data de seleção:'.
  ls_header-info = sy-datum.
  APPEND ls_header TO p_list.

  CLEAR ls_header.
  ls_header-typ  = 'S'.
  ls_header-key  = 'Usuário:'.
  ls_header-info = sy-uname.
  APPEND ls_header TO p_list.

ENDFORM.

FORM top_of_page.
  PERFORM top_page USING it_header.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = it_header.
ENDFORM.

FORM set_pf_status USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'STANDARD'.
ENDFORM.

FORM HANDLE_ALV_EVENT
  USING ucomm TYPE sy-ucomm
        selfield TYPE slis_selfield.

  DATA ld_field type char10.

  READ TABLE lt_out INTO ls_out INDEX selfield-tabindex.
  ld_field = ls_out-id_ped.
  CONDENSE ld_field NO-GAPS.

  SET PARAMETER ID 'ZID_PED' FIELD ld_field.

  CASE ucomm.
    WHEN 'EDIT'.
      CALL TRANSACTION 'ZEDIT_PEDIDO'.
    WHEN 'DELETE'.

  ENDCASE.


  PERFORM f_exibir_pedidos.
  selfield-refresh = 'X'.

  ENDFORM.
