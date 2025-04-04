/*
=======================================================================
Autor:        Guilherme Machancoses
Data:         04/04/2025
Versão:       1.0
Descrição:    Script para consultar os itens do cadastro geral de componentes (CTD010),
              retornando apenas os registros não bloqueados e não deletados.

              Funcionalidades:
              - Utiliza TRIM para remover espaços em branco dos campos CTD_ITEM e CTD_DESC01
              - Filtra registros com:
                - CTD_BLOQ <> 1 (itens não bloqueados)
                - D_E_L_E_T_ = '' (registros válidos, não deletados)
              - Ordena o resultado pela descrição do item (CTD_DESC01)

Aplicação: Uso Alianzo
=======================================================================
*/


SELECT
	TRIM(CTD_ITEM) AS CTD_ITEM,
	TRIM(CTD_DESC01) AS CTD_DESC01	
FROM CTD010
WHERE CTD_BLOQ <> 1 AND D_E_L_E_T_ = ''
ORDER BY TRIM(CTD_DESC01) ASC


