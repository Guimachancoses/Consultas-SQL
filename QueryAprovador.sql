DECLARE @TotalRecords INT;
DECLARE @TotalPages INT;
DECLARE @RecordsPerPage INT = 100;
DECLARE @PageNumber INT = 1; -- Número da página desejada
DECLARE @Offset INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX);
DECLARE @NumPc NVARCHAR(MAX) = '''059172''';  -- Nota: Passar o número do pedido aqui

-- Ajusta o número da página
IF @PageNumber = 0 SET @PageNumber = 1;

-- Calcula o total de registros
DECLARE @TotalRecordsQuery NVARCHAR(MAX) = '
    SELECT @TotalRecords = COUNT(*)
    FROM SC7010 SC7
    INNER JOIN SB1010 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO AND SB1.D_E_L_E_T_ = ''''
    INNER JOIN SA2010 SA2 ON SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA AND SA2.D_E_L_E_T_ = ''''
    LEFT JOIN SX5010 SX5 ON SX5.X5_TABELA = ''Z2'' AND SX5.X5_CHAVE = SC7.C7_ZZMODPG AND SX5.D_E_L_E_T_ = ''''
    WHERE SC7.C7_NUM = ' + @NumPc + ' AND SC7.D_E_L_E_T_ = '''';';

EXEC sp_executesql @TotalRecordsQuery, N'@TotalRecords INT OUTPUT', @TotalRecords OUTPUT;

-- Calcula total de páginas
SET @TotalPages = CEILING(@TotalRecords * 1.0 / @RecordsPerPage);
SET @Offset = (@PageNumber - 1) * @RecordsPerPage;

-- Define a lista de colunas manualmente
DECLARE @ExistColumns NVARCHAR(MAX) = 'C7_ITEM,C7_NUM,C7_PRODUTO,C7_UM,SB1.B1_DESC,C7_XMARCA,C7_QUANT,C7_SEGUM,C7_QTSEGUM,C7_PRECO,C7_TOTAL,C7_OP,C7_PLACA,C7_FORNECE,A2_NOME,
A2_INSCR,A2_EST,A2_DDD,A2_TEL,C7_NUMSC,C7_LOJA,A2_END,A2_CGC,A2_CEP,A2_MUN,C7_ITEMSC,SC7.C7_VALFRE,A2_EMAIL,A2_CONTATO,C7_DATPRF,C7_EMISSAO,C7_OBS,C7_SOLICIT,A2_BAIRRO,
C7_ZZUSUIN,C7_ZZRLGI,C7_FRETE,C7_DESCRI,C7_DESPESA,C7_VLDESC,C7_TPFRETE,X5_DESCRI,C7_FILENT';

-- Divide as colunas em uma tabela temporária
DECLARE @TempColumns TABLE (ColumnName NVARCHAR(MAX));
INSERT INTO @TempColumns (ColumnName)
SELECT value FROM STRING_SPLIT(@ExistColumns, ',');

-- Monta lista de colunas dinamicamente
SET @ColumnList = STUFF((SELECT ', ' + C.COLUMN_NAME + ' AS ['+ REPLACE(REPLACE(LTRIM(RTRIM(SX3.X3_TITULO)), '%', ''), '?', '') + ']'
                         FROM INFORMATION_SCHEMA.COLUMNS C
	JOIN SX3010 SX3 ON C.COLUMN_NAME = SX3.X3_CAMPO
    JOIN (
        SELECT 'SC7010' AS TABLE_NAME, 'SC7' AS TABLE_ALIAS
        UNION ALL
        SELECT 'SX5010', 'SX5'
        UNION ALL
        SELECT 'SB1010', 'SB1'
        UNION ALL
        SELECT 'SA2010', 'SA2'
    ) T ON C.TABLE_NAME = T.TABLE_NAME
    WHERE C.COLUMN_NAME IN (SELECT ColumnName FROM @TempColumns)
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Monta a consulta paginada
SET @SQL = '
WITH PaginatedTable AS (
    SELECT ' + @ColumnList + ',
	SUM(SC7.C7_TOTAL) OVER () AS TOTAL_GERAL,
           ROW_NUMBER() OVER (ORDER BY SC7.C7_ITEM ASC) AS NumLinha
    FROM SC7010 SC7
    INNER JOIN SB1010 SB1 ON SB1.B1_COD = SC7.C7_PRODUTO AND SB1.D_E_L_E_T_ = ''''
    INNER JOIN SA2010 SA2 ON SA2.A2_COD = SC7.C7_FORNECE AND SA2.A2_LOJA = SC7.C7_LOJA AND SA2.D_E_L_E_T_ = ''''
    LEFT JOIN SX5010 SX5 ON SX5.X5_TABELA = ''Z2'' AND SX5.X5_CHAVE = SC7.C7_ZZMODPG AND SX5.D_E_L_E_T_ = ''''
    WHERE SC7.C7_NUM = ' + @NumPc + ' AND SC7.D_E_L_E_T_ = ''''
)
SELECT *
FROM PaginatedTable
WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage';

-- Executa a consulta
EXEC sp_executesql @SQL, N'@PageNumber INT, @TotalPages INT, @TotalRecords INT, @Offset INT, @RecordsPerPage INT',
                   @PageNumber, @TotalPages, @TotalRecords, @Offset, @RecordsPerPage;
