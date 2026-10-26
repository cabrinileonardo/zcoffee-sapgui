REPORT zprg_pedido.

*---------------------------------------------------------------------*
* Includes do programa
*---------------------------------------------------------------------*
* TOP  -> Declarações globais (types, data, constantes, etc.)
* FRM  -> Sub-rotinas (FORMS)
* PBO  -> Process Before Output (lógica de tela antes de exibir)
* PAI  -> Process After Input  (lógica após ações do usuário)
*---------------------------------------------------------------------*
INCLUDE zprg_pedido_top.
INCLUDE zprg_pedido_frm.
INCLUDE zprg_pedido_pbo.
INCLUDE zprg_pedido_pai.

*---------------------------------------------------------------------*
* Tela de seleção
*---------------------------------------------------------------------*
* Bloco com opções para definir a ação do programa:
* - Criar pedido
* - Consultar / modificar pedido
*---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  PARAMETERS:
    rb_criar RADIOBUTTON GROUP clic, " Opção: Criar pedido
    rb_cons  RADIOBUTTON GROUP clic,             " Opção: Consultar pedido
    rb_view  RADIOBUTTON GROUP clic.             " Opção: Vizualizar relatorio de pedidos

SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.

  CASE sy-tcode.
    WHEN 'ZPEDIDOS_M'.
      rb_cons     = abap_true.
      gv_skip_sel = abap_true.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.

  IF gv_skip_sel = abap_true.
    gv_skip_sel = abap_false. " evita loop
    LEAVE TO SCREEN 0.
  ENDIF.



*---------------------------------------------------------------------*
* Evento principal do programa
*---------------------------------------------------------------------*
START-OF-SELECTION.

  " Verifica qual opção foi selecionada na tela
  CASE 'X'.
    WHEN rb_criar.
      " Chamada da rotina responsável pela criação do pedido
      PERFORM f_criar_pedido.

    WHEN rb_cons.
      " Chamada da rotina responsável pela consulta/modificação do pedido
      PERFORM f_modificar_pedido.

      " Chamada da transação para o relatório de pedidos.
    WHEN rb_view.
      CALL TRANSACTION 'ZREL_PEDIDOS'.

    WHEN OTHERS.
      " Tratamento para o caso de nenhuma opção válida ser selecionada
      MESSAGE 'Selecione uma opção válida' TYPE 'I'.
  ENDCASE.

*---------------------------------------------------------------------*
* Include gerado automaticamente pelo Screen Painter (Table Control)
*---------------------------------------------------------------------*
* ATENÇÃO:
* - Código gerado automaticamente
* - Não alterar manualmente para evitar inconsistências
*---------------------------------------------------------------------*
*&SPWizard: Data incl. inserted by SP Wizard. DO NOT CHANGE THIS LINE!
  INCLUDE zprg_pedido_tc.
