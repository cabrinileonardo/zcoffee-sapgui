*&---------------------------------------------------------------------*
*& Include          ZREP_SD_ALV_COFFEE_F01
*&---------------------------------------------------------------------*
* Este include contém rotinas auxiliares para manipulação de pedidos
* no ALV de café. Mantém a lógica separada do programa principal.
*----------------------------------------------------------------------*

FORM alterar_status.  " Rotina para alterar o status de um pedido

  " --- Validação de entrada ---
  IF gv_new_status IS INITIAL.
    MESSAGE 'Informe um status' TYPE 'I'.  " Mensagem informativa ao usuário
    EXIT.                                  " Sai da rotina sem executar o restante
  ENDIF.

  IF lwa_ped-status_ped = 3 AND gv_new_status = 9.
    MESSAGE 'Não é possível cancelar um pedido finalizado' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " --- Atualização do status no banco ---
  UPDATE ztb_ped
     SET status_ped = gv_new_status        " Novo status informado
   WHERE id_ped     = lv_id_ped.           " Pedido específico identificado pela chave

  " --- Tratamento do resultado da atualização ---
  IF sy-subrc = 0.
    COMMIT WORK.                           " Confirma a transação no banco
    MESSAGE 'Status do pedido alterado com sucesso' TYPE 'S'.  " Mensagem de sucesso
    PERFORM f_refresh_alv.                 " Atualiza o ALV para refletir a mudança
  ELSE.
    ROLLBACK WORK.                         " Reverte a transação em caso de erro
    MESSAGE 'Erro ao alterar status do pedido' TYPE 'E'.        " Mensagem de erro
  ENDIF.

ENDFORM.  " alterar_status


*&---------------------------------------------------------------------*
*& Form f_refresh_alv
*&---------------------------------------------------------------------*
*& Rotina responsável por atualizar os dados exibidos no ALV
*&---------------------------------------------------------------------*

FORM f_refresh_alv.

  " --- Limpa dados atuais da tabela interna ---
  CLEAR lt_ped.                 " Remove conteúdo anterior para evitar duplicidade

  " --- Busca novamente os dados respeitando filtros definidos ---
  PERFORM f_buscar_dados.       " Rotina que carrega os registros atualizados

  " --- Reexibe o ALV com os novos dados ---
  PERFORM f_show_alv.           " Rotina que monta e apresenta o ALV

ENDFORM.  " f_refresh_alv


*&---------------------------------------------------------------------*
*& Form f_buscar_dados
*&---------------------------------------------------------------------*
*& Busca pedidos no banco de dados com base nos filtros da tela
*& Retorna os registros na tabela interna lt_ped
*&---------------------------------------------------------------------*
FORM f_buscar_dados.
  " Busca pedidos no banco de dados com base nos filtros da tela

  SELECT
    a~id_ped,          " Identificador único do pedido
    a~id_cliente,      " Código do cliente
    b~nome_cli AS nome_cliente,    " Nome do cliente
    a~data_ped,        " Data do pedido
    a~hora_ped,        " Hora do pedido
    a~valor_total,     " Valor total do pedido
    a~id_func,         " Código do funcionário responsável
    c~nome AS nome_func,       " Nome do funcionário
    a~moeda,           " Moeda utilizada no pedido
    a~status_ped,      " Status atual do pedido
    d~ddtext AS status_desc, " Texto descritivo do status (domínio ZSTATUS_PED_D)
    a~pm,
    f~descricao  AS pm_desc,     " Texto descritivo do meio de pagamento (domínio ZDOPM)
    g~id_fat
    FROM ztb_ped AS a
    INNER JOIN ztb_clientes AS b
     ON a~id_cliente = b~id_cliente
    INNER JOIN ztb_func AS c
     ON a~id_func = c~id_func
    INNER JOIN dd07t AS d
      ON d~domname     = 'ZSTATUS_PED_D'   " Nome do domínio do status
     AND d~domvalue_l = a~status_ped       " Valor do domínio correspondente ao status
     AND d~ddlanguage = @sy-langu          " Idioma da sessão atual
    LEFT JOIN ztb_pagamento AS f
    ON a~pm = f~id
    LEFT JOIN ztb_fatura AS g
     ON g~id_ped = a~id_ped
    WHERE a~id_ped      IN @so_idped       " Filtro por ID do pedido
      AND a~id_cliente  IN @so_idcli       " Filtro por cliente
      AND a~id_func     IN @so_idfun       " Filtro por funcionário
      AND a~data_ped    IN @so_data        " Filtro por data
      AND a~hora_ped    IN @so_hora        " Filtro por hora
      AND a~valor_total IN @so_val         " Filtro por valor total
      AND ( @p_fm   IS INITIAL OR a~pm = @p_fm ) " Se parâmetro p_fm estiver preenchido, filtra pelo meio de pagamento
      AND ( @p_all  = @abap_true
         OR ( @p_all = @abap_false AND a~status_ped = @p_stat ) ) " Se p_all = false, filtra pelo status específico
    INTO CORRESPONDING FIELDS OF TABLE @lt_ped. " Carrega os dados na tabela interna lt_ped

  SORT lt_ped BY id_ped.

  PERFORM preparar_status_icon.

  SORT lt_ped BY id_ped.


ENDFORM.  " f_buscar_dados


FORM preparar_status_icon.

  LOOP AT lt_ped ASSIGNING FIELD-SYMBOL(<fs_ped>).

    CASE <fs_ped>-status_ped.
      WHEN 1. "Incluido
        <fs_ped>-icon = '@09@'. "indefinido
      WHEN 3. "Entregue
        <fs_ped>-icon = '@08@'. "verde
      WHEN 9. "Cancelado
        <fs_ped>-icon = '@5C@'. "vermelho
    ENDCASE.

    CONCATENATE <fs_ped>-icon <fs_ped>-status_desc
      INTO <fs_ped>-status_icon SEPARATED BY space.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_show_alv
*&---------------------------------------------------------------------*
*& Criar e exibir o ALV com os pedidos da cafeteria incluindo
*& configuração de colunas, ordenação, eventos e layout.
*&---------------------------------------------------------------------*
FORM f_show_alv.

  "--- Criação do objeto ALV para pedidos
  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_ped.   " Passa a tabela de pedidos
    CATCH cx_salv_msg.
      " Tratar exceção caso ALV não seja criado
      MESSAGE 'Erro ao criar ALV de pedidos' TYPE 'S' DISPLAY LIKE 'E'.
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

  "--- Definir ordem das colunas (ID_PED como primeira)
  CALL METHOD lo_columns->set_column_position
    EXPORTING
      columnname = 'ID_PED'
      position   = 1.

  "--- Alterar texto longo e curto das colunas
  PERFORM f_set_col_text USING 'ID_PED'     'Código do Pedido'     ''.
  PERFORM f_set_col_text USING 'NOME_FUNC'  'Nome do Funcionário'  ''.
  PERFORM f_set_col_text USING 'STATUS_DESC' 'Status do pedido'    'Status'.
  PERFORM f_set_col_text USING 'PM_DESC'    'Forma de pagamento'   'Pagamento'.

  "--- Ocultar a coluna STATUS_PED (campo técnico)
  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_columns
    RECEIVING
      value = lo_columns.
  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'STATUS_PED'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_visible
    EXPORTING
      value = if_salv_c_bool_sap=>false.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'PM'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_visible
    EXPORTING
      value = if_salv_c_bool_sap=>false.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'STATUS_DESC'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_visible
    EXPORTING
      value = if_salv_c_bool_sap=>false.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'ICON'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_visible
    EXPORTING
      value = if_salv_c_bool_sap=>false.

  TRY.
      CALL METHOD lo_columns->get_column
        EXPORTING
          columnname = 'STATUS_ICON'
        RECEIVING
          value      = lo_column.
    CATCH cx_salv_not_found.
  ENDTRY.

  CALL METHOD lo_column->set_short_text
    EXPORTING
      value = 'Status'.


  "--- Ordenação padrão por ID_PED
  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_sorts
    RECEIVING
      value = lo_sorts.
  TRY.
      CALL METHOD lo_sorts->add_sort
        EXPORTING
          columnname = 'ID_PED'
          sequence   = if_salv_c_sort=>sort_up.
    CATCH cx_salv_not_found.
    CATCH cx_salv_existing.
    CATCH cx_salv_data_error.
  ENDTRY.

  "--- Evento de double click (abre itens do pedido)
  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_event
    RECEIVING
      value = lo_events.

  DATA: lo_object TYPE REF TO lcl_events.
  CREATE OBJECT lo_object.
  SET HANDLER lo_object->handler FOR lo_events.

  "--- Configuração de seleção (linha/coluna)
  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_selections
    RECEIVING
      value = lo_selection.
  CALL METHOD lo_selection->set_selection_mode
    EXPORTING
      value = if_salv_c_selection_mode=>row_column.

  "--- Configuração do PF Status
  CALL METHOD lo_alv->if_salv_gui_om_table_info~set_screen_status
    EXPORTING
      report   = sy-repid
      pfstatus = 'STANDARD'.

  CALL METHOD lo_alv->if_salv_gui_om_table_info~get_event
    RECEIVING
      value = lo_events.
  SET HANDLER lo_object->pfstatus FOR lo_events.

  "--- Configurações visuais do ALV
  lo_display = lo_alv->get_display_settings( ).
  lo_display->set_striped_pattern( abap_true ).          " Linhas alternadas
  lo_display->set_list_header( 'Pedidos da Cafeteria' ). " Cabeçalho da lista

  "--- Ajuste automático das colunas
  CALL METHOD lo_columns->set_optimize
    EXPORTING
      value = if_salv_c_bool_sap=>true.

  "--- Configuração da coluna ID_PED
  CALL METHOD lo_column->set_alignment
    EXPORTING
      value = if_salv_c_alignment=>centered.
  TRY.
      CALL METHOD lo_column->set_currency_column
        EXPORTING
          value = 'MOEDA'.
    CATCH cx_salv_not_found.
    CATCH cx_salv_data_error.
  ENDTRY.
  CALL METHOD lo_column->set_tooltip
    EXPORTING
      value = 'Identificador único do pedido'.

  "--- Configuração de layout (salvamento de variantes)
  DATA lo_layout TYPE REF TO cl_salv_layout.
  lo_layout = lo_alv->get_layout( ).
  lo_layout->set_key( VALUE salv_s_layout_key( report = sy-repid ) ).
  lo_layout->set_save_restriction( if_salv_c_layout=>restrict_none ).

    SORT lt_ped BY id_ped.

  "--- Exibir ALV de pedidos
  CALL METHOD lo_alv->if_salv_gui_om_table_action~display.

ENDFORM.  " f_show_alv


*----------------------------------------------------------------------*
*       FORM f_show_alv_it
*----------------------------------------------------------------------*
*       Criar e configurar o alv de itens do pedido
*----------------------------------------------------------------------*
FORM f_show_alv_it.
  "--- Criação do objeto ALV para itens
  TRY.
      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = lo_alv_it
        CHANGING
          t_table      = lt_item. " Passa a tabela de itens
    CATCH cx_salv_msg.
      MESSAGE 'Erro ao criar ALV de itens' TYPE 'E'.
  ENDTRY.

  "--- Ativar todas as funções padrão do ALV (filtros, exportar, etc.)
  CALL METHOD lo_alv_it->if_salv_gui_om_table_info~get_functions
    RECEIVING
      value = lo_functions_it.
  CALL METHOD lo_functions_it->set_all
    EXPORTING
      value = if_salv_c_bool_sap=>true.

  "--- Configuração de seleção (linha/coluna)
  CALL METHOD lo_alv_it->if_salv_gui_om_table_info~get_selections
    RECEIVING
      value = lo_selection_it.
  CALL METHOD lo_selection_it->set_selection_mode
    EXPORTING
      value = if_salv_c_selection_mode=>row_column.

  lo_display_it = lo_alv_it->get_display_settings( ).
  lo_display_it->set_striped_pattern( abap_true ).

  lo_display_it->set_list_header( 'Itens do pedido' ).

  "--- Exibir ALV de itens
  CALL METHOD lo_alv_it->if_salv_gui_om_table_action~display.
ENDFORM.  "f_show_alv_it


*----------------------------------------------------------------------*
*       FORM f_buscar_itens
*----------------------------------------------------------------------*
*       Buscar dados da ZTB_PEDIT para os itens do pedido
*----------------------------------------------------------------------*
FORM f_buscar_itens.
  SELECT a~id_ped,
         a~id_prod,
         b~nome_prod,
         b~preco,
         a~qtde,
         a~valor_item
  FROM ztb_pedit AS a
  INNER JOIN ztb_prod AS b
   ON a~id_prod = b~id_prod
  INTO CORRESPONDING FIELDS OF TABLE @lt_item
  WHERE id_ped = @lwa_ped-id_ped.
ENDFORM.  "f_buscar_itens


*----------------------------------------------------------------------*
*       FORM f_set_col_text
*----------------------------------------------------------------------*
*       Configuração do texto das colunas
*----------------------------------------------------------------------*
FORM f_set_col_text
  USING
    iv_col   TYPE lvc_fname   " Nome da coluna
    iv_long  TYPE scrtext_l   " Texto longo
    iv_short TYPE scrtext_s.  " Texto curto

  DATA lo_col TYPE REF TO cl_salv_column. " Referência para coluna do ALV

  TRY.
      "--- Obter coluna pelo nome informado
      lo_col = lo_columns->get_column( columnname = iv_col ).

      "--- Definir texto longo, se informado
      IF iv_long IS NOT INITIAL.
        lo_col->set_long_text( value = iv_long ).
      ENDIF.

      "--- Definir texto curto, se informado
      IF iv_short IS NOT INITIAL.
        lo_col->set_short_text( value = iv_short ).
      ENDIF.

    CATCH cx_salv_not_found.
      " Caso a coluna não exista, exceção é ignorada
  ENDTRY.

ENDFORM.  " f_set_col_text



FORM preparar_faturamento .

  DATA lv_id_fat TYPE zdeidfat.
  DATA ls_fat_cab TYPE ztb_fatura.
  DATA ls_fat_it TYPE ztb_fatura_itens.
  DATA: lv_parcelas  TYPE i,
        lv_intervalo TYPE i.

  DATA: lt_pag_it TYPE STANDARD TABLE OF ztb_pagamento_it,
        ls_pag_it TYPE ztb_pagamento_it.

  SELECT *
    FROM ztb_pagamento_it
    INTO TABLE @lt_pag_it
   WHERE id = @lwa_ped-pm
   ORDER BY seq_pagamento.

  IF sy-subrc <> 0.
    MESSAGE 'Forma de pagamento sem parcelas cadastradas' TYPE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'Z_FAT'
    IMPORTING
      number                  = lv_id_fat
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    MESSAGE 'Erro ao gerar número da fatura' TYPE 'E'.
    RETURN.
  ENDIF.

  ls_fat_cab-mandt = sy-mandt.
  ls_fat_cab-id_fat = lv_id_fat.
  ls_fat_cab-id_ped = lwa_ped-id_ped.
  ls_fat_cab-data_fat = sy-datum.
  ls_fat_cab-hora_fat = sy-uzeit.
  ls_fat_cab-valor_total = lwa_ped-valor_total.
  ls_fat_cab-moeda = lwa_ped-moeda.
  ls_fat_cab-id_pagamento = lwa_ped-pm.
  ls_fat_cab-status = 'A'.
  ls_fat_cab-usuario = sy-uname.

  INSERT ztb_fatura FROM ls_fat_cab.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'Erro ao gravar fatura (cabeçalho)' TYPE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_pag_it INTO ls_pag_it.

    CLEAR ls_fat_it.

    ls_fat_it-mandt     = sy-mandt.
    ls_fat_it-id_fat    = lv_id_fat.
    ls_fat_it-seq_fat   = ls_pag_it-seq_pagamento.

    ls_fat_it-valor = lwa_ped-valor_total * ls_pag_it-porc_pag / 100.

    ls_fat_it-data_venc = sy-datum + ls_pag_it-dias.
    ls_fat_it-status    = 'A'.
    ls_fat_it-moeda = lwa_ped-moeda.

    INSERT ztb_fatura_itens FROM ls_fat_it.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE 'Erro ao criar parcelas da fatura' TYPE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

  UPDATE ztb_ped
    SET status_ped = 3
    WHERE id_ped = lwa_ped-id_ped.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE 'Erro ao atualizar pedido' TYPE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK.
  MESSAGE |Pedido { lwa_ped-id_ped } faturado com sucesso| TYPE 'S'.

  PERFORM f_buscar_dados.
  PERFORM f_show_alv.

ENDFORM.
