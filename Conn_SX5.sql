/*
-------------------------------------------------------------
Autor   : Guilherme Machancoses
Data    : 04/04/2025
Versão  : 1.0
Descrição: Consulta responsável por retornar os códigos e 
           descrições de bancos a partir da tabela SX5, 
           filtrando pela tabela '0N' e registros não deletados.
Aplicação: Portal do wTMH, consulta dos bancos cadastrados
-------------------------------------------------------------
*/

SELECT
TRIM(X5_CHAVE) AS CODIGO,
TRIM(X5_DESCRI) AS BANCO
FROM SX5010 (nolock)
WHERE X5_TABELA = '0N' AND D_E_L_E_T_ = ''