*&---------------------------------------------------------------------*
*& Include          ZREP_SD_ALV_COFFEE_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
* Módulo PAI da tela 0300
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.

  CASE gv_okcode.
    WHEN 'SAVE'.

      IF gv_new_status IS INITIAL.
        MESSAGE 'Campo obrigatório' TYPE 'I'.
        RETURN.
      ENDIF.

      PERFORM alterar_status.
      LEAVE TO SCREEN 0.

    WHEN 'CANC'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
