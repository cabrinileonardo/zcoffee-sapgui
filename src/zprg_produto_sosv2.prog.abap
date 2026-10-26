*&---------------------------------------------------------------------*
*& Include          ZPRG_FUNCIONARIO_SOS
*&---------------------------------------------------------------------*

************************************************************************
*& PROCESSAMENTO DE DADOS
************************************************************************


START-OF-SELECTION.


  CASE 'X'.
    WHEN rb_ins.
      PERFORM f_inserir_prod.
    WHEN rb_exi.
      PERFORM f_exibir_prod.
    WHEN rb_alt.
      PERFORM f_alterar_prod.
    WHEN rb_del.
      PERFORM f_deletar_prod.
  ENDCASE.

END-OF-SELECTION.

* Limpa todas as estruturas
  PERFORM f_limpa_tudo.

*&---------------------------------------------------------------------*
*& Inserir Produto
*&---------------------------------------------------------------------*
FORM f_inserir_prod.

  DATA: lv_salvou TYPE abap_bool.
  DATA: lv_id_prod TYPE ztb_prod-id_prod.

  CLEAR ls_prod.

  ls_prod-id_prod  = p_idprod.
  ls_prod-nome_prod = p_nome.

  CALL SCREEN 9000.


  SELECT MAX( id_prod ) FROM ztb_prod INTO lv_id_prod.
  lv_id_prod = lv_id_prod + 1.

  IF lv_id_prod <> ls_prod-id_prod.
    MESSAGE 'O número do produto foi atualizado. Salve novamente.' TYPE 'E'.
    ROLLBACK WORK.
    EXIT.
  ENDIF.

  " 3. Verifica se houve preenchimento/confirmação
  IF ls_prod-nome_prod IS INITIAL.
    MESSAGE 'Inserção de produto abortada ou cancelada.' TYPE 'I'.

  ELSE.

    IF ls_prod-id_prod IS INITIAL.
      PERFORM f_gerar_id_final_number_next CHANGING ls_prod-id_prod.
    ENDIF.

    IF ls_prod-id_prod IS NOT INITIAL.

      INSERT ztb_prod FROM ls_prod.

      IF sy-subrc = 0.
        COMMIT WORK.
        MESSAGE |Produto ID { ls_prod-id_prod } criado com sucesso!| TYPE 'S'.
        lv_salvou = abap_true.
      ELSE.
        ROLLBACK WORK.
        MESSAGE 'Erro ao inserir registro. ID pode já existir ou falha no banco.' TYPE 'E'.
      ENDIF.

    ELSE.
      MESSAGE 'Falha ao gerar ID. Operação cancelada.' TYPE 'E'.
    ENDIF.

  ENDIF.

  IF lv_salvou = abap_true.

    CLEAR p_nome.
    CLEAR p_idprod.

  ENDIF.

ENDFORM. " f_inserir_prod

*&---------------------------------------------------------------------*
*& Form f_obter_id_para_exibir
*&---------------------------------------------------------------------*
*& Usa NUMBER_GET_INFO para obter o próximo ID (não consome o número)
*&---------------------------------------------------------------------*
FORM f_obter_id_para_exibir
  CHANGING cv_proximo_id TYPE ztb_prod-id_prod.


  DATA: ls_nriv TYPE nriv.
  CLEAR cv_proximo_id.

  " Chama a função para ler o status do intervalo de numeração
  CALL FUNCTION 'NUMBER_GET_INFO'
    EXPORTING
      object      = 'Z_ID_PROD_'
      nr_range_nr = '01'
      subobject   = space
      toyear      = '0000'
    IMPORTING
      interval    = ls_nriv
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc = 0.

    cv_proximo_id = ls_nriv-nrlevel + 1.
  ELSE.
    MESSAGE 'Falha ao ler o status do objeto de numeração ZID_PROD_.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_obter_id_para_exibir


*&---------------------------------------------------------------------*
*& Form f_gerar_id_final_number_next
*&---------------------------------------------------------------------*
*& Gerar o ID FINAL (Consome o número do range)
*&---------------------------------------------------------------------*
FORM f_gerar_id_final_number_next
  CHANGING cv_novo_id TYPE ztb_prod-id_prod. " Tipo do campo ID na sua tabela

  DATA: lv_number TYPE n LENGTH 20.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      object      = 'Z_ID_PROD_'
      nr_range_nr = '01'
      quantity    = '1'
      subobject   = space
      toyear      = '0000'
    IMPORTING
      number      = lv_number
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc = 0.

    cv_novo_id = lv_number.
  ELSE.
    MESSAGE 'Erro fatal: Falha ao obter número de range para ZID_PROD_.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_gerar_id_final_number_next

*----------------------------------------------------------------------*
* Sub-rotina para exibir um Pop-up de Confirmação e retornar a resposta *
*----------------------------------------------------------------------*
FORM f_confirmar
  USING
    iv_titulo     TYPE char50  " Título da Janela
    iv_pergunta   TYPE char100 " Texto da Pergunta
    iv_botao1     TYPE char20  " Texto Botão 1 (Ex: Sim)
    iv_botao2     TYPE char20  " Texto Botão 2 (Ex: Não)
  CHANGING
    cv_resposta   TYPE char01. " Resposta (1, 2, A)

  CLEAR cv_resposta.
  CLEAR sy-subrc.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = iv_titulo   " Título genérico
      text_question  = iv_pergunta " Pergunta genérica
      text_button_1  = iv_botao1
      text_button_2  = iv_botao2
      default_button = '1'
    IMPORTING
      answer         = cv_resposta
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.

  IF sy-subrc <> 0 AND sy-subrc <> 2.
    " Tratar outros erros se necessário
    cv_resposta = 'A'.
  ENDIF.

ENDFORM. " f_confirmar


FORM f_exibir_prod.

  DATA(lv_ativo) = COND #( WHEN p_ativo = 'X' THEN '1' ELSE '9' ).

  SELECT a~id_prod,
         a~nome_prod,
         a~categoria,
         b~ddtext      AS categoria_desc,
         a~preco,
         a~qtde_estoque,
         a~status_prod,
         a~status_icon,
         c~ddtext      AS status_desc
    FROM ztb_prod AS a
    LEFT JOIN dd07t AS b                 " JOIN 1: Para a Categoria
      ON  b~domname    = 'ZDO_TIPOPROD'
      AND b~domvalue_l = a~categoria
      AND b~ddlanguage = @sy-langu
    LEFT JOIN dd07t AS c                 " JOIN 2: Para o Status
      ON  c~domname    = 'ZSTATUS_PROD_D'
      AND c~domvalue_l = a~status_prod
      AND c~ddlanguage = @sy-langu
WHERE id_prod      IN @s_id
  AND nome_prod    IN @s_nome
  AND categoria    IN @s_cat
  AND qtde_estoque IN @s_qtde
  AND preco        IN @s_preco
  AND status_prod  = @lv_ativo
    INTO CORRESPONDING FIELDS OF TABLE @lt_prod.

  IF lt_prod IS INITIAL.
    MESSAGE 'Nenhum produto encontrado com os filtros informados.' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM f_exibir_alv.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_exibir_alv
*&---------------------------------------------------------------------*
*& Orquestra a exibição do ALV
*&---------------------------------------------------------------------*
FORM f_exibir_alv .

  " 1. Define ordenação
  PERFORM f_alv_sort_prod.

  " 2. Define campos a exibir
  PERFORM f_alv_fieldcat_prod.

  " 3. Imprime relatório
  PERFORM f_alv_imprime_prod.

ENDFORM. " f_exibir_alv


*&---------------------------------------------------------------------*
*& Form F_ALV_SORT_PROD
*&---------------------------------------------------------------------*
*& Define a ordenação inicial da lista (Tabela: IT_SORT)
*&---------------------------------------------------------------------*
FORM f_alv_sort_prod.

  DATA i TYPE i.
  CLEAR it_sort.

  " 1. ID_PROD (Chave primária)
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'ID_PROD'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  " 2. NOME_PROD
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'NOME_PROD'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  " 3. CATEGORIA
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'CATEGORIA'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  " 3. DESCRIÇÂO DA CATEGORIA
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'CATEGORIA_DESC'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  " 4. NOME_PROD
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'PRECO'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  " 5. NOME_PROD
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'QTDE_ESTOQUE'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  " 6. NOME_PROD
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'STATUS_PROD'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'STATUS_DESC'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

ENDFORM. " f_alv_sort_prod

*&---------------------------------------------------------------------*
*& Form F_ALV_FIELDCAT_PROD
*&---------------------------------------------------------------------*
*& Define os campos e características de exibição (Tabela: IT_FIELDCAT)
*&---------------------------------------------------------------------*
FORM f_alv_fieldcat_prod.

  DATA i TYPE i.
  CLEAR it_fieldcat.

  " 1. ID_PROD
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'ID_PROD'.
  wa_afield-seltext_l         = 'ID do Produto'.
  wa_afield-ref_fieldname     = 'ID_PROD'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  wa_afield-key               = 'X'. " Campo chave
  APPEND wa_afield TO it_fieldcat.

  " 2. NOME_PROD
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'NOME_PROD'.
  wa_afield-seltext_l         = 'Nome do Produto'.
  wa_afield-ref_fieldname     = 'NOME_PROD'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  APPEND wa_afield TO it_fieldcat.


  i = i + 1. CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'CATEGORIA'. "
  wa_afield-seltext_l         = 'Cód. Categoria'.
  wa_afield-ref_fieldname     = 'CATEGORIA'.
  wa_afield-ref_tabname      = 'ZTB_PROD'.
  APPEND wa_afield TO it_fieldcat.


  i = i + 1. CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'CATEGORIA_DESC'.
  wa_afield-seltext_l         = 'Descrição da Categoria'.
  wa_afield-ref_fieldname     = 'CATEGORIA_DESC'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  wa_afield-outputlen         = 30. "
  APPEND wa_afield TO it_fieldcat.

  " 4. QTDE_ESTOQUE (Quantidade)
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'QTDE_ESTOQUE'.
  wa_afield-seltext_l         = 'Qtd. Estoque'.
  wa_afield-ref_fieldname     = 'QTDE_ESTOQUE'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  wa_afield-datatype          = 'QUAN'.
  APPEND wa_afield TO it_fieldcat.

  " 5. PRECO (Preço)
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'PRECO'.
  wa_afield-seltext_l         = 'Preço Unitário'.
  wa_afield-ref_fieldname     = 'PRECO'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  wa_afield-datatype          = 'CURR'.
  wa_afield-cfieldname        = 'WAERS'.
  APPEND wa_afield TO it_fieldcat.

  " 6. ATIVO (Situação)
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'STATUS_PROD'.
  wa_afield-seltext_l         = 'Situação'.
  wa_afield-ref_fieldname     = 'STATUS_PROD'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  wa_afield-ddictxt           = 'L'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'STATUS_DESC'.
  wa_afield-seltext_l         = 'Descrição Situação'.
  wa_afield-ref_fieldname     = 'STATUS_DESC'.
  wa_afield-ref_tabname       = 'ZTB_PROD'.
  wa_afield-outputlen         = 30. "
  APPEND wa_afield TO it_fieldcat.



ENDFORM. " f_alv_fieldcat_prod


*&---------------------------------------------------------------------*
*& Form F_ALV_IMPRIME_PROD
*&---------------------------------------------------------------------*
*& Chama a função principal de exibição do ALV (REUSE_ALV_GRID_DISPLAY)
*&---------------------------------------------------------------------*
FORM f_alv_imprime_prod.

* Transfere dados para o Field Catalog (estrutura SLIS)
  CALL FUNCTION 'REUSE_ALV_TRANSFER_DATA_BACK'
    EXPORTING
      it_fieldcat = it_fieldcat " Catálogo KKBLO
      is_layout   = wa_layout
    IMPORTING
      et_fieldcat = it_fcat     " Catálogo SLIS
      es_layout   = wa_lay.

* Imprime dados --------------------------------
  MOVE sy-repid TO v_repid.
  MOVE v_repid TO wa_variant-report.

  DATA: lv_repid TYPE sy-repid.
  lv_repid = sy-repid.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = lv_repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'HANDLE_ALV_EVENT'
      i_grid_title             = 'Relatório de Produtos'
      is_layout                = wa_lay
      it_fieldcat              = it_fcat
      it_sort                  = it_sort[]
      i_save                   = v_save
      is_variant               = wa_variant
    TABLES
      t_outtab                 = lt_prod
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I'
    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    STOP.
  ENDIF.
ENDFORM. " f_alv_imprime_prod

*&---------------------------------------------------------------------*
*& Form SET_PF_STATUS
*&---------------------------------------------------------------------*
*& Define o Status GUI para o ALV
*&---------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_ALV_EVENT
*&---------------------------------------------------------------------*
*& Trata comandos e eventos do usuário no ALV
*&---------------------------------------------------------------------*
FORM handle_alv_event
  USING ucomm TYPE syucomm
        selfield TYPE slis_selfield.

  DATA ld_field TYPE char10.
  DATA lv_resposta TYPE char1.


  READ TABLE lt_prod INTO ls_prod INDEX selfield-tabindex.
  ld_field = ls_prod-id_prod.
  CONDENSE ld_field NO-GAPS.

  CASE ucomm.
    WHEN 'CREATE'.

      PERFORM f_confirmar
        USING
          'Confirmação de Criação de Produto'
          'Tem certeza que deseja criar um novo registro de produto?'
          'SIM - Criar'
          'NÃO - Voltar'
        CHANGING
          lv_resposta.

      IF sy-subrc = 0 AND lv_resposta = '1'.
        CLEAR ls_prod.
        PERFORM f_inserir_prod.

      ELSEIF sy-subrc = 0 AND lv_resposta = '2'.
        MESSAGE 'Criação de produto cancelada pelo usuário.' TYPE 'I'.
      ENDIF.

      CLEAR lv_resposta.
      PERFORM f_exibir_prod.
      selfield-refresh = 'X'.

    WHEN 'EDIT'.

      PERFORM f_confirmar
        USING
          'Confirmação de Edição de Produto'
          'Tem certeza que deseja editar este registro de produto?'
          'SIM - Editar'
          'NÃO - Voltar'
        CHANGING
          lv_resposta.

      IF lv_resposta = '1'.
        READ TABLE lt_prod INTO ls_dados_selecionados INDEX selfield-tabindex.

        IF sy-subrc = 0.
          PERFORM f_navegar_para_edicao USING ls_dados_selecionados-id_prod.
        ELSE.
          MESSAGE 'Selecione uma linha para editar.' TYPE 'I'.
        ENDIF.
      ENDIF.

      PERFORM f_exibir_prod.
      selfield-refresh = 'X'.

    WHEN 'DELETE'.

      READ TABLE lt_prod INTO ls_dados_selecionados INDEX selfield-tabindex.

      IF sy-subrc = 0.
        PERFORM f_iniciar_exclusao USING ls_dados_selecionados-id_prod.

        PERFORM f_exibir_prod.
        selfield-refresh = 'X'.

      ELSE.
        MESSAGE 'Selecione uma linha para excluir.' TYPE 'I'.
      ENDIF.

    WHEN OTHERS.

  ENDCASE.

ENDFORM. " HANDLE_ALV_EVENT

*&---------------------------------------------------------------------*
*& Form f_limpa_tudo
*&---------------------------------------------------------------------*
*& Limpa todas as variáveis globais e estruturas após a execução
*&---------------------------------------------------------------------*
FORM f_limpa_tudo.

  CLEAR: lt_prod[],              " Tabela interna principal de produtos
         ls_prod,                " Estrutura de trabalho
         ls_dados_selecionados,  " Estrutura para dados selecionados do ALV
         v_repid, v_save,
         it_fcat[], it_fieldcat[], it_header[], it_sort[],
         wa_variant, wa_afield, wa_colinfo, wa_layout, wa_header, wa_lay, wa_sort.

  " Limpeza dos SELECT-OPTIONS
  CLEAR: s_id[], s_nome[], s_cat[], s_qtde[], s_preco[].

  " Limpeza dos parâmetros de seleção
  CLEAR: p_idprod, p_nome.


ENDFORM. " f_limpa_tudo

*&---------------------------------------------------------------------*
*& Form f_consultar_prod_simples
*&---------------------------------------------------------------------*
*& Realiza uma consulta genérica usando todos os SELECT-OPTIONS
*&---------------------------------------------------------------------*
FORM f_consultar_prod_simples.

  SELECT *
    INTO TABLE @lt_prod
    FROM ztb_prod
    WHERE id_prod      IN @s_id[]
    AND   nome_prod    IN @s_nome[]
    AND   categoria    IN @s_cat[]
    AND   qtde_estoque IN @s_qtde[]
    AND   preco        IN @s_preco[]
    AND   status_prod       = '1'.

ENDFORM. " f_consultar_prod_simples


*&---------------------------------------------------------------------*
*& Form f_alterar_prod
*&---------------------------------------------------------------------*
*& Realiza a leitura dos dados para preencher a tela de alteração (9001)
*&---------------------------------------------------------------------*
FORM f_alterar_prod.


  IF p_idprod IS INITIAL.
    MESSAGE 'Informe o ID do produto que deseja alterar.' TYPE 'I'.
    EXIT.
  ENDIF.


  SELECT SINGLE *
    FROM ztb_prod
    INTO @ls_prod
    WHERE id_prod = @p_idprod.

  IF sy-subrc <> 0.

    MESSAGE |Produto ID { p_idprod } não encontrado.| TYPE 'E'.
    EXIT.
  ENDIF.


  CALL SCREEN 9001.


  CLEAR: p_nome, p_idprod.


  CALL SELECTION-SCREEN 1000.

ENDFORM. " f_alterar_prod

*&---------------------------------------------------------------------*
*& Form f_deletar_prod
*&---------------------------------------------------------------------*
*& Inativa (Deleta logico) um registro de Produto
*&---------------------------------------------------------------------*
FORM f_deletar_prod.

  DATA lv_confirma TYPE c.

  IF p_idprod IS INITIAL.
    MESSAGE 'Informe o ID do produto para inativar.' TYPE 'I'.
    EXIT.
  ENDIF.

  SELECT SINGLE *
    FROM ztb_prod
    INTO @ls_prod
    WHERE id_prod = @p_idprod.

  IF sy-subrc <> 0.
    MESSAGE 'Produto não encontrado.' TYPE 'E'.
    EXIT.
  ENDIF.

  IF ls_prod-status_prod = 9.
    MESSAGE 'Produto já está inativo.' TYPE 'I'.
    EXIT.
  ENDIF.


  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar      = 'Confirmação de Inativação'
      text_question = |Deseja realmente inativar o produto { p_idprod } ({ ls_prod-nome_prod })?|
      text_button_1 = 'Sim'
      text_button_2 = 'Não'
    IMPORTING
      answer        = lv_confirma.

  IF lv_confirma = '1'.

    UPDATE ztb_prod
        SET status_prod = '9'
      WHERE id_prod = @p_idprod.

    IF sy-subrc = 0.
      COMMIT WORK.
      MESSAGE |Produto { p_idprod } ({ ls_prod-nome_prod }) marcado como inativo.| TYPE 'S'.
    ELSE.
      ROLLBACK WORK.
      MESSAGE 'Erro ao inativar produto.' TYPE 'E'.
    ENDIF.

  ELSE.
    MESSAGE 'Operação cancelada pelo usuário.' TYPE 'I'.
  ENDIF.

ENDFORM. " f_deletar_prod

*&---------------------------------------------------------------------*
*& Form f_navegar_para_edicao
*&---------------------------------------------------------------------*
*& Navega do ALV para a tela 9001 (Edição)
*&---------------------------------------------------------------------*
FORM f_navegar_para_edicao USING iv_id_prod TYPE ztb_prod-id_prod.

  IF iv_id_prod IS NOT INITIAL.

    SET PARAMETER ID 'ZID_PROD' FIELD iv_id_prod.

    CALL SCREEN 9001.

  ENDIF.

ENDFORM. " f_navegar_para_edicao

*&---------------------------------------------------------------------*
*& Form f_iniciar_exclusao
*&---------------------------------------------------------------------*
*& Inativa o produto selecionado no ALV
*&---------------------------------------------------------------------*
FORM f_iniciar_exclusao
  USING uv_id_prod TYPE ztb_prod-id_prod.

  DATA: lv_pop TYPE char01.

  PERFORM f_confirmar
    USING 'Confirmação de Inativação de Produto'
          'Deseja realmente INATIVAR o produto?'
          'Sim, Inativar'
          'Não'
    CHANGING lv_pop.

  IF lv_pop = '1'.

    UPDATE ztb_prod
       SET status_prod = '9'
     WHERE id_prod = uv_id_prod.

    IF sy-subrc = 0.
      COMMIT WORK.
      MESSAGE |Produto ID { uv_id_prod } inativado com sucesso!| TYPE 'S'.

    ELSE.
      ROLLBACK WORK.
      MESSAGE 'Erro ao inativar produto.' TYPE 'E'.
    ENDIF.

  ELSE.
    MESSAGE 'Inativação de produto cancelada pelo usuário.' TYPE 'I'.
  ENDIF.

ENDFORM. " f_iniciar_exclusao

*&---------------------------------------------------------------------*
*& Form f_bloquear_campos
*&---------------------------------------------------------------------*
*& Bloqueia campos da tela (geralmente usado na tela de alteração/edição)
*&---------------------------------------------------------------------*
FORM f_bloquear_campos.

  LOOP AT SCREEN.
    IF screen-name EQ 'LS_PROD-ID_PROD'.
      screen-input    = 0.
      screen-required = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM. " f_bloquear_campos


FORM tela_inicial .
LEAVE TO SCREEN 0.
ENDFORM.
