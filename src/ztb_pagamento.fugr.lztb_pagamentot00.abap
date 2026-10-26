*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_PAGAMENTO...................................*
DATA:  BEGIN OF STATUS_ZTB_PAGAMENTO                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_PAGAMENTO                 .
CONTROLS: TCTRL_ZTB_PAGAMENTO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_PAGAMENTO                 .
TABLES: ZTB_PAGAMENTO                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
