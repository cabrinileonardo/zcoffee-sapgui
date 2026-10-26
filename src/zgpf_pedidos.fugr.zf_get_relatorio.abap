FUNCTION zf_get_relatorio.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_ID_PED_LOW) TYPE  ZID_PED OPTIONAL
*"     REFERENCE(IV_ID_PED_H) TYPE  ZID_PED OPTIONAL
*"     REFERENCE(IV_ID_CLIENTE_L) TYPE  ZID_CLIENTE OPTIONAL
*"     REFERENCE(IV_ID_CLIENTE_H) TYPE  ZID_CLIENTE OPTIONAL
*"     REFERENCE(IV_DATA_PED_L) TYPE  ZDATA_PED OPTIONAL
*"     REFERENCE(IV_DATA_PED_H) TYPE  ZDATA_PED OPTIONAL
*"     REFERENCE(IV_STATUS) TYPE  ZSTATUS_PED OPTIONAL
*"     REFERENCE(IV_ID_FUNC_L) TYPE  ZID_FUNC OPTIONAL
*"     REFERENCE(IV_ID_FUNC_H) TYPE  ZID_FUNC OPTIONAL
*"     REFERENCE(IV_ID_PROD_L) TYPE  ZID_PROD OPTIONAL
*"     REFERENCE(IV_ID_PROD_H) TYPE  ZID_PROD OPTIONAL
*"     REFERENCE(IV_TIPO) TYPE  CHAR1 OPTIONAL
*"     REFERENCE(IV_CAT_PROD) TYPE  ZCATEGORIA OPTIONAL
*"     REFERENCE(IV_QTDE_ESTOQUE_MIN) TYPE  ZQTDE_ESTOQUE OPTIONAL
*"     REFERENCE(IV_QTDE_ESTOQUE_MAX) TYPE  ZQTDE_ESTOQUE OPTIONAL
*"     REFERENCE(IV_STATUS_PROD) TYPE  ZSTATUS_PROD_E OPTIONAL
*"  EXPORTING
*"     REFERENCE(EV_RESULT_PED) TYPE  ZTYP_REL_PED
*"     REFERENCE(EV_RESULT_EST) TYPE  ZTYP_RELATORIO_ESTOQUE
*"  EXCEPTIONS
*"      SEM_DADOS
*"      TIPO_INEXISTENTE
*"----------------------------------------------------------------------

  CASE iv_tipo.
    WHEN 'P'.
      SELECT a~id_ped,
            e~id_cliente,
            e~nome_cli AS cliente,
            a~data_ped,
            a~hora_ped,
            a~valor_total,
            c~id_func,
            c~nome AS nome_func,
            a~moeda,
            a~status_ped,
            f~ddtext AS status_desc,
            a~pm,
            g~ddtext AS pm_desc
       FROM ztb_ped AS a
       INNER JOIN ztb_func AS c
         ON  a~id_func = c~id_func
       INNER JOIN ztb_clientes AS e
         ON  a~id_cliente = e~id_cliente
       LEFT JOIN dd07t AS f
         ON  f~domname    = 'ZSTATUS_PED_D'
         AND f~domvalue_l = a~status_ped
         AND f~ddlanguage     = @sy-langu
       LEFT JOIN dd07t AS g
         ON  g~domname = 'ZDOPM'
         AND g~domvalue_l = a~pm
         AND g~ddlanguage = @sy-langu
       WHERE ( a~id_ped BETWEEN @iv_id_ped_low AND @iv_id_ped_h
             OR ( @iv_id_ped_low IS INITIAL AND @iv_id_ped_h IS INITIAL ) )
       AND ( c~id_func BETWEEN @iv_id_func_l AND @iv_id_func_h
             OR ( @iv_id_func_l IS INITIAL AND @iv_id_func_h IS INITIAL ) )
       AND ( e~id_cliente BETWEEN @iv_id_cliente_l AND @iv_id_cliente_h
             OR ( @iv_id_cliente_l IS INITIAL AND @iv_id_cliente_h IS INITIAL ) )
       AND ( ( a~data_ped BETWEEN @iv_data_ped_l AND @iv_data_ped_h )
             OR ( @iv_data_ped_l IS INITIAL AND @iv_data_ped_h IS INITIAL )
             OR ( @iv_data_ped_l IS NOT INITIAL AND @iv_data_ped_h IS INITIAL
       AND a~data_ped >= @iv_data_ped_l )
             OR ( @iv_data_ped_l IS INITIAL AND @iv_data_ped_h IS NOT INITIAL
       AND a~data_ped <= @iv_data_ped_h ) )
       AND ( a~status_ped = @iv_status
             OR @iv_status IS INITIAL )
       INTO CORRESPONDING FIELDS OF TABLE @ev_result_ped.

      IF sy-subrc <> 0.
        RAISE sem_dados.
      ENDIF.

    WHEN 'E'.

      SELECT a~id_prod,
             a~nome_prod,
             a~categoria,
             b~ddtext AS categoria_desc,
             a~qtde_estoque,
             a~preco,
             a~waers   AS moeda,
             a~status_prod,
             c~ddtext AS status_desc
        FROM ztb_prod AS a
        LEFT JOIN dd07t AS b
          ON b~domname    = 'ZDO_TIPOPROD'
         AND b~domvalue_l = a~categoria
         AND b~ddlanguage     = @sy-langu
        LEFT JOIN dd07t AS c
          ON c~domname    = 'ZSTATUS_PROD_D'
         AND c~domvalue_l = a~status_prod
         AND c~ddlanguage      = @sy-langu
        WHERE ( a~id_prod BETWEEN @iv_id_prod_l AND @iv_id_prod_h
             OR ( @iv_id_prod_l IS INITIAL AND @iv_id_prod_h IS INITIAL ) )
         AND ( a~categoria = @iv_cat_prod OR @iv_cat_prod IS INITIAL )
         AND ( ( a~qtde_estoque BETWEEN @iv_qtde_estoque_min AND @iv_qtde_estoque_max )
             OR ( @iv_qtde_estoque_min IS INITIAL AND @iv_qtde_estoque_max IS INITIAL )
             OR ( @iv_qtde_estoque_min IS NOT INITIAL AND @iv_qtde_estoque_max IS INITIAL
         AND a~qtde_estoque >= @iv_qtde_estoque_min )
             OR ( @iv_qtde_estoque_min IS INITIAL AND @iv_qtde_estoque_max IS NOT INITIAL
         AND a~qtde_estoque <= @iv_qtde_estoque_max ) )
        INTO CORRESPONDING FIELDS OF TABLE @ev_result_est.

      IF sy-subrc <> 0.
        RAISE sem_dados.
      ENDIF.

    WHEN OTHERS.
      RAISE tipo_inexistente.
  ENDCASE.

ENDFUNCTION.
