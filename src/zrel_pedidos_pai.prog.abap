*&---------------------------------------------------------------------*
*&      Module  PAI_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'SAVE'.
      MODIFY ztb_ped FROM wa_ped.
      IF sy-subrc = 0.
        COMMIT WORK.
        MESSAGE 'Pedido alterado com sucesso' TYPE 'S'.
        LEAVE TO SCREEN 0.
      ELSE.
        ROLLBACK WORK.
        MESSAGE 'falha em alterar pedido' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.
    ENDCASE.
ENDMODULE.
