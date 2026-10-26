MODULE pbo_9001 OUTPUT.
  CLEAR gd_okcode.
  SET PF-STATUS 'S9001'.
  SET TITLEBAR 'EDIT'.
ENDMODULE.

MODULE pai_9001 INPUT.
  CASE gd_okcode.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0100.
    WHEN 'SAVE'.
    WHEN 'EXEC' OR ''.
      PERFORM modificar_funcionario.
  ENDCASE.
ENDMODULE.

MODULE pbo_0901 OUTPUT.
  CLEAR gd_okcode.
  IF sy-dynnr = '9000'.
    SET TITLEBAR 'NEW'.
  ENDIF.
  IF sy-dynnr = '0901'.
    SET TITLEBAR 'EDIT'.
  ENDIF.
  SET PF-STATUS 'S9000'.
ENDMODULE.

MODULE pai_0901 INPUT.
  CASE gd_okcode.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      IF sy-dynnr = '9000'.
        PERFORM inserir.
      ENDIF.
      IF sy-dynnr = '0901'.
        PERFORM modificar.

      ENDIF.

  ENDCASE.
ENDMODULE.
