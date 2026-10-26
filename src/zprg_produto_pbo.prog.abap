*---------------------------------------------------------------------*
* INCLUDE ZPRG_PRODUTO_PBO
*---------------------------------------------------------------------*
* Rotinas PBO (Process Before Output)
* Responsável por:
*  - Definir status da tela
*  - Configurar título
*  - Preparar dados iniciais
*  - Bloquear campos conforme regra de negócio
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* PBO - Tela 9000 (Inserção de Produto)
*---------------------------------------------------------------------*
MODULE pbo_9000 OUTPUT.

  "Define o status GUI (menus e botões) da tela 9000
  SET PF-STATUS 'S9000'.

  "Define o título da tela (modo Inserção)
  SET TITLEBAR 'INS'.

  "Geração automática do próximo ID do produto
  "Executa apenas uma vez por chamada da tela
  IF gv_id_prod_temp IS INITIAL.

    SELECT MAX( id_prod )
      FROM ztb_prod
      INTO @DATA(lv_max_id).

    gv_id_prod_temp = lv_max_id + 1.

  ENDIF.

  "Atribui o ID gerado à estrutura de produto
  ls_prod-id_prod = gv_id_prod_temp.

  "Bloqueia campos conforme regra de negócio
  PERFORM f_bloquear_campos.

  "Valores padrão para novo cadastro
  ls_prod-status_prod = '1'.   "Produto ativo
  ls_prod-waers       = 'BRL'. "Moeda padrão

ENDMODULE.

*---------------------------------------------------------------------*
* PBO - Tela 9001 (Alteração / Visualização de Produto)
*---------------------------------------------------------------------*
MODULE pbo_9001 OUTPUT.

  "Define o status GUI da tela 9001
  SET PF-STATUS 'S9001'.

  "Define o título da tela (modo Edição)
  SET TITLEBAR 'EDIT'.

  "Bloqueia campos conforme regra de negócio
  PERFORM f_bloquear_campos.

ENDMODULE.
