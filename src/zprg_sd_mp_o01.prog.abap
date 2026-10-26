*&---------------------------------------------------------------------*
*& Include          ZREP_SD_ALV_COFFEE_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*& Modulo PBO da tela 0300
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.

  SET PF-STATUS 'POPUP'.

  IF gv_new_status IS INITIAL.
    SELECT SINGLE status_ped
      INTO gv_new_status
      FROM ztb_ped
      WHERE id_ped = lv_id_ped.
  ENDIF.

ENDMODULE.
