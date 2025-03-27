DECLARE @TotalRecords INT;
DECLARE @TotalPages INT;
DECLARE @RecordsPerPage INT = 1000;
DECLARE @PageNumber INT = 1;  -- Defina aqui o n�mero da p�gina desejada
DECLARE @Offset INT;
DECLARE @CurrentPageRecords INT; -- P�gina atual
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(MAX) = 'CT2010';  -- Nome da tabela
DECLARE @Alias NVARCHAR(MAX) = 'CT2';  -- Alias da tabela
DECLARE @ORDERBY NVARCHAR(MAX) = 'CT2_DATA ASC';  -- Ordene pelo campo
DECLARE @startDate NVARCHAR(MAX) = '''20240101''';  -- Nota: Coloquei aspas simples ao redor do valor
DECLARE @endDate NVARCHAR(MAX) = '''20240102''';  -- Nota: Coloquei aspas simples ao redor do valor

-- Lista de campos a serem desconsiderados
DECLARE @ExcludedColumns NVARCHAR(MAX) = 'D_E_L_E_T_';

-- Verificar se a p�gina � igual a 0 e ajustar para 1
IF @PageNumber = 0
BEGIN
    SET @PageNumber = 1;
END

-- Calcular o total de registros
DECLARE @TotalRecordsQuery NVARCHAR(MAX) = '
    SELECT @TotalRecords = COUNT(*)
	FROM ' + @TableName + ' ' + @Alias + '
	LEFT JOIN SYS_COMPANY SY ON SY.M0_CODFIL = ' + @Alias + '.CT2_FILIAL AND SY.D_E_L_E_T_ = ''''
	WHERE ' + @Alias + '.CT2_DATA >= ' + @startDate + ' AND ' + @Alias + '.CT2_DATA <= ' + @endDate + '
	AND ' + @Alias + '.D_E_L_E_T_ = '''' ;';


EXEC sp_executesql @TotalRecordsQuery,
    N'@TotalRecords INT OUTPUT',
    @TotalRecords OUTPUT;

-- Calcular o total de p�ginas
SET @TotalPages = CEILING(@TotalRecords * 1.0 / @RecordsPerPage);

-- Calcular o offset
SET @Offset = (@PageNumber - 1) * @RecordsPerPage;

-- Construir a lista de colunas com os t�tulos usando FOR XML PATH
SET @ColumnList = STUFF((SELECT ', ' + C.COLUMN_NAME + ' AS [' + SX3.X3_TITULO + ']'
                         FROM INFORMATION_SCHEMA.COLUMNS C
                         JOIN SX3010 SX3 ON C.COLUMN_NAME = SX3.X3_CAMPO
                         WHERE C.TABLE_NAME = @TableName
						 AND CHARINDEX(C.COLUMN_NAME, @ExcludedColumns) = 0  -- Excluir colunas da lista
                         FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Construir a consulta din�mica
SET @SQL = '
WITH PaginatedTable AS (
    SELECT ' + @Alias + '.*,
		SY.M0_FILIAL AS FilialNome,
		SY.M0_CGC AS CNPJ_filial,
           ROW_NUMBER() OVER (ORDER BY ' + @ORDERBY + ') AS NumLinha
    FROM ' + @TableName + ' ' + @Alias + '
	LEFT JOIN SYS_COMPANY SY ON SY.M0_CODFIL = ' + @Alias + '.CT2_FILIAL AND  SY.D_E_L_E_T_ = ''''
	WHERE ' + @Alias + '.CT2_DATA >= ' + @startDate + ' AND ' + @Alias + '.CT2_DATA <= ' + @endDate + '
	AND ' + @Alias + '.D_E_L_E_T_ = ''''
)
SELECT	FilialNome,
		CNPJ_filial,
		' + @ColumnList + ',
		NumLinha,
       @TotalRecords AS TotalRegistros,
       @TotalPages AS TotalPaginas,
       @PageNumber AS PaginaAtual,
       (SELECT COUNT(*) FROM PaginatedTable WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage) AS RegistrosPorPagina
FROM PaginatedTable
WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage
ORDER BY ' + @ORDERBY + '';

-- Executar a consulta din�mica
EXEC sp_executesql @SQL,
    N'@TotalRecords INT, @TotalPages INT, @PageNumber INT, @Offset INT, @RecordsPerPage INT',
    @TotalRecords, @TotalPages, @PageNumber, @Offset, @RecordsPerPage;


