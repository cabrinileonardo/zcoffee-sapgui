FUNCTION zf_atualiza_estoque.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_ID_PED) TYPE  ZTB_PED-ID_PED
*"  EXPORTING
*"     REFERENCE(EV_MSG) TYPE  CHAR100
*"  EXCEPTIONS
*"      ESTOQUE_INSUFICIENTE
*"      PRODUTO_NAO_ENCONTRADO
*"----------------------------------------------------------------------

  DATA: lt_pedit TYPE TABLE OF ztb_pedit,
        ls_pedit TYPE ztb_pedit,
        lt_prod  TYPE TABLE OF ztb_prod,
        ls_prod  TYPE ztb_prod.

  "---------------------------------------------------------
  " 1. Buscar itens do pedido
  "---------------------------------------------------------
  SELECT *
    FROM ztb_pedit
    INTO TABLE @lt_pedit
    WHERE id_ped = @iv_id_ped.

  IF sy-subrc <> 0.
    ev_msg = 'Nenhum item encontrado para este pedido.'.
    RAISE produto_nao_encontrado.
  ENDIF.

  "---------------------------------------------------------
  " 2. Buscar todos os produtos envolvidos no pedido (de uma vez)
  "---------------------------------------------------------
  SELECT *
    FROM ztb_prod
    INTO TABLE @lt_prod
    FOR ALL ENTRIES IN @lt_pedit
    WHERE id_prod = @lt_pedit-id_prod.

  IF sy-subrc <> 0.
    RAISE produto_nao_encontrado.
  ENDIF.

  "---------------------------------------------------------
  " 3. Validação de estoque antes de atualizar
  "   - Não atualiza nada até garantir que TUDO tem estoque
  "---------------------------------------------------------
  LOOP AT lt_pedit INTO ls_pedit.

    READ TABLE lt_prod INTO ls_prod
      WITH KEY id_prod = ls_pedit-id_prod.

    IF sy-subrc <> 0.
      RAISE produto_nao_encontrado.
    ENDIF.

    IF ls_prod-qtde_estoque < ls_pedit-qtde.
      RAISE estoque_insuficiente.
    ENDIF.

  ENDLOOP.

  "---------------------------------------------------------
  " 4. Atualizar estoque (Agora sim é seguro atualizar)
  "---------------------------------------------------------
  LOOP AT lt_pedit INTO ls_pedit.

    READ TABLE lt_prod INTO ls_prod
      WITH KEY id_prod = ls_pedit-id_prod.

    ls_prod-qtde_estoque = ls_prod-qtde_estoque - ls_pedit-qtde.

    UPDATE ztb_prod SET qtde_estoque = @ls_prod-qtde_estoque
      WHERE id_prod = @ls_prod-id_prod.

  ENDLOOP.

  ev_msg = 'Estoque atualizado com sucesso.'.

ENDFUNCTION.
