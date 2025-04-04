/*
=======================================================================
Autor:        Guilherme Machancoses
Data:         04/04/2025
Versão:       1.0
Descrição:    Script para consultar os dados bancários cadastrados na tabela SA6010,
              retornando apenas registros ativos e não deletados.

              Funcionalidades:
              - Retorna os campos: código do banco, agência, dígitos verificadores,
                nome da agência, número da conta e nome do banco
              - Filtra registros com:
                - D_E_L_E_T_ = '' (registros válidos)
                - A6_BLOCKED <> 1 (bancos não bloqueados)
              - Ordena o resultado pelo nome do banco (A6_NOME)

Aplicação: Portal wTMH consulta nos bancos. 

************(Não utilizada no momento)*******************
=======================================================================
*/


SELECT
 SA6.A6_COD,
 SA6.A6_AGENCIA,
 SA6.A6_DVAGE,
 SA6.A6_NOMEAGE,
 SA6.A6_NUMCON,
 SA6.A6_DVCTA,
 SA6.A6_NOME
FROM SA6010 SA6
WHERE D_E_L_E_T_ ='' AND A6_BLOCKED <> 1
ORDER BY A6_NOME ASC