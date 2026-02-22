DECLARE @sql NVARCHAR(MAX) = N'';

-- 1) Dropa todas as FOREIGN KEYS das tabelas do schema dbo
SELECT @sql += N'ALTER TABLE ' 
    + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
    + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(13)
FROM sys.foreign_keys fk
JOIN sys.tables t ON t.object_id = fk.parent_object_id
WHERE t.schema_id = SCHEMA_ID('dbo');

-- 2) Dropa todas as tabelas do schema dbo
SELECT @sql += N'DROP TABLE '
    + QUOTENAME(SCHEMA_NAME(schema_id)) + N'.' + QUOTENAME(name)
    + N';' + CHAR(13)
FROM sys.tables
WHERE schema_id = SCHEMA_ID('dbo');

PRINT @sql;  -- veja o que vai executar (opcional)
EXEC sp_executesql @sql;
