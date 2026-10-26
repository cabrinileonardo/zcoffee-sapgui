*&---------------------------------------------------------------------*
*& Include          ZFI_CAD_FORMA_PAG_PAI
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE gd_okcode.
    WHEN 'BACK' OR 'CANC' OR 'EXIT'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      IF gd_mode = 'C'.
*        PERFORM salvar_forma_pag.
        CLEAR gd_mode.
      ELSEIF gd_mode = 'E'.
*        PERFORM modificar_forma_pag.
      ENDIF.
  ENDCASE.

ENDMODULE.
