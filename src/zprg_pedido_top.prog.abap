*---------------------------------------------------------------------*
* Declarações de tabelas do dicionário (TABLES)
*---------------------------------------------------------------------*
* Utilizadas para acesso direto aos campos das tabelas
*---------------------------------------------------------------------*
TABLES:
  ztb_func,      " Funcionários
  ztb_prod,      " Produtos
  ztb_clientes,  " Clientes
  ztb_ped,       " Cabeçalho do pedido
  ztb_pedit.     " Itens do pedido

*---------------------------------------------------------------------*
* Type-pool para ALV clássico
*---------------------------------------------------------------------*
TYPE-POOLS: slis.

*---------------------------------------------------------------------*
* Declarações internas de dados (Pedidos)
*---------------------------------------------------------------------*
DATA gv_skip_sel TYPE abap_bool.

DATA:
  gt_ped   TYPE STANDARD TABLE OF ztb_ped,   " Tabela interna de pedidos
  gt_out   TYPE zest_pedido,                 " Estrutura/tabela de saída para ALV
  gs_ped   TYPE ztb_ped,                     " Work area do pedido
  gs_pedit TYPE ztb_pedit,                   " Work area dos itens do pedido
  gs_out   TYPE zest_pedido.                 " Work area de saída

*---------------------------------------------------------------------*
* Declarações para configuração do ALV
*---------------------------------------------------------------------*
DATA:
  gt_fcat1 TYPE STANDARD TABLE OF slis_fieldcat_alv, " Fieldcat ALV 1
  gt_fcat2 TYPE STANDARD TABLE OF slis_fieldcat_alv, " Fieldcat ALV 2
  gt_sort  TYPE STANDARD TABLE OF slis_sortinfo_alv, " Ordenação do ALV

  gs_fcat1 TYPE slis_fieldcat_alv,                   " Work area fieldcat 1
  gs_fcat2 TYPE slis_fieldcat_alv,                   " Work area fieldcat 2
  gs_sort  TYPE slis_sortinfo_alv.                    " Work area sort

*---------------------------------------------------------------------*
* Variáveis de controle do ALV
*---------------------------------------------------------------------*
DATA:
  v_repid LIKE sy-repid,  " Nome do programa (Report ID)
  v_save  TYPE c.         " Controle de salvamento de layout

DATA gv_first_time TYPE abap_bool VALUE abap_true.


DATA:
  gs_variant TYPE disvariant,            " Variante de layout do ALV
  gs_colinfo TYPE slis_specialcol_alv,   " Configuração especial de colunas
  gs_lay     TYPE slis_layout_alv.        " Layout geral do ALV

*---------------------------------------------------------------------*
* Variáveis de controle de tela
*---------------------------------------------------------------------*
DATA:
  gd_okcode TYPE sy-ucomm.  " Código de função (OK_CODE)
DATA gv_auto_search TYPE abap_bool VALUE abap_true.


*---------------------------------------------------------------------*
* Variáveis para radiobuttons
*---------------------------------------------------------------------*
DATA:
  rad1,
  rad2,
  rad3.   " Radiobuttons de controle (uso em telas)

*---------------------------------------------------------------------*
* Variáveis de negócio
*---------------------------------------------------------------------*
DATA:
  gd_id_ped TYPE ztb_ped-id_ped.  " ID do pedido

DATA:
  gd_resposta TYPE char1.         " Resposta genérica (S/N, por exemplo)

*---------------------------------------------------------------------*
* Controle de modo do programa
*---------------------------------------------------------------------*
* 'C' = Criação de pedido
* 'E' = Edição / Inclusão de itens
*---------------------------------------------------------------------*
DATA:
  gd_mode TYPE c LENGTH 1.

*---------------------------------------------------------------------*
* Tipo para manipulação dos itens do pedido em tela
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_pedit_screen.
    INCLUDE STRUCTURE zest_pedido.   " Estrutura base do pedido
TYPES: gd_status TYPE c LENGTH 1, " Status do item:
    " 'N' = Novo
    " ' ' = Existente
    " 'D' = Deletado
  END OF ty_pedit_screen.

*---------------------------------------------------------------------*
* Tabelas internas e work areas dos itens do pedido
*---------------------------------------------------------------------*
DATA:
  gt_pedit     TYPE STANDARD TABLE OF ty_pedit_screen, " Itens do pedido (tela)
  gs_est_pedit TYPE ty_pedit_screen.                   " Work area do item
