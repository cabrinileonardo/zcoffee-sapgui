MODULE pbo_9000 OUTPUT.
  CLEAR gd_okcode.
  IF sy-dynnr = '9000'.
    SET TITLEBAR 'NEW'.
  ENDIF.
  IF sy-dynnr = '9001' .
    SET TITLEBAR 'EDIT'.
  ENDIF.
  IF sy-dynnr = '0901'.

  ENDIF.

  SET PF-STATUS 'S9000'.

*SELECT * FROM ztb_func INTO TABLE lt_func.
*
*  IF lt_func IS INITIAL.  "Só gera se estiver em branco
*    PERFORM gerar_id.
*  ELSE.
*    CALL FUNCTION 'NUMBER_GET_INFO'
*      EXPORTING
*       NR_RANGE_NR              = '01'
*        object                   = 'ZID_FUNC01'
*       SUBOBJECT                = ' '
*       TOYEAR                   = '0000'
*     IMPORTING
*       INTERVAL                 = lv_intervalo
*       NRIV                     =
*     EXCEPTIONS
*       INTERVAL_NOT_FOUND       = 1
*       OBJECT_NOT_FOUND         = 2
*       OTHERS                   = 3
*              .
*    IF sy-subrc <> 0.
* Implement suitable error handling here
*    ENDIF.
*
*  ENDIF.
*
*  Travando o campo para não editar
*  LOOP AT SCREEN.
*    IF screen-name = 'ZTB_FUNC-ID_FUNC'.
*      screen-input = '0'.   "Só leitura
*      screen-output = '1'.  "Continua visível
*      MODIFY SCREEN.
*    ENDIF.
*  ENDLOOP.
*
*lv_intervalo = lv_intervalo + 1.

ENDMODULE.

MODULE pai_9000 INPUT.
  CASE gd_okcode.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      IF sy-dynnr = '9000'.
        PERFORM inserir.
      ENDIF.
      IF sy-dynnr = '0900'.
        PERFORM modificar.
      ENDIF.

  ENDCASE.
ENDMODULE.
