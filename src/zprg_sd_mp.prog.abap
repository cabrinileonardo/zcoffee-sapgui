REPORT zprg_sd_mp.

INCLUDE <icon>.

INCLUDE zprg_sd_mp_top.
INCLUDE zprg_sd_mp_o01.
INCLUDE zprg_sd_mp_i01.

************************************************************************
* Classe local lcl_events - implementation
************************************************************************
CLASS lcl_events IMPLEMENTATION.
  METHOD handler.
    " Lê o pedido selecionado no ALV
    READ TABLE lt_ped INTO lwa_ped INDEX row.

    IF sy-subrc = 0.
      " Busca os itens do pedido selecionado
      PERFORM f_buscar_itens.

      " Exibe ALV de itens
      PERFORM f_show_alv_it.
    ENDIF.
  ENDMETHOD.

  METHOD pfstatus.

    CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
      IMPORTING
        e_grid = lo_grid.

    CALL METHOD lo_grid->get_selected_rows
      IMPORTING
        et_index_rows = lt_rows.

    READ TABLE lt_rows INTO lwa_rows INDEX 1.

    IF lt_rows IS INITIAL OR lines( lt_rows ) <> 1.
      MESSAGE 'Selecione exatamente um pedido na lista' TYPE 'I'.
      RETURN.
    ENDIF.

    IF sy-subrc = 0.
      READ TABLE lt_ped INTO lwa_ped INDEX lwa_rows-index.

      lv_id_ped = lwa_ped-id_ped.

      " Seta o parâmetro global
      SET PARAMETER ID 'ZPED_M' FIELD lv_id_ped.

      CASE e_salv_function.
        WHEN 'VIEW'.
          PERFORM f_buscar_itens.
          PERFORM f_show_alv_it.

        WHEN 'EDIT'.

          DATA lv_answer TYPE c.

          CASE lwa_ped-status_ped.

            WHEN '1'. " Aberto → pode editar
              LEAVE TO TRANSACTION 'ZSDPED_ALT' AND SKIP FIRST SCREEN.
              PERFORM f_refresh_alv.

            WHEN '3' OR '9'. " Finalizado ou Cancelado → bloqueia edição

              CALL FUNCTION 'POPUP_TO_CONFIRM'
                EXPORTING
                  titlebar       = 'Edição não permitida'
                  text_question  = 'Pedidos finalizados ou cancelados não podem ser editados. Deseja visualizar o pedido?'
                  text_button_1  = 'Visualizar'
                  text_button_2  = 'Cancelar'
                  default_button = '2'
                IMPORTING
                  answer         = lv_answer.

              IF lv_answer = '1'.
                " Abre transação em modo visualização
                LEAVE TO TRANSACTION 'ZSDPED_ALT' AND SKIP FIRST SCREEN.
              ENDIF.

            WHEN OTHERS.
              MESSAGE 'Status do pedido inválido' TYPE 'E'.

          ENDCASE.

        WHEN 'FAT'.
          IF lwa_ped-status_ped <> 1.
            MESSAGE 'Somente pedidos abertos podem ser faturados' TYPE 'E'.
            RETURN.
          ENDIF.

          IF lwa_ped-valor_total <= 0.
            MESSAGE 'Pedido sem valor não pode ser faturado' TYPE 'E'.
            RETURN.
          ENDIF.

          PERFORM preparar_faturamento.

        WHEN 'ZSTAT'.
          " Guarda pedido selecionado
          lv_id_ped = lwa_ped-id_ped.

          IF lwa_ped-status_ped = 3.
            MESSAGE |O pedido { lwa_ped-id_ped } já foi finalizado! | TYPE 'E'.
            RETURN.
          ELSEIF lwa_ped-status_ped = 9.
            MESSAGE |O pedido { lwa_ped-id_ped } já foi cancelado! | TYPE 'E'.
            RETURN.
          ELSE.
            UPDATE ztb_ped
             SET status_ped = 9
             WHERE id_ped = lwa_ped-id_ped.

            IF sy-subrc = 0.
              COMMIT WORK.
              PERFORM f_buscar_dados.
              PERFORM f_show_alv.
            ENDIF.

          ENDIF.

        WHEN 'RCPT'.

          CASE lwa_ped-status_ped.
            WHEN 1.
              MESSAGE 'Pedido ainda não faturado' TYPE 'I'.
              RETURN.
            WHEN 9.
              MESSAGE 'Pedido cancelado não pode ser faturado' TYPE 'I'.
              RETURN.
          ENDCASE.

          EXPORT gv_id_ped = lwa_ped-id_ped TO MEMORY ID 'Z_ID_PED_R'.
          CALL TRANSACTION 'ZPED_RCPT' AND SKIP FIRST SCREEN.
      ENDCASE.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

************************************************************************
* Tela de seleção - parâmetros e filtros para busca de pedidos
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS:
    so_idped  FOR lwa_ped-id_ped,     " Filtro por código do pedido
    so_idcli  FOR lwa_ped-id_cliente, " Filtro por cliente
    so_idfun  FOR lwa_ped-id_func.    " Filtro por funcionário
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
  SELECT-OPTIONS:
    so_data FOR lwa_ped-data_ped,     " Filtro por data
    so_hora FOR lwa_ped-hora_ped.     " Filtro por hora
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.
  SELECT-OPTIONS:
    so_val FOR lwa_ped-valor_total.   " Filtro por valor total
  PARAMETERS:
  p_fm TYPE ztb_ped-pm.             " Forma de pagamento
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-b04.
  PARAMETERS:
    p_stat TYPE ztb_ped-status_ped,   " Status do pedido
    p_all  AS CHECKBOX DEFAULT abap_true. " Considerar todos os status
SELECTION-SCREEN END OF BLOCK b4.

*---------------------------------------------------------------------*
* Validação da Tela de Seleção
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF p_all = abap_false AND p_stat IS INITIAL.
    MESSAGE 'Informe um status ou marque "Todos"' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

*---------------------------------------------------------------------*
* Ajuste dinâmico da Tela - desabilita campo status se "Todos" estiver marcado
*---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_STAT'.
      screen-input = COND #( WHEN p_all = abap_true THEN 0 ELSE 1 ).
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

************************************************************************
* Fluxo principal
************************************************************************
START-OF-SELECTION.

  SET PF-STATUS 'STANDARD'.

  PERFORM f_buscar_dados. " Busca pedidos conforme filtros
  PERFORM f_show_alv.     " Exibe ALV com pedidos

  INCLUDE zprg_sd_mp_f01.
*  INCLUDE zfi_alv_coffee_f01.
*  INCLUDE zrep_sd_alv_coffee_F01.
