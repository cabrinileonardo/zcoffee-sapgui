*&---------------------------------------------------------------------*
*& Include          ZFI_CAD_FORMA_PAG_FRM
*&---------------------------------------------------------------------*

FORM criar_forma_pag .
  gd_mode = 'C'.
  CALL SCREEN 0100.
ENDFORM.


FORM editar_forma_pag.

  PERFORM get_linha_selecionada CHANGING gs_forma_pag.

  IF gs_forma_pag-id_forma IS INITIAL.
    EXIT.
  ENDIF.

  gd_mode = 'E'.
  CALL SCREEN 0100.

ENDFORM.



FORM ativar_desativar_forma.

  DATA ls_forma TYPE ty_forma_pag.

  PERFORM get_linha_selecionada CHANGING ls_forma.

  IF ls_forma-id_forma IS INITIAL.
    EXIT.
  ENDIF.

  IF ls_forma-ativo = 1.
    ls_forma-ativo = 9.
  ELSE.
    ls_forma-ativo = 1.
  ENDIF.

  UPDATE ztfi_forma_pag
    SET ativo = @ls_forma-ativo
    WHERE id_forma = @ls_forma-id_forma.

  COMMIT WORK AND WAIT.

  PERFORM refresh_alv.

ENDFORM.



FORM salvar_forma_pag.

  DATA:
    lv_id_existente TYPE ztfi_forma_pag-id_forma,
    ls_db           TYPE ztfi_forma_pag.

  "--- Validação de duplicidade
  SELECT SINGLE id_forma
    FROM ztfi_forma_pag
    WHERE descricao = @gs_forma_pag-descricao
    INTO @lv_id_existente.

  IF sy-subrc = 0.
    MESSAGE 'Forma de pagamento já cadastrada' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  "--- Monta registro DB
  CLEAR ls_db.
  ls_db-mandt      = sy-mandt.
  ls_db-id_forma   = gs_forma_pag-id_forma.
  ls_db-descricao  = gs_forma_pag-descricao.
  ls_db-tipo       = gs_forma_pag-tipo.
  ls_db-ativo      = 1.
  ls_db-dt_criacao = sy-datum.
  ls_db-usuario    = sy-uname.

  "--- Grava no banco
  INSERT ztfi_forma_pag FROM ls_db.

  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Forma de pagamento criada com sucesso' TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Erro ao gravar forma de pagamento' TYPE 'E'.
  ENDIF.

ENDFORM.

FORM modificar_forma_pag.

  DATA:
    lv_id_existente TYPE ztfi_forma_pag-id_forma,
    ls_db           TYPE ztfi_forma_pag.

  "--- Valida se o ID existe
  SELECT SINGLE id_forma
    FROM ztfi_forma_pag
    WHERE id_forma = @gs_forma_pag-id_forma
    INTO @lv_id_existente.

  IF sy-subrc <> 0.
    MESSAGE 'Registro não encontrado para alteração' TYPE 'E'.
    EXIT.
  ENDIF.

  "--- Valida duplicidade de descrição (exceto o próprio registro)
  CLEAR lv_id_existente.
  SELECT SINGLE id_forma
    FROM ztfi_forma_pag
    WHERE descricao = @gs_forma_pag-descricao
      AND id_forma <> @gs_forma_pag-id_forma
    INTO @lv_id_existente.

  IF sy-subrc = 0.
    MESSAGE 'Já existe outra forma de pagamento com esta descrição' TYPE 'E'.
    EXIT.
  ENDIF.

  "--- Monta estrutura DB (não altera ID nem data de criação)
  CLEAR ls_db.
  ls_db-mandt     = sy-mandt.
  ls_db-id_forma  = gs_forma_pag-id_forma.
  ls_db-descricao = gs_forma_pag-descricao.
  ls_db-tipo      = gs_forma_pag-tipo.
  ls_db-ativo     = gs_forma_pag-ativo.
  ls_db-usuario   = sy-uname. " usuário que alterou

  "--- Atualiza
  UPDATE ztfi_forma_pag FROM ls_db.

  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.
    MESSAGE 'Forma de pagamento alterada com sucesso' TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Erro ao alterar forma de pagamento' TYPE 'E'.
  ENDIF.

ENDFORM.

FORM get_linha_selecionada
  CHANGING
    cs_forma TYPE ty_forma_pag.

  DATA:
    lt_rows TYPE salv_t_row,
    lv_row  TYPE salv_de_row.

  DATA(lo_sel) = go_salv->get_selections( ).
  lt_rows = lo_sel->get_selected_rows( ).

  IF lt_rows IS INITIAL.
    MESSAGE 'Selecione uma linha' TYPE 'I'.
    EXIT.
  ENDIF.

  READ TABLE lt_rows INTO lv_row INDEX 1.
  READ TABLE gt_forma_pag INTO cs_forma INDEX lv_row.

ENDFORM.

FORM refresh_alv.

  SELECT id_forma
         descricao
         tipo
         ativo
    FROM ztfi_forma_pag
    INTO TABLE gt_forma_pag.

  go_salv->refresh( ).

ENDFORM.
