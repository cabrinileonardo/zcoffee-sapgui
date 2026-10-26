*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTB_PED.........................................*
DATA:  BEGIN OF STATUS_ZTB_PED                       .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTB_PED                       .
CONTROLS: TCTRL_ZTB_PED
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTB_PED                       .
TABLES: ZTB_PED                        .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
