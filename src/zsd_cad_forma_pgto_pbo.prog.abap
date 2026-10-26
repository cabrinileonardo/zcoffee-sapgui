MODULE status_0100 OUTPUT.
  DATA: lv_number       TYPE i,
        lv_number_itens TYPE i.

  SET PF-STATUS 'MAIN'.

  CASE sy-tcode.
    WHEN 'ZFINEWPAG'.
      SET TITLEBAR 'NEW'.

      PERFORM f_preview_id CHANGING lv_number lv_number_itens.
      gs_pgto-id = lv_number.

      gs_pgto-status = 1.

      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'GS_PGTO-ID' OR 'GS_PGTO-STATUS'.
            screen-input = 0.
            MODIFY SCREEN.
          WHEN 'GS_PGTO-PARCELA'.
            IF gv_destravar_p = abap_true.
              screen-input = 1.
            ELSE.
              screen-input = 0.
            ENDIF.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

      IF gv_first = abap_false.
        PERFORM f_criar_alv.
      ELSE.
        CALL METHOD go_alv->refresh_table_display.
      ENDIF.

      gs_itens-id = lv_number_itens.

      LOOP AT SCREEN.
        IF screen-name = 'GS_ITENS-SEQ_PAGAMENTO'
        OR screen-name = 'GS_ITENS-DIAS'
        OR screen-name = 'GS_ITENS-PORC_PAG'.

          IF gv_trava_itens = abap_true.
            screen-input = 0.
          ELSE.
            screen-input = 1.
          ENDIF.

          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.

    WHEN 'ZFIEDITPAG'.
      SET TITLEBAR 'MOD'.
      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'GS_PGTO-ID'.
            screen-input = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

      IF gv_first = abap_false.
        PERFORM f_criar_alv.
      ELSE.
        CALL METHOD go_alv->refresh_table_display.
      ENDIF.

      IF gv_edit = abap_false.
        IMPORT gv_id_pgto FROM MEMORY ID 'ZPGTO_ID'.
        IF gv_id_pgto IS INITIAL.
          MESSAGE 'Nenhum pagamento selecionado' TYPE 'E'.
        ENDIF.
        PERFORM f_carregar_dados.
      ENDIF.


    WHEN 'ZFIDELPAG'.
      SET TITLEBAR 'DEL'.
  ENDCASE.


ENDMODULE.
