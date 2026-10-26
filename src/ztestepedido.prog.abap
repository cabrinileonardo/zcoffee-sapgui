 REPORT ztestepedido.

INCLUDE ztestepedido_top.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: rb_criar RADIOBUTTON GROUP clic DEFAULT 'X',
              rb_list  RADIOBUTTON GROUP clic.
SELECTION-SCREEN END OF BLOCK b1.

INCLUDE ztestepedido_FRM.
INCLUDE ztestepedido_PBO.
INCLUDE zztestepedido_PAI.

START-OF-SELECTION.
  CASE 'X'.
    WHEN rb_criar.
      PERFORM f_criar_pedido.
    WHEN rb_list.
      PERFORM f_listar_pedido.
    WHEN OTHERS.
      MESSAGE 'Selecione uma opção válida' TYPE 'I'.
  ENDCASE.
