*&---------------------------------------------------------------------*
*& Include SAPMZ_RH_COFFEE_TOP                      - PoolMóds.        SAPMZ_RH_COFFEE
*&---------------------------------------------------------------------*
PROGRAM sapmz_rh_coffee.

*&---------------------------------------------------------------------*
*& Global Object
*&---------------------------------------------------------------------*

DATA: go_container1 TYPE REF TO cl_gui_custom_container,
      go_container2 TYPE REF TO cl_gui_custom_container,
      go_grid1      TYPE REF TO cl_gui_alv_grid,
      go_grid2      TYPE REF TO cl_gui_alv_grid.

*----------------------------------------------------------------------*
*    Global Tables                                                                  *
*----------------------------------------------------------------------*
DATA: it_VBAK TYPE STANDARD TABLE OF VBAK,
      it_sbook   TYPE STANDARD TABLE OF sbook.

DATA: lt_fcat TYPE lvc_t_fcat,
      ls_fcat TYPE lvc_s_fcat.
