TABLES: ztb_pagamento,
        ztb_pagamento_it.

DATA:
  gt_pgto  TYPE STANDARD TABLE OF ztb_pagamento,
  gs_pgto  TYPE ztb_pagamento,
  gt_itens TYPE STANDARD TABLE OF ztb_pagamento_it,
  gs_itens TYPE ztb_pagamento_it.

DATA gv_mode TYPE char1. " C/U/V

DATA: gv_okcode TYPE sy-ucomm.

CONSTANTS: gc_save TYPE sy-ucomm VALUE 'SAVE',
           gc_back TYPE sy-ucomm VALUE 'BACK',
           gc_exit TYPE sy-ucomm VALUE 'EXIT'.

DATA: gv_first TYPE abap_bool VALUE abap_false.

DATA: go_alv  TYPE REF TO cl_gui_alv_grid,
      go_cont TYPE REF TO cl_gui_custom_container.

DATA gs_layout TYPE lvc_s_layo.

DATA gv_trava_itens TYPE abap_bool.

DATA gv_destravar_p TYPE abap_bool.

DATA gv_edit TYPE abap_bool.

DATA gv_id_pgto TYPE zdeidpag.
