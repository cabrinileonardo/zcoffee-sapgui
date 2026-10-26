************************************************************************
* Declarações globais
************************************************************************

*----------------------------------------------------------------------*
* Tabelas do Dictionary
*----------------------------------------------------------------------*
TABLES: ztb_pedit. "Tabela base de pedidos (DDIC)

*----------------------------------------------------------------------*
* Tipos de dados internos (Internal Tables)
*----------------------------------------------------------------------*
DATA: gt_ped       TYPE STANDARD TABLE OF zest_ped,   "Tabela interna de pedidos
      gt_itens     TYPE STANDARD TABLE OF zest_itens, "Tabela interna de itens
      gt_itens_del TYPE STANDARD TABLE OF ztb_pedit. " buffer de exclusão

*----------------------------------------------------------------------*
* Estruturas de trabalho (Work Areas)
*----------------------------------------------------------------------*
DATA: gs_ped   TYPE zest_ped,   "Work area de pedido
      gs_itens TYPE zest_itens. "Work area de item

*----------------------------------------------------------------------*
* ALV - Field Catalog
*----------------------------------------------------------------------*
DATA: gt_fieldcat TYPE lvc_t_fcat. "Catálogo de campos do ALV
DATA: gs_fieldcat TYPE lvc_s_fcat.

DATA: gt_fieldcat2 TYPE lvc_t_fcat. "Catálogo de campos do ALV
DATA: gs_fieldcat2 TYPE lvc_s_fcat.
*----------------------------------------------------------------------*
* Controle de comandos de tela (OK-CODE)
*----------------------------------------------------------------------*
DATA: gd_okcode TYPE sy-ucomm. "Código do comando da tela

*----------------------------------------------------------------------*
* Constantes de comandos (PF-STATUS)
*----------------------------------------------------------------------*
CONSTANTS:
  gc_save TYPE sy-ucomm VALUE 'SAVE', "Salvar dados
  gc_back TYPE sy-ucomm VALUE 'BACK', "Voltar
  gc_canc TYPE sy-ucomm VALUE 'CANC', "Cancelar
  gc_exit TYPE sy-ucomm VALUE 'EXIT'. "Sair do programa

*----------------------------------------------------------------------*
* Objetos de apoio
*----------------------------------------------------------------------*
DATA: go_confirmar TYPE REF TO zcl_popup. "Classe de popup de confirmação

*----------------------------------------------------------------------*
* Controle de modo de tela
* C = Criar | A = Alterar | V = Visualizar
*----------------------------------------------------------------------*
DATA: gd_mode TYPE char1.

*----------------------------------------------------------------------*
* Objetos ALV
*----------------------------------------------------------------------*
DATA: go_alv  TYPE REF TO cl_gui_alv_grid,            "Grid ALV
      go_cont TYPE REF TO cl_gui_custom_container.   "Container do ALV

DATA: go_alv2  TYPE REF TO cl_gui_alv_grid,            "Grid ALV
      go_cont2 TYPE REF TO cl_gui_custom_container.   "Container do ALV

DATA: gs_layout TYPE lvc_s_layo.
DATA: gs_layout2 TYPE lvc_s_layo.

DATA gv_edit_mode  TYPE abap_bool.
DATA gv_edit_index TYPE sy-tabix.

DATA gv_loading_edit TYPE abap_bool.

DATA gv_first_display TYPE abap_bool.

DATA: gt_sort TYPE lvc_t_sort,
      gs_sort TYPE lvc_s_sort.

DATA gv_ok TYPE abap_bool.

DATA gd_idped TYPE zid_ped.
DATA gd_zid_ped TYPE char10.

DATA gv_externo TYPE abap_bool.
