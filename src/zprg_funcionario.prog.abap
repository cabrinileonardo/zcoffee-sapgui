*&---------------------------------------------------------------------*
*& Report ZPRG_FUNCIONARIO
*&---------------------------------------------------------------------*
*& Autor      : Leonardo Cabrini Mauro
*& Data       : 16/10/2025
*&---------------------------------------------------------------------*
*& Descrição  :
*& Programa responsável pelo cadastro e manutenção de funcionários
*& ZCoffee. Permite:
*&  - Inserção de funcionários
*&  - Visualização dos registros
*&  - Alteração de dados existentes
*&  - Exclusão de funcionários
*&
*& A execução das funcionalidades é controlada por radio buttons
*& definidos na tela de seleção.
*&---------------------------------------------------------------------*

REPORT zprg_funcionario.

*---------------------------------------------------------------------*
* Includes
*---------------------------------------------------------------------*
* TOP  - Declarações globais (types, data, constantes)
* SOS  - Subroutines auxiliares
* PBO  - Process Before Output (lógica de tela)
* PAI  - Process After Input (eventos de usuário)
*---------------------------------------------------------------------*
INCLUDE zprg_funcionario_TOP.
INCLUDE zprg_funcionario_FRM.
INCLUDE zprg_funcionario_PBO.
INCLUDE zprg_funcionario_PAI.

*---------------------------------------------------------------------*
* Processamento principal
*---------------------------------------------------------------------*

START-OF-SELECTION.

  " Verifica qual opção foi selecionada na tela
  IF rb_ins = 'X'.
    " Inserção de novo funcionário
    PERFORM inserir.

    " Limpa campos após a operação
    CLEAR: p_idfunc,
           p_nome.

  ELSEIF rb_exi = 'X'.
    " Visualização dos funcionários cadastrados
    PERFORM vizualizar.

  ELSEIF rb_alt = 'X'.
    " Alteração de dados de funcionário
    PERFORM alterar.

    " Limpa campos após a operação
    CLEAR: p_idfunc,
           p_nome.

  ELSEIF rb_del = 'X'.
    " Exclusão de funcionário
    PERFORM excluir.
  ENDIF.

END-OF-SELECTION.

*---------------------------------------------------------------------*
* Limpeza geral de estruturas e variáveis
*---------------------------------------------------------------------*
PERFORM limpa_tudo.
