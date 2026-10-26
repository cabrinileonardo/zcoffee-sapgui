*---------------------------------------------------------------------*
* INCLUDE ZPRG_PRODUTO_PAI
*---------------------------------------------------------------------*
* Rotinas PAI (Process After Input)
* Responsável por:
*  - Tratar comandos de usuário (OKCODE)
*  - Exibir mensagens de confirmação
*  - Executar ações de salvar, voltar e sair
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* PAI - Tela 9000 (Inserção de Produto)
*---------------------------------------------------------------------*
MODULE pai_9000 INPUT.

  CASE gd_okcode.

    WHEN 'SAVE'.

      "Confirmação para cadastro do produto
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja cadastrar o produto?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.
        WHEN '1'.
          "Confirmação positiva
          LEAVE TO SCREEN 0.

        WHEN '2'.
          "Usuário cancelou a ação
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

        WHEN 'A'.
          "Usuário fechou o popup (nenhuma ação)
      ENDCASE.

      CLEAR gd_resposta.

    WHEN 'BACK'.

      "Confirmação para retorno à tela inicial
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja retornar?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.
        WHEN '1'.
          PERFORM tela_inicial.
        WHEN '2'.
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
        WHEN 'A'.
      ENDCASE.

      CLEAR gd_resposta.

    WHEN 'EXIT'.

      "Confirmação para sair do programa
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja sair do programa?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.
        WHEN '1'.
          LEAVE PROGRAM.
        WHEN '2'.
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
        WHEN 'A'.
      ENDCASE.

      CLEAR gd_resposta.

  ENDCASE.

ENDMODULE.

*---------------------------------------------------------------------*
* PAI - Tela 9001 (Alteração de Produto)
*---------------------------------------------------------------------*
MODULE pai_9001 INPUT.

  CASE gd_okcode.

    WHEN 'SAVE' OR ''.

      "Confirmação para alteração dos dados do produto
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja alterar os dados do produto?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.

        WHEN '1'.
          "Usuário confirmou a alteração
          MODIFY ztb_prod FROM ls_prod.

          IF sy-subrc = 0.
            COMMIT WORK.
            MESSAGE s013(zmsg_coffee).
            LEAVE TO SCREEN 0.
          ELSE.
            ROLLBACK WORK.
            MESSAGE s014(zmsg_coffee) DISPLAY LIKE 'E'.
          ENDIF.

        WHEN '2'.
          "Usuário cancelou a alteração
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

        WHEN 'A'.
          "Popup fechado sem ação
      ENDCASE.

      CLEAR gd_resposta.

    WHEN 'BACK'.

      "Confirmação para retorno sem salvar
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja retornar à tela inicial?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.
        WHEN '1'.
          MESSAGE 'Nenhuma alteração realizada.' TYPE 'I'.
          LEAVE TO SCREEN 0.
        WHEN '2'.
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
        WHEN 'A'.
      ENDCASE.

      CLEAR gd_resposta.

    WHEN 'EXIT'.

      "Confirmação para saída do programa
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja sair do programa?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.
        WHEN '1'.
          MESSAGE 'Nenhuma alteração realizada.' TYPE 'I'.
          LEAVE PROGRAM.
        WHEN '2'.
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
        WHEN 'A'.
      ENDCASE.

      CLEAR gd_resposta.

  ENDCASE.

ENDMODULE.
