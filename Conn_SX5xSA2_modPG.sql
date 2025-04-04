/*
=======================================================================
Autor:        Guilherme Machancoses
Data:         04/04/2025
Versão:       1.0
Descrição:    Script para consultar fornecedores ativos da tabela SA2010,
              vinculando-os à tabela de descrições de forma de pagamento (SX5010),
              com base no código A2_ZZMODPG.

              Funcionalidades:
              - Retira espaços dos campos usando TRIM
              - Realiza RIGHT JOIN com a tabela SX5010 (formas de pagamento)
              - Filtra fornecedores com A2_MSBLQL = '2' (não bloqueados)
              - Ordena os resultados por nome (A2_NOME) de forma ascendente

Observação:
              A tabela SX5 deve conter a chave 'Z2' para identificação correta da forma de pagamento.
              O campo A2_ZZMODPG em SA2 deve conter o código da forma de pagamento a ser cruzado.

Aplicação: Portal wTMH, consulta dos modos de pagamentos.
=======================================================================
*/


SELECT
	TRIM(A2_CGC) A2_CGC,
	TRIM(A2_NOME) A2_NOME,
	TRIM(A2_COD) A2_COD,
	TRIM(A2_LOJA) A2_LOJA,
	TRIM(A2_MUN) A2_MUN,
	TRIM(A2_EST) A2_EST,
	TRIM(X5_DESCRI) X5_DESCRI
FROM SA2010 SA2
RIGHT JOIN SX5010 SX5
ON SX5.X5_TABELA = 'Z2' AND SX5.D_E_L_E_T_ = '' AND SX5.X5_CHAVE = SA2.A2_ZZMODPG
WHERE SA2.D_E_L_E_T_ = '' AND SA2.A2_MSBLQL = '2'
ORDER BY SA2.A2_NOME ASC