*&---------------------------------------------------------------------*
*& Form f_inserir_cliente
*&---------------------------------------------------------------------*
*& Insere um novo registro de cliente usando o id como chave
*&---------------------------------------------------------------------*
FORM f_inserir_cliente.

  DATA: lv_id_cli TYPE ztb_clientes-id_cliente.
  DATA lv_salvou TYPE abap_bool.
  CLEAR lv_salvou.

  " 1. Limpa a estrutura global para receber novos dados na tela
  CLEAR ls_cliente.

  " 2. Chama a tela de inserção (9000). A tela preenche a LS_CLIENTE.
  CALL SCREEN 9000.

* 3. Geração e REVALIDAÇÃO CRÍTICA DO ID
  SELECT MAX( id_cliente ) FROM ztb_clientes INTO lv_id_cli.
  lv_id_cli = lv_id_cli + 1.

  " Checa se o ID da tela é o mesmo que o gerado agora.
  " Se forem diferentes, significa que outro usuário salvou na frente!
  IF lv_id_cli <> ls_cliente-id_cliente.
    " ID da tela está desatualizado. Recomenda-se um ROLLBACK ou um aviso.
    MESSAGE 'O número do cliente foi atualizado. Salve novamente.' TYPE 'E'.
    ROLLBACK WORK.
    EXIT.
  ENDIF.

  " 3. Verifica se o usuário preencheu/confirmou e se o CPF está preenchido
  IF ls_cliente-cpf IS INITIAL.
    MESSAGE 'Inserção de cliente abortada ou CPF não informado.' TYPE 'I'.
    EXIT.
  ENDIF.

  DATA: lv_id_existente  TYPE zid_cliente.

  " 4. Verifica se o CPF já existe no banco de dados
  SELECT SINGLE id_cliente
    FROM ztb_clientes
    INTO ( @lv_id_existente )
    WHERE id_cliente = @ls_cliente-id_cliente.


  IF sy-subrc = 0.
    MESSAGE |CPF ou ID{ ls_cliente-cpf } já cadastrado. Não é possível duplicar o registro.| TYPE 'E'.
    EXIT.
  ENDIF.

  " 5. Insere o registro
  INSERT ztb_clientes FROM ls_cliente.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Cliente ID { ls_cliente-id_cliente } cadastrado com sucesso!| TYPE 'S'.
    lv_salvou = abap_true.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Erro ao inserir registro. Verifique a integridade dos dados.' TYPE 'E'.
  ENDIF.

  " 6. Limpeza e retorno à tela de seleção após o sucesso
  IF lv_salvou = abap_true.
    CLEAR: s_cpf[], s_nome[]. " Limpa o conteúdo das tabelas internas
    CALL SELECTION-SCREEN 1000.
  ENDIF.

ENDFORM. " f_inserir_cliente


**&---------------------------------------------------------------------*
**& Form f_alterar_cliente
**&---------------------------------------------------------------------*
**& altera um  registro de cliente usando o CPF como chave
**&---------------------------------------------------------------------*
*
*FORM f_alterar_cliente.


FORM f_alterar_cliente.

  IF p_id IS INITIAL.
    MESSAGE 'Para alterar, informe um id do cliente' TYPE 'I'.
  ENDIF.

  SELECT SINGLE *
    FROM ztb_clientes
    INTO @ls_cliente
    WHERE id_cliente = @p_id.

  IF sy-subrc <> 0.
    MESSAGE |Cliente ID { p_id } não encontrado.| TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  CALL SCREEN 9001.

  CLEAR: p_id.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_exibir_cliente
*&---------------------------------------------------------------------*
*& altera um  registro de cliente usando o CPF como chave
*&---------------------------------------------------------------------*

FORM f_exibir_cliente.

  DATA(lv_ativo) = p_ativo.

  IF p_all IS NOT INITIAL.
    SELECT a~id_cliente,
           a~cpf,
           a~nome_cli,
           a~data_nasc,
           a~telefone,
           a~cidade,
           a~status_cli,
           b~ddtext      AS status_desc
      FROM ztb_clientes AS a
      LEFT JOIN dd07t AS b
        ON  b~domname    = 'Z_STATUS_CLI_D'
        AND b~domvalue_l = a~status_cli
        AND b~ddlanguage = @sy-langu
  WHERE id_cliente  IN @s_id
    AND cpf         IN @s_cpf
    AND nome_cli    IN @s_nome
    AND data_nasc   IN @s_data
    AND telefone    IN @s_tel
      INTO CORRESPONDING FIELDS OF TABLE @lt_cliente.
  ELSE.
    SELECT a~id_cliente,
         a~cpf,
         a~nome_cli,
         a~data_nasc,
         a~telefone,
         a~cidade,
         a~status_cli,
         b~ddtext      AS status_desc
    FROM ztb_clientes AS a
    LEFT JOIN dd07t AS b
      ON  b~domname    = 'Z_STATUS_CLI_D'
      AND b~domvalue_l = a~status_cli
      AND b~ddlanguage = @sy-langu
    WHERE id_cliente  IN @s_id
      AND cpf         IN @s_cpf
      AND nome_cli    IN @s_nome
      AND data_nasc   IN @s_data
      AND telefone    IN @s_tel
      AND status_cli  = @lv_ativo
    INTO CORRESPONDING FIELDS OF TABLE @lt_cliente.
  ENDIF.

  IF lt_cliente IS INITIAL.
    MESSAGE 'Nenhum cliente encontrado com os filtros informados.' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM f_exibir_alv.

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


*&---------------------------------------------------------------------*
*& Form f_exibir_alv
*&---------------------------------------------------------------------*
*& Orquestra a exibição do ALV
*&---------------------------------------------------------------------*
FORM f_exibir_alv .

  " 1. Define ordenação
  PERFORM f_alv_sort_cli.

  " 2. Define campos a exibir
  PERFORM f_alv_fieldcat_cli.

  " 3. Imprime relatório
  PERFORM f_alv_imprime_cli.

ENDFORM. " f_exibir_alv



*&---------------------------------------------------------------------*
*& Form F_ALV_SORT_cli
*&---------------------------------------------------------------------*
*& Define a ordenação inicial da lista (Tabela: IT_SORT)
*&---------------------------------------------------------------------*
FORM f_alv_sort_cli.

  DATA i TYPE i.
  CLEAR it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'ID_CLIENTE'.
  wa_sort-up          = 'X'. " Ordem Crescente
  APPEND wa_sort TO it_sort.


  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'CPF'.
  wa_sort-up          = 'X'. " Ordem Crescente
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'NOME_CLI'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'DATA_NASC'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'TELEFONE'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'STATUS_CLI'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

  i = i + 1.
  CLEAR wa_sort.
  wa_sort-spos        = i.
  wa_sort-fieldname   = 'STATUS_DESC'.
  wa_sort-up          = 'X'.
  APPEND wa_sort TO it_sort.

ENDFORM. " f_alv_sort_cli

*&---------------------------------------------------------------------*
*& Form F_ALV_FIELDCAT_CLI
*&---------------------------------------------------------------------*
*& Define os campos e características de exibição (Tabela: IT_FIELDCAT)
*&---------------------------------------------------------------------*
FORM f_alv_fieldcat_cli.

  DATA i TYPE i.
  CLEAR it_fieldcat. " Limpa catálogo de campos

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'ID_CLIENTE'.
  wa_afield-seltext_l         = 'Cod Cliente'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  wa_afield-key               = 'X'. " Campo chave
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'CPF'.
  wa_afield-seltext_l         = 'CPF do cliente'.
  wa_afield-ref_fieldname     = 'CPF'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  wa_afield-key               = 'X'. " Campo chave
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'NOME_CLI'.
  wa_afield-seltext_l         = 'Nome do cliente'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'DATA_NASC'.
  wa_afield-seltext_l         = 'Data de nascimento'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'TELEFONE'.
  wa_afield-seltext_l         = 'Número de telefone'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'CIDADE'.
  wa_afield-seltext_l         = 'Cidade'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'STATUS_CLI'.
  wa_afield-seltext_l         = 'Situação'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  wa_afield-ddictxt           = 'L'.
  APPEND wa_afield TO it_fieldcat.

  i = i + 1.
  CLEAR wa_afield.
  wa_afield-col_pos           = i.
  wa_afield-fieldname         = 'STATUS_DESC'.
  wa_afield-seltext_l         = 'Descrição Situação'.
  wa_afield-ref_tabname       = 'ZTB_CLIENTES'.
  wa_afield-outputlen         = 30. "
  APPEND wa_afield TO it_fieldcat.



ENDFORM. " f_alv_fieldcat_cli

*&---------------------------------------------------------------------*
*& Form F_ALV_IMPRIME_CLI
*&---------------------------------------------------------------------*
*& Chama a função principal de exibição do ALV (REUSE_ALV_GRID_DISPLAY)
*&---------------------------------------------------------------------*
FORM f_alv_imprime_cli.

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
*     i_callback_top_of_page   = 'lt_header'
      i_grid_title             = 'Relatório de Clientes' " Título alterado
      is_layout                = wa_lay
      it_fieldcat              = it_fcat
      it_sort                  = it_sort[]
      i_save                   = v_save
      is_variant               = wa_variant
    TABLES
      t_outtab                 = lt_cliente " Tabela interna de clientes
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I'
    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    STOP.
  ENDIF.
ENDFORM. " f_alv_imprime_cli

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

* Lê a linha da tabela interna para a estrutura global
  READ TABLE lt_cliente INTO ls_cliente INDEX selfield-tabindex.
  ld_field = ls_cliente-cpf.
  CONDENSE ld_field NO-GAPS.

  CASE ucomm.
    WHEN 'CREATE'. " Comando para criar um novo registro

      PERFORM f_confirmar
        USING
          'Confirmação de Criação de Cliente'
          'Tem certeza que deseja criar um novo registro de cliente?'
          'Sim '
          'Não '
        CHANGING
          gd_resposta.

      IF sy-subrc = 0 AND gd_resposta = '1'.
        CLEAR ls_cliente.
        PERFORM f_inserir_cliente. " Chama a lógica de inserção de produto

      ELSEIF sy-subrc = 0 AND gd_resposta = '2'.
        MESSAGE 'Criação de produto cancelada pelo usuário.' TYPE 'I'.
      ENDIF.

      CLEAR gd_resposta.
      PERFORM f_exibir_cliente. " Atualiza a lista
      selfield-refresh = 'X'.

    WHEN 'EDIT'. " Comando para editar o registro selecionado (pode ser um botão customizado)

      PERFORM f_confirmar " Esta subroutine deve ser criada/implementada
        USING
          'Confirmação de Edição de Cliente'
          'Tem certeza que deseja editar este registro do cliente?'
          'Sim'
          'Não'
        CHANGING
          gd_resposta.

      IF gd_resposta = '1'.
        READ TABLE lt_cliente INTO ls_dados_selecionados INDEX selfield-tabindex.

        IF sy-subrc = 0.
          PERFORM f_navegar_para_edicao USING ls_dados_selecionados-cpf. " ID do produto
        ELSE.
          MESSAGE 'Selecione uma linha para editar.' TYPE 'I'.
        ENDIF.
      ENDIF.

      PERFORM f_exibir_cliente. " Atualiza a lista
      selfield-refresh = 'X'.

    WHEN 'DELETE'. " Comando para deletar o registro selecionado (pode ser um botão customizado)

      READ TABLE lt_cliente INTO ls_dados_selecionados INDEX selfield-tabindex.

      IF sy-subrc = 0.
        PERFORM f_iniciar_exclusao USING ls_dados_selecionados-cpf. " ID do produto

        PERFORM f_exibir_cliente. " Atualiza a lista
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

  " Limpeza de dados de produto e estruturas ALV
  CLEAR: lt_cliente[],              " Tabela interna principal de produtos
         ls_cliente,                " Estrutura de trabalho
         ls_dados_selecionados,  " Estrutura para dados selecionados do ALV
         v_repid, v_save,
         it_fcat[], it_fieldcat[], it_header[], it_sort[],
         wa_variant, wa_afield, wa_colinfo, wa_layout, wa_header, wa_lay, wa_sort.

  " Limpeza dos SELECT-OPTIONS
  CLEAR: s_cpf[], s_nome[], s_data[], s_tel[].

  " Limpeza dos parâmetros de seleção
  CLEAR: s_cpf, s_nome.


ENDFORM. " f_limpa_tudo

*&---------------------------------------------------------------------*
*& Form f_consultar_cliente_simples
*&---------------------------------------------------------------------*
*& Realiza uma consulta genérica usando todos os SELECT-OPTIONS de cliente
*&---------------------------------------------------------------------*
FORM f_consultar_cliente_simples.

  DATA(lv_status_ativo) = COND #( WHEN p_ativo = 'X' THEN '1' ELSE '%' ).

  SELECT *
    INTO TABLE @lt_cliente
    FROM ztb_clientes
    WHERE cpf          IN @s_cpf[]
    AND   nome_cli     IN @s_nome[]
    AND   data_nasc    IN @s_data[]
    AND   telefone     IN @s_tel[]
    AND   status_cli   LIKE @lv_status_ativo. " Filtrando pelo status (1 ou %)

ENDFORM. " f_consultar_cliente_simples

*&---------------------------------------------------------------------*
*& Form f_navegar_para_edicao
*&---------------------------------------------------------------------*
*& Navega do ALV para a tela 9001 (Edição)
*&---------------------------------------------------------------------*
FORM f_navegar_para_edicao USING iv_cpf TYPE ztb_clientes-cpf.

  IF iv_cpf IS NOT INITIAL.

    SET PARAMETER ID 'ZCPF_E' FIELD iv_cpf.

    " Chama a tela de Edição/Alteração
    CALL SCREEN 9001.

  ENDIF.

ENDFORM. " f_navegar_para_edicao

*&---------------------------------------------------------------------*
*& Form f_iniciar_exclusao
*&---------------------------------------------------------------------*
*& Inativa o cliente selecionado no ALV (Deleção Lógica)
*&---------------------------------------------------------------------*
FORM f_iniciar_exclusao
  USING uv_cpf TYPE ztb_clientes-cpf.

  DATA: lv_pop TYPE char01.

  " Obter o nome do cliente para a mensagem (opcional, mas bom para UX)
  SELECT SINGLE nome_cli INTO @DATA(lv_nome_cli) FROM ztb_clientes WHERE cpf = @uv_cpf.
  IF sy-subrc <> 0.
    lv_nome_cli = 'Não encontrado'.
  ENDIF.

  " Chama o pop-up de confirmação (necessita do FORM f_confirmar)
  PERFORM f_confirmar
    USING 'Confirmação de Inativação de Cliente'
          'Deseja realmente INATIVAR o cliente?'
          'Sim, Inativar'
          'Não'
    CHANGING lv_pop.

  IF lv_pop = '1'.

    " Executa a exclusão lógica: Altera o campo STATUS_CLI para '9' (Inativo)
    UPDATE ztb_clientes
       SET status_cli = '9'
     WHERE cpf = uv_cpf.

    IF sy-subrc = 0.
      COMMIT WORK.
      MESSAGE |Cliente CPF { uv_cpf } inativado com sucesso!| TYPE 'S'.

    ELSE.
      ROLLBACK WORK.
      MESSAGE 'Erro ao inativar cliente.' TYPE 'E'.
    ENDIF.

  ELSE.
    MESSAGE 'Inativação de cliente cancelada pelo usuário.' TYPE 'I'.
  ENDIF.

ENDFORM. " f_iniciar_exclusao
