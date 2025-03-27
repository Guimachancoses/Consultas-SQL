DECLARE @TotalRecords INT;
DECLARE @TotalPages INT;
DECLARE @RecordsPerPage INT = 1000;
DECLARE @PageNumber INT = 1;  -- Número da página desejada
DECLARE @Offset INT;
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX);
DECLARE @ExistColumns NVARCHAR(MAX) = 'F1_FILIAL,F1_DOC,F1_SERIE,F1_EMISSAO,D1_VUNIT,F1_VALBRUT,D1_COD,B1_DESC,D1_QUANT,F1_FORNECE,A2_NOME,A2_CGC';

-- Ajusta o número da página
IF @PageNumber = 0 SET @PageNumber = 1;

-- Calcula o total de registros
DECLARE @TotalRecordsQuery NVARCHAR(MAX) = '
WITH RankedData AS (
    SELECT 
        SF1.F1_FILIAL,
		 (SELECT 
            STUFF(STUFF(STUFF(STUFF(SY.M0_CGC, 3, 0, ''.''), 7, 0, ''.''), 11, 0, ''/''), 16, 0, ''-'') 
         FROM SYS_COMPANY AS SY 
         WHERE SY.M0_CODFIL = SF1.F1_FILIAL 
           AND SY.D_E_L_E_T_ = ''''
        ) AS CNPJ_FILIAL,
        SF1.F1_DOC,
        SF1.F1_SERIE,
        SF1.F1_EMISSAO,
        SD1.D1_VUNIT,
        SF1.F1_VALBRUT,
        SD1.D1_COD,
        SB1.B1_DESC,
        SD1.D1_QUANT,
        SF1.F1_FORNECE,
        SA2.A2_NOME,
        STUFF(STUFF(STUFF(STUFF(SA2.A2_CGC, 3, 0, ''.''), 7, 0, ''.''), 11, 0, ''/''), 16, 0, ''-'') AS A2_CGC,
        ROW_NUMBER() OVER (PARTITION BY SF1.F1_FILIAL ORDER BY SF1.F1_EMISSAO DESC, SD1.D1_COD DESC) AS NumLinha
    FROM SF1010 SF1
    LEFT JOIN SD1010 SD1 ON SD1.D1_DOC = SF1.F1_DOC AND SF1.F1_FORNECE = SD1.D1_FORNECE AND SF1.F1_SERIE = SD1.D1_SERIE AND SD1.D_E_L_E_T_ = '''' AND SD1.D1_EMISSAO > ''20241201''
    LEFT JOIN SB1010 SB1 ON SB1.B1_COD = SD1.D1_COD AND SB1.D_E_L_E_T_ = ''''
    LEFT JOIN SA2010 SA2 ON SA2.A2_COD = SF1.F1_FORNECE AND SA2.D_E_L_E_T_ = ''''
    WHERE SF1.F1_EMISSAO > ''20241201'' AND SD1.D1_COD IN (''1011.0001'',''1021.0001'') AND SF1.D_E_L_E_T_ = '''' AND (SD1.D1_QUANT >= ''500'' AND SD1.D1_COD = ''1021.0001'') OR (SD1.D1_QUANT >= ''5000'' AND SD1.D1_COD = ''1011.0001'')
)
SELECT @TotalRecords = COUNT(*)
FROM RankedData
WHERE NumLinha <= 10;';

EXEC sp_executesql @TotalRecordsQuery, N'@TotalRecords INT OUTPUT', @TotalRecords OUTPUT;

-- Calcula total de páginas
SET @TotalPages = CEILING(@TotalRecords * 1.0 / @RecordsPerPage);
SET @Offset = (@PageNumber - 1) * @RecordsPerPage;

-- Divide as colunas em uma tabela temporária
DECLARE @TempColumns TABLE (ColumnName NVARCHAR(MAX));
INSERT INTO @TempColumns (ColumnName)
SELECT value FROM STRING_SPLIT(@ExistColumns, ',');

-- Monta lista de colunas dinamicamente
SET @ColumnList = STUFF((SELECT ', ' + C.COLUMN_NAME + ' AS ['+ REPLACE(REPLACE(LTRIM(RTRIM(SX3.X3_TITULO)), '%', ''), '?', '') + ']'
                         FROM INFORMATION_SCHEMA.COLUMNS C
	JOIN SX3010 SX3 ON C.COLUMN_NAME = SX3.X3_CAMPO
    JOIN (
        SELECT 'SF1010' AS TABLE_NAME, 'SF1' AS TABLE_ALIAS
        UNION ALL
        SELECT 'SD1010', 'SD1'
        UNION ALL
        SELECT 'SB1010', 'SB1'
        UNION ALL
        SELECT 'SA2010', 'SA2'
    ) T ON C.TABLE_NAME = T.TABLE_NAME
    WHERE C.COLUMN_NAME IN (SELECT ColumnName FROM @TempColumns)
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Monta consulta paginada
SET @SQL = '
WITH PaginatedTable AS (
    SELECT
        SF1.F1_FILIAL,
		 (SELECT 
            STUFF(STUFF(STUFF(STUFF(SY.M0_CGC, 3, 0, ''.''), 7, 0, ''.''), 11, 0, ''/''), 16, 0, ''-'') 
         FROM SYS_COMPANY AS SY 
         WHERE SY.M0_CODFIL = SF1.F1_FILIAL 
           AND SY.D_E_L_E_T_ = ''''
        ) AS CNPJ_FILIAL,
        SF1.F1_DOC,
        SF1.F1_SERIE,
        SF1.F1_EMISSAO,
        SD1.D1_VUNIT,
        SF1.F1_VALBRUT,
        SD1.D1_COD,
        SB1.B1_DESC,
        SD1.D1_QUANT,
        SF1.F1_FORNECE,
        SA2.A2_NOME,
		STUFF(STUFF(STUFF(STUFF(SA2.A2_CGC, 3, 0, ''.''), 7, 0, ''.''), 11, 0, ''/''), 16, 0, ''-'') AS A2_CGC,
        ROW_NUMBER() OVER (PARTITION BY SF1.F1_FILIAL ORDER BY SF1.F1_EMISSAO DESC, SD1.D1_COD DESC) AS NumLinha
    FROM SF1010 SF1
    LEFT JOIN SD1010 SD1 ON SD1.D1_DOC = SF1.F1_DOC AND SF1.F1_FORNECE = SD1.D1_FORNECE AND SF1.F1_SERIE = SD1.D1_SERIE AND SD1.D_E_L_E_T_ = '''' AND SD1.D1_EMISSAO > ''20241201''
    LEFT JOIN SB1010 SB1 ON SB1.B1_COD = SD1.D1_COD AND SB1.D_E_L_E_T_ = ''''
    LEFT JOIN SA2010 SA2 ON SA2.A2_COD = SF1.F1_FORNECE AND SA2.D_E_L_E_T_ = ''''
    WHERE SF1.F1_EMISSAO > ''20241201'' AND SD1.D1_COD IN (''1011.0001'',''1021.0001'') AND SF1.D_E_L_E_T_ = '''' AND (SD1.D1_QUANT >= ''500'' AND SD1.D1_COD = ''1021.0001'') OR (SD1.D1_QUANT >= ''5000'' AND SD1.D1_COD = ''1011.0001'')
)
SELECT CNPJ_FILIAL, 
	' + @ColumnList + ',
       @TotalRecords AS TotalRegistros
FROM PaginatedTable
WHERE NumLinha <= 10
ORDER BY F1_FILIAL, F1_EMISSAO, D1_COD, NumLinha ASC';

-- Executa a consulta
EXEC sp_executesql @SQL, N'@PageNumber INT, @TotalPages INT, @TotalRecords INT, @Offset INT, @RecordsPerPage INT',
                   @PageNumber, @TotalPages, @TotalRecords, @Offset, @RecordsPerPage;

PRINT @ColumnList;
PRINT @SQL;