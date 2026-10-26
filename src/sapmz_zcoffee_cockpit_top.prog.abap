"---------------------------------------------------------------
" Variáveis globais
"---------------------------------------------------------------
DATA: gv_resposta TYPE c LENGTH 1.       " Resposta do usuário (popup)
DATA: gd_okcode   TYPE sy-ucomm.         " Código de comando da tela (OKCODE)

*----------------------------------------------------------------------*
*    Estrutura interna                                                 *
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_ped,
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
         pm_desc(60)  TYPE c,
       END OF ty_ped.

*----------------------------------------------------------------------*
* Tables globais                                                       *
*----------------------------------------------------------------------*
DATA: gt_ped TYPE STANDARD TABLE OF ty_ped.
DATA: gt_fcat TYPE lvc_t_fcat.
DATA: gt_sort TYPE lvc_t_sort.

*----------------------------------------------------------------------*
* Work areas                                                           *
*----------------------------------------------------------------------*
DATA: gs_ped    TYPE ty_ped,
      gs_fcat   TYPE lvc_s_fcat,
      gs_layout TYPE lvc_s_layo,
      gs_sort   TYPE lvc_s_sort.

"---------------------------------------------------------------
" Constantes para comandos padrão de navegação
"---------------------------------------------------------------
CONSTANTS: gc_back TYPE sy-ucomm VALUE 'BACK',   " Voltar
           gc_exit TYPE sy-ucomm VALUE 'EXIT',   " Sair
           gc_canc TYPE sy-ucomm VALUE 'CANC'.   " Cancelar

"---------------------------------------------------------------
" Classe local para exibição de pop up de confirmação - Definição
"---------------------------------------------------------------
CLASS lcl_popup DEFINITION.
  PUBLIC SECTION.
    METHODS confirmar_acao
      IMPORTING id_title           TYPE char30   "Título da janela do popup
                id_quest           TYPE char50   "Texto da pergunta exibida
                id_op1             TYPE char10   "Texto do botão 1
                id_op2             TYPE char10   "Texto do botão 2
      RETURNING VALUE(rd_resposta) TYPE char1.   "Resposta escolhida pelo usuário
ENDCLASS.

"---------------------------------------------------------------
" Classe RH
"---------------------------------------------------------------
CLASS lcl_rh DEFINITION.
  PUBLIC SECTION.
    METHODS: abrir_menu,
      abrir_funcionarios.
ENDCLASS.

"---------------------------------------------------------------
" Classe MM
"---------------------------------------------------------------
CLASS lcl_compras DEFINITION.
  PUBLIC SECTION.
    METHODS: abrir_menu,
      abrir_produtos,
      abrir_relatorio.
ENDCLASS.

"---------------------------------------------------------------
" Classe SD
"---------------------------------------------------------------
CLASS lcl_vendas DEFINITION.
  PUBLIC SECTION.
    METHODS: abrir_menu,
      criar_pedido,
      abrir_clientes,
      abrir_monitor,
      abrir_fatura.
ENDCLASS.

"---------------------------------------------------------------
" Classe FI
"---------------------------------------------------------------
CLASS lcl_fi DEFINITION.
  PUBLIC SECTION.
    METHODS: abrir_menu,
      fi_fp,
      fi_lucro,
      fi_ped_canc,
      fi_rfat.
ENDCLASS.

"---------------------------------------------------------------
" Classe principal de redirecionamento
"---------------------------------------------------------------
CLASS lcl_app DEFINITION.
  PUBLIC SECTION.
    METHODS:
      process_rh,
      process_compras,
      process_vendas,
      process_fi,
      return_to_screen_0100.
ENDCLASS.

*----------------------------------------------------------------------*
*        Objetos globais                                               *
*----------------------------------------------------------------------*
DATA: go_all TYPE REF TO lcl_app,
      go_pop TYPE REF TO lcl_popup.
