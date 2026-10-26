FUNCTION zf_calcula_total_ .
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_PRECO) TYPE  ZPRECO
*"     REFERENCE(IV_QTDE) TYPE  ZQTDE
*"  EXPORTING
*"     REFERENCE(EV_VALOR_ITEM) TYPE  ZVALOR_ITEM
*"  EXCEPTIONS
*"      QTDE_NEGATIVA
*"----------------------------------------------------------------------
  IF iv_preco < 0 OR iv_qtde < 0.
    RAISE qtde_negativa.
  ELSE.
    ev_valor_item = iv_preco * iv_qtde.
  ENDIF.
ENDFUNCTION.
