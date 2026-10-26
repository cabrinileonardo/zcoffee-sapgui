TABLES: ztb_ped,
        ztb_pedit,
        ztb_func,
        ztb_prod.
* ztb_clientes. " Removido, pois não é padrão nas tabelas

TYPES: BEGIN OF ty_out,
         " --- Campos do Cabeçalho (ZTB_PED)
         id_ped        TYPE ztb_ped-id_ped,
         cpf           TYPE ztb_ped-cpf,
         data_ped      TYPE ztb_ped-data_ped,
         nome_cliente  TYPE ztb_ped-nome_cliente,
         valor_total   TYPE ztb_ped-valor_total,
         id_func       TYPE ztb_ped-id_func,

         " --- Campos do Item (ZTB_PEDIT)
         id_prod       TYPE ztb_pedit-id_prod,
         qtde          TYPE ztb_pedit-qtde,
         valor_item    TYPE ztb_pedit-valor_item,

         " --- Extras opcionais (caso precise)
         nome_prod     TYPE ztb_prod-nome_prod,  "Nome do produto
         nome_func     TYPE ztb_func-nome,       "Nome do funcionário
       END OF ty_out.

DATA: lt_ped   TYPE STANDARD TABLE OF ztb_ped,
      ls_ped   TYPE ztb_ped,
      lt_pedit TYPE STANDARD TABLE OF ztb_pedit,
      ls_pedit TYPE ztb_pedit,
      lt_out TYPE STANDARD TABLE OF ty_out,
      ls_out TYPE ty_out.

DATA gd_idped TYPE ztb_ped-id_ped.

* CORRIGIDO: gt_pedidos deve ser uma TABLE OF ZTYP_RELATORIO_PED
DATA: gt_pedidos TYPE TABLE OF ZEST_PEDIDO,
      gs_pedido  TYPE ZEST_PEDIDO.
* Resolvido o erro: GS_PEDIDO cannot be converted to the row type of "GT_PEDIDOS"



************************************************************************
* 2. Declarações ALV
************************************************************************

" Pools de ALV clássico
TYPE-POOLS: slis, kkblo.

" Programa atual
DATA: v_repid TYPE sy-repid VALUE sy-repid,
      v_save  TYPE c.

DATA: it_fcat     TYPE slis_t_fieldcat_alv,
      it_fieldcat TYPE kkblo_t_fieldcat,
      it_header   TYPE kkblo_t_listheader,
      it_sort     TYPE slis_t_sortinfo_alv.

DATA: wa_variant TYPE disvariant,
      wa_afield  TYPE kkblo_fieldcat,
      wa_colinfo TYPE kkblo_specialcol,
      wa_layout  TYPE kkblo_layout,
      wa_header  TYPE kkblo_listheader,
      wa_lay     TYPE slis_layout_alv,
      wa_sort    LIKE LINE OF it_sort.

DATA: ls_dados_selecionados TYPE ZEST_PEDIDO.
