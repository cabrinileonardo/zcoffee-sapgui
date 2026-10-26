MODULE pai_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'SAVE'.
     MODIFY ztb_prod FROM wa_prod.
            IF sy-subrc = 0.
              COMMIT WORK.
              MESSAGE 'Itens inseridos com sucesso' TYPE 'S'.
              LEAVE TO SCREEN 0.
            ELSE.
              ROLLBACK WORK.
              MESSAGE 'Falha em inserir itens' TYPE 'S' DISPLAY LIKE 'E'.
            ENDIF.
  ENDCASE.

ENDMODULE.
