*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_FATURA......................................*
DATA:  BEGIN OF STATUS_ZTB_FATURA                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_FATURA                    .
CONTROLS: TCTRL_ZTB_FATURA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_FATURA                    .
TABLES: ZTB_FATURA                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
