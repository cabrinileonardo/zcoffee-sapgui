FORM f_salvar_new.

  DATA: lv_salvou    TYPE abap_bool VALUE abap_false,
        lv_salvou_it TYPE abap_bool VALUE abap_false,
        lv_total     TYPE p DECIMALS 2.

  "-------------------------------------------------------------*
  " 1. Validações de cabeçalho
  "-------------------------------------------------------------*
  IF gs_pgto-descricao IS INITIAL.
    MESSAGE 'Informe a descrição da condição!' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_pgto-parcela < 0.
    MESSAGE 'Informe a quantidade de parcelas!' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 2. Validação quantidade de itens
  "-------------------------------------------------------------*
  IF NOT gs_pgto-tipo_pag = 'P'.
    IF lines( gt_itens ) <> gs_pgto-parcela.
      MESSAGE 'Quantidade de parcelas não confere com os itens informados'
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF gs_pgto-tipo_pag = 'D' AND gs_pgto-parcela > 1.
      MESSAGE 'Débito não permite parcelamento' TYPE 'E'.
      EXIT.
    ENDIF.

  ENDIF.

  "-------------------------------------------------------------*
  " 3. Validação soma das porcentagens
  "-------------------------------------------------------------*
  CLEAR lv_total.

  LOOP AT gt_itens INTO gs_itens.
    lv_total = lv_total + gs_itens-porc_pag.
  ENDLOOP.

  " Tolerância para decimal
  IF lv_total - 100 <> 0.
    MESSAGE 'A soma das parcelas deve ser exatamente 100%'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 4. gera o número real
  "-------------------------------------------------------------*
  PERFORM f_incrementar_id.

  "-------------------------------------------------------------*
  " 5. Persistência
  "-------------------------------------------------------------*
  PERFORM f_insert_cab CHANGING lv_salvou.

  IF lv_salvou = abap_true.
    PERFORM f_insert_itens CHANGING lv_salvou_it.
  ENDIF.

  "-------------------------------------------------------------*
  " 6. Commit / Rollback
  "-------------------------------------------------------------*
  IF lv_salvou = abap_true AND lv_salvou_it = abap_true.
    COMMIT WORK.
    MESSAGE 'Pagamento salvo com sucesso!' TYPE 'S'.
    LEAVE TO TRANSACTION 'ZFIMENUPAG'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Erro ao salvar pagamento!' TYPE 'E'.
  ENDIF.

ENDFORM.



FORM f_insert_cab CHANGING cv_salvou TYPE abap_bool.

  INSERT ztb_pagamento FROM gs_pgto.

  IF sy-subrc <> 0.
    cv_salvou = abap_false.
    RETURN.
  ENDIF.

  cv_salvou = abap_true.

ENDFORM.


FORM f_insert_itens CHANGING cv_salvou_it TYPE abap_bool.

  LOOP AT gt_itens INTO gs_itens.
    gs_itens-id = gs_pgto-id.

    INSERT ztb_pagamento_it FROM gs_itens.
    IF sy-subrc <> 0.
      cv_salvou_it = abap_false.
      RETURN.
    ENDIF.
  ENDLOOP.

  cv_salvou_it = abap_true.

ENDFORM.


FORM f_incrementar_id.

  DATA lv_number TYPE i.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = 'CR'
      object                  = 'ZFIFPAG'
    IMPORTING
      number                  = lv_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      interval_overflow       = 4
      OTHERS                  = 5.

  IF sy-subrc <> 0.
    MESSAGE 'Erro ao gerar número do pagamento' TYPE 'E'.
    EXIT.
  ENDIF.

  gs_pgto-id = lv_number.

ENDFORM.


FORM f_criar_alv .

  CLEAR gs_layout.
  gs_layout-zebra = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-sel_mode = 'A'.


  IF go_cont IS NOT BOUND.
    CREATE OBJECT go_cont
      EXPORTING
        container_name = 'CC_ALV_ITENS'.

    CHECK sy-subrc = 0.

    IF go_alv IS NOT BOUND.
      CREATE OBJECT go_alv
        EXPORTING
          i_parent = go_cont.
    ENDIF.

    CHECK sy-subrc = 0.
  ENDIF.

  go_alv->set_table_for_first_display(
    EXPORTING
      i_structure_name              =  'ZTB_PAGAMENTO_IT'
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_itens
  ).

  gv_first = abap_true.

ENDFORM.


FORM f_preview_id CHANGING cv_number TYPE i
                           cv_number_itens TYPE i.

  DATA ls_nriv TYPE nriv.

  CALL FUNCTION 'NUMBER_GET_INFO'
    EXPORTING
      nr_range_nr        = 'CR'
      object             = 'ZFIFPAG'
    IMPORTING
      interval           = ls_nriv
    EXCEPTIONS
      interval_not_found = 1
      object_not_found   = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Erro ao buscar number range' TYPE 'E'.
    EXIT.
  ENDIF.

  " Próximo número apenas para exibição
  cv_number = ls_nriv-nrlevel + 1.
  cv_number_itens = ls_nriv-nrlevel + 1.

ENDFORM.


FORM f_adicionar_item .

  DATA: ls_item     TYPE ztb_pagamento_it,
        lv_total    TYPE p DECIMALS 2,
        lv_restante TYPE p DECIMALS 2.

  "-------------------------------------------------------------*
  " 1. Validações básicas
  "-------------------------------------------------------------*
  IF gs_itens-porc_pag IS INITIAL OR gs_itens-porc_pag <= 0.
    MESSAGE 'Informe uma porcentagem válida.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_itens-dias IS INITIAL.
    CASE gs_pgto-tipo_pag.
      WHEN 'C'.
        gs_itens-dias = 30 * gs_itens-seq_pagamento.
      WHEN 'D'.
        gs_itens-dias = 1.
      WHEN 'P'.
        gs_itens-dias = 0.
      WHEN 'B'.
        gs_itens-dias = 30 * gs_itens-seq_pagamento.
    ENDCASE.
  ENDIF.


  "-------------------------------------------------------------*
  " 2. Soma percentual já existente
  "-------------------------------------------------------------*
  CLEAR lv_total.

  LOOP AT gt_itens INTO ls_item.
    lv_total = lv_total + ls_item-porc_pag.
  ENDLOOP.

  lv_restante = 100 - lv_total.

  IF lv_restante <= 0.
    MESSAGE 'O total de parcelas já atingiu 100%' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 3. Ajuste automático da última parcela
  "-------------------------------------------------------------*
  IF gs_itens-porc_pag > lv_restante.
    gs_itens-porc_pag = lv_restante.
  ENDIF.

  "-------------------------------------------------------------*
  " 4. Validação de quantidade máxima de parcelas
  "-------------------------------------------------------------*
  IF lines( gt_itens ) >= gs_pgto-parcela.
    MESSAGE 'Quantidade máxima de parcelas atingida' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 5. Sequência automática
  "-------------------------------------------------------------*
  gs_itens-seq_pagamento = lines( gt_itens ) + 1.

  "-------------------------------------------------------------*
  " 6. ADD real
  "-------------------------------------------------------------*
  MOVE-CORRESPONDING gs_itens TO ls_item.
  APPEND ls_item TO gt_itens.

  PERFORM f_refresh_alv.

  CLEAR gs_itens.

  SET CURSOR FIELD 'GS_ITENS-PORC_PAG'.

  MESSAGE 'Item adicionado com sucesso' TYPE 'S'.

  "-------------------------------------------------------------*
  " 7. Trava inclusão se fechou tudo
  "-------------------------------------------------------------*
  IF lines( gt_itens ) >= gs_pgto-parcela
  OR lv_total + ls_item-porc_pag = 100.
    gv_trava_itens = abap_true.
  ENDIF.

ENDFORM.


FORM f_calcular_percentual
  USING    uv_seq       TYPE int1
           uv_parcelas  TYPE int1
  CHANGING cv_percent   TYPE p.

  DATA lv_base TYPE p DECIMALS 2.
  DATA lv_soma TYPE p DECIMALS 2.

  " Percentual base (ex: 33,33)
  lv_base = 100 / uv_parcelas.

  " Força 2 casas decimais sem arredondar
  lv_base = trunc( lv_base * 100 ) / 100.

  IF uv_seq < uv_parcelas.
    cv_percent = lv_base.
  ELSE.
    " Última parcela fecha 100%
    lv_soma = lv_base * ( uv_parcelas - 1 ).
    cv_percent = 100 - lv_soma.
  ENDIF.

ENDFORM.


FORM f_refresh_alv.

  DATA ls_stable TYPE lvc_s_stbl.

  ls_stable-row = abap_true.
  ls_stable-col = abap_true.

  IF go_alv IS BOUND.
    go_alv->refresh_table_display(
      EXPORTING
        is_stable = ls_stable
    ).
  ENDIF.

ENDFORM.


FORM f_calcular_dias
  USING    uv_seq  TYPE int1
  CHANGING cv_dias TYPE i.

  CONSTANTS c_base_dias TYPE i VALUE 30.

  cv_dias = uv_seq * c_base_dias.

ENDFORM.


FORM f_preencher_itens_auto.

  DATA: lv_parcelas TYPE i,
        lv_base     TYPE p DECIMALS 2,
        lv_resto    TYPE p DECIMALS 2,
        ls_item     TYPE ztb_pagamento_it.

  "-------------------------------------------------------------*
  " Validações
  "-------------------------------------------------------------*
  IF gs_pgto-tipo_pag = 'C' OR gs_pgto-tipo_pag = 'B'.
    IF gs_pgto-parcela IS INITIAL OR gs_pgto-parcela <= 0.
      MESSAGE 'Informe a quantidade de parcelas' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ENDIF.

  "-------------------------------------------------------------*
  " Limpa itens atuais
  "-------------------------------------------------------------*
  CLEAR gt_itens.

  "-------------------------------------------------------------*
  " Define parcelas conforme tipo
  "-------------------------------------------------------------*
  CASE gs_pgto-tipo_pag.
    WHEN 'P' OR 'D'.
      lv_parcelas = 1. " PIX e Débito são à vista
    WHEN OTHERS.
      lv_parcelas = gs_pgto-parcela.
  ENDCASE.

  "-------------------------------------------------------------*
  " Cálculo percentual
  "-------------------------------------------------------------*
  lv_base  = 100 / lv_parcelas.
  lv_resto = 100 - ( lv_base * lv_parcelas ).

  "-------------------------------------------------------------*
  " Monta itens
  "-------------------------------------------------------------*
  DO lv_parcelas TIMES.

    CLEAR ls_item.

    ls_item-id             = gs_pgto-id.
    ls_item-seq_pagamento  = sy-index.
    ls_item-porc_pag       = lv_base.

    " Ajuste última parcela
    IF sy-index = lv_parcelas.
      ls_item-porc_pag = ls_item-porc_pag + lv_resto.
    ENDIF.

    " Dias conforme tipo
    CASE gs_pgto-tipo_pag.
      WHEN 'C' OR 'B'.
        ls_item-dias = 30 * sy-index.
      WHEN 'D'.
        ls_item-dias = 0.
      WHEN 'P'.
        ls_item-dias = 0.
    ENDCASE.

    APPEND ls_item TO gt_itens.

  ENDDO.

  "-------------------------------------------------------------*
  " Atualiza ALV
  "-------------------------------------------------------------*
  PERFORM f_refresh_alv.

  gv_trava_itens = abap_true.

  MESSAGE 'Itens preenchidos automaticamente' TYPE 'S'.

ENDFORM.


*FORM f_preencher_itens_auto.
*
*  DATA: lv_parcelas TYPE i,
*        lv_base     TYPE p DECIMALS 2,
*        lv_resto    TYPE p DECIMALS 2,
*        ls_item     TYPE ztb_pagamento_it.
*
*  "-------------------------------------------------------------*
*  " Validações
*  "-------------------------------------------------------------*
*  IF gs_pgto-tipo_pag = 'C' OR gs_pgto-tipo_pag = 'B'.
*    IF gs_pgto-parcela IS INITIAL OR gs_pgto-parcela <= 0.
*      MESSAGE 'Informe a quantidade de parcelas' TYPE 'S' DISPLAY LIKE 'E'.
*      RETURN.
*    ENDIF.
*  ENDIF.
*
*  "-------------------------------------------------------------*
*  " Limpa itens atuais
*  "-------------------------------------------------------------*
*  CLEAR gt_itens.
*
*  lv_parcelas = gs_pgto-parcela.
*
*  " Divide 100% igualmente
*  IF lv_parcelas IS INITIAL.
*
*    " PIX
*    lv_base  = 100.
*    lv_resto = 0.
*
*  ELSE.
*
*    lv_base  = 100 / lv_parcelas.
*    lv_resto = 100 - ( lv_base * lv_parcelas ).
*
*  ENDIF.
*
*
*  DO lv_parcelas TIMES.
*    CLEAR ls_item.
*
*    ls_item-seq_pagamento = sy-index.
*    ls_item-porc_pag      = lv_base.
*
*    " Ajuste da última parcela
*    IF sy-index = lv_parcelas.
*      ls_item-porc_pag = ls_item-porc_pag + lv_resto.
*    ENDIF.
*
*    CASE gs_pgto-tipo_pag.
*      WHEN 'C'. " Crédito
*        ls_item-dias = 30 * sy-index.
*      WHEN 'D'. " Débito
*        ls_item-dias = 1.
*      WHEN 'P'. " PIX
*        ls_item-dias = 0.
*      WHEN 'B'. " Boleto
*        ls_item-dias = 30 * sy-index.
*    ENDCASE.
*
*    ls_item-id = gs_pgto-id.
*
*    APPEND ls_item TO gt_itens.
*  ENDDO.
*
*  "-------------------------------------------------------------*
*  " Atualiza ALV
*  "-------------------------------------------------------------*
*  PERFORM f_refresh_alv.
*
*  "-------------------------------------------------------------*
*  " Trava edição manual (opcional)
*  "-------------------------------------------------------------*
*  gv_trava_itens = abap_true.
*
*  MESSAGE 'Itens preenchidos automaticamente' TYPE 'S'.
*
*ENDFORM.


FORM f_excluir_itens_alv.

  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row,
        lv_idx  TYPE sy-tabix.

  "-------------------------------------------------------------*
  " Buscar linhas selecionadas no ALV
  "-------------------------------------------------------------*
  CALL METHOD go_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE 'Selecione ao menos uma linha para excluir' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " Excluir da tabela interna (de trás pra frente!)
  "-------------------------------------------------------------*
  SORT lt_rows BY index DESCENDING.

  LOOP AT lt_rows INTO ls_row.
    lv_idx = ls_row-index.
    DELETE gt_itens INDEX lv_idx.
  ENDLOOP.

  "-------------------------------------------------------------*
  " Atualiza ALV
  "-------------------------------------------------------------*
  PERFORM f_refresh_alv.

  MESSAGE 'Item(ns) removido(s)' TYPE 'S'.

ENDFORM.


FORM f_carregar_dados .

  SELECT SINGLE id,
                descricao,
                parcela,
                status,
                tipo_pag
    FROM ztb_pagamento
    INTO CORRESPONDING FIELDS OF @gs_pgto
    WHERE id = @gv_id_pgto.

  IF sy-subrc = 0.
    SELECT DISTINCT b~id,
        b~seq_pagamento,
        b~porc_pag,
        b~dias
  FROM ztb_pagamento_it AS b
  INNER JOIN ztb_pagamento AS a
   ON b~id = a~id
  INTO CORRESPONDING FIELDS OF TABLE @gt_itens
   WHERE b~id = @gs_pgto-id.
  ENDIF.

  gv_edit = abap_true.

  PERFORM f_refresh_alv.

ENDFORM.


FORM f_modificar_pgto .
  DATA: ls_pgto  TYPE ztb_pagamento,
        ls_itens TYPE ztb_pagamento_it.

  IF gs_pgto-descricao IS INITIAL.
    MESSAGE 'Preencha a descrição' TYPE sy-ucomm.
    RETURN.
  ENDIF.

  IF gt_itens IS INITIAL.
    MESSAGE 'Adicione ao menos um item' TYPE 'I'.
    RETURN.
  ENDIF.

  MOVE-CORRESPONDING gs_pgto TO ls_pgto.

  MODIFY ztb_pagamento FROM ls_pgto.
  IF sy-subrc <> 0.
    MESSAGE |Erro ao modificar condição { gs_pgto-descricao }| TYPE 'E'.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  LOOP AT gt_itens INTO gs_itens.

    gs_itens-id = gs_pgto-id.

    MOVE-CORRESPONDING gs_itens TO ls_itens.

    MODIFY ztb_pagamento_it FROM ls_itens.
    IF sy-subrc <> 0.
      MESSAGE |Erro ao modificar item do pgto{ gs_pgto-id }| TYPE 'E'.
      ROLLBACK WORK.
      RETURN.
    ENDIF.

    CLEAR ls_itens.
  ENDLOOP.

  COMMIT WORK.
  MESSAGE |Condição { gs_pgto-id } salvo com sucesso!| TYPE 'S'.
  CLEAR: gt_itens, gs_itens, gs_pgto.

  PERFORM f_refresh_alv.

  LEAVE TO TRANSACTION 'ZFIMENUPAG'.
ENDFORM.
