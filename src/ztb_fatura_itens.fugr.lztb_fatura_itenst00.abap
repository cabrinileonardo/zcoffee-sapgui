*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_FATURA_ITENS................................*
DATA:  BEGIN OF STATUS_ZTB_FATURA_ITENS              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_FATURA_ITENS              .
CONTROLS: TCTRL_ZTB_FATURA_ITENS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_FATURA_ITENS              .
TABLES: ZTB_FATURA_ITENS               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
