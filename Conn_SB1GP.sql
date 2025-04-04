/*
=======================================================================
Autor:        Guilherme Machancoses
Data:         04/04/2025
Versão:       1.0
Descrição:    Script para consultar os produtos ativos da tabela SB1010,
              vinculando a descrição da localização padrão a partir da tabela NNR010.

              Funcionalidades:
              - Retira espaços dos campos utilizando TRIM
              - Realiza RIGHT JOIN com a tabela NNR010 (descrição da localização)
              - Filtra produtos com:
                - B1_ATIVO = 'S' (produtos ativos)
                - B1_MSBLQL = '2' (produtos liberados)
                - B1_GRUPO diferente de '9999' e '0000'
              - Ordena os resultados pelo código do produto (B1_COD)

Observação:
              A localização padrão do produto (B1_LOCPAD) deve existir na tabela NNR010.
              A consulta desconsidera grupos genéricos ou inválidos com códigos '9999' e '0000'.

Aplicação: Portal wTMH, consulta dos grupos de produtos.
=======================================================================
*/


SELECT
TRIM(B1_COD) B1_COD,
TRIM(B1_GRUPO) B1_GRUPO,
TRIM(B1_UM) B1_UM,
TRIM(B1_DESC) B1_DESC,
TRIM(NNR_DESCRI) NNR_DESCRI
FROM SB1010 SB1
RIGHT JOIN NNR010 NNR
ON NNR.NNR_CODIGO = SB1.B1_LOCPAD AND NNR.D_E_L_E_T_ = ''
WHERE SB1.D_E_L_E_T_ = '' AND B1_ATIVO = 'S' AND B1_MSBLQL = '2' AND B1_GRUPO NOT IN ('9999', '0000')
ORDER BY B1_COD ASC


