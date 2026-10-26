class ZCL_POPUP definition
  public
  create public .

public section.

  methods CONFIRMAR
    importing
      !IV_TEXT type STRING
    returning
      value(RV_CONFIRMADO) type ABAP_BOOL .
protected section.
private section.
ENDCLASS.



CLASS ZCL_POPUP IMPLEMENTATION.


METHOD confirmar.

  DATA lv_answer TYPE c.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar      = 'Confirmação'
      text_question = iv_text
      text_button_1 = 'Sim'
      text_button_2 = 'Não'
      default_button = '1'
      display_cancel_button = abap_false
    IMPORTING
      answer        = lv_answer
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.

  IF sy-subrc <> 0.
    rv_confirmado = abap_false.
    RETURN.
  ENDIF.

  IF lv_answer = '1'.
    rv_confirmado = abap_true.
  ELSE.
    rv_confirmado = abap_false.
  ENDIF.

ENDMETHOD.
ENDCLASS.
