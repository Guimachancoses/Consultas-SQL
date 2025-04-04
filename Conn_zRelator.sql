/*
=======================================================================
Autor:        Guilherme Machancoses  
Data:         04/04/2025  
Versão:       1.0  
Descrição:    Script para consulta de notas fiscais de entrada (SD1)  
              vinculadas a títulos a pagar (SE2), com enriquecimento  
              de dados do produto, centro de custo e fornecedor.

              Funcionalidades:
              - Consulta itens de nota fiscal de entrada (SD1)
              - Realiza JOIN com SE2 (títulos a pagar), SB1 (produto),  
                SA2 (fornecedor) e CTT (centro de custo)
              - Calcula valor líquido da nota considerando impostos,  
                despesas e descontos
              - Identifica status de bloqueio do fornecedor (SA2.A2_MSBLQL)
              - Permite análise cruzada entre data de emissão da nota e  
                data de emissão/baixa do título
              - Aplica filtro por filial, data de emissão e prefixos
              - Ordena os resultados por filial

Observação:
              Parâmetros genéricos a serem substituídos antes da execução:
              - SD1.D1_EMISSAO → intervalo de datas (ex: '"+cDataDe+"' até '"+cDataAte+"')
              - SD1.D1_FILIAL → faixa de filiais (ex: '0101' até '0120')

Aplicação: Impressão do pedido de compra do setor de compras.
            Solicitado pelo Matheus, consulta dos pedidos na SC7
=======================================================================
*/


SELECT SD1.D1_FILIAL FILIAL, SD1.D1_CC CCUSTO, CTT.CTT_DESC01 DESCCCUSTO, SD1.D1_PEDIDO PEDIDO, SD1.D1_COD PRODUTO, SB1.B1_UM UM, SB1.B1_DESC DESCPROD, SD1.D1_QUANT QTDE, SD1.D1_VUNIT VALUNIT,   
SD1.D1_TOTAL VALBRUTO, ((SD1.D1_TOTAL + SD1.D1_VALIPI + SD1.D1_DESPESA) - SD1.D1_VALDESC) VALLIQUIDO, SE2.E2_FILIAL FILSE2, SE2.E2_PREFIXO PREFIXO, SE2.E2_NUM TITULO, SE2.E2_PARCELA PARCELA, SE2.E2_TIPO TIPO, SE2.E2_FORNECE FORNECE, SE2.E2_LOJA LOJA,    
SE2.E2_NOMFOR NOMFOR, SA2.A2_NOME NOME, SA2.A2_ZZDRE DRE, SD1.D1_EMISSAO DTEMISNF, SE2.E2_EMISSAO DTEMISTIT, SE2.E2_VENCTO DTVENCTO, SE2.E2_BAIXA DTBAIXA, SE2.E2_VALOR VALTITULO, SE2.E2_HIST HISTORICO, SD1.D1_ZZUSER USUARIO, SE2.E2_USERLGI USERLGI,  
CASE WHEN SA2.A2_MSBLQL = 1 THEN 'Sim' ELSE 'Não' END AS BLOQUEADO
FROM SD1010 SD
INNER JOIN SE2010 SE2 ON SE2.E2_FILIAL = SD1.D1_FILIAL AND SE2.E2_NUM = SD1.D1_DOC AND SE2.E2_FORNECE = SD1.D1_FORNECE AND SE2.E2_LOJA = SD1.D1_LOJA AND SE2.D_E_L_E_T_ = ' '   
INNER JOIN SB1010 SB1 ON SB1.B1_COD = SD1.D1_COD AND SB1.D_E_L_E_T_ = ' '   
INNER JOIN SA2010 SA2 ON SA2.A2_COD = SD1.D1_FORNECE AND SA2.A2_LOJA = SD1.D1_LOJA AND SA2.D_E_L_E_T_ = ' '
LEFT JOIN CTT010 CTT ON CTT.CTT_CUSTO = SD1.D1_CC AND CTT.D_E_L_E_T_ = ' ' 
WHERE SD1.D1_FILIAL BETWEEN '0101' AND '0120' 
AND SD1.D1_EMISSAO BETWEEN '"+cDataDe+"' AND '"+cDataAte+"' 
AND SD1.D_E_L_E_T_ = ' ' AND SE2.E2_PREFIXO NOT IN('AGL', 'PMF')
ORDER BY SD1.D1_FILIAL  






