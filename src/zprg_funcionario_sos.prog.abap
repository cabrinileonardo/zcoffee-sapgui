*&---------------------------------------------------------------------*
*& Include          ZPRG_FUNCIONARIO_SOS
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Inserir funcionário
*&---------------------------------------------------------------------*

FORM inserir.

  DATA: lv_salvou TYPE abap_bool.

  CLEAR ls_func.

  " 1. CHAMA A TELA 9000
  CALL SCREEN 9000.


  " 2. Verifica se houve preenchimento/confirmação
  IF ls_func-nome IS INITIAL.
    MESSAGE 'Inserção abortada ou cancelada.' TYPE 'I'.

  ELSE.

    PERFORM f_gerar_id_final_number_next CHANGING ls_func-id_func.

    IF ls_func-id_func IS NOT INITIAL.

      " 4. INSERÇÃO DOS DADOS (AGORA COM O ID GERADO)
      INSERT ztb_func FROM ls_func.

      IF sy-subrc = 0.
        COMMIT WORK.
        MESSAGE |Funcionário ID { ls_func-id_func } criado com sucesso!| TYPE 'S'.
        lv_salvou = abap_true.
      ELSE.
        ROLLBACK WORK.
        MESSAGE 'Erro ao inserir registro. ID pode já existir ou falha no banco.' TYPE 'E'.
      ENDIF.

    ELSE.
      MESSAGE 'Falha ao gerar ID. Operação cancelada.' TYPE 'E'.
    ENDIF.

  ENDIF.

  " 5. Limpeza e Reexibição APENAS se salvou
  IF lv_salvou = abap_true.

    CLEAR p_nome.
    CLEAR p_idfunc.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& exibir funcionários
*&---------------------------------------------------------------------*
FORM vizualizar.


  DATA(lv_ativo) = COND #( WHEN p_ativo = 'X' THEN '1' ELSE '9' ).

  SELECT a~id_func,
         a~nome,
         a~cargo,
         b~ddtext      AS cargo_desc,
         a~data_adm,
         a~salario,
         a~atividade,
         c~ddtext      AS status_desc
    FROM ztb_func AS a
    LEFT JOIN dd07t AS b                 " JOIN 1: Para a Categoria
      ON  b~domname    = 'ZDO_CARGOFUNC'
      AND b~domvalue_l = a~cargo
      AND b~ddlanguage = @sy-langu
    LEFT JOIN dd07t AS c                 " JOIN 2: Para o Status
      ON  c~domname    = 'ZATIVIDADE_D'
      AND c~domvalue_l = a~atividade
      AND c~ddlanguage = @sy-langu
WHERE id_func      IN @s_id
  AND nome    IN @s_nome
  AND cargo    IN @s_cargo
  AND data_adm IN @s_data
  AND salario       IN @s_salr
  AND atividade  = @lv_ativo
    INTO CORRESPONDING FIELDS OF TABLE @lt_func.

  IF lt_func IS INITIAL.
    MESSAGE 'Nenhum funcionário encontrado com os filtros informados.' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM exibir_alv.

ENDFORM.




FORM exibir_alv.

  " Define ordenação
  PERFORM f_alv_sort.

  " Define campos a exibir
  PERFORM f_alv_fieldcat.

  " Imprime relatório
  PERFORM f_alv_imprime.

ENDFORM.  " exibir_alv


*---------------------------------------------------------------------*
* Form F_ALV_SORT
*---------------------------------------------------------------------*
FORM f_alv_sort .

  DATA i TYPE i.

  " 1. ID_FUNC
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'ID_FUNC'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.

  " 2. NOME
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'NOME'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.

  " 3. CARGO
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'CARGO'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'CARGO_DESC'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.

  " 4. DATA
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'DATA_ADM'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.

  " 5.SALARIO
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'SALARIO'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.

  " 6.ATIVIDADE
  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'ATIVIDADE'.
  wa_sort-up          = 'X'.
  wa_sort-subtot      = space.
  APPEND wa_sort TO it_sort.


ENDFORM.


*---------------------------------------------------------------------*
* Form F_ALV_FIELDCAT -
*---------------------------------------------------------------------*
FORM f_alv_fieldcat .

  DATA i TYPE i.

  " 1. ID_FUNC
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'ID_FUNC'.
  wa_afield-seltext_l         = 'ID do Funcionário'.
  wa_afield-ref_fieldname     = 'ID_FUNC'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  wa_afield-key               = 'X'.
  APPEND wa_afield TO it_fieldcat.

  " 2. NOME
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'NOME'.
  wa_afield-seltext_l         = 'Nome Completo'.
  wa_afield-ref_fieldname     = 'NOME'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  " 3. CARGO
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'CARGO'.
  wa_afield-seltext_l         = 'Cargo'.
  wa_afield-ref_fieldname     = 'CARGO'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'CARGO_DESC'.
  wa_afield-seltext_l         = 'Descrição cargo'.
  wa_afield-ref_fieldname     = 'CARGO_DESC'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  " 4. DATA_ADM
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'DATA_ADM'.
  wa_afield-seltext_l         = 'Data de admissão'.
  wa_afield-ref_fieldname     = 'DATA_ADM'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  APPEND wa_afield TO it_fieldcat.

  " 5. SALARIO
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'SALARIO'.
  wa_afield-seltext_l         = 'Salário Mensal'.
  wa_afield-ref_fieldname     = 'SALARIO'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  wa_afield-datatype          = 'CURR'.
  wa_afield-cfieldname        = 'WAERS'.
  APPEND wa_afield TO it_fieldcat.

  " 6. ATIVIDADE
  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'ATIVIDADE'.
  wa_afield-seltext_l         = 'Situação'.
  wa_afield-ref_fieldname     = 'ATIVIDADE'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  wa_afield-ddictxt           = 'L'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'STATUS_DESC'.
  wa_afield-seltext_l         = 'Descrição Situação'.
  wa_afield-ref_fieldname     = 'STATUS_DESC'.
  wa_afield-ref_tabname       = 'ZTB_FUNC'.
  wa_afield-ddictxt           = 'L'.
  APPEND wa_afield TO it_fieldcat.

ENDFORM.

*---------------------------------------------------------------------*
* Form F_ALV_IMPRIME
*---------------------------------------------------------------------*
FORM f_alv_imprime .

  CALL FUNCTION 'REUSE_ALV_TRANSFER_DATA_BACK'
    EXPORTING
      it_fieldcat = it_fieldcat
      is_layout   = wa_layout
    IMPORTING
      et_fieldcat = it_fcat
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
      i_grid_title             = 'Relatório de funcionários'
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

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I'
    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    STOP.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
* Form SET_PF_STATUS
*---------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'.
ENDFORM.

*---------------------------------------------------------------------*
* Form HANDLE_ALV_EVENT
*---------------------------------------------------------------------*
FORM handle_alv_event
  USING
    ucomm    TYPE syucomm
    selfield TYPE slis_selfield.

  DATA: ld_field    TYPE char10,
        lv_resposta TYPE char1.


  READ TABLE lt_func INTO ls_func INDEX selfield-tabindex.

  IF sy-subrc = 0.
    ld_field = ls_func-id_func.
    CONDENSE ld_field NO-GAPS.
  ENDIF.

  CASE ucomm.

    WHEN 'CREATE'.

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

      PERFORM consultar.
      selfield-refresh = 'X'.


    WHEN 'EDIT'.

      PERFORM f_confirmar
        USING
          'Confirmação de Edição'
          'Tem certeza que deseja editar este registro?'
          'Sim'
          'Não'
        CHANGING
          lv_resposta.

      IF lv_resposta = '1'.

        READ TABLE lt_func INTO ls_dados_selecionados INDEX selfield-tabindex.

        IF sy-subrc = 0.
          PERFORM f_navegar_para_edicao
            USING ls_dados_selecionados-id_func.
        ELSE.
          MESSAGE 'Selecione uma linha para editar.' TYPE 'I'.
        ENDIF.

      ENDIF.

      PERFORM consultar.
      selfield-refresh = 'X'.



    WHEN 'DELETE'.

      READ TABLE lt_func INTO ls_dados_selecionados INDEX selfield-tabindex.

      IF sy-subrc = 0.

        PERFORM f_iniciar_exclusao
          USING ls_dados_selecionados-id_func.

        PERFORM consultar.
        selfield-refresh = 'X'.

      ELSE.
        MESSAGE 'Selecione uma linha para excluir.' TYPE 'I'.
      ENDIF.

    WHEN OTHERS.

  ENDCASE.

ENDFORM.


FORM consultar.
  SELECT *
    INTO TABLE lt_func
    FROM ztb_func
    WHERE id_func  IN s_id[]
    AND   nome     IN s_nome[]
    AND   cargo    IN s_cargo[]
    AND   data_adm IN s_data[]
    AND   salario  IN s_salr[]
    AND   atividade = '1'.
ENDFORM.


*---------------------------------------------------------------------*
* Form LIMPA_TUDO
*---------------------------------------------------------------------*
FORM limpa_tudo .

  CLEAR: lt_func[], ls_func, v_repid , v_save , it_fcat[], it_fieldcat[], it_header[], it_sort[],
         wa_variant , wa_afield , wa_colinfo , wa_layout , wa_header , wa_lay , wa_sort .

ENDFORM. " limpa_tudo


*&---------------------------------------------------------------------*
*& Alterar funcionário
*&---------------------------------------------------------------------*
FORM alterar.

  SELECT SINGLE *
    FROM ztb_func
    INTO @ls_func
    WHERE id_func = @p_idfunc.

  IF sy-subrc <> 0.
    MESSAGE s002(zmsg_coffee) DISPLAY LIKE 'E'.
* Nenhum funcionário encontrado.
    EXIT.
  ENDIF.

  CALL SCREEN 9001.

  CLEAR: p_nome, p_idfunc.
  CALL SELECTION-SCREEN 1000.

ENDFORM.
*&---------------------------------------------------------------------*
*& deletar funcionário
*&---------------------------------------------------------------------*
FORM excluir.

  DATA lv_confirma TYPE c.

  " Verifica se o usuário informou o ID
  IF p_idfunc IS INITIAL.
    MESSAGE 'Informe o ID do funcionário para excluir.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Verifica se o funcionário existe
  SELECT SINGLE *
    FROM ztb_func
    INTO @ls_func
    WHERE id_func = @p_idfunc.

  IF sy-subrc <> 0.
    MESSAGE 'Funcionário não encontrado.' TYPE 'E'.
    EXIT.
  ENDIF.

  " Se já estiver inativo, não faz nada
  IF ls_func-atividade = '9'.
    MESSAGE 'Funcionário já está inativo.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Confirmação simples
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar      = 'Confirmação'
      text_question = |Deseja realmente inativar o funcionário { p_idfunc } ({ ls_func-nome })?|
      text_button_1 = 'Sim'
      text_button_2 = 'Não'
    IMPORTING
      answer        = lv_confirma.

  " Se o usuário apertar 'Sim' (resposta = '1')
  IF lv_confirma = '1'.

    UPDATE ztb_func
       SET atividade = '9'
     WHERE id_func = @p_idfunc.

    IF sy-subrc = 0.
      MESSAGE |Funcionário { p_idfunc } marcado como inativo.| TYPE 'S'.
    ELSE.
      MESSAGE 'Erro ao inativar funcionário.' TYPE 'E'.
    ENDIF.

  ELSE.
    MESSAGE 'Operação cancelada pelo usuário.' TYPE 'I'.
  ENDIF.

ENDFORM.

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


FORM f_navegar_para_edicao USING iv_id_func TYPE ztb_func-id_func.

  IF iv_id_func IS NOT INITIAL.

    SET PARAMETER ID 'ZID_FUNC' FIELD iv_id_func.

    CALL SCREEN 9001.

  ENDIF.

ENDFORM.



FORM f_obter_id_para_exibir
  CHANGING cv_proximo_id TYPE ztb_func-id_func.

  DATA: ls_nriv TYPE nriv.
  CLEAR cv_proximo_id.


  CALL FUNCTION 'NUMBER_GET_INFO'
    EXPORTING
      object      = 'ZID_FUNC01'
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
    CLEAR: p_idfunc, ls_func-id_func.
  ENDIF.

ENDFORM.



FORM f_gerar_id_final_number_next
  CHANGING cv_novo_id TYPE ztb_func-id_func.

  DATA: lv_number TYPE n LENGTH 20.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      object      = 'ZID_FUNC01'
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
    MESSAGE 'Erro fatal: Falha ao obter número de range.' TYPE 'E'.
  ENDIF.

ENDFORM.



FORM f_iniciar_exclusao
  USING uv_id_func TYPE ztb_func-id_func.

  DATA: lv_pop TYPE char01.

  " Chama o pop-up de confirmação
  PERFORM f_confirmar
    USING 'Confirmação de Inativação'
          'Deseja realmente INATIVAR o funcionário?'
          'Sim, Inativar'
          'Não'
    CHANGING lv_pop.

  IF lv_pop = '1'.

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

  ELSE.
    MESSAGE 'Inativação cancelada pelo usuário.' TYPE 'I'.
  ENDIF.

ENDFORM. " f_iniciar_exclusao


FORM f_bloquear_campos.

  LOOP AT SCREEN.
    IF screen-name EQ 'LS_FUNC-ID_FUNC' OR screen-name EQ 'CODIGO'.
      screen-input = 0.
      screen-required = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.
