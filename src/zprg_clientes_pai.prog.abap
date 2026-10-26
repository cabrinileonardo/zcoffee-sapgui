MODULE pai_9000 INPUT.

  CASE gd_okcode.
    WHEN 'SAVE'.
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja cadastrar o cliente?'
              'Sim'
              'Não'
        CHANGING gd_resposta.

      IF gd_resposta = '1'.

        LEAVE TO SCREEN 0.

      ELSEIF gd_resposta = '2'.
        MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

      ELSEIF gd_resposta = 'A'.
        " Permanece na tela 9000
      ENDIF.

      CLEAR gd_resposta.
    WHEN 'BACK'.
      PERFORM f_confirmar
  USING 'Confirmação de Ação'
        'Deseja Retornar para tela de início?'
        'Sim'
        'Não'
  CHANGING gd_resposta.

      IF gd_resposta = '1'.

        LEAVE TO SCREEN 0.

      ELSEIF gd_resposta = '2'.
        MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

      ELSEIF gd_resposta = 'A'.
        " Permanece na tela 9000
      ENDIF.

      CLEAR gd_resposta.
    WHEN 'EXIT'.
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja sair do programa?'
              'Sim'
              'Não'
        CHANGING gd_resposta.

      IF gd_resposta = '1'.
        LEAVE PROGRAM.
      ELSEIF gd_resposta = '2'.
        MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
      ENDIF.
      CLEAR gd_resposta.
  ENDCASE.

ENDMODULE.

MODULE pai_9001 INPUT.
  CASE gd_okcode.
    WHEN 'SAVE' OR ''.

      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja alterar os dados do cliente?'
              'Sim'
              'Não'
        CHANGING gd_resposta.

      IF sy-subrc = 0.

        CASE gd_resposta.
          WHEN '1'.

            MODIFY ztb_clientes FROM ls_cliente.
            IF sy-subrc = 0.
              COMMIT WORK.
              MESSAGE | Dados do cliente CPF { ls_cliente-cpf } alterados com sucesso!| TYPE 'S'.
              LEAVE TO SCREEN 0.
            ELSE.
              ROLLBACK WORK.
              MESSAGE | Erro em alterar dados do cliente CPF { ls_cliente-cpf }. | TYPE 'S' DISPLAY LIKE 'E'.
            ENDIF.

          WHEN '2'.
            MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
          WHEN 'A'.
        ENDCASE.

      ENDIF.
      CLEAR gd_resposta.

    WHEN 'BACK'.
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja retornar a tela inicial?'
              'Sim'
              'Não'
        CHANGING gd_resposta.

      IF sy-subrc = 0.
        CASE gd_resposta.
          WHEN '1'.
            MESSAGE 'Nenhuma alteração realizada' TYPE 'I'.
            LEAVE TO SCREEN 0.
          WHEN '2'.
            MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
          WHEN 'A'.
        ENDCASE.
      ENDIF.
      CLEAR gd_resposta.

    WHEN 'EXIT'.
      PERFORM f_confirmar
        USING 'Confirmação de Ação'
              'Deseja sair do programa?'
              'Sim'
              'Não'
        CHANGING gd_resposta.

      IF sy-subrc = 0.

        CASE gd_resposta.
          WHEN '1'.
            MESSAGE 'Nenhuma alteração realizada' TYPE 'I'.
            LEAVE PROGRAM.
          WHEN '2'.
            MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.
          WHEN 'A'.
        ENDCASE.
      ENDIF.
      CLEAR gd_resposta.
  ENDCASE.

ENDMODULE.
