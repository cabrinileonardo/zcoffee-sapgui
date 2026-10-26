************************************************************************
* PAI – Tela 0100 (Menu Principal)
************************************************************************
************************************************************************
* PAI – Tela 0100 (Menu Principal)
************************************************************************
MODULE user_command_0100 INPUT.

  DATA lv_confirmado TYPE abap_bool. " Garante instância da classe de confirmação

  IF go_confirmar IS NOT BOUND.
    CREATE OBJECT go_confirmar.
  ENDIF.

  CASE gd_okcode.

      "---------------------------------------------------------------"
      " Sair do programa
      "---------------------------------------------------------------"
    WHEN gc_back OR gc_canc OR gc_exit.
      lv_confirmado = go_confirmar->confirmar(
        iv_text = 'Deseja sair do programa?'
      ).
      IF lv_confirmado = abap_true.
        LEAVE PROGRAM.
      ENDIF.
      CLEAR gd_okcode.

      "---------------------------------------------------------------"
      " Criar pedido
      "---------------------------------------------------------------"
    WHEN 'BTN_CRIAR'.
      gd_mode = 'C'. " Modo criação
      PERFORM f_criar_pedido.

      "---------------------------------------------------------------"
      " Editar pedido
      "---------------------------------------------------------------"
    WHEN 'BTN_EDIT'.
      gd_mode = 'E'. " Modo edição
      PERFORM f_show_alv_cabecalho.
      CALL SCREEN 0300.

  ENDCASE.

ENDMODULE.



************************************************************************
* PAI – Tela 0200 (Criar / Editar Pedido)
************************************************************************
MODULE user_command_0200 INPUT.

  "---------------------------------------------------------------"
  " Garante instância da classe de confirmação
  "---------------------------------------------------------------"
  IF go_confirmar IS NOT BOUND.
    CREATE OBJECT go_confirmar.
  ENDIF.

  CASE gd_okcode.

      "---------------------------------------------------------------"
      " Retornar à tela anterior
      "---------------------------------------------------------------"
    WHEN gc_back OR gc_canc OR gc_exit.
      lv_confirmado = go_confirmar->confirmar(
        iv_text = 'Deseja retornar ao menu?'
      ).
      IF lv_confirmado = abap_true.
        MESSAGE 'Pedido Abortado' TYPE 'S' DISPLAY LIKE 'E'.
        CLEAR: gt_itens, gs_ped.
        IF gv_externo = abap_true.
          LEAVE TO TRANSACTION 'ZSDMP' AND SKIP FIRST SCREEN.
          CLEAR gd_idped.
        ENDIF.
        LEAVE TO SCREEN 0.
      ENDIF.
      CLEAR gd_okcode.

      "---------------------------------------------------------------"
      " Salvar pedido
      "---------------------------------------------------------------"
    WHEN 'BTN_SAVE' OR 'SAVE'.

      lv_confirmado = go_confirmar->confirmar(
        iv_text = 'Deseja salvar o pedido?'
      ).

      IF lv_confirmado = abap_true.
        CASE gd_mode.
          WHEN 'C'.
            PERFORM f_salvar_pedido.
          WHEN 'E'.
            PERFORM f_modificar_pedido.
        ENDCASE.
        LEAVE TO SCREEN 0.
      ENDIF.
      CLEAR gd_okcode.


      "---------------------------------------------------------------"
      " Adicionar item ao pedido
      "---------------------------------------------------------------"
    WHEN 'BTN_ADD'.
      PERFORM f_adicionar_item.

      "---------------------------------------------------------------"
      " Cadastro de clientes
      "---------------------------------------------------------------"
    WHEN 'BTN_CLIENTE'.
      CALL TRANSACTION 'ZCLIENTES' AND SKIP FIRST SCREEN.

      "---------------------------------------------------------------"
      " Funcionalidades futuras
      "---------------------------------------------------------------"
    WHEN 'BTN_ELIM'.   " Excluir item
      PERFORM f_eliminar_item.
      CLEAR gd_okcode.

    WHEN 'BTN_EDIT'.
      gv_edit_mode = abap_true.
      PERFORM f_editar_item.
      CLEAR gd_okcode.


    WHEN 'BTN_REFRESH'.   " Recalcular item
      PERFORM f_recalcular_item.

  ENDCASE.

ENDMODULE.


************************************************************************
* Preenchimento automático de nomes (Pedido)
************************************************************************
MODULE id_and_name_fill_ped INPUT.

  DATA: ls_func    TYPE ztb_func,
        ls_cliente TYPE ztb_clientes.

  "---------------------------------------------------------------"
  " Funcionário
  "---------------------------------------------------------------"
  IF gs_ped-id_func IS NOT INITIAL.

    SELECT SINGLE nome
      INTO @ls_func-nome
      FROM ztb_func
      WHERE id_func = @gs_ped-id_func.

    IF sy-subrc = 0.
      gs_ped-nome_func = ls_func-nome.
    ELSE.
      CLEAR gs_ped-nome_func.
      MESSAGE 'Funcionário não encontrado!' TYPE 'I'.
    ENDIF.

  ELSE.
    CLEAR gs_ped-nome_func.
  ENDIF.

  "---------------------------------------------------------------"
  " Cliente
  "---------------------------------------------------------------"
  IF gs_ped-id_cliente IS NOT INITIAL.

    SELECT SINGLE nome_cli
      INTO @ls_cliente-nome_cli
      FROM ztb_clientes
      WHERE id_cliente = @gs_ped-id_cliente.

    IF sy-subrc = 0.
      gs_ped-nome_cliente = ls_cliente-nome_cli.
    ELSE.
      CLEAR gs_ped-nome_cliente.
      MESSAGE 'Cliente não encontrado!' TYPE 'I'.
    ENDIF.

  ELSE.
    CLEAR gs_ped-nome_cliente.
  ENDIF.

ENDMODULE.


************************************************************************
* Preenchimento automático de dados do produto
************************************************************************
MODULE id_name_preco_prod INPUT.

  "Se estiver editando item, NÃO recalcula produto/preço
  IF gv_edit_mode = abap_true AND gv_loading_edit = abap_false.
    RETURN.
  ENDIF.


  DATA ls_prod TYPE zest_itens.

  IF gs_itens-id_prod IS NOT INITIAL.

    SELECT SINGLE nome_prod, preco
      INTO ( @ls_prod-nome_prod, @ls_prod-preco_unit )
      FROM ztb_prod
      WHERE id_prod = @gs_itens-id_prod.

    IF sy-subrc = 0.
      gs_itens-nome_prod  = ls_prod-nome_prod.
      gs_itens-preco_unit = ls_prod-preco_unit.
    ELSE.
      CLEAR: gs_itens-nome_prod,
             gs_itens-preco_unit.
      MESSAGE 'Produto não encontrado!' TYPE 'I'.
    ENDIF.

  ELSE.
    CLEAR: gs_itens-nome_prod,
           gs_itens-preco_unit.
  ENDIF.

ENDMODULE.



************************************************************************
* Cálculo do valor total do item
************************************************************************
MODULE calcula_item INPUT.

  CALL FUNCTION 'ZF_CALCULA_TOTAL_'
    EXPORTING
      iv_preco      = gs_itens-preco_unit
      iv_qtde       = gs_itens-qtde
    IMPORTING
      ev_valor_item = gs_itens-valor_item
    EXCEPTIONS
      qtde_negativa = 1
      OTHERS        = 2.

  CASE sy-subrc.
    WHEN 1.
      MESSAGE 'Informe uma quantidade maior que 0!' TYPE 'I'.
    WHEN OTHERS.
      "Tratamento genérico (log / mensagem futura)
  ENDCASE.

  SET CURSOR FIELD 'BTN_REFRESH'.

ENDMODULE.

MODULE user_command_0300 INPUT.
  CASE gd_okcode.

    WHEN gc_back OR gc_canc OR gc_exit.
      LEAVE TO SCREEN 0.

    WHEN 'SEARCH'.
      PERFORM f_search.

  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0400 INPUT.
  CASE gd_okcode.

    WHEN gc_back OR gc_canc OR gc_exit.
      LEAVE PROGRAM.

    WHEN 'SEARCH'.

  ENDCASE.
ENDMODULE.


MODULE forma_pag INPUT.
  DATA lv_status TYPE zdestatus.

  SELECT status
    FROM ztb_pagamento
    INTO @lv_status
    WHERE id = @gs_ped-pm.
  ENDSELECT.

  IF sy-subrc <> 0.
    MESSAGE 'Pagamento não encontrado' TYPE 'E'.
  ENDIF.

  IF lv_status = 9.
    MESSAGE 'Forma de pagamento inativa' TYPE 'E'.
    CLEAR gs_ped-pm.
    RETURN.
  ENDIF.
ENDMODULE.
