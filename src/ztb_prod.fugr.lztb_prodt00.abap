*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_PROD........................................*
DATA:  BEGIN OF STATUS_ZTB_PROD                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_PROD                      .
CONTROLS: TCTRL_ZTB_PROD
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_PROD                      .
TABLES: ZTB_PROD                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
