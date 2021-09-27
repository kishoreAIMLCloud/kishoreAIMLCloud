/*-------------------------------------------------------------------------------------------------
 * Enable clr extensions so we can embed the parsing functions in the database.
 *-------------------------------------------------------------------------------------------------*/
exec sp_configure 'clr enabled', 1
if @@error <> 0 return;

reconfigure with override
if @@error <> 0 return;
GO

if exists (select * from sys.assemblies where name='ccpSqlHelpers')
begin
    drop assembly ccpsqlhelpers;
    if @@error <> 0 return;
end

create assembly ccpsqlhelpers from '$(SqlHelperFile)'
if @@error <> 0 return;

GO