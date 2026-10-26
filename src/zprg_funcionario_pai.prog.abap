*---------------------------------------------------------------------*
* Include          ZPRG_FUNCIONARIO_PAI
*---------------------------------------------------------------------*
* Descrição:
* Include responsável pelo processamento PAI (Process After Input),
* ou seja, trata todas as ações do usuário após interação com a tela,
* como cliques em botões, salvar, voltar ou sair do programa.
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* PAI – Tela 9000
*---------------------------------------------------------------------*
* Tela utilizada principalmente para inserção de funcionários.
*---------------------------------------------------------------------*
MODULE pai_9000 INPUT.

  " Variável auxiliar para capturar resposta do popup
  DATA: lv_pop TYPE char01.

  " Avalia o comando acionado pelo usuário
  CASE gd_okcode.

    WHEN 'SAVE'.
      " Solicita confirmação do usuário antes de prosseguir
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja continuar?'
              'Sim'
              'Não'
        CHANGING lv_pop.

      " Trata resposta do popup
      IF lv_pop = '1'.
        " Usuário confirmou a ação
        LEAVE TO SCREEN 0.

      ELSEIF lv_pop = '2'.
        " Usuário cancelou a ação
        MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

      ELSEIF lv_pop = 'A'.
        " Popup fechado sem seleção explícita
        " Nenhuma ação é executada
      ENDIF.

      " Limpa variável de controle
      CLEAR lv_pop.

    WHEN 'BACK'.
      " Confirmação para retornar à tela anterior
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja Retornar?'
              'Sim'
              'Não'
        CHANGING lv_pop.

      IF lv_pop = '1'.
        LEAVE TO SCREEN 0.
      ELSEIF lv_pop = '2'.
        MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
      ENDIF.

      CLEAR lv_pop.

    WHEN 'EXIT'.
      " Confirmação para encerrar o programa
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja sair do programa?'
              'Sim'
              'Não'
        CHANGING lv_pop.

      IF lv_pop = '1'.
        LEAVE PROGRAM.
      ELSEIF lv_pop = '2'.
        MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
      ENDIF.

      CLEAR lv_pop.

  ENDCASE.

ENDMODULE.

*---------------------------------------------------------------------*
* PAI – Tela 9001
*---------------------------------------------------------------------*
* Tela utilizada para alteração de dados de funcionários.
*---------------------------------------------------------------------*
MODULE pai_9001 INPUT.

  " Avalia o comando acionado pelo usuário
  CASE gd_okcode.

    WHEN 'SAVE' OR ''.
      " Exibe popup padrão de confirmação para salvar alterações
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = 'Confirmação de Ação'
          text_question  = 'Deseja salvar modificações?'
          text_button_1  = 'Sim'
          text_button_2  = 'Não'
          default_button = '2'
        IMPORTING
          answer         = lv_pop
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.

      " Verifica retorno da function module
      IF sy-subrc = 0.

        CASE lv_pop.

          WHEN '1'.
            " Usuário confirmou o salvamento
            MODIFY ztb_func FROM ls_func.

            IF sy-subrc = 0.
              COMMIT WORK.
              MESSAGE s003(zmsg_coffee). " Funcionário alterado com sucesso

              CLEAR p_idfunc.
              CLEAR p_nome.

              LEAVE TO SCREEN 0.
            ELSE.
              ROLLBACK WORK.
              MESSAGE s004(zmsg_coffee). " Funcionário não encontrado
            ENDIF.

          WHEN '2'.
            " Usuário cancelou a ação
            MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

          WHEN 'A'.
            " Popup fechado sem seleção
            " Nenhuma ação executada
        ENDCASE.

      ELSEIF sy-subrc = 2.
        " Erro inesperado na chamada da function module
        " Nenhum tratamento adicional definido
      ENDIF.

      " Limpa variável de controle
      CLEAR lv_pop.

    WHEN 'BACK'.
      " Retorno sem salvar alterações
      MESSAGE 'Nenhuma alteração realizada' TYPE 'I'.

      CLEAR p_idfunc.
      CLEAR p_nome.

      LEAVE TO SCREEN 0.

  ENDCASE.

ENDMODULE.
