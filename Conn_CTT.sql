/* 
=======================================================================
Autor:        Guilherme Machancoses
Data:         04/04/2025
Versão:       1.0
Descrição:    Script para realizar paginação dinâmica sobre a tabela CTT010.
              - Calcula total de registros e páginas com base no filtro D_E_L_E_T_.
              - Gera consulta dinâmica com títulos das colunas a partir da SX3.
              - Utiliza ROW_NUMBER() para paginação.
              - Retorna colunas com alias personalizados, total de registros, total de páginas,
                número da página atual e quantidade de registros por página.
Aplicação: API - Alianzo, consulta dos centro de custos cadastrados.
=======================================================================
*/

DECLARE @TotalRecords INT;
DECLARE @TotalPages INT;
DECLARE @RecordsPerPage INT = 1000;
DECLARE @PageNumber INT = 1;  -- Defina aqui o n�mero da p�gina desejada
DECLARE @Offset INT;
DECLARE @CurrentPageRecords INT; -- P�gina atual
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(MAX) = 'CTT010';  -- Nome da tabela
DECLARE @Alias NVARCHAR(MAX) = 'CTT';  -- Alias da tabela
DECLARE @ORDERBY NVARCHAR(MAX) = 'CTT_CUSTO ASC';  -- Ordene pelo campo

-- Verificar se a p�gina � igual a 0 e ajustar para 1
IF @PageNumber = 0
BEGIN
    SET @PageNumber = 1;
END

-- Calcular o total de registros
DECLARE @TotalRecordsQuery NVARCHAR(MAX) = '
    SELECT @TotalRecords = COUNT(*)
	FROM ' + @TableName + ' ' + @Alias + '
	WHERE D_E_L_E_T_ = '''' ;';


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
                         FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Construir a consulta din�mica
SET @SQL = '
WITH PaginatedTable AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY ' + @ORDERBY + ') AS NumLinha
    FROM ' + @TableName + ' ' + @Alias + '
	WHERE D_E_L_E_T_ = ''''
)
SELECT ' + @ColumnList + ',
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
