REPORT zrel_pedidos.

*--------------------------------------------------------------------*
* DECLARAÇÃO DE TIPOS
*--------------------------------------------------------------------*
TYPES:
  BEGIN OF st_ped,
    id_ped       TYPE zid_ped,
    id_cliente   TYPE zid_cliente,
    cpf          TYPE zcpf_e,
    nome_cliente TYPE zcliente,
    data_ped     TYPE zdata_ped,
    hora_ped     TYPE erzet,
    valor_total  TYPE zvalor_total,
    id_func      TYPE zid_func,
    nome_func    TYPE znome,
    moeda        TYPE waers,
    status_ped   TYPE zstatus_ped,
    status_desc  TYPE ddtext,
    pm           TYPE zdepm,
  END OF st_ped,

  BEGIN OF st_pedit,
    id_ped     TYPE zid_ped,
    id_prod    TYPE zid_prod,
    qtde       TYPE zqtde,
    preco      TYPE zpreco,
    valor_item TYPE zvalor_item,
    marca      TYPE char1,
  END OF st_pedit.

*--------------------------------------------------------------------*
* DECLARAÇÃO DE VARIÁVEIS GLOBAIS
*--------------------------------------------------------------------*
DATA:
  it_ped      TYPE STANDARD TABLE OF zstr_pedido,
  it_pedit    TYPE STANDARD TABLE OF ztb_pedit,
  it_fcat1    TYPE STANDARD TABLE OF slis_fieldcat_alv,
  it_fcat2    TYPE STANDARD TABLE OF slis_fieldcat_alv,
  it_fieldcat TYPE kkblo_t_fieldcat,

  wa_pedit    TYPE ztb_pedit,
  wa_ped      TYPE zstr_pedido,
  wa_ped_sel  TYPE ztb_ped,
  wa_fcat1    TYPE slis_fieldcat_alv,
  wa_fcat2    TYPE slis_fieldcat_alv.

TYPE-POOLS: slis, kkblo.

DATA:
  v_repid LIKE sy-repid,
  v_save  TYPE c.

DATA:
  it_fcat   TYPE slis_t_fieldcat_alv,
  it_header TYPE kkblo_t_listheader,
  it_sort   TYPE slis_t_sortinfo_alv.

DATA:
  wa_variant TYPE disvariant,
  wa_colinfo TYPE kkblo_specialcol,
  wa_layout  TYPE kkblo_layout,
  wa_header  TYPE kkblo_listheader,
  wa_lay     TYPE slis_layout_alv,
  wa_sort    LIKE LINE OF it_sort.

*--------------------------------------------------------------------*
* CRITÉRIOS DE SELEÇÃO
*--------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS:
    s_idped       FOR wa_ped-id_ped,
    s_idcli        FOR wa_ped-id_cliente,
    s_idfunc      FOR wa_ped-id_func,
    s_data        FOR wa_ped-data_ped.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_status TYPE zstatus_ped,
    p_all    AS CHECKBOX DEFAULT ''.
SELECTION-SCREEN END OF  BLOCK b4.

*--------------------------------------------------------------------*
* BUSCA DE DADOS
*--------------------------------------------------------------------*
IF p_all = 'X'.
  SELECT a~id_ped,
         b~id_cliente,
         b~nome_cli as cliente,
         a~data_ped,
         a~hora_ped,
         a~valor_total,
         c~id_func,
         c~nome AS nome_func,
         a~moeda,
         a~status_ped,
         d~ddtext AS status_desc,
         e~ddtext as pm_desc
    FROM ztb_ped AS a
    INNER JOIN ztb_clientes AS b
     ON a~id_cliente = b~id_cliente
    INNER JOIN ztb_func AS c
     ON a~id_func = c~id_func
    INNER JOIN dd07t AS d
     ON d~domname = 'ZSTATUS_PED_D'
     AND d~domvalue_l = a~status_ped
     AND d~ddlanguage     = @sy-langu
    LEFT JOIN dd07t AS e
     ON e~domname = 'ZDOPM'
     AND e~domvalue_l = a~pm
     AND e~ddlanguage = @sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @it_ped.

ELSE.

  CALL FUNCTION 'ZF_GET_RELATORIO'
    EXPORTING
      iv_id_ped_low    = s_idped-low
      iv_id_ped_h      = s_idped-high
      iv_id_cliente_l  = s_idcli-low
      iv_id_cliente_h  = s_idcli-high
      iv_data_ped_l    = s_data-low
      iv_data_ped_h    = s_data-high
      iv_status        = p_status
      iv_id_func_l     = s_idfunc-low
      iv_id_func_h     = s_idfunc-high
      iv_tipo          = 'P'
    IMPORTING
      ev_result_ped    = it_ped
    EXCEPTIONS
      sem_dados        = 1
      tipo_inexistente = 2
      OTHERS           = 3.

  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE i030(zmsg_coffee).
* Nenhum dado encontrado para relatório.

      WHEN 2.
        MESSAGE i032(zmsg_coffee).
* Tipo de relatório inexistente.
    ENDCASE.
  ENDIF.

ENDIF.

*--------------------------------------------------------------------*
* MONTAGEM DO SORT - CABEÇALHO (it_fcat1)
*--------------------------------------------------------------------*

CLEAR wa_sort.
wa_sort-fieldname = 'ID_PED'.
wa_sort-up        = 'X'.   " Ordem crescente
wa_sort-spos      = 1.     " Primeira prioridade
APPEND wa_sort TO it_sort.

*--------------------------------------------------------------------*
* MONTAGEM DO FIELDCATALOG - CABEÇALHO (it_fcat1)
*--------------------------------------------------------------------*

DATA i TYPE i.
i = 0.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'ID_PED'.
wa_fcat1-seltext_m = 'Cod. Pedido'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'ID_CLIENTE'.
wa_fcat1-seltext_m = 'Cod. Cliente'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'CLIENTE'.
wa_fcat1-seltext_m = 'Cliente'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'DATA_PED'.
wa_fcat1-seltext_m = 'Data do pedido'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.

i = i + 1.
wa_fcat1-col_pos   = i.
wa_fcat1-fieldname = 'HORA_PED'.
wa_fcat1-ref_tabname   = 'ZSTR_PEDIDO'.
wa_fcat1-ref_fieldname = 'HORA_PED'.
wa_fcat1-seltext_s = 'Hora'.
wa_fcat1-seltext_m = 'Hora Pedido'.
wa_fcat1-seltext_l = 'Hora do Pedido'.
wa_fcat1-outputlen = 8.   " HH:MM:SS
wa_fcat1-no_out    = space.

APPEND wa_fcat1 TO it_fcat1.


CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'VALOR_TOTAL'.
wa_fcat1-seltext_m = 'Total'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'PM_DESC'.
wa_fcat1-seltext_m = 'Método de pagamento'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'ID_FUNC'.
wa_fcat1-seltext_m = 'Cod. Funcionário'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'NOME_FUNC'.
wa_fcat1-seltext_m = 'Funcionário'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'STATUS_PED'.
wa_fcat1-seltext_m = 'Status'.
APPEND wa_fcat1 TO it_fcat1.

CLEAR wa_fcat1.
wa_fcat1-col_pos   = i + 1.
wa_fcat1-fieldname = 'STATUS_DESC'.
wa_fcat1-seltext_m = 'Descrição da situação'.
APPEND wa_fcat1 TO it_fcat1.

*--------------------------------------------------------------------*
* MONTAGEM DO FIELDCATALOG - ITENS (it_fcat2)
*--------------------------------------------------------------------*
CLEAR wa_fcat2.
wa_fcat2-col_pos   = '1'.
wa_fcat2-fieldname = 'ID_PED'.
wa_fcat2-seltext_m = 'Cod. It. Pedido'.
APPEND wa_fcat2 TO it_fcat2.

CLEAR wa_fcat2.
wa_fcat2-col_pos   = '2'.
wa_fcat2-fieldname = 'ID_PROD'.
wa_fcat2-seltext_m = 'Cod. Produto'.
APPEND wa_fcat2 TO it_fcat2.

CLEAR wa_fcat2.
wa_fcat2-col_pos   = '3'.
wa_fcat2-fieldname = 'NOME_PROD'.
wa_fcat2-seltext_m = 'Produto'.
APPEND wa_fcat2 TO it_fcat2.


CLEAR wa_fcat2.
wa_fcat2-col_pos   = '4'.
wa_fcat2-fieldname = 'QTDE'.
wa_fcat2-seltext_m = 'Quantidade Pedida'.
APPEND wa_fcat2 TO it_fcat2.

CLEAR wa_fcat2.
wa_fcat2-col_pos   = '4'.
wa_fcat2-fieldname = 'PRECO'.
wa_fcat2-seltext_m = 'Preço'.
APPEND wa_fcat2 TO it_fcat2.

CLEAR wa_fcat2.
wa_fcat2-col_pos   = '6'.
wa_fcat2-fieldname = 'VALOR_ITEM'.
wa_fcat2-seltext_m = 'Valor Item'.
APPEND wa_fcat2 TO it_fcat2.

*--------------------------------------------------------------------*
* PREPARAÇÃO DO ALV
*--------------------------------------------------------------------*
* Transfere dados para o Field Catalog (estrutura SLIS)
CALL FUNCTION 'REUSE_ALV_TRANSFER_DATA_BACK'
  EXPORTING
    it_fieldcat = it_fieldcat " Catálogo KKBLO
    is_layout   = wa_layout
  IMPORTING
    et_fieldcat = it_fcat     " Catálogo SLIS
    es_layout   = wa_lay.

* Imprime dados --------------------------------
MOVE sy-repid TO v_repid.
MOVE v_repid TO wa_variant-report.

DATA: lv_repid TYPE sy-repid.
lv_repid = sy-repid.

wa_lay-zebra = 'X'.

CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program      = lv_repid
    i_callback_user_command = 'SECOND'
    i_grid_title            = 'Relatorio de pedidos'
    is_layout               = wa_lay
    it_fieldcat             = it_fcat1
    it_sort                 = it_sort
    i_save                  = v_save
    is_variant              = wa_variant
  TABLES
    t_outtab                = it_ped
  EXCEPTIONS
    program_error           = 1
    OTHERS                  = 2.

IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

*--------------------------------------------------------------------*
* FORM SECOND: Tratamento de Comandos (Double-Click, etc.)
*--------------------------------------------------------------------*
FORM second USING c LIKE sy-ucomm
                  d TYPE slis_selfield.

  READ TABLE it_ped INTO wa_ped INDEX d-tabindex.

  CLEAR it_pedit.

  SELECT
    id_ped,
    id_prod,
    nome_prod,
    qtde,
    preco,
    moeda,
    valor_item
    FROM ztb_pedit
    WHERE id_ped = @wa_ped-id_ped
    INTO CORRESPONDING FIELDS OF TABLE @it_pedit.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title  = 'Relatório de itens de pedido'
      it_fieldcat   = it_fcat2
    TABLES
      t_outtab      = it_pedit
    EXCEPTIONS
      program_error = 1
      OTHERS        = 2.

  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM. " second
