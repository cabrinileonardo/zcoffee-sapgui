*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_PEDIT.......................................*
DATA:  BEGIN OF STATUS_ZTB_PEDIT                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_PEDIT                     .
CONTROLS: TCTRL_ZTB_PEDIT
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_PEDIT                     .
TABLES: ZTB_PEDIT                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
