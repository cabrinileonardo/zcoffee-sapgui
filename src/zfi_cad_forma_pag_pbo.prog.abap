*&---------------------------------------------------------------------*
*& Include          ZFI_CAD_FORMA_PAG_PBO
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.

  IF gd_mode = 'C'.
    SET TITLEBAR 'NEW'.

    LOOP AT SCREEN.
      IF screen-name = 'GS_FORMA_PAG-ATIVO'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

    ELSEIF gd_mode = 'E'.
      SET TITLEBAR 'EDIT'.
    ENDIF.
ENDMODULE.
