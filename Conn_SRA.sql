/*
=======================================================================
Autor:        Guilherme Machancoses
Data:         04/04/2025
Versão:       1.0
Descrição:    Script para realizar paginação dinâmica sobre uma tabela genérica,
              filtrando registros com base em critérios específicos (ex: RA_ZZMOTOR = 'S',
              D_E_L_E_T_ = '', RA_SITFOLH IN (...)).
              
              Funcionalidades:
              - Recebe a lista de colunas existentes dinamicamente (@ExistColumns)
              - Utiliza a tabela SX3 para mapear os títulos das colunas
              - Calcula o total de registros, total de páginas e registros por página
              - Traduz valores das colunas RA_SITFOLH (Status) e RA_CATCNH (Categoria da CNH)
              - Executa paginação com ROW_NUMBER() e OFFSET
              - Gera consulta dinâmica com colunas customizadas e metadados de paginação

Observação:
              Parâmetros genéricos a serem substituídos antes da execução:
              - <>page</>      → Número da página
              - <>tabela</>    → Nome da tabela
              - <>Alias</>     → Alias usado na consulta
              - <>orderby</>   → Campo para ordenação
              - <>block</>     → Lista de códigos de RA_SITFOLH permitidos (ex: ' ', 'D')
Aplicação: API - AUCOM, consulta dos motoristas cadastrados.
=======================================================================
*/

DECLARE @TotalRecords INT;
DECLARE @TotalPages INT;
DECLARE @RecordsPerPage INT = 100;
DECLARE @PageNumber INT = <>page</>;  -- Defina aqui o número da página desejada
DECLARE @Offset INT;
DECLARE @CurrentPageRecords INT; -- Página atual
DECLARE @SQL NVARCHAR(MAX);
DECLARE @ColumnList NVARCHAR(MAX) = '';
DECLARE @TableName NVARCHAR(MAX) = '<>tabela</>';  -- Nome da tabela
DECLARE @Alias NVARCHAR(MAX) = '<>Alias</>';  -- Alias da tabela
DECLARE @ORDERBY NVARCHAR(MAX) = '<>orderby</>';  -- Ordene pelo campo

DECLARE @ExistColumns NVARCHAR(MAX) = 'RA_NOME, RA_ESTCIVI, RA_HABILIT, RA_CNHORG, RA_DTEMCNH, RA_DTVCCNH, RA_NASC, RA_ENDEREC, RA_NUMENDE, RA_BAIRRO, RA_CODMUN, RA_CEP, RA_ESTADO, RA_PAI, RA_MAE, RA_RG, RA_RGEXP, RA_RGEXP, RA_ORGEMRG, RA_CIC, RA_SITFOLH, RA_DDDFONE, RA_TELEFON, RA_DDDCELU, RA_NUMCELU, RA_NUMCP, RA_SERCP, RA_EXAMEDI, RA_PIS, RA_TITULOE, RA_ZONASEC, RA_SECAO, RA_MAT';

-- Verificar se a página é igual a 0 e ajustar para 1
IF @PageNumber = 0
BEGIN
    SET @PageNumber = 1;
END

-- Calcular o total de registros
DECLARE @TotalRecordsQuery NVARCHAR(MAX) = '
    SELECT @TotalRecords = COUNT(*)
    FROM ' + @TableName + ' ' + @Alias + '
    WHERE ' + @Alias + '.RA_ZZMOTOR = ''S'' AND ' + @Alias + '.D_E_L_E_T_ = '''' AND ' + @Alias + '.RA_SITFOLH IN (<>block</>);';

EXEC sp_executesql @TotalRecordsQuery,
    N'@TotalRecords INT OUTPUT',
    @TotalRecords OUTPUT;

-- Calcular o total de páginas
SET @TotalPages = CEILING(@TotalRecords * 1.0 / @RecordsPerPage);

-- Calcular o offset
SET @Offset = (@PageNumber - 1) * @RecordsPerPage;

-- Dividir @ExistColumns em uma tabela temporária
DECLARE @TempColumns TABLE (ColumnName NVARCHAR(128));
INSERT INTO @TempColumns (ColumnName)
SELECT TRIM(value) FROM STRING_SPLIT(@ExistColumns, ',');

-- Construir a lista de colunas com os títulos usando FOR XML PATH
SET @ColumnList = STUFF((SELECT ', ' + C.COLUMN_NAME + ' AS [' + SX3.X3_TITULO + ']'
                         FROM INFORMATION_SCHEMA.COLUMNS C
                         JOIN SX3010 SX3 ON C.COLUMN_NAME = SX3.X3_CAMPO
                         WHERE C.TABLE_NAME = @TableName
                         AND C.COLUMN_NAME IN (SELECT ColumnName FROM @TempColumns)   -- Apenas colunas da lista
                         FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Construir a consulta dinâmica
SET @SQL = '
WITH PaginatedTable AS (
    SELECT ' + 
           '    ' + @Alias + '.*,' + -- Inclua todas as colunas da tabela original
           '    CASE' +
           '        WHEN ' + @Alias + '.RA_SITFOLH = '''' THEN ''Ativo''' +
           '        WHEN ' + @Alias + '.RA_SITFOLH = ''D'' THEN ''Inativo''' +
           '        ELSE '''' ' +
           '    END AS Status,' +
           '    CASE' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''1'' THEN ''A''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''2'' THEN ''B''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''3'' THEN ''C''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''4'' THEN ''D''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''5'' THEN ''E''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''6'' THEN ''AB''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''7'' THEN ''AC''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''8'' THEN ''AD''' +
           '        WHEN ' + @Alias + '.RA_CATCNH = ''9'' THEN ''AE''' +
           '        ELSE '''' ' +
           '    END AS "CNH Categ.",' +
           '    ROW_NUMBER() OVER (ORDER BY ' + @ORDERBY + ' ASC) AS NumLinha' +
    ' FROM ' + @TableName + ' ' + @Alias + 
    ' WHERE ' + @Alias + '.RA_ZZMOTOR = ''S'' AND ' + @Alias + '.D_E_L_E_T_ = '''' AND ' + @Alias + '.RA_SITFOLH IN (<>block</>)
)
SELECT ' + @ColumnList + ',
        Status,
		"CNH Categ.",
		NumLinha,
        @TotalRecords AS TotalRegistros,
        @TotalPages AS TotalPaginas,
        @PageNumber AS PaginaAtual,
        (SELECT COUNT(*) FROM PaginatedTable WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage) AS RegistrosPorPagina
FROM PaginatedTable
WHERE NumLinha BETWEEN @Offset + 1 AND @Offset + @RecordsPerPage
ORDER BY ' + @ORDERBY + ' ASC';

-- Executar a consulta dinâmica
EXEC sp_executesql @SQL,
    N'@TotalRecords INT, @TotalPages INT, @PageNumber INT, @Offset INT, @RecordsPerPage INT',
    @TotalRecords, @TotalPages, @PageNumber, @Offset, @RecordsPerPage;
