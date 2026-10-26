*---------------------------------------------------------------------*
* PBO – Tela 2000
*---------------------------------------------------------------------*
* Responsável por:
* - Definir status GUI e título da tela
* - Inicializar valores padrão na criação do pedido
* - Garantir moeda padrão
* - Recalcular o valor total do pedido
*---------------------------------------------------------------------*
MODULE pbo_2000 OUTPUT.

  DATA gv_id_ped TYPE zid_ped.


  IF gs_ped-id_ped IS NOT INITIAL.
    PERFORM carregar_dados.
  ENDIF.


  " Define o status da tela (menus, botões e funções)
  SET PF-STATUS 'S2000'.

  "-------------------------------------------------------------*
  " Modo Criação de Pedido
  "-------------------------------------------------------------*
  IF gd_mode = 'C'.
    " Título da tela para criação
    SET TITLEBAR 'CRIAR'.

    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'GS_PED-STATUS_PED' OR 'GS_PED-DATA_PED' OR 'GS_PED-HORA_PED'.
          screen-input = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.

    " Inicializações padrão para novo pedido
    gs_ped-hora_ped = sy-uzeit.
    gs_ped-data_ped   = sy-datum. " Data do pedido = data atual
    gs_ped-status_ped = 1.        " Status do pedido sendo criado = 1 (incluido)
    gs_ped-moeda      = 'BRL'.    " Moeda padrão do pedido
    gs_pedit-moeda    = 'BRL'.    " Moeda padrão dos itens
    gs_est_pedit-moeda = 'BRL'.   " Moeda padrão (estrutura de tela)
  ENDIF.

  "-------------------------------------------------------------*
  " Modo Edição / Modificação de Pedido
  "-------------------------------------------------------------*
  IF gd_mode = 'E'.
    " Título da tela para modificação
    SET TITLEBAR 'MODF'.

    " Garante moeda padrão durante a edição
    gs_ped-moeda      = 'BRL'.
    gs_pedit-moeda    = 'BRL'.
    gs_est_pedit-moeda = 'BRL'.
  ENDIF.

  "-------------------------------------------------------------*
  " Recalcula o valor total do pedido a cada exibição da tela
  "-------------------------------------------------------------*
  PERFORM f_calcular_valor_total.

ENDMODULE.

*---------------------------------------------------------------------*
* PBO – Tela 3100
*---------------------------------------------------------------------*
* Responsável por:
* - Definir status GUI e título da tela
* - Forçar modo de edição
*---------------------------------------------------------------------*
MODULE pbo_3100 OUTPUT.

  " Define o status da tela (menus, botões e funções)
  SET PF-STATUS 'S3100'.

  " Define título da tela como modificação
  SET TITLEBAR 'MODF'.

  " Força o modo de edição
  gd_mode = 'E'.

  IF gv_first_time = abap_true.
    GET PARAMETER ID 'ZPED' FIELD gs_ped-id_ped.
    gv_first_time = abap_false.
  ENDIF.


  " Só executa automaticamente na primeira vez
  IF gv_auto_search = abap_true
     AND gs_ped-id_ped IS NOT INITIAL.

    gv_auto_search = abap_false.

    " Simula clique no botão SEARCH
    gd_okcode = 'SEARCH'.

    " Força o processamento do PAI
    LEAVE TO SCREEN sy-dynnr.
  ENDIF.

ENDMODULE.
