*&---------------------------------------------------------------------*
*& Include          ZPRG_FUNCIONARIO_FRM
*&---------------------------------------------------------------------*
*& Contém todas as sub-rotinas (FORMS) relacionadas ao
*& cadastro, geração de ID e confirmação de ações
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* FORM f_inserir_prod
*---------------------------------------------------------------------*
* Responsável por:
*  - Abrir a tela de inserção
*  - Validar concorrência de ID
*  - Gerar ID definitivo via Number Range
*  - Persistir o produto no banco
*---------------------------------------------------------------------*
FORM f_inserir_prod.

  DATA: lv_salvou  TYPE abap_bool,
        lv_id_prod TYPE ztb_prod-id_prod.

  "Limpa estrutura de trabalho
  CLEAR ls_prod.

  "Preenche dados iniciais vindos da seleção
  ls_prod-id_prod   = p_idprod.
  ls_prod-nome_prod = p_nome.

  "Chama a tela de inserção
  CALL SCREEN 9000.

  "Validação de concorrência (ID pode ter sido alterado por outro usuário)
  SELECT MAX( id_prod )
    FROM ztb_prod
    INTO lv_id_prod.

  lv_id_prod = lv_id_prod + 1.

  IF lv_id_prod <> ls_prod-id_prod.
    MESSAGE 'O número do produto foi atualizado. Salve novamente.' TYPE 'E'.
    ROLLBACK WORK.
    EXIT.
  ENDIF.

  "Verifica se a inserção foi confirmada
  IF ls_prod-nome_prod IS INITIAL.

    MESSAGE 'Inserção de produto abortada ou cancelada.' TYPE 'I'.

  ELSE.

    "Geração do ID definitivo caso não exista
    IF ls_prod-id_prod IS INITIAL.
      PERFORM f_gerar_id_final_number_next
        CHANGING ls_prod-id_prod.
    ENDIF.

    IF ls_prod-id_prod IS NOT INITIAL.

      "Inserção no banco de dados
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

  "Limpa parâmetros da tela caso o salvamento tenha ocorrido
  IF lv_salvou = abap_true.
    CLEAR: p_nome,
           p_idprod.
  ENDIF.

ENDFORM. " f_inserir_prod

*---------------------------------------------------------------------*
* FORM f_obter_id_para_exibir
*---------------------------------------------------------------------*
* Obtém o próximo ID disponível apenas para exibição
* Não consome o número do intervalo
*---------------------------------------------------------------------*
FORM f_obter_id_para_exibir
  CHANGING cv_proximo_id TYPE ztb_prod-id_prod.

  DATA ls_nriv TYPE nriv.

  CLEAR cv_proximo_id.

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

*---------------------------------------------------------------------*
* FORM f_gerar_id_final_number_next
*---------------------------------------------------------------------*
* Gera o ID definitivo do produto
* Consome o número do intervalo de numeração
*---------------------------------------------------------------------*
FORM f_gerar_id_final_number_next
  CHANGING cv_novo_id TYPE ztb_prod-id_prod.

  DATA lv_number TYPE n LENGTH 20.

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

*---------------------------------------------------------------------*
* FORM f_confirmar
*---------------------------------------------------------------------*
* Exibe um popup de confirmação genérico
* Retorna:
*  '1' = Botão 1 (Sim)
*  '2' = Botão 2 (Não)
*  'A' = Janela fechada
*---------------------------------------------------------------------*
FORM f_confirmar
  USING
    iv_titulo     TYPE char50
    iv_pergunta   TYPE char100
    iv_botao1     TYPE char20
    iv_botao2     TYPE char20
  CHANGING
    cv_resposta   TYPE char01.

  CLEAR cv_resposta.
  CLEAR sy-subrc.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = iv_titulo
      text_question  = iv_pergunta
      text_button_1  = iv_botao1
      text_button_2  = iv_botao2
      default_button = '1'
    IMPORTING
      answer         = cv_resposta
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.

  IF sy-subrc <> 0 AND sy-subrc <> 2.
    cv_resposta = 'A'.
  ENDIF.

ENDFORM. " f_confirmar

*---------------------------------------------------------------------*
* FORM f_exibir_prod
*---------------------------------------------------------------------*
* Responsável por:
*  - Montar o filtro de produtos conforme tela de seleção
*  - Buscar dados da tabela ZTB_PROD
*  - Resolver descrições de domínio (categoria e status)
*  - Popular tabela interna para exibição no ALV
*---------------------------------------------------------------------*
FORM f_exibir_prod.

  DATA(lv_ativo) = p_ativo.

  IF p_all IS NOT INITIAL.

    SELECT
           a~id_prod,
           a~nome_prod,
           a~categoria,
           b~ddtext        AS categoria_desc,
           a~preco,
           a~qtde_estoque,
           a~status_prod,
           a~status_icon,
           c~ddtext        AS status_desc
      FROM ztb_prod AS a
      LEFT JOIN dd07t AS b
        ON  b~domname     = 'ZDO_TIPOPROD'
        AND b~domvalue_l = a~categoria
        AND b~ddlanguage = @sy-langu
      LEFT JOIN dd07t AS c
        ON  c~domname     = 'ZSTATUS_PROD_D'
        AND c~domvalue_l = a~status_prod
        AND c~ddlanguage = @sy-langu
      WHERE a~id_prod      IN @s_id
        AND a~nome_prod    IN @s_nome
        AND a~categoria    IN @s_cat
        AND a~qtde_estoque IN @s_qtde
        AND a~preco        IN @s_preco
      INTO CORRESPONDING FIELDS OF TABLE @lt_prod.

  ELSE.
    SELECT
           a~id_prod,
           a~nome_prod,
           a~categoria,
           b~ddtext        AS categoria_desc,
           a~preco,
           a~qtde_estoque,
           a~status_prod,
           a~status_icon,
           c~ddtext        AS status_desc
      FROM ztb_prod AS a
      LEFT JOIN dd07t AS b
        ON  b~domname     = 'ZDO_TIPOPROD'
        AND b~domvalue_l = a~categoria
        AND b~ddlanguage = @sy-langu
      LEFT JOIN dd07t AS c
        ON  c~domname     = 'ZSTATUS_PROD_D'
        AND c~domvalue_l = a~status_prod
        AND c~ddlanguage = @sy-langu
      WHERE a~id_prod      IN @s_id
        AND a~nome_prod    IN @s_nome
        AND a~categoria    IN @s_cat
        AND a~qtde_estoque IN @s_qtde
        AND a~preco        IN @s_preco
        AND a~status_prod  = @lv_ativo
      INTO CORRESPONDING FIELDS OF TABLE @lt_prod.

  ENDIF.

  "Validação de retorno
  IF lt_prod IS INITIAL.
    MESSAGE 'Nenhum produto encontrado com os filtros informados.' TYPE 'I'.
    EXIT.
  ENDIF.

  "Exibe dados no ALV
  PERFORM f_exibir_alv.

ENDFORM. " f_exibir_prod

*---------------------------------------------------------------------*
* FORM f_exibir_alv
*---------------------------------------------------------------------*
* Responsável por:
*  - Preparar ordenação
*  - Definir catálogo de campos
*  - Executar a impressão do ALV
*---------------------------------------------------------------------*
FORM f_exibir_alv.

  "1. Define ordenação padrão do relatório
  PERFORM f_alv_sort_prod.

  "2. Define campos e propriedades do ALV
  PERFORM f_alv_fieldcat_prod.

  "3. Executa a exibição do ALV
  PERFORM f_alv_imprime_prod.

ENDFORM. " f_exibir_alv

*---------------------------------------------------------------------*
* FORM f_alv_sort_prod
*---------------------------------------------------------------------*
* Define a ordenação inicial do ALV
* A ordem segue a relevância dos dados para o usuário
*---------------------------------------------------------------------*
FORM f_alv_sort_prod.

  DATA lv_pos TYPE i.

  CLEAR it_sort.

  "1. ID do Produto (chave primária)
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'ID_PROD'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "2. Nome do Produto
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'NOME_PROD'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "3. Código da Categoria
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'CATEGORIA'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "4. Descrição da Categoria
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'CATEGORIA_DESC'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "5. Preço
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'PRECO'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "6. Quantidade em Estoque
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'QTDE_ESTOQUE'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "7. Status do Produto
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'STATUS_PROD'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

  "8. Descrição do Status
  lv_pos = lv_pos + 1.
  CLEAR wa_sort.
  wa_sort-spos      = lv_pos.
  wa_sort-fieldname = 'STATUS_DESC'.
  wa_sort-up        = 'X'.
  APPEND wa_sort TO it_sort.

ENDFORM. " f_alv_sort_prod

*---------------------------------------------------------------------*
* FORM f_alv_fieldcat_prod
*---------------------------------------------------------------------*
* Define os campos exibidos no ALV e suas propriedades visuais
*---------------------------------------------------------------------*
FORM f_alv_fieldcat_prod.

  DATA lv_pos TYPE i.

  CLEAR it_fieldcat.

  "1. ID do Produto (Campo-chave)
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'ID_PROD'.
  wa_afield-seltext_l     = 'ID do Produto'.
  wa_afield-ref_tabname   = 'ZTB_PROD'.
  wa_afield-ref_fieldname = 'ID_PROD'.
  wa_afield-key           = abap_true.
  APPEND wa_afield TO it_fieldcat.

  "2. Nome do Produto
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'NOME_PROD'.
  wa_afield-seltext_l     = 'Nome do Produto'.
  wa_afield-ref_tabname   = 'ZTB_PROD'.
  wa_afield-ref_fieldname = 'NOME_PROD'.
  APPEND wa_afield TO it_fieldcat.

  "3. Código da Categoria
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'CATEGORIA'.
  wa_afield-seltext_l     = 'Cód. Categoria'.
  wa_afield-ref_tabname   = 'ZTB_PROD'.
  wa_afield-ref_fieldname = 'CATEGORIA'.
  APPEND wa_afield TO it_fieldcat.

  "4. Descrição da Categoria
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'CATEGORIA_DESC'.
  wa_afield-seltext_l     = 'Descrição da Categoria'.
  wa_afield-outputlen     = 30.
  APPEND wa_afield TO it_fieldcat.

  "5. Quantidade em Estoque
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'QTDE_ESTOQUE'.
  wa_afield-seltext_l     = 'Qtd. Estoque'.
  wa_afield-datatype      = 'QUAN'.
  APPEND wa_afield TO it_fieldcat.

  "6. Preço Unitário
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'PRECO'.
  wa_afield-seltext_l     = 'Preço Unitário'.
  wa_afield-datatype      = 'CURR'.
  wa_afield-cfieldname    = 'WAERS'.
  APPEND wa_afield TO it_fieldcat.

  "7. Status do Produto
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'STATUS_PROD'.
  wa_afield-seltext_l     = 'Situação'.
  wa_afield-ddictxt       = 'L'.
  APPEND wa_afield TO it_fieldcat.

  "8. Descrição do Status
  lv_pos = lv_pos + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = lv_pos.
  wa_afield-fieldname     = 'STATUS_DESC'.
  wa_afield-seltext_l     = 'Descrição Situação'.
  wa_afield-outputlen     = 30.
  APPEND wa_afield TO it_fieldcat.

ENDFORM. " f_alv_fieldcat_prod

*---------------------------------------------------------------------*
* FORM f_alv_imprime_prod
*---------------------------------------------------------------------*
* Responsável por chamar o ALV Grid e exibir os dados
*---------------------------------------------------------------------*
FORM f_alv_imprime_prod.

  DATA lv_repid TYPE sy-repid.

  "Converte Field Catalog KKBLO -para SLIS
  CALL FUNCTION 'REUSE_ALV_TRANSFER_DATA_BACK'
    EXPORTING
      it_fieldcat = it_fieldcat
      is_layout   = wa_layout
    IMPORTING
      et_fieldcat = it_fcat
      es_layout   = wa_lay.

  lv_repid = sy-repid.
  wa_variant-report = lv_repid.

  "Exibe o ALV Grid
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = lv_repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'HANDLE_ALV_EVENT'
      i_grid_title             = 'Relatório de Produtos'
      is_layout                = wa_lay
      it_fieldcat              = it_fcat
      it_sort                  = it_sort
      i_save                   = v_save
      is_variant               = wa_variant
    TABLES
      t_outtab                 = lt_prod
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I'
      NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
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
