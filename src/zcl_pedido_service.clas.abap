class ZCL_PEDIDO_SERVICE definition
  public
  inheriting from ZCL_POPUP
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !IV_ID_PED type ZID_PED optional .
  methods VALIDAR_CABECALHO
    importing
      !IV_CAB type ZEST_PED optional
    exceptions
      ERRO_NEGOCIO .
  methods VALIDAR_ITEM
    importing
      !IS_ITEM type ZEST_ITENS
    exceptions
      ERRO_NEGOCIO .
  methods ADICIONAR_ITEM
    importing
      !IS_ITEM type ZEST_ITENS .
  methods REMOVER_ITEM
    importing
      !IV_PROD_ID type ZID_PROD .
  methods CALCULAR_TOTAIS
    exceptions
      ERRO_NEGOCIO .
  methods SALVAR_PEDIDO
    returning
      value(RV_PEDIDO) type ZID_PED
    exceptions
      ERRO_NEGOCIO .
  methods CARREGAR_PEDIDO
    importing
      !IV_PEDIDO type ZID_PED
    exceptions
      ERRO_NEGOCIO .
protected section.
private section.

  data GS_PEDIDO type ZEST_PED .
  data GT_ITENS type ZTEST_ITENS .
ENDCLASS.



CLASS ZCL_PEDIDO_SERVICE IMPLEMENTATION.


  METHOD adicionar_item.
    DATA: ls_item TYPE zest_itens.

    me->validar_item(
      EXPORTING
        is_item      = is_item         " Estrutura do cabeçalho de pedidos
    ).

    READ TABLE gt_itens INTO ls_item
    WITH KEY id_prod = is_item-id_prod.

    IF sy-subrc = 0.
      ls_item-qtde = ls_item-qtde + is_item-qtde.
      ls_item-preco_unit = is_item-preco_unit.

      MODIFY gt_itens FROM ls_item
        TRANSPORTING qtde preco_unit.
    ELSE.
      ls_item = is_item.
      APPEND ls_item TO gt_itens.
    ENDIF.

    me->calcular_totais( ).

  ENDMETHOD.


METHOD calcular_totais.

  DATA lv_total TYPE ztb_ped-valor_total.

  CLEAR lv_total.

  LOOP AT gt_itens ASSIGNING FIELD-SYMBOL(<fs_item>).

    CALL FUNCTION 'ZF_CALCULA_TOTAL_'
      EXPORTING
        iv_preco      = <fs_item>-preco_unit
        iv_qtde       = <fs_item>-qtde
      IMPORTING
        ev_valor_item = <fs_item>-valor_item
      EXCEPTIONS
        qtde_negativa = 1
        OTHERS        = 2.

    IF sy-subrc <> 0.
      RAISE erro_negocio.
    ENDIF.

    lv_total = lv_total + <fs_item>-valor_item.

  ENDLOOP.

  gs_pedido-valor_total = lv_total.

ENDMETHOD.


  METHOD carregar_pedido.

    CLEAR gs_pedido.
    CLEAR gt_itens.

    SELECT SINGLE *
      FROM ztb_ped
      INTO CORRESPONDING FIELDS OF @gs_pedido
      WHERE id_ped = @iv_pedido.

    IF sy-subrc <> 0.
      RAISE erro_negocio.
    ENDIF.

    SELECT
        a~id_prod,
        a~qtde,
        b~preco AS preco_unit,
        a~valor_item
      FROM ztb_pedit AS a
      INNER JOIN ztb_prod AS b
       ON a~id_prod = b~id_prod
      INTO CORRESPONDING FIELDS OF TABLE @gt_itens
      WHERE a~id_ped = @iv_pedido.

  ENDMETHOD.


  METHOD constructor.

    super->constructor( ).

    CLEAR gs_pedido.
    CLEAR gt_itens.

    IF iv_id_ped IS INITIAL.

      gs_pedido-data_ped = sy-datum.
      gs_pedido-hora_ped = sy-uzeit.
      gs_pedido-usuario  = sy-uname.

    ELSE.
      me->carregar_pedido( iv_id_ped ).
    ENDIF.

  ENDMETHOD.


METHOD remover_item.

  DELETE gt_itens WHERE id_prod = iv_prod_id.

  me->calcular_totais( ).

ENDMETHOD.


METHOD salvar_pedido.

*  DATA lv_id_ped TYPE ztb_ped-id_ped.
*
*  " 1. Valida cabeçalho
*  me->validar_cabecalho(
**    EXPORTING
**      iv_cab       =                  " Estrutura do cabeçalho de pedidos
**    EXCEPTIONS
**      erro_negocio = 1
**      others       = 2
*  ).
*  IF SY-SUBRC <> 0.
**   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**     WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF..
*
*
*  " 2. Define ID do pedido
*  IF gs_pedido-id_ped IS INITIAL.
*
*    CALL FUNCTION 'NUMBER_GET_NEXT'
*      EXPORTING
*        nr_range_nr = '01'
*        object      = 'ZPED'
*      IMPORTING
*        number      = lv_id_ped
*      EXCEPTIONS
*        OTHERS      = 1.
*
*    IF sy-subrc <> 0.
*      RAISE erro_negocio.
*    ENDIF.
*
*    gs_pedido-id_ped = lv_id_ped.
*
*  ELSE.
*    lv_id_ped = gs_pedido-id_ped.
*  ENDIF.
*
*
*  " 3. Grava cabeçalho
*  MODIFY ztb_ped FROM gs_pedido.
*
*  IF sy-subrc <> 0.
*    ROLLBACK WORK.
*    RAISE erro_negocio.
*  ENDIF.
*
*  " 4. Remove itens antigos (edição)
*  DELETE FROM ztb_pedit WHERE id_ped = lv_id_ped.
*
*  " 5. Grava itens
*  LOOP AT gt_itens ASSIGNING FIELD-SYMBOL(<fs_item>).
*
*    INSERT ztb_pedit FROM value ztb_pedit(
*      id_ped     = lv_id_ped
*      id_prod    = <fs_item>-id_prod
*      qtde       = <fs_item>-qtde
*      preco      = <fs_item>-preco
*      valor_item = <fs_item>-valor_item ).
*
*    IF sy-subrc <> 0.
*      ROLLBACK WORK.
*      RAISE erro_negocio.
*    ENDIF.
*
*  ENDLOOP.
*
*  COMMIT WORK.
*
*  rv_pedido = lv_id_ped.

ENDMETHOD.


  method VALIDAR_CABECALHO.
  endmethod.


  METHOD validar_item.

    DATA ls_prod TYPE ztb_prod.

    IF is_item-qtde <= 0.
      RAISE erro_negocio.
    ENDIF.

    SELECT SINGLE id_prod,
                  nome_prod,
                  preco,
                  qtde_estoque
      FROM ztb_prod
      INTO CORRESPONDING FIELDS OF @ls_prod
      WHERE id_prod = @is_item-id_prod
        AND status_prod  = '1'.

    IF sy-subrc <> 0.
      RAISE erro_negocio.
    ENDIF.

    IF ls_prod-qtde_estoque < is_item-qtde.
      RAISE erro_negocio.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
