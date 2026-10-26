FORM inserir .

  gs_funcionario-data_adm = sy-datum.

  INSERT ztb_func FROM gs_funcionario.
  IF sy-subrc = 0.
    MESSAGE s000(zmsg_coffee).
* Funcionário Cadastrado com Sucesso!
    LEAVE TO SCREEN 0.
  ELSE.
    MESSAGE s001(zmsg_coffee) DISPLAY LIKE 'E'.
* Erro ao cadastrar funcionário (ID já exite).
  ENDIF.
ENDFORM.


*FORM gerar_id.
*  CALL FUNCTION 'NUMBER_GET_NEXT'
*    EXPORTING
*      object      = 'ZID_FUNC01'
*      nr_range_nr = '01'
*    IMPORTING
*      number      = lv_number.
*
*ENDFORM.

FORM modificar_funcionario .
  SELECT SINGLE *
    FROM ztb_func
    INTO gs_funcionario
    WHERE id_func = gd_zid_func.

  IF sy-subrc <> 0.
    MESSAGE s002(zmsg_coffee) DISPLAY LIKE 'E'.
* Nenhum funcionário encontrado.
    EXIT.
  ENDIF.
  CALL SCREEN 0901.
ENDFORM.

FORM modificar.
  MODIFY ztb_func FROM gs_funcionario.
  IF sy-subrc = 0.
    MESSAGE s003(zmsg_coffee).
* Funcionario alterado com sucesso.
    LEAVE TO SCREEN 0100.
  ELSE.
    MESSAGE s004(zmsg_coffee) DISPLAY LIKE 'E'.
* Funcionário não encontrado para alteração.
  ENDIF.
ENDFORM.

FORM excluir .
  CALL SCREEN 9004.
  SELECT SINGLE *
  FROM ztb_func
  INTO gs_funcionario
  WHERE id_func = gd_zid_func.

  IF sy-subrc <> 0.
    MESSAGE s002(zmsg_coffee) DISPLAY LIKE 'E'.
* Nenhum funcionário encontrado.
    EXIT.
  ENDIF.
ENDFORM.
