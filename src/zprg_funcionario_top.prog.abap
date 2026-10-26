*&---------------------------------------------------------------------*
*& Include          ZPRG_FUNCIONARIO_TOP
*&---------------------------------------------------------------------*
*& Descrição:
*& Include responsável por conter todas as declarações globais do
*& programa ZPRG_FUNCIONARIO, incluindo:
*&  - Tipos de dados
*&  - Tabelas internas
*&  - Variáveis globais
*&  - Definição da tela de seleção
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* Declaração da tabela do dicionário
*---------------------------------------------------------------------*
* Permite acesso direto aos campos da tabela ZTB_FUNC
TABLES ztb_func.

************************************************************************
* 1. Tipos de Dados
************************************************************************
* Estrutura interna utilizada para exibição no ALV.
* Inclui todos os campos da tabela ZTB_FUNC e campos auxiliares
* para exibição de textos descritivos.
************************************************************************
TYPES: BEGIN OF ty_func.
         INCLUDE TYPE ztb_func.           " Campos base do funcionário
TYPES: status_texto TYPE char20. " Texto descritivo do status
TYPES: nome_cargo TYPE char50.   " Descrição do cargo
TYPES: END OF ty_func.

************************************************************************
* 2. Declarações Globais
************************************************************************

*---------------------------------------------------------------------*
* Tabelas internas e work areas
*---------------------------------------------------------------------*
DATA: lt_func TYPE TABLE OF ty_func, " Tabela principal de funcionários
      ls_func TYPE ty_func.          " Work area auxiliar

*---------------------------------------------------------------------*
* Controle de comandos da tela (OK_CODE)
*---------------------------------------------------------------------*
DATA gd_okcode TYPE sy-ucomm.

*---------------------------------------------------------------------*
* Estrutura para armazenar linha selecionada no ALV
*---------------------------------------------------------------------*
DATA: ls_dados_selecionados LIKE LINE OF lt_func.

*---------------------------------------------------------------------*
* Type-Pools necessários para ALV (REUSE)
*---------------------------------------------------------------------*
TYPE-POOLS: slis, kkblo.

*---------------------------------------------------------------------*
* Variáveis de controle do ALV
*---------------------------------------------------------------------*
DATA: v_repid LIKE sy-repid,  " Nome do programa
      v_save  TYPE c.         " Controle de variante (Salvar layout)

*---------------------------------------------------------------------*
* Tabelas internas para configuração do ALV
*---------------------------------------------------------------------*
DATA: it_fcat     TYPE slis_t_fieldcat_alv, " Fieldcat (REUSE)
      it_fieldcat TYPE kkblo_t_fieldcat,    " Fieldcat alternativo
      it_header   TYPE kkblo_t_listheader,  " Cabeçalho do ALV
      it_sort     TYPE slis_t_sortinfo_alv. " Ordenação do ALV

*---------------------------------------------------------------------*
* Work areas auxiliares do ALV
*---------------------------------------------------------------------*
DATA: wa_variant TYPE disvariant,            " Variante de layout
      wa_afield  TYPE kkblo_fieldcat,        " Campo do fieldcat
      wa_colinfo TYPE kkblo_specialcol,      " Configuração especial
      wa_layout  TYPE kkblo_layout,          " Layout ALV (KKBLO)
      wa_header  TYPE kkblo_listheader,      " Header individual
      wa_lay     TYPE slis_layout_alv,       " Layout ALV (SLIS)
      wa_sort    LIKE LINE OF it_sort.       " Linha de ordenação

************************************************************************
* 3. Tela de Seleção
************************************************************************

*---------------------------------------------------------------------*
* BLOCO 1 - Dados do Funcionário
*---------------------------------------------------------------------*
* Utilizado para informar dados básicos do funcionário
* (ID e Nome) para operações de inserção, alteração ou exclusão.
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    p_idfunc TYPE ztb_func-id_func, " Identificador do funcionário
    p_nome   TYPE ztb_func-nome.    " Nome do funcionário

SELECTION-SCREEN END OF BLOCK b1.

*---------------------------------------------------------------------*
* BLOCO 2 - Ações
*---------------------------------------------------------------------*
* Define qual operação será executada no programa.
* Apenas uma ação pode ser selecionada por vez.
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS:
    rb_ins RADIOBUTTON GROUP act DEFAULT 'X', " Inserir funcionário
    rb_alt RADIOBUTTON GROUP act,             " Alterar funcionário
    rb_exi RADIOBUTTON GROUP act,             " Exibir funcionários
    rb_del RADIOBUTTON GROUP act.             " Excluir funcionário

SELECTION-SCREEN END OF BLOCK b2.

*---------------------------------------------------------------------*
* BLOCO 3 - Filtros Avançados
*---------------------------------------------------------------------*
* Utilizado principalmente na funcionalidade de exibição (ALV),
* permitindo filtrar os registros conforme critérios específicos.
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.

  SELECT-OPTIONS:
    s_id    FOR ztb_func-id_func,    " Faixa de IDs
    s_nome  FOR ztb_func-nome,       " Faixa de nomes
    s_cargo FOR ztb_func-cargo,      " Cargo do funcionário
    s_data  FOR ztb_func-data_adm,   " Data de admissão
    s_salr  FOR ztb_func-salario.    " Faixa salarial

  PARAMETERS:
    p_ativo TYPE ztb_func-atividade,
*    p_ativo AS CHECKBOX DEFAULT 'X', " Filtrar apenas funcionários ativos
    p_all   AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b3.
