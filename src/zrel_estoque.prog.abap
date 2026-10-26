REPORT zrel_estoque.

INCLUDE zrel_estoque_top.
INCLUDE zrel_estoque_pbo.

INCLUDE zrel_estoque_pai.
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
* Tela de Seleção (Selection-Screen)
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
* TEXT-t01: 'Filtros de Produtos' (Definido nas Textos de Seleção)

* Select-Options: Múltiplos filtros para campos da tabela ztb_prod
  SELECT-OPTIONS: s_idprd FOR wa_prod-id_prod,      " ID do Produto
                  s_preco FOR wa_prod-preco,        " Preço do Produto
                  s_qtde  FOR wa_prod-qtde_estoque, " Quantidade em Estoque
                  s_categ FOR wa_prod-categoria.    " Categoria do Produto

* Parâmetro: Selecionar Todos os Dados (Ignora os SELECT-OPTIONS acima)
  PARAMETERS: p_all AS CHECKBOX DEFAULT 'X'.
  PARAMETERS: p_sts TYPE ztb_prod-status_prod.

  PARAMETERS: p_verde TYPE zqtde_estoque DEFAULT 50,  " Qtde mínima para LED VERDE (>= p_verde)
              p_amare TYPE zqtde_estoque DEFAULT 10.  " Qtde mínima para LED AMARELO (p_amare <= Qtde < p_verde, abaixo é VERMELHO)
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Evento START-OF-SELECTION: Ponto de partida da execução do relatório
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM exibir_alv. " Chamada para a rotina principal de exibição do ALV

*----------------------------------------------------------------------*
* Rotina para buscar os dados, processar os ícones de status e exibir o ALV
*----------------------------------------------------------------------*
FORM exibir_alv.

*--- Busca os dados com JOIN (apenas uma rotina centralizada)
  PERFORM f_exibir_prod.

  IF it_prod IS INITIAL.
    MESSAGE 'Sem dados para esses filtros' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

*--- Processa os ícones
  LOOP AT it_prod ASSIGNING FIELD-SYMBOL(<fs_prod>).
    IF <fs_prod>-qtde_estoque >= p_verde.
      <fs_prod>-status_icon = '@08@'. " Verde
    ELSEIF <fs_prod>-qtde_estoque >= p_amare.
      <fs_prod>-status_icon = '@09@'. " Amarelo
    ELSE.
      <fs_prod>-status_icon = '@0A@'. " Vermelho
    ENDIF.
  ENDLOOP.


*----------------------------------------------------------------------*
* 1. DEFINIÇÃO DO SORT CATALOG (IT_SORT)
*----------------------------------------------------------------------*
  CLEAR it_sort[].
  CLEAR wa_sort.

* Ordena pelo ID do Produto (ID_PROD)
  wa_sort-fieldname = 'ID_PROD'.
  wa_sort-up = 'X'. " 'X' = Ascendente (crescente), ' ' = Descendente
  wa_sort-subtot = ' '. " 'X' se for criar um subtotal para esse campo
  APPEND wa_sort TO it_sort.

* Se quiser um segundo nível de ordenação (ex: pela Categoria)
* CLEAR wa_sort.
* wa_sort-fieldname = 'CATEGORIA'.
* wa_sort-up = 'X'.
* APPEND wa_sort TO it_sort.


*----------------------------------------------------------------------*
* Definição das Colunas no Field Catalog (it_fieldcat)
*----------------------------------------------------------------------*
  DATA i TYPE i.
* Coluna 0: Ícone de Status do Estoque
  i = i + 1.
  wa_fieldcat-fieldname = 'STATUS_ICON'.
  wa_fieldcat-seltext_m = 'Estoque'.
  wa_fieldcat-col_pos   = i.
  wa_fieldcat-outputlen = 4.      " Tamanho pequeno para o ícone
  wa_fieldcat-just      = 'C'.    " Centralizado
  wa_fieldcat-icon      = 'X'.    " Marca a coluna como ícone
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Coluna 1: ID do Produto (Chave)
  i = i + 1.
  wa_fieldcat-fieldname = 'ID_PROD'.
  wa_fieldcat-seltext_m = 'Cod. Produto'.
  wa_fieldcat-col_pos = i.
  wa_fieldcat-outputlen = 6.
  wa_fieldcat-key = 'X'. " Coluna chave para destaque
  wa_fieldcat-just = 'L'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Coluna 2: Nome do Produto
  i = i + 1.
  wa_fieldcat-fieldname = 'NOME_PROD'.
  wa_fieldcat-seltext_m = 'Produto'.
  wa_fieldcat-col_pos = i.
  wa_fieldcat-outputlen = 30.
  wa_fieldcat-just = 'C'.
* wa_fieldcat-edit = 'X'. " Se a coluna pudesse ser editada no ALV
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Coluna 3: Categoria (Código)
  i = i + 1.
  wa_fieldcat-fieldname = 'CATEGORIA'.
  wa_fieldcat-seltext_m = 'Categoria'.
  wa_fieldcat-col_pos = i.
  wa_fieldcat-outputlen = 20.
  wa_fieldcat-just = 'L'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Coluna 4: Descrição da Categoria (Busca de DD07T no SELECT)
  i = i + 1.
  wa_fieldcat-col_pos           = i.
  wa_fieldcat-fieldname         = 'CATEGORIA_DESC'.
  wa_fieldcat-seltext_l         = 'Descrição da Categoria'.
  wa_fieldcat-ref_fieldname     = 'CATEGORIA_DESC'.
  wa_fieldcat-ref_tabname       = 'ZTB_PROD'. " Referência à estrutura/tabela (opcional se não for campo de dicionário)
  wa_fieldcat-outputlen         = 30.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Coluna 5: Quantidade em Estoque
  i = i + 1.
  wa_fieldcat-fieldname = 'QTDE_ESTOQUE'.
  wa_fieldcat-seltext_m = 'Quantidade'.
  wa_fieldcat-col_pos = i.
  wa_fieldcat-outputlen = 20.
  wa_fieldcat-just = 'L'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.


* Coluna 7: Status do Produto (Código)
  i = i + 1.
  wa_fieldcat-fieldname = 'STATUS_PROD'.
  wa_fieldcat-seltext_m = 'Status'.
  wa_fieldcat-col_pos = i.
  wa_fieldcat-outputlen = 10.
  wa_fieldcat-just = 'L'.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Coluna 8: Descrição do Status (Busca de DD07T no SELECT)
  i = i + 1.
  wa_fieldcat-col_pos           = i.
  wa_fieldcat-fieldname         = 'STATUS_DESC'.
  wa_fieldcat-seltext_l         = 'Descrição Situação'.
  wa_fieldcat-ref_fieldname     = 'STATUS_DESC'.
  wa_fieldcat-ref_tabname       = 'ZTB_PROD'.
  wa_fieldcat-outputlen         = 30.
  APPEND wa_fieldcat TO it_fieldcat.
  CLEAR wa_fieldcat.

* Layout alv: Ativa a Zebragem (cores alternadas nas linhas)
  wa_layout-zebra = 'X'.

* Chamada da Função para Exibir o alv
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid         " Nome do programa de chamada
      i_callback_pf_status_set = 'PF_STATUS_SET'  " Rotina para configurar o Status GUI
      i_callback_user_command  = 'USER_COMMAND'   " Rotina para comandos do usuário (botões)
      is_layout                = wa_layout        " Layout (Zebra, títulos, etc.)
      it_fieldcat              = it_fieldcat      " Catálogo de Campos (colunas)
      i_grid_title             = 'Relatório detalhado do estoque'
    TABLES
      t_outtab                 = it_prod.         " Tabela Interna de Dados
ENDFORM.

*----------------------------------------------------------------------*
* Rotina PF_STATUS_SET: Define o Status GUI e botões customizados
* Usada pelo ALV.
*----------------------------------------------------------------------*
FORM pf_status_set USING extab TYPE slis_t_extab.
* Define o Status GUI (STANDARD inclui botões como 'Detalhe', 'Filtro', etc.)
* Se houver botões customizados (como 'EDIT' ou '&DATA_SAVE'), devem ser
* incluídos ou no status 'STANDARD' (copiado e modificado) ou em um customizado.
  SET PF-STATUS 'STANDARD'.
ENDFORM.

*----------------------------------------------------------------------*
* Rotina F_SAVE_DATA: Rotina para salvar alterações feitas no ALV (se for editável)
* Nota: A edição real no ALV não está configurada (wa_fieldcat-edit comentado),
* mas a rotina de salvar está presente.
*----------------------------------------------------------------------*
FORM f_save_data.
  DATA: wa_prodcp   TYPE ztb_prod, " Cópia do registro
        wa_prod_tmp TYPE ztb_prod. " Registro temporário para modificação

  CLEAR it_changes[]. " Limpa a tabela de controle de mudanças (assumindo que existe em TOP)

* Compara os dados atuais (it_prod) com a cópia original (it_prodcp)
  LOOP AT it_prod INTO wa_prod.

    READ TABLE it_prodcp INTO wa_prodcp INDEX sy-tabix.

    IF wa_prodcp NE wa_prod. " Se houver diferença, houve alteração
      APPEND wa_prod TO it_changes.         " Guarda o registro alterado
      MOVE-CORRESPONDING wa_prod TO wa_prod_tmp. " Move para a área de trabalho temporária

* Tenta modificar o registro no Banco de Dados
      MODIFY ztb_prod FROM wa_prod_tmp.
* Idealmente, adicionar commit work aqui ou ao final, dependendo da necessidade
    ENDIF.

    CLEAR wa_prodcp. " Limpa a cópia para a próxima iteração

  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
* Rotina USER_COMMAND: Processa os comandos de função (botões) do usuário no ALV
* Usada pelo ALV.
*----------------------------------------------------------------------*
FORM user_command USING p_ucomm TYPE sy-ucomm " Comando de função
                      p_selfield TYPE slis_selfield. " Informações do campo/linha selecionada

  DATA ld_field TYPE char10.

  CASE p_ucomm.
    WHEN 'EDIT'. " Comando de função para Edição
* Busca a linha selecionada para obter os dados
      READ TABLE it_prod INTO wa_prod_sel INDEX p_selfield-tabindex.
      IF sy-subrc = 0.
        PERFORM f_navegar_para_edicao USING wa_prod_sel-id_prod. " Navega para a transação de edição (CALL SCREEN 0100)
      ELSE.
        MESSAGE 'Selecione uma linha para editar.' TYPE 'I'.
      ENDIF.

* Atualiza a lista alv após o retorno da tela de edição (necessário para refletir mudanças)
      PERFORM f_exibir_prod. " Recarrega os dados (f_exibir_prod precisa ser renomeado para "f_buscar_dados" - veja nota abaixo)
      p_selfield-refresh = 'X'. " Força o refresh do ALV

    WHEN '&DATA_SAVE'. " Comando para Salvar (padrão SAP para salvar no ALV Editável)
      PERFORM f_save_data.

  ENDCASE.
ENDFORM.

*----------------------------------------------------------------------*
* Rotina F_NAVEGAR_PARA_EDICAO: Navega para a tela de edição do produto
* Recebe o ID do produto selecionado.
*----------------------------------------------------------------------*
FORM f_navegar_para_edicao  USING  iv_id_prod TYPE ztb_prod-id_prod.

  IF iv_id_prod IS NOT INITIAL.

* Define o id de Parâmetro para ser lido na tela de edição (CALL SCREEN 0100)
    SET PARAMETER ID 'ZID_PROD' FIELD iv_id_prod.

* Verificação do produto (opcional se já tiver sido verificado anteriormente)
    SELECT SINGLE *
    FROM ztb_prod
    INTO @wa_prod
    WHERE id_prod = @iv_id_prod.

    IF sy-subrc <> 0.
* Mensagem de Produto não encontrado. (Ajuste a ID/Número da mensagem)
      MESSAGE |Produto ID { iv_id_prod } não encontrado.| TYPE 'E'.
      EXIT.
    ENDIF.

* Chama a tela de Edição/Alteração (assumindo que a tela 0100 é a tela de edição)
    CALL SCREEN 0100.

  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Rotina F_EXIBIR_PROD: Busca os dados dos produtos com JOIN para descrições
* Nota: Essa rotina substitui/complementa a lógica de SELECT da "exibir_alv"
* para inclusão de textos de domínio.
* Sugestão: Renomear para F_BUSCAR_DADOS_JOIN para maior clareza de função.
*----------------------------------------------------------------------*
FORM f_exibir_prod.

  IF p_all = 'X'.

*--------------------------------------------------------------*
*  CASO 1: Buscar tudo (ignora todos os filtros)
*--------------------------------------------------------------*
    SELECT a~id_prod,
           a~nome_prod,
           a~categoria,
           b~ddtext           AS categoria_desc,
           a~preco,
           a~qtde_estoque,
           a~status_prod,
           a~status_icon,
           c~ddtext           AS status_desc
      FROM ztb_prod AS a
      LEFT JOIN dd07t AS b
        ON  b~domname    = 'ZDO_TIPOPROD'
        AND b~domvalue_l = a~categoria
        AND b~ddlanguage = @sy-langu
      LEFT JOIN dd07t AS c
        ON  c~domname    = 'ZSTATUS_PROD_D'
        AND c~domvalue_l = a~status_prod
        AND c~ddlanguage = @sy-langu
      INTO CORRESPONDING FIELDS OF TABLE @it_prod.

  ELSE.

*--------------------------------------------------------------*
*  CASO 2: Buscar aplicando filtros da tela de seleção
*--------------------------------------------------------------*
    SELECT a~id_prod,
           a~nome_prod,
           a~categoria,
           b~ddtext           AS categoria_desc,
           a~preco,
           a~waers,
           a~qtde_estoque,
           a~status_prod,
           a~status_icon,
           c~ddtext           AS status_desc
      FROM ztb_prod AS a
      LEFT JOIN dd07t AS b
        ON  b~domname    = 'ZDO_TIPOPROD'
        AND b~domvalue_l = a~categoria
        AND b~ddlanguage = @sy-langu
      LEFT JOIN dd07t AS c
        ON  c~domname    = 'ZSTATUS_PROD_D'
        AND c~domvalue_l = a~status_prod
        AND c~ddlanguage = @sy-langu
      WHERE a~id_prod        IN @s_idprd
        AND a~categoria     IN @s_categ
        AND a~qtde_estoque  IN @s_qtde
        AND a~preco         IN @s_preco
        AND ( a~status_prod = @p_sts OR @p_sts IS INITIAL )  " evita bug quando p_sts vazio
      INTO CORRESPONDING FIELDS OF TABLE @it_prod.

  ENDIF.
ENDFORM.
