*&---------------------------------------------------------------------*
*&      Module  PAI_0100  INPUT
*&---------------------------------------------------------------------*
*& PAI da tela principal (menu inicial)
*&---------------------------------------------------------------------*
MODULE pai_0100 INPUT.

  " Instancia classes locais
  go_pop = NEW lcl_popup( ).
  go_all = NEW lcl_app( ).

  CASE gd_okcode.

      "---------------------------------------------------------------
      " Botões de saída
      "---------------------------------------------------------------
    WHEN gc_back OR gc_exit OR gc_canc.

      gv_resposta = go_pop->confirmar_acao(
        id_title = 'Confirmação de ação'
        id_quest = 'Deseja sair do programa?'
        id_op1   = 'Sim'
        id_op2   = 'Não'
      ).

      CASE gv_resposta.
        WHEN '1'. " Botão 1 - Sim
          LEAVE PROGRAM.
        WHEN '2'. " Botão 2 - Não
          MESSAGE i042(zmsg_coffee). " Ação cancelada pelo usuário
        WHEN 'A'. " Cancelar
          " Não faz nada
      ENDCASE.

      CLEAR gv_resposta.

      "---------------------------------------------------------------
      " Botões de navegação para módulos
      "---------------------------------------------------------------
    WHEN 'BTN_RH'.
      NEW lcl_rh( )->abrir_funcionarios( ).

    WHEN 'BTN_COMPRAS'.
      go_all->process_compras( ).

    WHEN 'BTN_VENDAS'.
      go_all->process_vendas( ).

    WHEN 'BTN_FI'.
      go_all->process_fi( ).

  ENDCASE.

ENDMODULE.                    " pai_0100


*&---------------------------------------------------------------------*
*&      Module  PAI_0200  INPUT
*&---------------------------------------------------------------------*
*& PAI da tela de vendas (menu)
*&---------------------------------------------------------------------*
MODULE pai_0200 INPUT.

  DATA lo_vendas TYPE REF TO lcl_vendas.

  go_pop = NEW lcl_popup( ).
  go_all = NEW lcl_app( ).

  IF lo_vendas IS NOT BOUND.
    CREATE OBJECT lo_vendas.
  ENDIF.

  CASE gd_okcode.

      "---------------------------------------------------------------
      " Botões de saída
      "---------------------------------------------------------------
    WHEN gc_back OR gc_exit OR gc_canc.

      gv_resposta = go_pop->confirmar_acao(
        id_title = 'Confirmação de ação'
        id_quest = 'Deseja retornar ao menu?'
        id_op1   = 'Sim'
        id_op2   = 'Não'
      ).

      CASE gv_resposta.
        WHEN '1'. " Botão 1 - Sim
          go_all->return_to_screen_0100( ).
        WHEN '2'. " Botão 2 - Não
          MESSAGE i042(zmsg_coffee). " Ação cancelada pelo usuário
        WHEN 'A'. " Cancelar
          " Não faz nada
      ENDCASE.

      CLEAR gv_resposta.

      "---------------------------------------------------------------
      " Botões específicos do módulo de vendas
      "---------------------------------------------------------------
    WHEN 'BTN_CRIAR_PED'.
      lo_vendas->criar_pedido( ).

    WHEN 'BTN_CLIENTES'.
      lo_vendas->abrir_clientes( ).

    WHEN 'BTN_FATURA'.
      lo_vendas->abrir_fatura( ).

    WHEN 'BTN_MP'.
      lo_vendas->abrir_monitor( ).

  ENDCASE.

ENDMODULE.                    " pai_0200


*&---------------------------------------------------------------------*
*&      Module  PAI_0300  INPUT
*&---------------------------------------------------------------------*
*& PAI da tela de financeiro (menu)
*&---------------------------------------------------------------------*
MODULE pai_0300 INPUT.

  go_pop = NEW lcl_popup( ).
  go_all = NEW lcl_app( ).

  CASE gd_okcode.

      "---------------------------------------------------------------
      " Botões de saída
      "---------------------------------------------------------------
    WHEN gc_back OR gc_exit OR gc_canc.

      gv_resposta = go_pop->confirmar_acao(
        id_title = 'Confirmação de ação'
        id_quest = 'Deseja retornar ao menu?'
        id_op1   = 'Sim'
        id_op2   = 'Não'
      ).

      CASE gv_resposta.
        WHEN '1'. " Botão 1 - Sim
          go_all->return_to_screen_0100( ).
        WHEN '2'. " Botão 2 - Não
          MESSAGE i042(zmsg_coffee). " Ação cancelada pelo usuário
        WHEN 'A'. " Cancelar
          " Não faz nada
      ENDCASE.

      CLEAR gv_resposta.

      "---------------------------------------------------------------
      " Botões específicos do módulo financeiro
      "---------------------------------------------------------------
    WHEN 'BTN_FP'.
      NEW lcl_fi( )->fi_fp( ).

    WHEN 'BTN_LUCRO'.
      NEW lcl_fi( )->fi_lucro( ).

    WHEN 'BTN_BAIXA'.
      CALL TRANSACTION 'ZFIBAIXAFAT'.
  ENDCASE.

ENDMODULE.                    " pai_0300


*&---------------------------------------------------------------------*
*&      Module  PAI_0400  INPUT
*&---------------------------------------------------------------------*
*& PAI da tela de compras (menu)
*&---------------------------------------------------------------------*
MODULE pai_0400 INPUT.

  go_pop = NEW lcl_popup( ).
  go_all = NEW lcl_app( ).

  CASE gd_okcode.

      "---------------------------------------------------------------
      " Botões de saída
      "---------------------------------------------------------------
    WHEN gc_back OR gc_exit OR gc_canc.

      gv_resposta = go_pop->confirmar_acao(
        id_title = 'Confirmação de ação'
        id_quest = 'Deseja retornar ao menu?'
        id_op1   = 'Sim'
        id_op2   = 'Não'
      ).

      CASE gv_resposta.
        WHEN '1'. " Botão 1 - Sim
          go_all->return_to_screen_0100( ).
        WHEN '2'. " Botão 2 - Não
          MESSAGE i042(zmsg_coffee). " Ação cancelada pelo usuário
        WHEN 'A'. " Cancelar
          " Não faz nada
      ENDCASE.

      CLEAR gv_resposta.

      "---------------------------------------------------------------
      " Botões específicos do módulo de compras
      "---------------------------------------------------------------
    WHEN 'BTN_PROD'.
      NEW lcl_compras( )->abrir_produtos( ).

    WHEN 'BTN_REL_PROD'.
      NEW lcl_compras( )->abrir_relatorio( ).

  ENDCASE.

ENDMODULE.                    " pai_0400

*&---------------------------------------------------------------------*
*&      Module  PAI_0500  INPUT
*&---------------------------------------------------------------------*
* PAI do Rh
*----------------------------------------------------------------------*
MODULE pai_0500 INPUT.
  go_pop = NEW lcl_popup( ).
  go_all = NEW lcl_app( ).

  CASE gd_okcode.
    WHEN gc_back OR gc_exit OR gc_canc.

      gv_resposta = go_pop->confirmar_acao(
        id_title = 'Confirmação de ação'
        id_quest = 'Deseja retornar ao menu?'
        id_op1   = 'Sim'
        id_op2   = 'Não'
      ).

      CASE gv_resposta.
        WHEN '1'. " Botão 1 - Sim
          go_all->return_to_screen_0100( ).
        WHEN '2'. " Botão 2 - Não
          MESSAGE i042(zmsg_coffee). " Ação cancelada pelo usuário
        WHEN 'A'. " Cancelar
          " Não faz nada
      ENDCASE.

      CLEAR gv_resposta.

      "---------------------------------------------------------------
      " Botões específicos do módulo de RH
      "---------------------------------------------------------------

    WHEN 'BTN_FUNC'.
      NEW lcl_rh( )->abrir_funcionarios( ).
  ENDCASE.
ENDMODULE.
