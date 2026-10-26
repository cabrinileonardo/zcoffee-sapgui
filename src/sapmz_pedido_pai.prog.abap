MODULE pai_1000 INPUT.

  CASE ok_code.
    WHEN 'BACK' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CLICK'.
      CASE 'X'.
        WHEN 'RAD1'.
          PERFORM f_criar_pedido.
        WHEN 'RAD2'.
          PERFORM f_modificar_pedido.
        WHEN 'RAD3'.
          PERFORM f_vizualizar_pedido.
      ENDCASE.
  ENDCASE.


ENDMODULE.


MODULE pai_9000 INPUT.
  CASE ok_code.
    WHEN 'SAVE'.
      PERFORM gravar_pedido.
      CLEAR ok_code.
    WHEN 'CANC'.
      PERFORM cancelar_pedido.
      CLEAR ok_code.
    WHEN 'BACK' OR 'EXIT'.
      PERFORM sair_do_programa.
    WHEN 'ADD_ITEM' OR 'DEL_ITEM'.
      PERFORM manipular_item_alv USING ok_code.
    WHEN OTHERS.
      CLEAR ok_code.
  ENDCASE.
  CLEAR sy-ucomm.
ENDMODULE.
