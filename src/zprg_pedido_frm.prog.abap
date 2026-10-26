*---------------------------------------------------------------------*
* FORM f_criar_pedido
*---------------------------------------------------------------------*
* Responsável por:
* - Inicializar variáveis para criação de um novo pedido
* - Definir o modo de operação como Criação
* - Gerar o ID do pedido (apenas uma vez)
* - Navegar para a tela principal de manutenção do pedido
*---------------------------------------------------------------------*
FORM f_criar_pedido.

  " Limpa estruturas e tabelas internas
  CLEAR: gs_pedit,
         gs_ped,
         gs_out.
  CLEAR gt_pedit.

  " Define modo de criação
  gd_mode = 'C'.

  "-------------------------------------------------------------*
  " Geração do ID do pedido
  "-------------------------------------------------------------*
  IF gs_ped-id_ped IS INITIAL.
    PERFORM f_gerar_id_por_max
      CHANGING gs_ped-id_ped.
  ENDIF.

  " Abre a tela principal de criação/edição do pedido
  CALL SCREEN 2000.

ENDFORM.

*---------------------------------------------------------------------*
* FORM f_modificar_pedido
*---------------------------------------------------------------------*
* Responsável por:
* - Direcionar o usuário para a tela de busca de pedidos
* - Preparar o fluxo para edição de um pedido existente
*---------------------------------------------------------------------*
FORM f_modificar_pedido.

  " Abre a tela de pesquisa/seleção de pedido
  CALL SCREEN 3100.

ENDFORM.


*---------------------------------------------------------------------*
* FORM f_leave_screen
*---------------------------------------------------------------------*
* Responsável por:
* - Retornar à tela anterior
* - Encerrar corretamente o fluxo de navegação
*---------------------------------------------------------------------*
FORM f_leave_screen.

  " Retorna para a tela anterior
  LEAVE TO SCREEN 0.

ENDFORM.


*---------------------------------------------------------------------*
* FORM f_salvar_pedido
*---------------------------------------------------------------------*
* Função principal de persistência do pedido.
*
* Responsável por:
* 1. Validar campos obrigatórios
* 2. Validar estoque (pré-insert)
* 3. Inserir ou atualizar o cabeçalho do pedido
* 4. Salvar os itens do pedido
* 5. Atualizar o estoque (débito real)
* 6. Executar COMMIT e retornar mensagem ao usuário
*---------------------------------------------------------------------*
FORM f_salvar_pedido.

  DATA: lv_salvou TYPE abap_bool VALUE abap_false.

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

  IF gt_pedit IS INITIAL.
    MESSAGE 'O pedido deve ter pelo menos um item.' TYPE 'E'.
    RETURN.
  ENDIF.

*  "-------------------------------------------------------------*
*  " 2. Agrupamento automático de itens
*  "-------------------------------------------------------------*
*  DATA: lt_pedit TYPE STANDARD TABLE OF ty_pedit_screen,
*        ls_pedit TYPE ty_pedit_screen.
*
*  SORT gt_pedit BY id_prod preco_unit.
*
*  LOOP AT gt_pedit INTO ls_pedit.
*    COLLECT ls_pedit INTO lt_pedit.
*  ENDLOOP.
*
*  gt_pedit = lt_pedit.
*
*  MODIFY gt_pedit FROM ls_pedit.
*


  "-------------------------------------------------------------*
  " 3. Pré-validação de estoque
  "-------------------------------------------------------------*
  " Validação crítica: ocorre antes de qualquer INSERT/UPDATE
  PERFORM f_validar_estoque.
  IF sy-subrc <> 0.
    " Em caso de erro, o processo é interrompido
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 3. Salvamento do cabeçalho (Criação ou Edição)
  "-------------------------------------------------------------*
  IF gd_mode = 'C'.

    " Garante a geração do ID do pedido
    IF gs_ped-id_ped IS INITIAL.
      PERFORM f_gerar_id_por_max
        CHANGING gs_ped-id_ped.
    ENDIF.

    " Insere o cabeçalho do pedido
    PERFORM salvar_cabecalho_db
      CHANGING lv_salvou.

    IF lv_salvou = abap_false.
      RETURN.
    ENDIF.

  ELSEIF gd_mode = 'E'.

    " Validação de segurança: pedido deve estar carregado
    IF gs_ped-id_ped IS INITIAL.
      MESSAGE 'Pedido não carregado para edição.' TYPE 'E'.
      RETURN.
    ENDIF.

    " Atualiza o cabeçalho do pedido
    PERFORM atualizar_cabecalho_db
      CHANGING lv_salvou.

    IF lv_salvou = abap_false.
      RETURN.
    ENDIF.

  ENDIF.

  "-------------------------------------------------------------*
  " 4. Salvamento dos itens do pedido
  "-------------------------------------------------------------*
  PERFORM salvar_pedido_db
    CHANGING lv_salvou.

  IF lv_salvou = abap_false.
    RETURN.
  ENDIF.

  "-------------------------------------------------------------*
  " 5. Atualização de estoque (débito real)
  "-------------------------------------------------------------*
  " A validação já ocorreu anteriormente.
  " Aqui apenas efetuamos o débito, sem rollback do pedido.
  LOOP AT gt_pedit INTO gs_est_pedit.

    CALL FUNCTION 'ZF_ATUALIZA_ESTOQUE_'
      EXPORTING
        iv_id_prod             = gs_est_pedit-id_prod
        iv_qtde_vendida        = gs_est_pedit-qtde
      EXCEPTIONS
        estoque_insuficiente   = 1
        produto_nao_encontrado = 2
        OTHERS                 = 3.

    CASE sy-subrc.
      WHEN 1 OR 2.
        MESSAGE |Falha ao debitar estoque para o produto { gs_est_pedit-id_prod }| TYPE 'W'.
        " O pedido já foi salvo e validado — segue o processamento
        CONTINUE.
    ENDCASE.

  ENDLOOP.

  "-------------------------------------------------------------*
  " 6. Commit final e mensagem ao usuário
  "-------------------------------------------------------------*
  COMMIT WORK AND WAIT.

  IF sy-subrc = 0.

    IF gd_mode = 'C'.
      MESSAGE 'Pedido criado com sucesso!' TYPE 'S'.
    ELSEIF gd_mode = 'E'.
      MESSAGE 'Pedido alterado com sucesso!' TYPE 'S'.
    ENDIF.

    LEAVE TO SCREEN 0.

  ELSE.
    MESSAGE 'Erro ao salvar o pedido no banco de dados após o COMMIT.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_salvar_pedido

*---------------------------------------------------------------------*
* FORM f_gerar_id_por_max
*---------------------------------------------------------------------*
* Responsável por:
* - Gerar o próximo ID do pedido baseado no maior ID existente
* - Garantir preenchimento com zeros à esquerda (NUMC)
*---------------------------------------------------------------------*
FORM f_gerar_id_por_max
  CHANGING cv_id TYPE ztb_ped-id_ped.

  DATA lv_max TYPE ztb_ped-id_ped.

  " Busca o maior ID existente na tabela de pedidos
  SELECT MAX( id_ped )
    INTO @lv_max
    FROM ztb_ped.

  " Caso a tabela esteja vazia
  IF sy-subrc <> 0 OR lv_max IS INITIAL.
    cv_id = '0000000001'.
  ELSE.
    " Incrementa o ID
    cv_id = lv_max + 1.

    " Converte para NUMC com zeros à esquerda
    cv_id = |{ cv_id ALPHA = IN }|.
  ENDIF.

ENDFORM. " f_gerar_id_por_max


*---------------------------------------------------------------------*
* FORM salvar_pedido_db
*---------------------------------------------------------------------*
* FORM de suporte responsável EXCLUSIVAMENTE pelo salvamento
* dos ITENS do pedido no banco de dados.
*
* Estratégia adotada:
* - Criação  : INSERT de todos os itens informados em tela
* - Edição   : DELETE de todos os itens existentes no DB
*              seguido de INSERT de todos os itens da tela
*
* Observação:
* - O controle de COMMIT é feito externamente (FORM principal)
* - Em caso de erro, é executado ROLLBACK WORK
*---------------------------------------------------------------------*
FORM salvar_pedido_db
  CHANGING ev_ok TYPE abap_bool.

  ev_ok = abap_false.

  "-------------------------------------------------------------*
  " 1. Salvamento dos itens do pedido
  "-------------------------------------------------------------*
  IF gd_mode = 'C'.

    "-----------------------------------------------------------*
    " Modo Criação
    "-----------------------------------------------------------*
    " Percorre todos os itens da tela e realiza INSERT no DB
    LOOP AT gt_pedit INTO gs_est_pedit.

      PERFORM f_inserir_item_db.
      IF sy-subrc <> 0.
        " Em caso de erro no INSERT, desfaz toda a LUW
        ROLLBACK WORK.
        RETURN.
      ENDIF.

    ENDLOOP.

  ELSEIF gd_mode = 'E'.

    "-----------------------------------------------------------*
    " Modo Edição
    "-----------------------------------------------------------*
    " Estratégia: DELETE ALL + INSERT ALL
    " Simplifica o controle de itens alterados/excluídos/incluídos

    " A. Remove todos os itens existentes do pedido no DB
    DELETE FROM ztb_pedit
      WHERE id_ped = gs_ped-id_ped.

    " sy-subrc = 4 → nenhum registro encontrado (aceitável)
    IF sy-subrc <> 0 AND sy-subrc <> 4.
      MESSAGE 'Erro ao deletar itens antigos do pedido.' TYPE 'E'.
      ROLLBACK WORK.
      RETURN.
    ENDIF.

    " B. Insere novamente todos os itens informados na tela
    LOOP AT gt_pedit INTO gs_est_pedit.

      " Todos os itens da tela são tratados como novos
      PERFORM f_inserir_item_db.
      IF sy-subrc <> 0.
        " Em caso de falha, o DELETE anterior será desfeito
        ROLLBACK WORK.
        RETURN.
      ENDIF.

    ENDLOOP.

  ENDIF.

  " Indica que o processo foi executado com sucesso
  ev_ok = abap_true.

ENDFORM. " salvar_pedido_db

*---------------------------------------------------------------------*
* FORM f_confirmar
*---------------------------------------------------------------------*
* FORM utilitário responsável por exibir um popup genérico
* de confirmação ao usuário.
*
* Retorno:
* - '1' : Botão 1 pressionado (ex: Sim)
* - '2' : Botão 2 pressionado (ex: Não)
* - 'A' : Popup fechado / erro / ação indefinida
*---------------------------------------------------------------------*
FORM f_confirmar
  USING
    iv_titulo     TYPE char50   " Título da janela
    iv_pergunta   TYPE char100  " Texto da pergunta
    iv_botao1     TYPE char20   " Texto do botão 1 (ex: Sim)
    iv_botao2     TYPE char20   " Texto do botão 2 (ex: Não)
  CHANGING
    cv_resposta   TYPE char01.  " Resposta do usuário (1, 2, A)

  " Inicialização da resposta
  CLEAR cv_resposta.
  CLEAR sy-subrc.

  "-------------------------------------------------------------*
  " Chamada do popup padrão SAP
  "-------------------------------------------------------------*
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = iv_titulo      " Título do popup
      text_question  = iv_pergunta    " Pergunta exibida
      text_button_1  = iv_botao1      " Texto do botão 1
      text_button_2  = iv_botao2      " Texto do botão 2
      default_button = '1'            " Botão padrão
    IMPORTING
      answer         = cv_resposta
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.

  "-------------------------------------------------------------*
  " Tratamento de exceções
  "-------------------------------------------------------------*
  IF sy-subrc <> 0 AND sy-subrc <> 2.
    " Em caso de erro inesperado, assume ação indefinida
    cv_resposta = 'A'.
  ENDIF.

ENDFORM. " f_confirmar


*---------------------------------------------------------------------*
* FORM carregar_dados
*---------------------------------------------------------------------*
* Responsável por:
* - Carregar o cabeçalho do pedido a partir do banco de dados
* - Buscar todos os itens do pedido
* - Mapear os dados do tipo DB para o tipo de tela (Table Control)
*---------------------------------------------------------------------*
FORM carregar_dados.

  DATA:
    lt_pedit_db TYPE TABLE OF ztb_pedit, " Itens do pedido (tipo DB)
    ls_pedit_db TYPE ztb_pedit,          " Work Area DB
    ls_prod     TYPE ztb_prod.           " Work Area para produto

  "-------------------------------------------------------------*
  " 1. Busca do cabeçalho do pedido
  "-------------------------------------------------------------*
  SELECT SINGLE *
    FROM ztb_ped
    INTO @gs_ped
    WHERE id_ped = @gd_id_ped.

  IF sy-subrc <> 0.
    MESSAGE |Pedido ID { gd_id_ped } não encontrado.| TYPE 'E'.
    EXIT.
  ENDIF.

  "-------------------------------------------------------------*
  " 2. Busca dos itens do pedido no banco de dados
  "-------------------------------------------------------------*
  CLEAR: gt_pedit, gs_est_pedit.

  SELECT *
    FROM ztb_pedit
    INTO TABLE @lt_pedit_db
    WHERE id_ped = @gd_id_ped.

  "-------------------------------------------------------------*
  " 3. Mapeamento DB -> Tela (Table Control)
  "-------------------------------------------------------------*
  LOOP AT lt_pedit_db INTO ls_pedit_db.

    CLEAR gs_est_pedit.

    " Mapeamento dos campos principais
    gs_est_pedit-id_ped     = ls_pedit_db-id_ped.
    gs_est_pedit-id_prod    = ls_pedit_db-id_prod.
    gs_est_pedit-nome_prod  = ls_pedit_db-nome_prod.
    gs_est_pedit-qtde       = ls_pedit_db-qtde.
    gs_est_pedit-valor_item = ls_pedit_db-valor_item.
    gs_est_pedit-marca      = ls_pedit_db-marca.
    gs_est_pedit-gd_status  = ''. " Item existente

    " Campo PRECO no DB → PRECO_UNIT na tela
    gs_est_pedit-preco_unit = ls_pedit_db-preco.

    "-----------------------------------------------------------*
    " Garantia do nome do produto na tela
    "-----------------------------------------------------------*
    " Caso o nome não esteja gravado no item do DB,
    " busca novamente no cadastro de produtos
    SELECT SINGLE nome_prod
      INTO @gs_est_pedit-nome_prod
      FROM ztb_prod
      WHERE id_prod = @gs_est_pedit-id_prod.

    IF sy-subrc <> 0.
      gs_est_pedit-nome_prod = 'Produto Inexistente'.
    ENDIF.

    " Adiciona o item mapeado na tabela interna do TC
    APPEND gs_est_pedit TO gt_pedit.

  ENDLOOP.

  "-------------------------------------------------------------*
  " 4. Preparação da Work Area do Table Control
  "-------------------------------------------------------------*
  " O PBO do Table Control posiciona automaticamente o
  " primeiro item da tabela interna na Work Area.
  CLEAR gs_est_pedit.

ENDFORM. " carregar_dados


*---------------------------------------------------------------------*
* FORM salvar_cabecalho_db
*---------------------------------------------------------------------*
* FORM de suporte responsável EXCLUSIVAMENTE pela
* inserção do cabeçalho do pedido no banco de dados.
*
* Observações:
* - Utilizado apenas no modo de Criação
* - O controle de COMMIT é realizado externamente
* - Em caso de erro, é executado ROLLBACK WORK
*---------------------------------------------------------------------*
FORM salvar_cabecalho_db
  CHANGING p_lv_salvou TYPE abap_bool.

  p_lv_salvou = abap_false.

  "-------------------------------------------------------------*
  " Inserção do cabeçalho do pedido
  "-------------------------------------------------------------*
  INSERT ztb_ped FROM gs_ped.

  IF sy-subrc = 0.
    " Inserção realizada com sucesso
    p_lv_salvou = abap_true.
  ELSE.
    " Erro inesperado durante a inserção
    MESSAGE 'Erro ao salvar o cabeçalho do pedido no DB.' TYPE 'S'DISPLAY LIKE 'E'.
    ROLLBACK WORK. " Desfaz a tentativa de INSERT
  ENDIF.

ENDFORM. " salvar_cabecalho_db


*---------------------------------------------------------------------*
* FORM f_inserir_item_db
*---------------------------------------------------------------------*
* FORM de suporte responsável por inserir UM item do pedido
* no banco de dados.
*
* O tratamento de erro (sy-subrc / ROLLBACK) é realizado
* pelo FORM chamador (salvar_pedido_db).
*---------------------------------------------------------------------*
FORM f_inserir_item_db.

  "-------------------------------------------------------------*
  " 1. Limpa a Work Area do banco
  "-------------------------------------------------------------*
  CLEAR gs_pedit.

  "-------------------------------------------------------------*
  " 2. Mapeamento Tela -> Banco
  "-------------------------------------------------------------*

  " Chave estrangeira (vínculo com o cabeçalho do pedido)
  gs_pedit-id_ped = gs_ped-id_ped.

  " Dados do item
  gs_pedit-id_prod    = gs_est_pedit-id_prod.
  gs_pedit-nome_prod  = gs_est_pedit-nome_prod.
  gs_pedit-qtde       = gs_est_pedit-qtde.

  " Preço unitário: tela → banco
  gs_pedit-preco      = gs_est_pedit-preco_unit.

  gs_pedit-valor_item = gs_est_pedit-valor_item.
  gs_pedit-marca      = gs_est_pedit-marca.

  "-------------------------------------------------------------*
  " 3. Inserção do item no banco de dados
  "-------------------------------------------------------------*
  INSERT ztb_pedit FROM gs_pedit.

  " O SY-SUBRC é propagado ao FORM chamador para controle
  " de erro e execução de ROLLBACK, se necessário.

ENDFORM. " f_inserir_item_db


*---------------------------------------------------------------------*
* FORM f_calcular_valor_total
*---------------------------------------------------------------------*
* Responsável por:
* - Calcular o valor total do pedido
* - Somar o valor de todos os itens informados na tela
* - Atualizar o campo de total no cabeçalho
*---------------------------------------------------------------------*
FORM f_calcular_valor_total.

  DATA:
    lv_valor_total TYPE ztb_ped-valor_total, " Acumulador
    ls_item        LIKE LINE OF gt_pedit.    " Item temporário

  "-------------------------------------------------------------*
  " 1. Inicialização do total
  "-------------------------------------------------------------*
  CLEAR lv_valor_total.
  CLEAR gs_ped-valor_total.

  "-------------------------------------------------------------*
  " 2. Soma dos valores dos itens
  "-------------------------------------------------------------*
  LOOP AT gt_pedit INTO ls_item.
    lv_valor_total = lv_valor_total + ls_item-valor_item.
  ENDLOOP.

  "-------------------------------------------------------------*
  " 3. Atualização do total no cabeçalho
  "-------------------------------------------------------------*
  gs_ped-valor_total = lv_valor_total.

ENDFORM. " f_calcular_valor_total


*---------------------------------------------------------------------*
* FORM f_validar_estoque
*---------------------------------------------------------------------*
* Responsável por:
* - Validar se há estoque suficiente para todos os itens do pedido
* - Impedir qualquer persistência no banco em caso de inconsistência
*
* Observações:
* - Executado ANTES de qualquer INSERT ou UPDATE
* - Retorna erro via SY-SUBRC
* - Não realiza COMMIT nem ROLLBACK
*---------------------------------------------------------------------*
FORM f_validar_estoque.

  DATA: lv_estoque_atual TYPE n LENGTH 10.

  " Inicializa retorno
  CLEAR sy-subrc.

  "-------------------------------------------------------------*
  " Validação item a item
  "-------------------------------------------------------------*
  LOOP AT gt_pedit INTO gs_est_pedit.

    " Busca o estoque atual do produto
    SELECT SINGLE qtde_estoque
      INTO @lv_estoque_atual
      FROM ztb_prod
      WHERE id_prod = @gs_est_pedit-id_prod.

    IF sy-subrc <> 0.
      " Produto sem cadastro de estoque
      MESSAGE |Produto { gs_est_pedit-id_prod } sem cadastro de estoque.| TYPE 'S' DISPLAY LIKE 'E'.
      sy-subrc = 4.
      RETURN.
    ENDIF.

    " Verifica se a quantidade solicitada excede o estoque disponível
    IF gs_est_pedit-qtde > lv_estoque_atual.
      MESSAGE |Estoque insuficiente ({ lv_estoque_atual }) para o produto { gs_est_pedit-id_prod }.|
              TYPE 'S' DISPLAY LIKE 'E'.

      " Posiciona o cursor no campo de quantidade do item com erro
      SET CURSOR FIELD 'GS_EST_PEDIT-QTDE' LINE sy-tabix.

      sy-subrc = 8.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM. " f_validar_estoque


*---------------------------------------------------------------------*
* FORM atualizar_cabecalho_db
*---------------------------------------------------------------------*
* FORM de suporte responsável EXCLUSIVAMENTE por atualizar
* o cabeçalho do pedido no banco de dados.
*
* Observações:
* - Utilizado apenas no modo de Edição
* - O valor total é recalculado externamente
* - O controle de COMMIT é feito pelo FORM chamador
*---------------------------------------------------------------------*
FORM atualizar_cabecalho_db
  CHANGING p_lv_salvou TYPE abap_bool.

  p_lv_salvou = abap_false.

  "-------------------------------------------------------------*
  " Atualização do cabeçalho do pedido
  "-------------------------------------------------------------*
  UPDATE ztb_ped FROM gs_ped.

  IF sy-subrc = 0.
    p_lv_salvou = abap_true.
  ELSE.
    MESSAGE 'Erro ao atualizar o cabeçalho do pedido no DB.' TYPE 'E'.
    ROLLBACK WORK.
  ENDIF.

ENDFORM. " atualizar_cabecalho_db
