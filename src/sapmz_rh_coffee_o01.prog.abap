*&---------------------------------------------------------------------*
*& Include          SAPMZ_RH_COFFEE_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS0100'.
  SET TITLEBAR 'PED'.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SELECT_DATA OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE select_data OUTPUT.
  SELECT *
    FROM VBAK
    INTO CORRESPONDING FIELDS OF TABLE @it_VBAK
    UP TO 50 ROWS.

  SELECT *
    FROM sbook
    INTO TABLE @it_sbook
    UP TO 50 ROWS.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CREATE_GRID1 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_grid1 OUTPUT.
  IF go_container1 IS NOT BOUND.
    CREATE OBJECT go_container1
      EXPORTING
        container_name              = 'CC_ALV1'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.

  ENDIF.

  CHECK go_container1 IS BOUND.

  CREATE OBJECT go_grid1
    EXPORTING
      i_parent          = go_container1
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  CHECK go_grid1 IS BOUND.

  CALL METHOD go_grid1->set_table_for_first_display
    EXPORTING
      i_structure_name              = 'VBAK'
    CHANGING
      it_outtab                     = it_vbak
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

ENDMODULE.
