TABLES: ztb_prod.

TYPES: BEGIN OF st_prod,
         mandt        TYPE mandt,
         id_prod      TYPE zid_prod,
         nome_prod    TYPE znome_prod,
         categoria    TYPE zcategoria,
         preco        TYPE zpreco,
         qtde_estoque TYPE zqtde_estoque,
         waers        TYPE waers,
         status_prod  TYPE zstatus_prod_e,
         status_icon  TYPE icon_d,
       END OF st_prod.

DATA: it_prod     TYPE STANDARD TABLE OF ztb_prod,
      wa_prod     TYPE ztb_prod,
      wa_prod_sel TYPE ztb_prod,

      it_prodcp   TYPE STANDARD TABLE OF ztb_prod,
      it_changes  TYPE STANDARD TABLE OF ztb_prod,

      wa_fieldcat TYPE slis_fieldcat_alv,
      it_fieldcat TYPE STANDARD TABLE OF slis_fieldcat_alv,
      wa_layout   TYPE slis_layout_alv.

DATA:
  it_sort TYPE slis_t_sortinfo_alv,
  wa_sort TYPE slis_sortinfo_alv.
