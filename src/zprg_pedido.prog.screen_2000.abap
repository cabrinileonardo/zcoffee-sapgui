PROCESS BEFORE OUTPUT.
*&SPWIZARD: PBO FLOW LOGIC FOR TABLECONTROL 'TC_PEDIDO_ITENS'
  MODULE tc_pedido_itens_change_tc_attr.
*&SPWIZARD: MODULE TC_PEDIDO_ITENS_CHANGE_COL_ATTR.
  LOOP AT   gt_pedit
       INTO gs_est_pedit
       WITH CONTROL tc_pedido_itens
       CURSOR tc_pedido_itens-current_line.
    MODULE tc_pedido_itens_get_lines.
*&SPWIZARD:   MODULE TC_PEDIDO_ITENS_CHANGE_FIELD_ATTR
    MODULE tc_pedido_itens_set_fields.
  ENDLOOP.

  MODULE pbo_2000.

PROCESS AFTER INPUT.
*&SPWIZARD: PAI FLOW LOGIC FOR TABLECONTROL 'TC_PEDIDO_ITENS'
  LOOP AT gt_pedit.

    CHAIN.
      FIELD GS_EST_PEDIT-ID_PROD.
      FIELD GS_EST_PEDIT-QTDE.
      MODULE id_and_name_fill_tc ON CHAIN-REQUEST.
    ENDCHAIN.

    CHAIN.
      FIELD gs_est_pedit-id_prod.
      FIELD gs_est_pedit-nome_prod.
      FIELD gs_est_pedit-preco_unit.
      FIELD gs_est_pedit-qtde.
      FIELD gs_est_pedit-valor_item.
      MODULE tc_pedido_itens_modify ON CHAIN-REQUEST.
    ENDCHAIN.
    FIELD gs_est_pedit-marca
      MODULE tc_pedido_itens_mark ON REQUEST.
  ENDLOOP.
  MODULE tc_pedido_itens_user_command.
*&SPWIZARD: MODULE TC_PEDIDO_ITENS_CHANGE_TC_ATTR.
*&SPWIZARD: MODULE TC_PEDIDO_ITENS_CHANGE_COL_ATTR.

  MODULE id_and_name_fill_ped.
  MODULE pai_2000.
