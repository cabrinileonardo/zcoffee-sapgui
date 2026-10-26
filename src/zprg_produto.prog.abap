REPORT zprg_produto.

*---------------------------------------------------------------------*
* Includes do programa
*---------------------------------------------------------------------*
* TOP  - Declarações globais (types, data, constantes, parâmetros)
* FRM  - Subrotinas (FORMS)
* PBO  - Process Before Output (tela)
* PAI  - Process After Input (tela)
*---------------------------------------------------------------------*
INCLUDE zprg_produto_top.
INCLUDE zprg_produto_frm.
INCLUDE zprg_produto_pbo.
INCLUDE zprg_produto_pai.

*---------------------------------------------------------------------*
* Processamento principal do relatório
*---------------------------------------------------------------------*
START-OF-SELECTION.

  "O CASE é baseado no radio button selecionado na tela
  "Cada radio button representa uma ação de negócio
  CASE 'X'.

    WHEN rb_ins.
      "Inserção de um novo produto
      PERFORM f_inserir_prod.

    WHEN rb_exi.
      "Exibição dos dados do produto
      PERFORM f_exibir_prod.

    WHEN rb_alt.
      "Alteração dos dados do produto
      PERFORM f_alterar_prod.

    WHEN rb_del.
      "Exclusão de um produto
      PERFORM f_deletar_prod.

  ENDCASE.

END-OF-SELECTION.

*---------------------------------------------------------------------*
* Limpeza de variáveis e estruturas globais
*---------------------------------------------------------------------*
PERFORM f_limpa_tudo.
