DECLARE @TotalRecords INT;
DECLARE @TotalPages INT;
DECLARE @RecordsPerPage INT = 1000;
DECLARE @PageNumber INT = 1;  -- Defina aqui o n�mero da p�gina desejada
DECLARE @Offset INT;
DECLARE @CurrentPageRecords INT; -- P�gina atual
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(MAX) = 'ST9010';  -- Nome da tabela
DECLARE @Alias NVARCHAR(MAX) = 'ST9';  -- Alias da tabela
DECLARE @ORDERBY NVARCHAR(MAX) = 'T9_CODBEM ASC';  -- Ordene pelo campo
DECLARE @SitiBem NVARCHAR(MAX) = '''A'',''I''';  -- Nota: Coloquei aspas simples ao redor do valor
DECLARE @SitManu NVARCHAR(MAX) = '''A'',''I''';  -- Nota: Coloquei aspas simples ao redor do valor

DECLARE @ExistColumns NVARCHAR(MAX) = 'T9_NOMFAMI,T9_PLACA,T9_RENAVAM,T9_CHASSI,T9_NOMFABR,T9_DESMOD,T9_ANOFAB,T9_ANOMOD,T9_SITBEM,T9_PROPRIE,T9_UFEMPLA';

-- Verificar se a p�gina � igual a 0 e ajustar para 1
IF @PageNumber = 0
BEGIN
    SET @PageNumber = 1;
END

-- Calcular o total de registros
DECLARE @TotalRecordsQuery NVARCHAR(MAX) = '
    SELECT @TotalRecords = COUNT(*)
    FROM ' + @TableName + ' ' + @Alias + '
    WHERE (' + @Alias + '.T9_PLACA != '''' OR ' + @Alias + '.T9_ZZPLACA != '''') 
    AND D_E_L_E_T_ = '''' 
    AND ' + @Alias + '.T9_SITBEM IN (' + @SitiBem + ') 
    AND ' + @Alias + '.T9_SITMAN IN (' + @SitManu + ')';

EXEC sp_executesql @TotalRecordsQuery,
    N'@TotalRecords INT OUTPUT',
    @TotalRecords OUTPUT;

-- Calcular o total de p�ginas
SET @TotalPages = CEILING(@TotalRecords * 1.0 / @RecordsPerPage);

-- Calcular o offset
SET @Offset = (@PageNumber - 1) * @RecordsPerPage;

-- Dividir @ExistColumns em uma tabela tempor�ria
DECLARE @TempColumns TABLE (ColumnName NVARCHAR(MAX));
INSERT INTO @TempColumns (ColumnName)
SELECT value FROM STRING_SPLIT(@ExistColumns, ',');


-- Construir a lista de colunas com os t�tulos usando FOR XML PATH
SET @ColumnList = STUFF((SELECT ', ' + C.COLUMN_NAME + ' AS ['+ REPLACE(REPLACE(LTRIM(RTRIM(SX3.X3_TITULO)), '%', ''), '?', '') + ']'
                         FROM INFORMATION_SCHEMA.COLUMNS C
                         JOIN SX3010 SX3 ON C.COLUMN_NAME = SX3.X3_CAMPO
                         WHERE C.TABLE_NAME = @TableName 
						 AND C.COLUMN_NAME IN (SELECT ColumnName FROM @TempColumns)   -- Apenas colunas da lista
                         FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Construir a consulta din�mica
SET @SQL = '
WITH PaginatedTable AS (
    SELECT
		' + @Alias + '.T9_CODBEM,
        ' + @Alias + '.T9_PLACA,
        ' + @Alias + '.T9_RENAVAM,
        ' + @Alias + '.T9_CHASSI,
        ' + @Alias + '.T9_ANOFAB,
        ' + @Alias + '.T9_ANOMOD,
		CASE 
            WHEN ' + @Alias + '.T9_SITBEM = ''I'' THEN ''Inativo''
            WHEN ' + @Alias + '.T9_SITBEM = ''A'' THEN ''Ativo''
            ELSE ''Desconhecido''
        END AS T9_SITBEM,
        CASE 
            WHEN ' + @Alias + '.T9_PROPRIE = 1 THEN ''Próprio''
            WHEN ' + @Alias + '.T9_PROPRIE = 2 THEN ''Terceiro''
            ELSE ''Desconhecido''
        END AS T9_PROPRIE,
        ' + @Alias + '.T9_UFEMPLA,
		ST7.T7_NOME AS Fabricante,
        TQR.TQR_DESMOD AS Modelo,
		ST6.T6_NOME AS Familia, 
        ROW_NUMBER() OVER (ORDER BY ' + @ORDERBY + ') AS NumLinha
    FROM ' + @TableName + ' ' + @Alias + '
	INNER JOIN TQR010 TQR ON TQR.TQR_TIPMOD = ' + @Alias + '.T9_TIPMOD AND TQR.D_E_L_E_T_ = ''''
	INNER JOIN ST6010 ST6 ON ST6.T6_CODFAMI = ' + @Alias + '.T9_CODFAMI AND ST6.D_E_L_E_T_ = ''''
	inner JOIN ST7010 ST7 ON ST7.T7_FABRICA = ' + @Alias + '.T9_FABRICA AND ST7.D_E_L_E_T_ = ''''
    WHERE (' + @Alias + '.T9_PLACA != '''' OR ' + @Alias + '.T9_ZZPLACA != '''') 
    AND ' + @Alias + '.D_E_L_E_T_ = ''''
    AND ' + @Alias + '.T9_SITBEM IN (' + @SitiBem + ') 
    AND ' + @Alias + '.T9_SITMAN IN (' + @SitManu + ')
)
SELECT ' + @ColumnList + ',
	   Fabricante,
	   Familia,
	   Modelo,
       NumLinha,
	   @PageNumber AS PaginaAtual,
       @TotalPages AS TotalPaginas,
	   @TotalRecords AS TotalRegistros,
       (SELECT COUNT(*) FROM PaginatedTable WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage) AS RegistrosPorPagina
FROM PaginatedTable
WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage
ORDER BY ' + @ORDERBY + '';

-- Executar a consulta din�mica
EXEC sp_executesql @SQL,
    N'@TotalRecords INT, @TotalPages INT, @PageNumber INT, @Offset INT, @RecordsPerPage INT',
    @TotalRecords, @TotalPages, @PageNumber, @Offset, @RecordsPerPage;

PRINT @ColumnList;
PRINT @SQL;