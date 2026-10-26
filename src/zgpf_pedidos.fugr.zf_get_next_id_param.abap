FUNCTION zf_get_next_id_param.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_OBJETO) TYPE  CHAR20
*"  EXPORTING
*"     REFERENCE(EV_NEXT_ID) TYPE  NUMC10
*"  EXCEPTIONS
*"      NOT_FOUND_OTHERS
*"----------------------------------------------------------------------

  DATA ls_param TYPE ztb_param.

  SELECT SINGLE prox_id
    INTO ev_next_id
    FROM ztb_param
    WHERE objeto = iv_objeto.

  IF sy-subrc <> 0.
    ev_next_id = '0000000001'.
    ls_param-objeto = iv_objeto.
    ls_param-prox_id = ev_next_id + 1.
    INSERT ztb_param FROM ls_param.
  ELSE.
    DATA(lv_next) = ev_next_id.
    lv_next = lv_next + 1.
    UPDATE ztb_param SET prox_id = lv_next WHERE objeto = iv_objeto.
    IF sy-subrc <> 0.
      RAISE NOT_FOUND_OTHERS.
    ENDIF.
  ENDIF.

ENDFUNCTION.
