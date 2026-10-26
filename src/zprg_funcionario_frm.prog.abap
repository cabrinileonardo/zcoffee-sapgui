*&---------------------------------------------------------------------*
*& Include          ZPRG_FUNCIONARIO_FRM
*&---------------------------------------------------------------------*
*& Descrição:
*& Include responsável por conter as rotinas (FORMS) de negócio do
*& programa ZPRG_FUNCIONARIO, como inserção e exibição de funcionários.
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Inserir funcionário
*&---------------------------------------------------------------------*
*& Responsável por:
*&  - Exibir a tela de inserção (9000)
*&  - Validar preenchimento dos dados
*&  - Gerar o ID do funcionário
*&  - Persistir os dados na tabela ZTB_FUNC
*&---------------------------------------------------------------------*
FORM inserir.

  " Flag de controle para identificar se o registro foi salvo
  DATA: lv_salvou TYPE abap_bool.

  " Garante que a estrutura esteja limpa antes da inserção
  CLEAR ls_func.

  " 1. Chamada da tela de inserção de funcionários
  CALL SCREEN 9000.

  " 2. Verifica se houve preenchimento/confirmação
  " Caso o nome esteja inicial, considera que a ação foi abortada
  IF ls_func-nome IS INITIAL.
    MESSAGE 'Inserção abortada ou cancelada.' TYPE 'I'.

  ELSE.
    " 3. Geração do ID final do funcionário
    PERFORM f_gerar_id_final_number_next
      CHANGING ls_func-id_func.

    IF ls_func-id_func IS NOT INITIAL.

      " 4. Inserção dos dados na tabela ZTB_FUNC
      INSERT ztb_func FROM ls_func.

      IF sy-subrc = 0.
        " Registro inserido com sucesso
        COMMIT WORK.
        MESSAGE |Funcionário ID { ls_func-id_func } criado com sucesso!|
          TYPE 'S'.
        lv_salvou = abap_true.
      ELSE.
        " Erro durante a inserção
        ROLLBACK WORK.
        MESSAGE 'Erro ao inserir registro. ID pode já existir ou falha no banco.'
          TYPE 'E'.
      ENDIF.

    ELSE.
      " Falha na geração do ID
      MESSAGE 'Falha ao gerar ID. Operação cancelada.' TYPE 'E'.
    ENDIF.

  ENDIF.

  " 5. Limpeza de campos da tela apenas se houve salvamento
  IF lv_salvou = abap_true.
    CLEAR p_nome.
    CLEAR p_idfunc.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Exibir funcionários
*&---------------------------------------------------------------------*
*& Responsável por:
*&  - Ler os dados da tabela ZTB_FUNC
*&  - Aplicar filtros informados na tela de seleção
*&  - Buscar descrições de domínio (cargo e status)
*&  - Exibir os dados em ALV
*&---------------------------------------------------------------------*
FORM vizualizar.

  DATA lv_ativo TYPE ztb_func-atividade.

  lv_ativo = p_ativo.

  IF p_all IS NOT INITIAL.

    " Busca TODOS os funcionários
    SELECT a~id_func,
           a~nome,
           a~cargo,
           b~ddtext      AS cargo_desc,
           a~data_adm,
           a~salario,
           a~atividade,
           c~ddtext      AS status_desc
      FROM ztb_func AS a
      LEFT JOIN dd07t AS b
        ON  b~domname    = 'ZDO_CARGOFUNC'
        AND b~domvalue_l = a~cargo
        AND b~ddlanguage = @sy-langu
      LEFT JOIN dd07t AS c
        ON  c~domname    = 'ZATIVIDADE_D'
        AND c~domvalue_l = a~atividade
        AND c~ddlanguage = @sy-langu
      WHERE id_func  IN @s_id
        AND nome     IN @s_nome
        AND cargo    IN @s_cargo
        AND data_adm IN @s_data
        AND salario  IN @s_salr
      INTO CORRESPONDING FIELDS OF TABLE @lt_func.

  ELSE.

    " Busca funcionários conforme status selecionado
    SELECT a~id_func,
           a~nome,
           a~cargo,
           b~ddtext      AS cargo_desc,
           a~data_adm,
           a~salario,
           a~atividade,
           c~ddtext      AS status_desc
      FROM ztb_func AS a
      LEFT JOIN dd07t AS b
        ON  b~domname    = 'ZDO_CARGOFUNC'
        AND b~domvalue_l = a~cargo
        AND b~ddlanguage = @sy-langu
      LEFT JOIN dd07t AS c
        ON  c~domname    = 'ZATIVIDADE_D'
        AND c~domvalue_l = a~atividade
        AND c~ddlanguage = @sy-langu
      WHERE id_func   IN @s_id
        AND nome      IN @s_nome
        AND cargo     IN @s_cargo
        AND data_adm  IN @s_data
        AND salario   IN @s_salr
        AND atividade = @lv_ativo
      INTO CORRESPONDING FIELDS OF TABLE @lt_func.

  ENDIF.

  " Nenhum registro encontrado
  IF lt_func IS INITIAL.
    MESSAGE 'Nenhum funcionário encontrado com os filtros informados.' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM exibir_alv.

ENDFORM.



*---------------------------------------------------------------------*
* Exibição do ALV
*---------------------------------------------------------------------*
* Responsável por:
*  - Definir ordenação dos dados
*  - Definir catálogo de campos
*  - Executar a impressão do ALV
*---------------------------------------------------------------------*
FORM exibir_alv.

  " Define critérios de ordenação do ALV
  PERFORM f_alv_sort.

  " Define os campos e propriedades do ALV
  PERFORM f_alv_fieldcat.

  " Executa a exibição do relatório ALV
  PERFORM f_alv_imprime.

ENDFORM.  " exibir_alv


*---------------------------------------------------------------------*
* Form F_ALV_SORT
*---------------------------------------------------------------------*
* Define a ordenação padrão dos dados exibidos no ALV.
*---------------------------------------------------------------------*
FORM f_alv_sort.

  DATA i TYPE i.

  " 1. Ordenação por ID do Funcionário
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'ID_FUNC'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

  " 2. Ordenação por Nome
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'NOME'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

  " 3. Ordenação por Cargo
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'CARGO'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

  " 4. Ordenação por Descrição do Cargo
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'CARGO_DESC'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

  " 5. Ordenação por Data de Admissão
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'DATA_ADM'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

  " 6. Ordenação por Salário
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'SALARIO'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

  " 7. Ordenação por Situação (Ativo/Inativo)
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos      = i.
  wa_sort-fieldname = 'ATIVIDADE'.
  wa_sort-up        = 'X'.
  wa_sort-subtot    = space.
  APPEND wa_sort TO it_sort.

ENDFORM.


*---------------------------------------------------------------------*
* Form F_ALV_FIELDCAT
*---------------------------------------------------------------------*
* Define o catálogo de campos do ALV, controlando:
*  - Ordem das colunas
*  - Textos exibidos
*  - Campos-chave
*  - Formatação de valores
*---------------------------------------------------------------------*
FORM f_alv_fieldcat.

  DATA i TYPE i.

  " 1. ID do Funcionário (campo-chave)
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'ID_FUNC'.
  wa_afield-seltext_l     = 'ID do Funcionário'.
  wa_afield-ref_fieldname = 'ID_FUNC'.
  wa_afield-ref_tabname   = 'ZTB_FUNC'.
  wa_afield-key           = 'X'.
  APPEND wa_afield TO it_fieldcat.

  " 2. Nome do Funcionário
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'NOME'.
  wa_afield-seltext_l     = 'Nome Completo'.
  wa_afield-ref_fieldname = 'NOME'.
  wa_afield-ref_tabname   = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  " 3. Código do Cargo
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'CARGO'.
  wa_afield-seltext_l     = 'Cargo'.
  wa_afield-ref_fieldname = 'CARGO'.
  wa_afield-ref_tabname   = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  " 4. Descrição do Cargo
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'CARGO_DESC'.
  wa_afield-seltext_l     = 'Descrição do Cargo'.
  APPEND wa_afield TO it_fieldcat.

  " 5. Data de Admissão
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'DATA_ADM'.
  wa_afield-seltext_l     = 'Data de Admissão'.
  wa_afield-ref_fieldname = 'DATA_ADM'.
  wa_afield-ref_tabname   = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  " 6. Salário Mensal
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'SALARIO'.
  wa_afield-seltext_l     = 'Salário Mensal'.
  wa_afield-ref_fieldname = 'SALARIO'.
  wa_afield-ref_tabname   = 'ZTB_FUNC'.
  wa_afield-datatype      = 'CURR'.
  wa_afield-cfieldname    = 'WAERS'.
  APPEND wa_afield TO it_fieldcat.

  " 7. Código da Situação
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'ATIVIDADE'.
  wa_afield-seltext_l     = 'Situação'.
  wa_afield-ref_fieldname = 'ATIVIDADE'.
  wa_afield-ref_tabname   = 'ZTB_FUNC'.
  wa_afield-ddictxt       = 'L'.
  APPEND wa_afield TO it_fieldcat.

  " 8. Descrição da Situação
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos       = i.
  wa_afield-fieldname     = 'STATUS_DESC'.
  wa_afield-seltext_l     = 'Descrição da Situação'.
  wa_afield-ddictxt       = 'L'.
  APPEND wa_afield TO it_fieldcat.

ENDFORM.


*---------------------------------------------------------------------*
* Form F_ALV_IMPRIME
*---------------------------------------------------------------------*
* Responsável por:
*  - Converter fieldcat/layout KKBLO para SLIS
*  - Executar a exibição do ALV via REUSE_ALV_GRID_DISPLAY
*---------------------------------------------------------------------*
FORM f_alv_imprime.

  " Converte fieldcat e layout para formato SLIS
  CALL FUNCTION 'REUSE_ALV_TRANSFER_DATA_BACK'
    EXPORTING
      it_fieldcat = it_fieldcat
      is_layout   = wa_layout
    IMPORTING
      et_fieldcat = it_fcat
      es_layout   = wa_lay.

  " Define programa e variante do ALV
  MOVE sy-repid TO v_repid.
  MOVE v_repid TO wa_variant-report.

  DATA: lv_repid TYPE sy-repid.
  lv_repid = sy-repid.

  " Chamada do ALV GRID
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = lv_repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      i_callback_user_command  = 'HANDLE_ALV_EVENT'
      i_grid_title             = 'Relatório de Funcionários'
      is_layout                = wa_lay
      it_fieldcat              = it_fcat
      it_sort                  = it_sort[]
      i_save                   = v_save
      is_variant               = wa_variant
    TABLES
      t_outtab                 = lt_func
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  " Tratamento de erro genérico
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I'
      NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    STOP.
  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* Form SET_PF_STATUS
*---------------------------------------------------------------------*
* Define o status GUI padrão do ALV, controlando botões e funções
* disponíveis na toolbar (Criar, Editar, Excluir, etc.).
*---------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.

  " Define o PF-STATUS utilizado pelo ALV
  SET PF-STATUS 'STANDARD'.

ENDFORM.


*---------------------------------------------------------------------*
* Form HANDLE_ALV_EVENT
*---------------------------------------------------------------------*
* Trata os eventos de comando do ALV (toolbar e menu),
* executando ações conforme o botão selecionado.
*---------------------------------------------------------------------*
FORM handle_alv_event
  USING
    ucomm    TYPE syucomm
    selfield TYPE slis_selfield.

  " Variáveis auxiliares
  DATA: ld_field    TYPE char10,
        lv_resposta TYPE char1.

  " Obtém o registro selecionado no ALV
  READ TABLE lt_func INTO ls_func INDEX selfield-tabindex.

  IF sy-subrc = 0.
    ld_field = ls_func-id_func.
    CONDENSE ld_field NO-GAPS.
  ENDIF.

  " Avalia o comando acionado pelo usuário
  CASE ucomm.

    WHEN 'CREATE'.
      " Criação de novo funcionário
      PERFORM f_confirmar
        USING
          'Confirmar ação'
          'Deseja criar um funcionário?'
          'Sim'
          'Não'
        CHANGING
          lv_resposta.

      IF lv_resposta = '1'.
        CLEAR ls_func.
        PERFORM inserir.
      ENDIF.

      " Atualiza dados do ALV após a ação
      PERFORM consultar.
      selfield-refresh = 'X'.


    WHEN 'EDIT'.
      " Edição de funcionário selecionado
      PERFORM f_confirmar
        USING
          'Confirmação de Edição'
          'Tem certeza que deseja editar este registro?'
          'Sim'
          'Não'
        CHANGING
          lv_resposta.

      IF lv_resposta = '1'.

        READ TABLE lt_func INTO ls_dados_selecionados
          INDEX selfield-tabindex.

        IF sy-subrc = 0.
          PERFORM f_navegar_para_edicao
            USING ls_dados_selecionados-id_func.
        ELSE.
          MESSAGE 'Selecione uma linha para editar.' TYPE 'I'.
        ENDIF.

      ENDIF.

      " Reconsulta e atualiza o ALV
      PERFORM consultar.
      selfield-refresh = 'X'.


    WHEN 'DELETE'.
      " Exclusão de funcionário selecionado
      READ TABLE lt_func INTO ls_dados_selecionados
        INDEX selfield-tabindex.

      IF sy-subrc = 0.

        PERFORM f_iniciar_exclusao
          USING ls_dados_selecionados-id_func.

        " Atualiza dados do ALV após exclusão
        PERFORM consultar.
        selfield-refresh = 'X'.

      ELSE.
        MESSAGE 'Selecione uma linha para excluir.' TYPE 'I'.
      ENDIF.

    WHEN OTHERS.
      " Nenhuma ação definida

  ENDCASE.

ENDFORM.

*---------------------------------------------------------------------*
* Form CONSULTAR
*---------------------------------------------------------------------*
* Realiza a busca dos funcionários ativos conforme filtros
* informados na seleção.
*---------------------------------------------------------------------*
FORM consultar.

  SELECT *
    FROM ztb_func
    INTO TABLE lt_func
    WHERE id_func   IN s_id[]
      AND nome      IN s_nome[]
      AND cargo     IN s_cargo[]
      AND data_adm  IN s_data[]
      AND salario   IN s_salr[]
      AND atividade = '1'. " Apenas funcionários ativos

ENDFORM.

*---------------------------------------------------------------------*
* Form LIMPA_TUDO
*---------------------------------------------------------------------*
* Limpa dados de execução, ALV e variáveis auxiliares
*---------------------------------------------------------------------*
FORM limpa_tudo.

  CLEAR: p_ativo,p_idfunc, p_nome, p_ativo.

  " Dados
  CLEAR: lt_func[],
         ls_func.

  " Controle de execução
  CLEAR: v_repid,
         v_save.

  " ALV - Fieldcat / Layout / Header
  CLEAR: it_fcat[],
         it_fieldcat[],
         it_header[],
         it_sort[],
         wa_variant,
         wa_afield,
         wa_colinfo,
         wa_layout,
         wa_header,
         wa_lay,
         wa_sort.

ENDFORM.

*---------------------------------------------------------------------*
* Form ALTERAR
*---------------------------------------------------------------------*
* Carrega dados do funcionário informado e navega para
* a tela de alteração.
*---------------------------------------------------------------------*
FORM alterar.

  " Busca funcionário pelo ID informado
  SELECT SINGLE *
    FROM ztb_func
    INTO @ls_func
    WHERE id_func = @p_idfunc.

  IF sy-subrc <> 0.
    MESSAGE s002(zmsg_coffee) DISPLAY LIKE 'E'.
* Nenhum funcionário encontrado
    EXIT.
  ENDIF.

  " Chama tela de edição
  CALL SCREEN 9001.

  " Limpa campos e retorna à seleção
  CLEAR: p_nome,
         p_idfunc.

  CALL SELECTION-SCREEN 1000.

ENDFORM.

*---------------------------------------------------------------------*
* Form EXCLUIR
*---------------------------------------------------------------------*
* Realiza exclusão lógica (inativação) do funcionário
*---------------------------------------------------------------------*
FORM excluir.

  DATA lv_resposta TYPE char01.

  " Valida ID informado
  IF p_idfunc IS INITIAL.
    MESSAGE 'Informe o ID do funcionário para excluir.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Busca funcionário
  SELECT SINGLE *
    FROM ztb_func
    INTO @ls_func
    WHERE id_func = @p_idfunc.

  IF sy-subrc <> 0.
    MESSAGE 'Funcionário não encontrado.' TYPE 'E'.
    EXIT.
  ENDIF.

  " Verifica se já está inativo
  IF ls_func-atividade = '9'.
    MESSAGE 'Funcionário já está inativo.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Confirmação do usuário
  PERFORM f_confirmar
    USING
      'Confirmação'
      'Deseja realmente inativar o funcionário?'
      'Sim'
      'Não'
    CHANGING
      lv_resposta.

  IF lv_resposta <> '1'.
    MESSAGE 'Operação cancelada pelo usuário.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Exclusão lógica
  UPDATE ztb_func
     SET atividade = 9
   WHERE id_func = @p_idfunc.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Funcionário { p_idfunc } marcado como inativo.| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Erro ao inativar funcionário.' TYPE 'E'.
  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* Form F_CONFIRMAR
*---------------------------------------------------------------------*
* Exibe pop-up de confirmação e retorna resposta do usuário
* '1' = Botão 1 | '2' = Botão 2 | 'A' = Erro
*---------------------------------------------------------------------*
FORM f_confirmar
  USING
    iv_titulo    TYPE char50
    iv_pergunta  TYPE char100
    iv_botao1    TYPE char20
    iv_botao2    TYPE char20
  CHANGING
    cv_resposta  TYPE char01.

  CLEAR cv_resposta.

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
      OTHERS         = 1.

  IF sy-subrc <> 0.
    cv_resposta = 'A'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* Form F_NAVEGAR_PARA_EDICAO
*---------------------------------------------------------------------*
* Navega para a tela de edição carregando o ID do funcionário
*---------------------------------------------------------------------*
FORM f_navegar_para_edicao
  USING iv_id_func TYPE ztb_func-id_func.

  IF iv_id_func IS INITIAL.
    EXIT.
  ENDIF.

  SET PARAMETER ID 'ZID_FUNC' FIELD iv_id_func.
  CALL SCREEN 9001.

ENDFORM.

*---------------------------------------------------------------------*
* Form F_OBTER_ID_PARA_EXIBIR
*---------------------------------------------------------------------*
* Retorna o próximo ID apenas para exibição (não consome range)
*---------------------------------------------------------------------*
FORM f_obter_id_para_exibir
  CHANGING cv_proximo_id TYPE ztb_func-id_func.

  DATA ls_nriv TYPE nriv.

  CLEAR cv_proximo_id.

  CALL FUNCTION 'NUMBER_GET_INFO'
    EXPORTING
      object      = 'ZID_FUNC01'
      nr_range_nr = '01'
      toyear      = '0000'
    IMPORTING
      interval    = ls_nriv
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc = 0.
    cv_proximo_id = ls_nriv-nrlevel + 1.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* Form F_GERAR_ID_FINAL_NUMBER_NEXT
*---------------------------------------------------------------------*
* Consome o number range e retorna o ID definitivo
*---------------------------------------------------------------------*
FORM f_gerar_id_final_number_next
  CHANGING cv_novo_id TYPE ztb_func-id_func.

  DATA lv_number TYPE n LENGTH 20.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      object      = 'ZID_FUNC01'
      nr_range_nr = '01'
      quantity    = 1
      toyear      = '0000'
    IMPORTING
      number      = lv_number
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc = 0.
    cv_novo_id = lv_number.
  ELSE.
    MESSAGE 'Erro fatal ao gerar ID do funcionário.' TYPE 'E'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* Form F_INICIAR_EXCLUSAO
*---------------------------------------------------------------------*
* Realiza exclusão lógica (inativação) do funcionário
*---------------------------------------------------------------------*
FORM f_iniciar_exclusao
  USING uv_id_func TYPE ztb_func-id_func.

  DATA lv_resposta TYPE char01.

  PERFORM f_confirmar
    USING
      'Confirmação de Inativação'
      'Deseja realmente INATIVAR o funcionário?'
      'Sim, Inativar'
      'Não'
    CHANGING
      lv_resposta.

  IF lv_resposta <> '1'.
    MESSAGE 'Inativação cancelada pelo usuário.' TYPE 'I'.
    EXIT.
  ENDIF.

  UPDATE ztb_func
     SET atividade = '9'
   WHERE id_func = uv_id_func.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Funcionário ID { uv_id_func } inativado com sucesso!| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Erro ao inativar funcionário.' TYPE 'E'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* Form F_BLOQUEAR_CAMPOS
*---------------------------------------------------------------------*
* Bloqueia campos que não devem ser editados pelo usuário
*---------------------------------------------------------------------*
FORM f_bloquear_campos.

  LOOP AT SCREEN.
    IF screen-name = 'LS_FUNC-ID_FUNC'
    OR screen-name = 'CODIGO'.
      screen-input    = 0.
      screen-required = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.
