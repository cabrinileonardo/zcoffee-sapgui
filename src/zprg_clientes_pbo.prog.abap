MODULE pbo_9000 OUTPUT.
  SET PF-STATUS 'S9000'.
  SET TITLEBAR 'NEW'.

  IF gv_id_cli_temp IS INITIAL.
    SELECT MAX( id_cliente ) FROM ztb_clientes INTO @DATA(lv_max_id).
    gv_id_cli_temp = lv_max_id + 1.
  ENDIF.

    " Exibe o ID temporário no campo mapeado para gs_pedido_header-id_ped
  ls_cliente-id_cliente = gv_id_cli_temp.

  ls_cliente-status_cli = '1'.
ENDMODULE.

MODULE pbo_9001 OUTPUT.
 SET PF-STATUS 'S9001'.
 SET TITLEBAR 'EDIT'.
ENDMODULE.
