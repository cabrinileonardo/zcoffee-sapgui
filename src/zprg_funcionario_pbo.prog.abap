*---------------------------------------------------------------------*
* Include          ZPRG_FUNCIONARIO_PBO
*---------------------------------------------------------------------*
* Descrição:
* Include responsável pelo processamento PBO (Process Before Output),
* ou seja, toda a lógica executada antes da exibição das telas.
* Aqui são definidos:
*  - Status GUI (PF-STATUS)
*  - Títulos das telas
*  - Inicializações de campos
*  - Bloqueio/liberação de campos na tela
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* PBO – Tela 9000
*---------------------------------------------------------------------*
* Tela utilizada para inserção de funcionários.
*---------------------------------------------------------------------*
MODULE pbo_9000 OUTPUT.

  " Define o status GUI da tela 9000
  SET PF-STATUS 'S9000'.

  " Define o título da tela (modo Inserção)
  SET TITLEBAR 'INS'.

  " Obtém o próximo ID de funcionário para exibição
  PERFORM f_obter_id_para_exibir
    CHANGING ls_func-id_func.

  " Bloqueia campos conforme regras de negócio
  PERFORM f_bloquear_campos.

  " Define atividade padrão como ativa
  ls_func-atividade = '1'.

  " Define a data de admissão como a data atual do sistema
  ls_func-data_adm = sy-datum.

ENDMODULE.

*---------------------------------------------------------------------*
* PBO – Tela 9001
*---------------------------------------------------------------------*
* Tela utilizada para alteração de funcionários.
*---------------------------------------------------------------------*
MODULE pbo_9001 OUTPUT.

  " Define o status GUI da tela 9001
  SET PF-STATUS 'S9001'.

  " Define o título da tela (modo Alteração)
  SET TITLEBAR 'ALT'.

  " Bloqueia o campo ID do funcionário para edição
  LOOP AT SCREEN.
    IF screen-name EQ 'LS_FUNC-ID_FUNC'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDMODULE.
