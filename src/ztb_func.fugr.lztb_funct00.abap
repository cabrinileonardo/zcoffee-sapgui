*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_FUNC........................................*
DATA:  BEGIN OF STATUS_ZTB_FUNC                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_FUNC                      .
CONTROLS: TCTRL_ZTB_FUNC
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_FUNC                      .
TABLES: ZTB_FUNC                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
