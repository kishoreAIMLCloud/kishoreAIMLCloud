/*-------------------------------------------------------------------------------------------------
 * Create Login, Create Database User and Add it to db_datareader and db_datawriter.
 *
 * This script doesn't work for some corner cases:
 * 1) The $(TargetAccount) has been associated with other user names different from $(TargetAccount). For example: ccpheadnode of HPC V3.
 * 2) The $(TargetAccount) login is disabled or "Permission to connect to database engine" is denied. 
 *-------------------------------------------------------------------------------------------------*/
 
/*-------------------------------------------------------------------------------------------------
 * Due to the permission requirement of sys.server_principals
 * (Any login can see their own login name, the system logins, and the fixed server roles. 
 * To see other logins, requires ALTER ANY LOGIN, or a permission on the login. To see 
 * user-defined server roles, requires ALTER ANY SERVER ROLE, or membership in the role.)
 * Try...Catch block is introduced to ensure the following logic for "create login"
 * 1) The login already exists: does nothing
 * 1.1) The current user has login related permission: the current user sees this login.
 * 1.2) The current user doesn't have login related permission: the current user does't see this login and Try...Catch block eats the error for creating login.
 * 2) The login doesn't exist: try to create login 
 * 2.1) The current user has login related permission: the current user doesn't see this login and creates it.
 * 2.2) The current user doesn't have login related permission: the current user does't see this login and Try...Catch block eats the error for creating login. 
 *      Later "create user" will report error.
 *-------------------------------------------------------------------------------------------------*/
BEGIN TRY
    if not exists (select * from sys.server_principals where name = '$(TargetAccount)')
    begin
        create login [$(TargetAccount)] from windows;
    end
END TRY
BEGIN CATCH
END CATCH

if exists (select * from sys.database_principals where name = '$(TargetAccount)')
begin
    drop user [$(TargetAccount)];
    if @@error <> 0 return;
end

create user [$(TargetAccount)];
if @@error <> 0 return;

exec sp_addrolemember 'db_datareader', '$(TargetAccount)';
if @@error <> 0 return;

exec sp_addrolemember 'db_datawriter', '$(TargetAccount)';
if @@error <> 0 return;

exec sp_addrolemember 'db_ddladmin', '$(TargetAccount)';
if @@error <> 0 return;

-- Enable HPC setup user to configure database in HpcServer_x64.msi
grant alter to [$(TargetAccount)]
if @@error <> 0 return;

-- Enable HPC setup user to use user-defined FUNCTION
grant exec to [$(TargetAccount)];
if @@error <> 0 return;

-- Enable HPC setup user to query database extended property DbVersion
grant view definition to [$(TargetAccount)]
if @@error <> 0 return;
GO