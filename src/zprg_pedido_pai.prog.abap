*---------------------------------------------------------------------*
* PAI – Tela 2000
*---------------------------------------------------------------------*
* Responsável por:
* - Tratar ações do usuário (Salvar / Voltar / Cancelar / Sair)
* - Confirmar ações críticas
*---------------------------------------------------------------------*
MODULE pai_2000 INPUT.

  CASE gd_okcode.

    WHEN 'SAVE'.
      "-----------------------------------------------------------*
      " Confirmação de salvamento do pedido
      "-----------------------------------------------------------*
      PERFORM f_confirmar
        USING    'Confirmação de Ação'
                 'Deseja salvar pedido?'
                 'Sim'
                 'Não'
        CHANGING gd_resposta.

      CASE gd_resposta.
        WHEN '1'.
          " Usuário confirmou o salvamento
          PERFORM f_salvar_pedido.

        WHEN '2'.
          " Usuário cancelou a ação
          MESSAGE 'Ação cancelada pelo usuário.' TYPE 'I'.

        WHEN 'A'.
          " Janela fechada sem escolha explícita
      ENDCASE.

    WHEN 'BACK' OR 'CANC' OR 'EXIT'.
      " Retorno / cancelamento da tela
      PERFORM f_leave_screen.

    WHEN 'CRIAR'.
      CALL TRANSACTION 'ZCLIENTES' AND SKIP FIRST SCREEN.
  ENDCASE.

ENDMODULE.


*---------------------------------------------------------------------*
* PAI – Preenchimento automático de funcionário e cliente
*---------------------------------------------------------------------*
* Responsável por:
* - Buscar dados do funcionário a partir do ID
* - Buscar dados do cliente a partir do ID
* - Preencher nome e CPF automaticamente
*---------------------------------------------------------------------*
MODULE id_and_name_fill_ped INPUT.

  DATA: ls_func    TYPE ztb_func,
        ls_cliente TYPE ztb_clientes.

  "-------------------------------------------------------------*
  " Funcionário
  "-------------------------------------------------------------*
  IF gs_ped-id_func IS NOT INITIAL.

    " Busca o funcionário informado
    SELECT SINGLE nome
      INTO @ls_func-nome
      FROM ztb_func
      WHERE id_func = @gs_ped-id_func.

    IF sy-subrc = 0.
      " Funcionário encontrado
      gs_ped-nome_func = ls_func-nome.
    ELSE.
      " Funcionário não encontrado
      CLEAR gs_ped-nome_func.
      MESSAGE 'Funcionário não encontrado!' TYPE 'I'.
    ENDIF.

  ELSE.
    CLEAR gs_ped-nome_func.
  ENDIF.

  "-------------------------------------------------------------*
  " Cliente
  "-------------------------------------------------------------*
  IF gs_ped-id_cliente IS NOT INITIAL.

    " Busca o cliente informado
    SELECT SINGLE nome_cli, cpf
      INTO ( @ls_cliente-nome_cli, @ls_cliente-cpf )
      FROM ztb_clientes
      WHERE id_cliente = @gs_ped-id_cliente.

    IF sy-subrc = 0.
      " Cliente encontrado
      gs_ped-nome_cliente = ls_cliente-nome_cli.
      gs_ped-cpf          = ls_cliente-cpf.
    ELSE.
      " Cliente não encontrado
      CLEAR: gs_ped-nome_cliente, gs_ped-cpf.
      MESSAGE 'Cliente não encontrado!' TYPE 'I'.
    ENDIF.

  ELSE.
    CLEAR: gs_ped-nome_cliente, gs_ped-cpf.
  ENDIF.

ENDMODULE.


*---------------------------------------------------------------------*
* PAI – Preenchimento automático do item do pedido (TC)
*---------------------------------------------------------------------*
* Responsável por:
* - Buscar dados do produto
* - Preencher nome e preço unitário
* - Controlar status do item (Novo / Existente)
* - Recalcular o valor total do pedido
*---------------------------------------------------------------------*
MODULE id_and_name_fill_tc INPUT.

  DATA: ls_prod TYPE ztb_prod.

  " Limpa valores calculados antes de nova validação
  CLEAR: gs_est_pedit-nome_prod,
         gs_est_pedit-preco_unit,
         gs_est_pedit-valor_item.

  "-------------------------------------------------------------*
  " Produto
  "-------------------------------------------------------------*
  IF gs_est_pedit-id_prod IS NOT INITIAL.

    " Busca o produto informado
    SELECT SINGLE nome_prod, preco
      INTO ( @gs_est_pedit-nome_prod,
             @gs_est_pedit-preco_unit )
      FROM ztb_prod
      WHERE id_prod = @gs_est_pedit-id_prod.

    IF sy-subrc = 0.
      " Produto encontrado
      IF gs_est_pedit-gd_status IS INITIAL.
        gs_est_pedit-gd_status = 'N'. " Item novo
      ENDIF.
    ELSE.
      " Produto não encontrado
      CLEAR: gs_est_pedit-nome_prod,
             gs_est_pedit-preco_unit,
             gs_est_pedit-valor_item.
      gs_est_pedit-gd_status = ''.
      MESSAGE 'Produto não encontrado!' TYPE 'I'.
    ENDIF.

  ELSE.
    " Produto não informado
    CLEAR: gs_est_pedit-preco_unit,
           gs_est_pedit-nome_prod,
           gs_est_pedit-gd_status.
  ENDIF.

  "-------------------------------------------------------------*
  " Recalcula o valor total do pedido
  "-------------------------------------------------------------*
  PERFORM f_calcular_valor_total.

ENDMODULE.

*---------------------------------------------------------------------*
* PAI – Tela 3100
*---------------------------------------------------------------------*
* Responsável por:
* - Buscar pedido para edição
* - Controlar saída do programa
*---------------------------------------------------------------------*
MODULE pai_3100 INPUT.

  CASE gd_okcode.

    WHEN 'SEARCH'.
      " Verifica se o ID do pedido foi informado
      IF gd_id_ped IS INITIAL.
        MESSAGE 'Informe o ID do pedido que deseja alterar.' TYPE 'I'.
        EXIT.
      ELSE.
        " Carrega os dados do pedido e navega para a tela principal
        PERFORM carregar_dados.
        CALL SCREEN 2000.
      ENDIF.

    WHEN 'BACK' OR 'CANC'.
      PERFORM f_leave_screen.

    WHEN 'EXIT'.
      " Confirmação de saída do programa
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

  ENDCASE.

ENDMODULE.
