FUNCTION zf_atualiza_estoque_.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_ID_PROD) TYPE  ZID_PROD
*"     REFERENCE(IV_QTDE_VENDIDA) TYPE  ZQTDE
*"  EXPORTING
*"     REFERENCE(EV_SUCESSO) TYPE  CHAR1
*"  EXCEPTIONS
*"      ESTOQUE_INSUFICIENTE
*"      PRODUTO_NAO_ENCONTRADO
*"----------------------------------------------------------------------

  DATA: ld_estoque_atual TYPE ztb_prod-qtde_estoque,
        ld_novo_estoque  TYPE ztb_prod-qtde_estoque.

  SELECT SINGLE qtde_estoque
    FROM ztb_prod
    INTO ld_estoque_atual
    WHERE id_prod = iv_id_prod.

  IF sy-subrc <> 0.
    RAISE produto_nao_encontrado.
  ENDIF.

  IF ld_estoque_atual < iv_qtde_vendida.
    RAISE estoque_insuficiente.
  ENDIF.

  ld_novo_estoque = ld_estoque_atual - iv_qtde_vendida.

  UPDATE ztb_prod SET qtde_estoque = ld_novo_estoque
    WHERE id_prod = iv_id_prod.

  IF sy-subrc = 0.
    ev_sucesso = 'X'.
  ENDIF.

ENDFUNCTION.
