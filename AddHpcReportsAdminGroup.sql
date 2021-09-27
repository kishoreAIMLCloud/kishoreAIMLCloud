/*-------------------------------------------------------------------------------------------------
 * Create Login, Create Database User, Add it to db_datareader and Grant it the permission of EXECUTE on schema dbo
 *
 * This script doesn't work for some corner cases:
 * 1) The $(TargetAccount) has been associated with other user names different from ccpheadnode and $(TargetAccount)
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

if schema_id ('HpcReportingView') IS NULL 
  EXECUTE('CREATE SCHEMA HpcReportingView') 
if @@error <> 0 return;

if schema_id ('HpcReportingSp') IS NULL 
  EXECUTE('CREATE SCHEMA HpcReportingSp') 
if @@error <> 0 return;

grant select on schema::[HpcReportingView] to [$(TargetAccount)];
if @@error <> 0 return;

grant view definition on schema::[HpcReportingView] to [$(TargetAccount)];
if @@error <> 0 return;

grant exec on schema::[HpcReportingSp] to [$(TargetAccount)];
if @@error <> 0 return;

GO