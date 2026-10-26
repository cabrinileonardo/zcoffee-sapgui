FUNCTION zf_calcula_total.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_ID_PEDIDO) TYPE  NUMC10
*"  EXPORTING
*"     REFERENCE(EV_RESULTADO) TYPE  DECFLOAT34
*"  EXCEPTIONS
*"      SEM_ITENS
*"----------------------------------------------------------------------

  DATA: lt_pedit TYPE TABLE OF ztb_pedit,
        ls_pedit TYPE ztb_pedit.

  " Inicializa o valor total
  CLEAR ev_resultado.

  " Busca itens do pedido
  SELECT *
    FROM ztb_pedit
    INTO TABLE @lt_pedit
    WHERE id_ped = @iv_id_pedido.

  " Se não encontrar nada → exceção
  IF sy-subrc <> 0.
    RAISE sem_itens.
  ENDIF.

  " Soma total dos itens
  LOOP AT lt_pedit INTO ls_pedit.
    ev_resultado = ev_resultado + ls_pedit-valor_item.
  ENDLOOP.

ENDFUNCTION.
