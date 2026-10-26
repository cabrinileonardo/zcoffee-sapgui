*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo  : Chamar a tela 0200
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_criar_pedido.

  "Limpa estruturas e tabelas internas
  CLEAR: gs_ped,
         gs_itens.
  CLEAR gt_itens.

  "Define modo de criação
  gd_mode = 'C'.

  "-------------------------------------------------------------*
  " Geração do ID do pedido
  "-------------------------------------------------------------*
  IF gs_ped-id_ped IS INITIAL.
    PERFORM f_gerar_id_por_max
      CHANGING gs_ped-id_ped.
  ENDIF.

  PERFORM f_show_alv_itens.

  "Chama tela de manutenção do pedido
  CALL SCREEN 0200.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Chamar a tela de edição do pedido
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_editar_pedido.

  gd_mode = 'E'.

  CALL SCREEN 0300.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Salvar cabeçalho e itens do pedido
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_salvar_pedido.

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA lv_salvou TYPE abap_bool VALUE abap_false.

  "-------------------------------------------------------------*
  " 1. Validação de campos obrigatórios
  "-------------------------------------------------------------*
  IF gs_ped-id_cliente IS INITIAL.
    MESSAGE 'Preencha o código do cliente.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_ped-id_func IS INITIAL.
    MESSAGE 'Preencha o código do funcionário.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_ped-pm IS INITIAL.
    MESSAGE 'Informe a forma de pagamento.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gt_itens IS INITIAL.
    MESSAGE 'O pedido deve possuir ao menos um item.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 2. Validação de estoque (antes de gravar qualquer dado)
  "-------------------------------------------------------------*
  DATA lv_ok TYPE abap_bool.

  PERFORM f_validar_estoque CHANGING lv_ok.
  IF lv_ok = abap_false.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 3. Cálculo do valor total do pedido
  "-------------------------------------------------------------*
  PERFORM f_calcular_valor_total.

  "-------------------------------------------------------------*
  " 4. Salvamento do cabeçalho
  "-------------------------------------------------------------*
  IF gs_ped-id_ped IS INITIAL.
    PERFORM f_gerar_id_por_max CHANGING gs_ped-id_ped.
  ENDIF.

  PERFORM salvar_cabecalho_db CHANGING lv_salvou.
  IF lv_salvou = abap_false.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 5. Salvamento dos itens
  "-------------------------------------------------------------*
  PERFORM salvar_itens_db CHANGING lv_salvou.
  IF lv_salvou = abap_false.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 5.1 Atualização do estoque
  "-------------------------------------------------------------*
  DATA: lv_ok_estoque TYPE abap_bool.

  PERFORM f_atualizar_estoque CHANGING lv_ok_estoque.
  IF lv_ok_estoque = abap_false.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 6. Finalização da transação
  "-------------------------------------------------------------*
  COMMIT WORK.

  " Limpa buffers e estruturas
  CLEAR: gt_ped,
         gt_itens,
         gs_ped,
         gs_itens.

  " Mensagem de sucesso
  MESSAGE 'Pedido salvo com sucesso!' TYPE 'S'.

  IF go_alv IS BOUND.
    go_alv->refresh_table_display( ).
  ENDIF.

  " Reseta modo e retorna ao menu principal
  CLEAR gd_mode.
  LEAVE TO SCREEN 0100.

ENDFORM.


FORM f_atualizar_estoque CHANGING cv_ok TYPE abap_bool.

  DATA: lv_sucesso TYPE char1.

  LOOP AT gt_itens INTO gs_itens.

    CALL FUNCTION 'ZF_ATUALIZA_ESTOQUE_'
      EXPORTING
        iv_id_prod             = gs_itens-id_prod
        iv_qtde_vendida        = gs_itens-qtde
      IMPORTING
        ev_sucesso             = lv_sucesso
      EXCEPTIONS
        estoque_insuficiente   = 1
        produto_nao_encontrado = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0 OR lv_sucesso <> 'X'.
      cv_ok = abap_false.
      MESSAGE 'Erro ao atualizar estoque. Operação cancelada' TYPE 'E'.
      EXIT.
    ENDIF.

  ENDLOOP.

  cv_ok = abap_true.

ENDFORM.

*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Validar o estoque disponível
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_validar_estoque CHANGING pv_ok TYPE abap_bool.

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA: lv_estoque_atual TYPE ztb_prod-qtde_estoque.

  " Inicializa retorno
  CLEAR sy-subrc.

  "-------------------------------------------------------------*
  " Validação item a item
  "-------------------------------------------------------------*
  LOOP AT gt_itens INTO gs_itens.

    "-----------------------------------------------------------*
    " 1. Busca o estoque atual do produto
    "-----------------------------------------------------------*
    SELECT SINGLE qtde_estoque
      INTO @lv_estoque_atual
      FROM ztb_prod
      WHERE id_prod = @gs_itens-id_prod.

    IF sy-subrc <> 0.
      " Produto sem cadastro de estoque
      MESSAGE |Produto { gs_itens-id_prod } sem cadastro de estoque.|
        TYPE 'S' DISPLAY LIKE 'E'.
      sy-subrc = 4.
      RETURN.
    ENDIF.

    "-----------------------------------------------------------*
    " 2. Verifica se a quantidade solicitada excede o estoque
    "-----------------------------------------------------------*
    IF gs_itens-qtde > lv_estoque_atual.
      MESSAGE |Estoque insuficiente ({ lv_estoque_atual }) para o produto { gs_itens-id_prod }.|
        TYPE 'S' DISPLAY LIKE 'E'.

      " Posiciona o cursor no campo de quantidade do item com erro
      SET CURSOR FIELD 'GS_ITENS-QTDE' LINE sy-tabix.

      sy-subrc = 8.
      RETURN.
    ENDIF.

  ENDLOOP.

  pv_ok = abap_true.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Gerar um id automático por SELECT MAX
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_gerar_id_por_max
  CHANGING cv_id TYPE ztb_ped-id_ped.

  DATA lv_max TYPE ztb_ped-id_ped.

  SELECT MAX( id_ped )
    INTO @lv_max
    FROM ztb_ped.

  IF lv_max IS INITIAL.
    cv_id = '0000000001'.
  ELSE.
    cv_id = lv_max + 1.
    cv_id = |{ cv_id ALPHA = IN }|.
  ENDIF.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Calcular o valor total do pedido
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_calcular_valor_total.

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA lv_total TYPE ztb_ped-valor_total.

  " Inicializa acumulador
  CLEAR lv_total.

  "-------------------------------------------------------------*
  " 1. Percorre itens do pedido e acumula valores
  "-------------------------------------------------------------*
  LOOP AT gt_itens INTO DATA(ls_item).
    lv_total += ls_item-valor_item.
  ENDLOOP.

  "-------------------------------------------------------------*
  " 2. Atualiza valor total no cabeçalho do pedido
  "-------------------------------------------------------------*
  gs_ped-valor_total = lv_total.

ENDFORM. " f_calcular_valor_total


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Salvar cabeçalho no banco de dados
* Parâmetros: CHANGING p_lv_salvou TYPE abap_bool
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM salvar_cabecalho_db CHANGING p_lv_salvou TYPE abap_bool.

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA ls_ped TYPE ztb_ped.

  " Inicializa flag de salvamento
  p_lv_salvou = abap_false.

  " Copia dados do pedido para estrutura local
  MOVE-CORRESPONDING gs_ped TO ls_ped.

  "-------------------------------------------------------------*
  " Inserção ou atualização do cabeçalho do pedido
  "-------------------------------------------------------------*
  IF gd_mode = 'C'.

    " Inserção de novo pedido
    INSERT ztb_ped FROM ls_ped.

    IF sy-subrc = 0.
      " Inserção realizada com sucesso
      p_lv_salvou = abap_true.
    ELSE.
      " Erro inesperado durante a inserção
      MESSAGE 'Erro ao salvar o cabeçalho do pedido no DB.'
        TYPE 'S' DISPLAY LIKE 'E'.
      ROLLBACK WORK.   " Desfaz a tentativa de INSERT
    ENDIF.

  ENDIF.

ENDFORM. " salvar_cabecalho_db


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Salvar itens do pedido no banco de dados
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM salvar_itens_db CHANGING ev_ok TYPE abap_bool.

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA: ls_pedit    TYPE ztb_pedit,
        lt_db_itens TYPE TABLE OF ztb_pedit,
        ls_db_item  TYPE ztb_pedit.

  ev_ok = abap_false.

  "-------------------------------------------------------------*
  " Loop nos itens da tela (INSERT ou UPDATE)
  "-------------------------------------------------------------*
  LOOP AT gt_itens INTO gs_itens.

    gs_itens-id_ped = gs_ped-id_ped.
    MOVE-CORRESPONDING gs_itens TO ls_pedit.

    IF gd_mode = 'C'.

      " CREATE → sempre INSERT
      INSERT ztb_pedit FROM ls_pedit.
      IF sy-subrc <> 0.
        MESSAGE 'Erro ao inserir item do pedido.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
    ENDIF.

  ENDLOOP.

  "-------------------------------------------------------------*
  " Se chegou até aqui, deu tudo certo
  "-------------------------------------------------------------*
  ev_ok = abap_true.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Adicionar itens na lista
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_adicionar_item.

  FIELD-SYMBOLS: <fs_item> LIKE LINE OF gt_itens.

  "-------------------------------------------------------------*
  " 1. Validações
  "-------------------------------------------------------------*
  IF gs_itens-id_prod IS INITIAL.
    MESSAGE 'Informe o produto.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_itens-qtde IS INITIAL OR gs_itens-qtde <= 0.
    MESSAGE 'Quantidade inválida.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 2. Cálculo do valor do item
  "-------------------------------------------------------------*
  CALL FUNCTION 'ZF_CALCULA_TOTAL_'
    EXPORTING
      iv_preco      = gs_itens-preco_unit
      iv_qtde       = gs_itens-qtde
    IMPORTING
      ev_valor_item = gs_itens-valor_item
    EXCEPTIONS
      qtde_negativa = 1
      OTHERS        = 2.

  IF sy-subrc = 1.
    MESSAGE 'Informe uma quantidade maior que 0!' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 3. Inclusão ou edição de item conforme regra de negócio
  "-------------------------------------------------------------*
  IF gv_edit_mode = abap_true.
    " EDIÇÃO: altera SOMENTE a linha selecionada
    MODIFY gt_itens FROM gs_itens INDEX gv_edit_index.
    gv_edit_mode = abap_false.
    CLEAR gv_edit_index.

  ELSE.
    " INCLUSÃO: agrupa por produto
    READ TABLE gt_itens ASSIGNING <fs_item>
      WITH KEY id_prod = gs_itens-id_prod.

    IF sy-subrc = 0.
      " Produto já existe → soma quantidade
      <fs_item>-qtde       = <fs_item>-qtde + gs_itens-qtde.
      <fs_item>-valor_item = <fs_item>-qtde * <fs_item>-preco_unit.
    ELSE.
      " Produto novo
      APPEND gs_itens TO gt_itens.
    ENDIF.
  ENDIF.

  "-------------------------------------------------------------*
  " 4. Limpa campos de entrada
  "-------------------------------------------------------------*
  CLEAR: gs_itens-id_prod,
         gs_itens-nome_prod,
         gs_itens-qtde,
         gs_itens-preco_unit,
         gs_itens-valor_item.

  PERFORM f_calcular_valor_total.

  "-------------------------------------------------------------*
  " 5. Atualiza exibição do ALV
  "-------------------------------------------------------------*
  IF go_alv IS BOUND.
    go_alv->refresh_table_display( ).
  ENDIF.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Exibir alv de itens
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_show_alv_itens.

  "---------------------------------------------------------------"
  " Declarações locais
  "---------------------------------------------------------------"
  DATA: ls_stable TYPE lvc_s_stbl.

  "---------------------------------------------------------------"
  " Construção do Field Catalog (definição das colunas do ALV)
  "---------------------------------------------------------------"
  CLEAR gt_fieldcat.

  gs_fieldcat-fieldname = 'ID_PED'.
  gs_fieldcat-col_pos   = '1'.
  gs_fieldcat-scrtext_l = 'Código do pedido'.
  gs_fieldcat-no_out    = abap_true.   " Oculta coluna no ALV
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'ID_PROD'.
  gs_fieldcat-col_pos   = '2'.
  gs_fieldcat-scrtext_l = 'Código do produto'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'NOME_PROD'.
  gs_fieldcat-col_pos   = '3'.
  gs_fieldcat-scrtext_l = 'Nome do produto'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'PRECO_UNIT'.
  gs_fieldcat-col_pos   = '4'.
  gs_fieldcat-scrtext_l = 'Preço do produto'.
  gs_fieldcat-do_sum    = abap_false.
  gs_fieldcat-just      = 'R'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'QTDE'.
  gs_fieldcat-col_pos   = '5'.
  gs_fieldcat-scrtext_l = 'Quantidade Pedida'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'MOEDA'.
  gs_fieldcat-col_pos   = '6'.
  gs_fieldcat-scrtext_l = 'Moeda'.
  gs_fieldcat-no_out    = abap_true.   " Oculta coluna no ALV
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'VALOR_ITEM'.
  gs_fieldcat-col_pos   = '7'.
  gs_fieldcat-scrtext_l = 'Valor do item'.
  gs_fieldcat-just      = 'R'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR gs_fieldcat.

  gs_layout-zebra = 'X'.
  gs_layout-sel_mode = 'A'.

  "---------------------------------------------------------------"
  " Criação do container e objeto ALV
  "---------------------------------------------------------------"
  IF go_alv IS INITIAL.

    TRY.
        CREATE OBJECT go_cont
          EXPORTING
            container_name = 'CC_ALVGRID'.

        CREATE OBJECT go_alv
          EXPORTING
            i_parent = go_cont.

      CATCH cx_root.
        MESSAGE 'Erro ao criar ALV' TYPE 'E'.
        RETURN.
    ENDTRY.

    go_alv->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_layout
      CHANGING
        it_outtab       = gt_itens
        it_fieldcatalog = gt_fieldcat
    ).

  ELSE.

    ls_stable-row = abap_true.
    ls_stable-col = abap_true.

    go_alv->refresh_table_display(
      EXPORTING
        is_stable = ls_stable
    ).

  ENDIF.


ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Eliminar itens da lista
* Parâmetros: CHANGING lv_salvou TYPE abap_bool
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_eliminar_item .

  DATA: lt_rows TYPE lvc_t_row,
        ls_rows TYPE lvc_s_row.

  DATA ls_item_del TYPE ztb_pedit.

  " Linhas selecionadas
  CALL METHOD go_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE 'Selecione um item para excluir.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_rows INDEX 1.

  " Recupera item
  READ TABLE gt_itens INTO gs_itens INDEX ls_rows-index.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " Se pedido já existe, guarda para excluir no SAVE
  IF gs_ped-id_ped IS NOT INITIAL.
    MOVE-CORRESPONDING gs_itens TO ls_item_del.
    APPEND ls_item_del TO gt_itens_del.
  ENDIF.

  " Remove só da memória
  DELETE gt_itens INDEX ls_rows-index.

  " Atualiza ALV
  CALL METHOD go_alv->refresh_table_display.
  PERFORM f_calcular_valor_total.

ENDFORM.



*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Editar itens da lista
* Parâmetros: CHANGING lv_salvou TYPE abap_bool
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_editar_item .

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA: lt_rows TYPE lvc_t_row,
        ls_rows TYPE lvc_s_row.

  "-------------------------------------------------------------*
  " 1. Obter linhas selecionadas no ALV
  "-------------------------------------------------------------*
  CALL METHOD go_alv->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  "-------------------------------------------------------------*
  " 2. Validação: deve haver exatamente uma linha selecionada
  "-------------------------------------------------------------*
  IF lines( lt_rows ) <> 1.
    MESSAGE 'Selecione exatamente um item.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 3. Recupera índice da linha selecionada
  "-------------------------------------------------------------*
  READ TABLE lt_rows INTO ls_rows INDEX 1.
  gv_edit_index   = ls_rows-index.
  gv_edit_mode    = abap_true.
  gv_loading_edit = abap_true.

  "-------------------------------------------------------------*
  " 4. Carrega dados do item selecionado para edição
  "-------------------------------------------------------------*
  READ TABLE gt_itens INTO gs_itens INDEX gv_edit_index.

  " Finaliza flag de carregamento
  gv_loading_edit = abap_false.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Recaucular valor do item
* Parâmetros: CHANGING lv_salvou TYPE abap_bool
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_recalcular_item.

  "-------------------------------------------------------------*
  " Declarações locais
  "-------------------------------------------------------------*
  DATA ls_prod TYPE ztb_prod.

  "-------------------------------------------------------------*
  " 1. Valida produto
  "-------------------------------------------------------------*
  IF gs_itens-id_prod IS INITIAL.
    MESSAGE 'Informe o produto.' TYPE 'I'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 2. Valida quantidade
  "-------------------------------------------------------------*
  IF gs_itens-qtde IS INITIAL OR gs_itens-qtde <= 0.
    MESSAGE 'Informe uma quantidade válida.' TYPE 'I'.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 3. Busca dados do produto
  "-------------------------------------------------------------*
  SELECT SINGLE nome_prod, preco
    INTO ( @gs_itens-nome_prod, @gs_itens-preco_unit )
    FROM ztb_prod
    WHERE id_prod = @gs_itens-id_prod.

  IF sy-subrc <> 0.
    MESSAGE 'Produto não encontrado.' TYPE 'E'.
    CLEAR: gs_itens-nome_prod,
           gs_itens-preco_unit,
           gs_itens-valor_item.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 4. Calcula valor do item
  "-------------------------------------------------------------*
  gs_itens-valor_item = gs_itens-preco_unit * gs_itens-qtde.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Salvar cabeçalho e itens do pedido
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_show_alv_cabecalho.

  SELECT a~id_ped,
   a~id_cliente,
   b~nome_cli   AS nome_cliente,
   a~data_ped,
   a~hora_ped,
   a~valor_total,
   a~status_ped,
   c~ddtext     AS status_desc,
   a~pm,
   f~descricao  AS pm_desc,
   a~id_func,
   e~nome       AS nome_func,
   a~moeda
FROM ztb_ped AS a
INNER JOIN ztb_clientes AS b
ON a~id_cliente = b~id_cliente
INNER JOIN dd07t AS c
ON c~ddlanguage = @sy-langu
AND c~domvalue_l = a~status_ped
AND c~domname    = 'ZSTATUS_PED_D'
LEFT JOIN ztb_pagamento AS f
ON a~pm = f~id
INNER JOIN ztb_func AS e
ON a~id_func = e~id_func
INTO CORRESPONDING FIELDS OF TABLE @gt_ped.

  CLEAR gs_sort.
  gs_sort-fieldname = 'ID_PED'.
  gs_sort-up        = abap_true.   " ASC
  gs_sort-spos      = 1.
  APPEND gs_sort TO gt_sort.


  DATA i TYPE i.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'ID_PED'.
  gs_fieldcat2-scrtext_l = 'Código do pedido'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'ID_CLIENTE'.
  gs_fieldcat2-scrtext_l = 'Código do Cliente'.
  gs_fieldcat2-no_out = 'X'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'NOME_CLIENTE'.
  gs_fieldcat2-scrtext_l = 'Cliente'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'DATA_PED'.
  gs_fieldcat2-scrtext_l = 'Data do pedido'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'HORA_PED'.
  gs_fieldcat2-scrtext_l = 'Hora do pedido'.
  gs_fieldcat2-no_out = 'X'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'VALOR_TOTAL'.
  gs_fieldcat2-scrtext_l = 'Valor Total'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'STATUS_PED'.
  gs_fieldcat2-no_out = 'X'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'STATUS_DESC'.
  gs_fieldcat2-scrtext_l = 'Status'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'PM_DESC'.
  gs_fieldcat2-scrtext_l = 'Forma de pagamento'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'ID_FUNC'.
  gs_fieldcat2-no_out = 'X'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'NOME_FUNC'.
  gs_fieldcat2-scrtext_l = 'Funcionário'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'MOEDA'.
  gs_fieldcat2-no_out = 'X'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  i = i + 1.
  gs_fieldcat2-col_pos = i.
  gs_fieldcat2-fieldname = 'USUARIO'.
  gs_fieldcat2-no_out = 'X'.
  APPEND gs_fieldcat2 TO gt_fieldcat2.
  CLEAR: gs_fieldcat2.

  "--------------------------------------------------*
  " Container e ALV
  "--------------------------------------------------*
  IF go_cont2 IS NOT BOUND.
    CREATE OBJECT go_cont2
      EXPORTING
        container_name = 'CC_ALV_PED'.

    CREATE OBJECT go_alv2
      EXPORTING
        i_parent = go_cont2.

    gs_layout2-sel_mode   = 'A'.
    gs_layout2-cwidth_opt = abap_true.
    gs_layout2-zebra      = abap_true.

    go_alv2->set_table_for_first_display(
      EXPORTING
        is_layout        = gs_layout2
      CHANGING
        it_outtab        = gt_ped
        it_fieldcatalog = gt_fieldcat2
        it_sort          = gt_sort ).

  ELSE.
    go_alv2->refresh_table_display( ).
  ENDIF.

ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Buscar pedido selecionado
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_search.
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  IF go_alv2 IS BOUND.
    go_alv2->get_selected_rows(
      IMPORTING et_index_rows = lt_rows
    ).

    IF lt_rows IS INITIAL.
      MESSAGE 'Selecione ao menos uma linha'
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    READ TABLE lt_rows INTO ls_row INDEX 1.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SORT gt_ped BY id_ped ASCENDING.

    READ TABLE gt_ped INTO gs_ped INDEX ls_row-index.

    IF sy-subrc <> 0.
      MESSAGE 'Erro ao buscar pedido' TYPE 'E'.
      RETURN.
    ENDIF.

    PERFORM f_carregar_pedido USING gs_ped-id_ped.

    CALL SCREEN 0200.
  ENDIF.
ENDFORM.


*----------------------------------------------------------------------*
* Form  f_salvar_pedido
* Objetivo : Carregar itens do pedido selecionado
* Autor     : Leonardo
* Data      : 22.01.2026
*----------------------------------------------------------------------*
FORM f_carregar_pedido USING pv_id_ped TYPE zid_ped.

  CLEAR: gt_itens.

  " Cabeçalho
  SELECT SINGLE *
    FROM ztb_ped
    INTO CORRESPONDING FIELDS OF @gs_ped
    WHERE id_ped = @pv_id_ped.

  IF sy-subrc <> 0.
    MESSAGE | Pedido { gs_ped-id_ped } não existe| TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  SELECT a~id_ped,
         a~id_prod,
         b~nome_prod,
         b~preco     AS preco_unit,
         a~qtde,
         a~valor_item,
         a~moeda
    FROM ztb_pedit AS a
    INNER JOIN ztb_prod AS b
      ON b~id_prod = a~id_prod
    INTO TABLE @gt_itens
    WHERE a~id_ped = @pv_id_ped.

  "-------------------------------------------------------------*
  " 3. Validação: pedido sem itens
  "-------------------------------------------------------------*
  IF gt_itens IS INITIAL.
    MESSAGE | Pedido { gs_ped-id_ped } não possui itens | TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

ENDFORM. " f_carregar_itens


FORM f_modificar_pedido .

  DATA: ls_ped   TYPE ztb_ped,
        ls_itens TYPE ztb_pedit.

  "Validações iniciais
  IF gs_ped-id_cliente IS INITIAL.
    MESSAGE 'Preencha o código do cliente.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_ped-id_func IS INITIAL.
    MESSAGE 'Preencha o código do funcionário.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gs_ped-pm IS INITIAL.
    MESSAGE 'Informe a forma de pagamento.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gt_itens IS INITIAL.
    MESSAGE 'O pedido deve possuir ao menos um item.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "Validação de estoque suficiente
  DATA lv_ok TYPE abap_bool.

  PERFORM f_validar_estoque CHANGING lv_ok.
  IF lv_ok = abap_false.
    RETURN.
  ENDIF.

  "Calculo do valor total do pedido
  PERFORM f_calcular_valor_total.

  "--------------------------------------------------*
  " Atualiza cabeçalho do pedido
  "--------------------------------------------------*
  MOVE-CORRESPONDING gs_ped TO ls_ped.

  MODIFY ztb_ped FROM ls_ped.
  IF sy-subrc <> 0.
    MESSAGE |Erro ao modificar pedido { gs_ped-id_ped }| TYPE 'E'.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  "--------------------------------------------------*
  " Excluir itens removidos pelo usuário
  "--------------------------------------------------*
  DATA ls_itens_del TYPE ztb_pedit.

  MOVE-CORRESPONDING gs_itens TO ls_itens_del.

  LOOP AT gt_itens_del INTO ls_itens_del.

    DELETE FROM ztb_pedit
      WHERE id_ped  = gs_ped-id_ped
        AND id_prod = ls_itens_del-id_prod.

    IF sy-dbcnt = 0.
      MESSAGE |Erro ao excluir item { gs_itens-id_ped } do pedido| TYPE 'E'.
      ROLLBACK WORK.
      RETURN.
    ENDIF.

  ENDLOOP.

  CLEAR gt_itens_del.

  "--------------------------------------------------*
  " Atualiza itens do pedido
  "--------------------------------------------------*
  LOOP AT gt_itens INTO gs_itens.

    gs_itens-id_ped = gs_ped-id_ped.

    MOVE-CORRESPONDING gs_itens TO ls_itens.

    MODIFY ztb_pedit FROM ls_itens.
    IF sy-subrc <> 0.
      MESSAGE |Erro ao modificar item do pedido { gs_ped-id_ped }| TYPE 'E'.
      ROLLBACK WORK.
      RETURN.
    ENDIF.

    CLEAR ls_itens.

  ENDLOOP.

  "-------------------------------------------------------------*
  " 5.1 Atualização do estoque
  "-------------------------------------------------------------*
  DATA: lv_ok_estoque TYPE abap_bool.

  PERFORM f_atualizar_estoque CHANGING lv_ok_estoque.
  IF lv_ok_estoque = abap_false.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  "--------------------------------------------------*
  " Commit final (tudo OK)
  "--------------------------------------------------*
  COMMIT WORK.

  MESSAGE |Pedido { gs_ped-id_ped } salvo com sucesso!| TYPE 'S'.

  " Limpa buffers e estruturas
  CLEAR: gt_ped,
         gt_itens,
         gs_ped,
         gs_itens, gs_itens-id_ped, gs_itens-id_prod, gs_itens-moeda, gs_itens-nome_prod, gs_itens-preco_unit, gs_itens-qtde, gs_itens-valor_item.

  IF go_alv IS BOUND.
    go_alv->refresh_table_display( ).
  ENDIF.

  PERFORM f_show_alv_cabecalho.

  " Reseta modo e retorna ao menu principal
  CLEAR: gd_mode.

  IF gv_externo = abap_true.
    LEAVE TO TRANSACTION 'ZSDMP' AND SKIP FIRST SCREEN.
*    LEAVE TO SCREEN 0.
  ENDIF.
  CLEAR gv_externo.
  LEAVE TO SCREEN 0.

ENDFORM.
