FUNCTION zf_get_relatorio_.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(IV_ID_PED_LOW) TYPE  ZTB_PED2-ID_PED
*"     REFERENCE(IV_ID_PED_HIGH) TYPE  ZTB_PED2-ID_PED
*"     REFERENCE(IV_DATA_LOW) TYPE  ZTB_PED2-DATA_PED
*"     REFERENCE(IV_DATA_HIGH) TYPE  ZTB_PED2-DATA_PED
*"     REFERENCE(IV_ID_FUNC_LOW) TYPE  ZID_FUNC
*"     REFERENCE(IV_ID_FUNC_HIGH) TYPE  ZID_FUNC
*"     REFERENCE(IV_ID_PROD_LOW) TYPE  ZID_PROD
*"     REFERENCE(IV_ID_PROD_HIGH) TYPE  ZID_PROD
*"     REFERENCE(IV_STATUS) TYPE  ZSTATUS_PED
*"  EXPORTING
*"     REFERENCE(CT_RELATORIO) TYPE  ZTYP_RELATORIO_PED
*"----------------------------------------------------------------------

  SELECT
    a~id_ped,
    e~cpf AS cpf,           " <--- BUSCA O CPF DA ZTB_CLIENTES
    e~nome_cli AS cliente, " <--- BUSCA O NOME COMPLETO DA ZTB_CLIENTES
    a~data_ped,
    a~valor_total AS valor_total,      " <--- CORRIGIDO O ALIAS PARA ZVALOR_TOTAL
    a~status_ped AS status,             " <--- INCLUÍDO STATUS E MUDADO O ALIAS
    a~id_func AS id_func,
    a~moeda,
    b~id_prod,
    b~qtde,
    b~valor_item,
    c~nome_prod,
    c~preco AS preco_unit,
    d~nome AS nome_func

  INTO CORRESPONDING FIELDS OF TABLE @ct_relatorio
  FROM ztb_ped AS a " Cabeçalho (ZTB_PED)
  INNER JOIN ztb_pedit AS b " Itens (ZTB_PEDIT)
    ON a~id_ped = b~id_ped
  INNER JOIN ztb_prod AS c " Produtos (ZTB_PROD)
    ON b~id_prod = c~id_prod
  INNER JOIN ztb_func AS d " Funcionários (ZTB_FUNC)
    ON a~id_func = d~id_func " Campo 'FUNCIONARIO' na ZTB_PED
  INNER JOIN ztb_clientes AS e
    ON a~id_cliente = e~id_cliente

  WHERE
        a~id_ped   BETWEEN @iv_id_ped_low  AND @iv_id_ped_high
    AND a~data_ped BETWEEN @iv_data_low    AND @iv_data_high
    AND a~id_func BETWEEN @iv_id_func_low AND @iv_id_func_high  " FILTRO FUNCIONÁRIO
    AND b~id_prod BETWEEN @iv_id_prod_low AND @iv_id_prod_high      " FILTRO PRODUTO
    AND a~status_ped = @iv_status.                                  " FILTRO STATUS

ENDFUNCTION.
