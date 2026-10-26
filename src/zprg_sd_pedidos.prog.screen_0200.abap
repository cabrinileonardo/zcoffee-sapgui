PROCESS BEFORE OUTPUT.
  MODULE status_0200.

PROCESS AFTER INPUT.

  FIELD gs_ped-pm MODULE forma_pag.

  " Produto (quando sai do campo produto)
  MODULE id_name_preco_prod.

*   Quantidade (quando sai do campo quantidade)
  FIELD gs_itens-qtde
  MODULE calcula_item.

  " Cliente e Funcionário (validação geral)
  MODULE id_and_name_fill_ped.

  " Comandos de tela (botões)
  MODULE user_command_0200.
