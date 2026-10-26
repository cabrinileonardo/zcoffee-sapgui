TABLES ztb_clientes.

DATA: lt_cliente            TYPE STANDARD TABLE OF ztb_clientes,
      ls_cliente            TYPE ztb_clientes,
      gd_okcode             TYPE sy-ucomm,
      gd_resposta           TYPE char1,
      ls_dados_selecionados LIKE LINE OF lt_cliente.


************************************************************************
* 2. Declarações ALV (Mantidas)
************************************************************************

TYPE-POOLS: slis, kkblo.
DATA: v_repid LIKE sy-repid,
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

DATA gv_id_cli_temp TYPE ztb_clientes-id_cliente.

************************************************************************
* 3. Selection Screen (Tela de Seleção)
************************************************************************

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-000.
  PARAMETERS: p_id   TYPE ztb_clientes-id_cliente,
              p_nome TYPE ztb_clientes-nome_cli.
SELECTION-SCREEN END OF BLOCK b1.

* --- Opções de Transação ---
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002. " Ação
  PARAMETERS:
    rb_ins RADIOBUTTON GROUP g1 DEFAULT 'X', " Inserir
    rb_alt RADIOBUTTON GROUP g1,            " Alterar
    rb_exi RADIOBUTTON GROUP g1.            " Listar
SELECTION-SCREEN END OF BLOCK b2.

* --- Critérios de Seleção/Pesquisa ---
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-001. " Critérios de Pesquisa

  SELECT-OPTIONS s_id FOR ztb_clientes-id_cliente.

* CPF
  SELECT-OPTIONS: s_cpf FOR ztb_clientes-cpf.

* Nome do Cliente
  SELECT-OPTIONS: s_nome FOR ztb_clientes-nome_cli.

* Data de Nascimento
  SELECT-OPTIONS: s_data FOR ztb_clientes-data_nasc.

* Telefone
  SELECT-OPTIONS: s_tel FOR ztb_clientes-telefone.

* Cidade
  SELECT-OPTIONS: s_cidade FOR ztb_clientes-cidade.

* Checkbox para filtro (se necessário, ex: "Somente Ativos")
  PARAMETERS: p_ativo TYPE ztb_clientes-status_cli,
              p_all   AS CHECKBOX DEFAULT 'X'. " USER-COMMAND para interatividade

SELECTION-SCREEN END OF BLOCK b3.
