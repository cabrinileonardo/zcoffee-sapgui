MODULE pbo_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE pai_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'EXEC'.  "Botão de executar
      gs_funcionario-data_adm = sy-datum.
      IF rad1 = 'X'.
        gs_funcionario-atividade = '1'.
        CALL SCREEN 9000.
      ELSEIF rad3 = 'X'.
        CALL SCREEN 9001.
      ELSEIF rad2 = 'X'.
        gs_funcionario-atividade = '1'.
        CALL SCREEN 9002.
      ELSEIF rad4 = 'X'.
        gs_funcionario-atividade = '9'.
        CALL SCREEN 90.
      ELSE.
        MESSAGE 'Selecione uma opção antes de continuar!' TYPE 'E' DISPLAY LIKE 'S'.
      ENDIF.
    WHEN 'BACK'.  "Botão de voltar/sair
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.
