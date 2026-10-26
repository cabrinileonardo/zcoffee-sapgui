*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_ZTB_FATURA_ITENS
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_ZTB_FATURA_ITENS   .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
