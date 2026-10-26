
************************************************************************
* PBO – Process Before Output
************************************************************************

*---------------------------------------------------------------------*
* Tela 0100 – Tela principal
*---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'MAIN'.
ENDMODULE.


MODULE status_0200 OUTPUT.
  " Status e PF-STATUS padrão da tela
  SET PF-STATUS 'S0100'.

  CASE gd_mode.

      "---------------------------------------------------------------"
      " Modo CRIAÇÃO de pedido
      "---------------------------------------------------------------"
    WHEN 'C'.
      SET TITLEBAR 'NEW'.

      " Bloqueia campos que não devem ser editados na criação
      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'GS_PED-ID_PED'
            OR 'GS_PED-VALOR_TOTAL'
            OR 'GS_PED-DATA_PED'
            OR 'GS_PED-HORA_PED'
            OR 'GS_ITENS-VALOR_ITEM'
            OR 'GS_ITENS-NOME_PROD'
            OR 'GS_ITENS-PRECO_UNIT'.
            screen-input = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

      " Inicializações padrão para novo pedido
      gs_ped-data_ped   = sy-datum.   " Data do pedido = data atual
      gs_ped-hora_ped   = sy-uzeit.   " Hora do pedido = hora atual
      gs_ped-status_ped = 1.          " Status = Incluído
      gs_ped-moeda      = 'BRL'.      " Moeda padrão do pedido
      gs_ped-usuario    = sy-uname.

      IF gs_itens-moeda IS INITIAL.
        gs_itens-moeda = 'BRL'.
      ENDIF.

      IF gv_edit_mode = abap_false
         AND gv_loading_edit = abap_false.
        PERFORM f_calcular_valor_total.
      ENDIF.


      "---------------------------------------------------------------"
      " Modo EDIÇÃO de pedido
      "---------------------------------------------------------------"
    WHEN 'E'.
      SET TITLEBAR 'EDIT'.

      IF gs_ped-status_ped = 9 OR gs_ped-status_ped = 3.
        LOOP AT SCREEN.

          screen-input = 0.   " bloqueia edição
          MODIFY SCREEN.

        ENDLOOP.
      ENDIF.

      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'GS_PED-ID_PED'
            OR 'GS_PED-DATA_PED'
            OR 'GS_PED-HORA_PED'
            OR 'GS_PED-VALOR_TOTAL'
            OR 'GS_ITENS-VALOR_ITEM'.
            screen-input = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.

      IF go_alv IS INITIAL.
        PERFORM f_show_alv_itens.
      ELSE.
        go_alv->refresh_table_display( ).
      ENDIF.

  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  gd_mode = 'E'.
  SET PF-STATUS 'SEARCH'.
  SET TITLEBAR 'SEARCH'.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0400 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0400 OUTPUT.
  gd_mode = 'E'.
  gv_externo = abap_true.

  GET PARAMETER ID 'ZPED_M' FIELD gd_idped.

  SELECT a~id_ped,
         a~id_cliente,
         a~data_ped,
         a~hora_ped,
         a~valor_total,
         a~id_func,
         a~status_ped,
         a~moeda,
         a~pm
    FROM ztb_ped AS a
    INTO CORRESPONDING FIELDS OF @gs_ped
    WHERE id_ped = @gd_idped.

    SELECT a~id_ped,
           a~id_prod,
           b~nome_prod,
           b~preco AS preco_unit,
           a~qtde,
           a~valor_item,
           a~moeda
      FROM ztb_pedit AS a
      INNER JOIN ztb_prod AS b
       ON a~id_prod = b~id_prod
      INTO CORRESPONDING FIELDS OF TABLE @gt_itens
      WHERE id_ped = @gd_idped.
  ENDSELECT.

  CALL SCREEN 0200.


  SET PF-STATUS 'SEARCH'.
  SET TITLEBAR 'SEARCH'.


ENDMODULE.
