*======================================================================*
* 1. Declarações de Tabela e Variáveis de Cabeçalho/Itens
*======================================================================*
TABLES: ztb_ped, " Cabeçalho do pedido
        ztb_pedit. " Itens do pedido

DATA: gs_ped   TYPE ztb_ped, " Estrutura de trabalho do Cabeçalho
      gs_pedit TYPE ztb_pedit.

DATA: gt_pedit     TYPE STANDARD TABLE OF zest_pedido,
      gs_pedit_ext TYPE ZEST_PEDIDO.

DATA: rad1,rad2,rad3.

*======================================================================*
* 2. Variáveis de Controle
*======================================================================*
DATA: ok_code LIKE sy-ucomm.

* Flag para controle de saída sem salvar (Melhoria 1)
DATA: gd_changed TYPE abap_bool VALUE abap_false.
