REPORT zprg_sd_fatura.

DATA: gv_id_ped      TYPE zid_ped,
      lwa_parameters TYPE sfpoutputparams,
      lv_funcname    TYPE funcname,
      lv_result      TYPE sfpjoboutput.

DATA: ls_fat_cab TYPE zstrfatura_01,
      lt_fat_it  TYPE ztt_fatura_itens,
      lt_pedit   TYPE STANDARD TABLE OF zstrpedit_01.

*---------------------------------------------------------------------*
* INITIALIZATION
*---------------------------------------------------------------------*
INITIALIZATION.

  IMPORT gv_id_ped FROM MEMORY ID 'Z_ID_PED_R'.
  FREE MEMORY ID 'Z_ID_PED_R'.

  IF gv_id_ped IS INITIAL.
    MESSAGE 'ID do pedido não informado.' TYPE 'E'.
  ENDIF.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.

*---------------------------------------------------------------------*
* Busca cabeçalho da fatura
*---------------------------------------------------------------------*
  SELECT SINGLE
         a~id_fat,
         a~id_ped,
         a~data_fat,
         a~hora_fat,
         a~valor_total,
         a~moeda,
         a~id_pagamento,
         b~descricao,
         a~status,
         c~ddtext AS status_desc,
         a~usuario
    FROM ztb_fatura AS a
    LEFT JOIN ztb_pagamento AS b
      ON b~id = a~id_pagamento
    INNER JOIN dd07t AS c
      ON c~ddlanguage = @sy-langu
     AND c~domname    = 'ZDOSTSFATIT'
     AND c~domvalue_l = a~status
    INTO CORRESPONDING FIELDS OF @ls_fat_cab
    WHERE a~id_ped = @gv_id_ped.

  IF sy-subrc <> 0.
    MESSAGE 'Pedido ainda não faturado.' TYPE 'E'.
  ENDIF.

*---------------------------------------------------------------------*
* Busca parcelas da fatura
*---------------------------------------------------------------------*
  SELECT
         a~id_fat,
         a~seq_fat,
         a~data_venc,
         a~valor,
         a~status,
         b~ddtext AS status_desc,
         a~data_pag,
         a~moeda
    FROM ztb_fatura_itens AS a
    INNER JOIN dd07t AS b
      ON b~ddlanguage = @sy-langu
     AND b~domname    = 'ZDOSTSFATIT'
     AND b~domvalue_l = a~status
    INTO CORRESPONDING FIELDS OF TABLE @lt_fat_it
    WHERE a~id_fat = @ls_fat_cab-id_fat
    ORDER BY a~seq_fat.

*---------------------------------------------------------------------*
* Busca itens do pedido
*---------------------------------------------------------------------*
  SELECT
         a~id_ped,
         a~id_prod,
         b~nome_prod,
         b~preco AS preco_prod,
         a~qtde,
         a~moeda,
         a~valor_item
    FROM ztb_pedit AS a
    INNER JOIN ztb_prod AS b
      ON b~id_prod = a~id_prod
    INTO CORRESPONDING FIELDS OF TABLE @lt_pedit
    WHERE a~id_ped = @ls_fat_cab-id_ped.

*---------------------------------------------------------------------*
* Adobe Forms
*---------------------------------------------------------------------*
  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = lwa_parameters
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    MESSAGE 'Erro ao abrir job do Adobe.' TYPE 'E'.
  ENDIF.

*---------------------------------------------------------------------*
* Descobre FM do Adobe
*---------------------------------------------------------------------*
  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = 'ZADOBE_FATURA_CAFETERIA'
    IMPORTING
      e_funcname = lv_funcname.

*---------------------------------------------------------------------*
* Chamada do Adobe Form (APENAS UMA VEZ)
*---------------------------------------------------------------------*
  CALL FUNCTION lv_funcname
    EXPORTING
      is_fat_cab = ls_fat_cab
      it_fat_it  = lt_fat_it
      it_ped_it  = lt_pedit
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
  IF sy-subrc <> 0.
    MESSAGE 'Erro ao gerar formulário da fatura.' TYPE 'E'.
  ENDIF.

*---------------------------------------------------------------------*
* Fecha job Adobe
*---------------------------------------------------------------------*
  CALL FUNCTION 'FP_JOB_CLOSE'
    IMPORTING
      e_result = lv_result
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
  IF sy-subrc <> 0.
    MESSAGE 'Erro ao fechar job do Adobe.' TYPE 'E'.
  ENDIF.
