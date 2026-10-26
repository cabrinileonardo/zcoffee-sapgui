MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN gc_back.
      LEAVE TO SCREEN 0.
    WHEN gc_exit.
      LEAVE PROGRAM.
    WHEN gc_save.
      IF sy-tcode = 'ZFINEWPAG'.
        PERFORM f_salvar_new.
      ENDIF.
      IF sy-tcode = 'ZFIEDITPAG'.
        PERFORM f_modificar_pgto.
      ENDIF.
    WHEN 'BTN_FILL'.
      PERFORM f_preencher_itens_auto.
      CLEAR sy-ucomm.
    WHEN 'DEL'.
      PERFORM f_excluir_itens_alv.
      CLEAR sy-ucomm.

  ENDCASE.
ENDMODULE.


MODULE preencher_parcelas INPUT.
  IF gs_pgto-tipo_pag IS INITIAL.
    MESSAGE 'Preencha o tipo do pagamento para verificar as parcelas' TYPE 'I'.
    SET CURSOR FIELD 'GS_PGTO-TIPO_PAG'.
    RETURN.
  ENDIF.

  CASE gs_pgto-tipo_pag.
    WHEN 'D'.
      gs_pgto-parcela = 1.
      gv_destravar_p = abap_false.
    WHEN 'P'.
      gs_pgto-parcela = 1.
      gv_destravar_p = abap_false.
    WHEN 'B'.
      gs_pgto-parcela = 1.
      gv_destravar_p = abap_false.
    WHEN 'C'.
      gv_destravar_p = abap_true.
  ENDCASE.

  PERFORM f_refresh_alv.


ENDMODULE.
