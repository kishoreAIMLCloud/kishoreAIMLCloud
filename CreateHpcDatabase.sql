/**
 ** create hpc databases
 ** note that for each database, the settings are default. You can change it as appropirate
**/

USE master
GO
DECLARE @data_path nvarchar(256);
DECLARE @log_path nvarchar(256);
SET @data_path = (SELECT SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 1)
                  FROM master.sys.master_files
                  WHERE database_id = 1 AND file_id = 1);
SET @log_path = @data_path;

EXECUTE ('CREATE DATABASE HPCManagement
ON 
(
   NAME = HPCManagement_data,
   FILENAME = ''' + @data_path + 'HPCManagement.mdf'',
   size = 1024MB,
   FILEGROWTH  = 50% )
LOG ON
( 
   NAME = HPCManagement_log,
   FILENAME = ''' + @log_path +'HPCManagement.ldf'',
   size = 128MB,
   FILEGROWTH  = 50% )'
);

EXECUTE ('CREATE DATABASE HPCScheduler
ON 
(
   NAME = HPCScheduler_data,
   FILENAME = ''' + @data_path + 'HPCScheduler.mdf'',
   size = 256MB,
   FILEGROWTH  = 10% )
LOG ON
( 
   NAME = HPCScheduler_log,
   FILENAME = ''' + @log_path +'HPCScheduler.ldf'',
   size = 64MB,
   FILEGROWTH  = 10% )'
);

EXECUTE ('CREATE DATABASE HPCReporting
ON 
(
   NAME = HPCReporting_data,
   FILENAME = ''' + @data_path + 'HPCReporting.mdf'',
   size = 128MB,
   FILEGROWTH  = 10% )
LOG ON
( 
   NAME = HPCReporting_log,
   FILENAME = ''' + @log_path +'HPCReporting.ldf'',
   size = 64MB,
   FILEGROWTH  = 10% )'
);


EXECUTE ('CREATE DATABASE HPCDiagnostics
ON 
(
   NAME = HPCDiagnostics_data,
   FILENAME = ''' + @data_path + 'HPCDiagnostics.mdf'',
   size = 256MB,
   FILEGROWTH  = 10% )
LOG ON
( 
   NAME = HPCDiagnostics_log,
   FILENAME = ''' + @log_path +'HPCDiagnostics.ldf'',
   size = 64MB,
   FILEGROWTH  = 10% )'
);

EXECUTE ('CREATE DATABASE HPCMonitoring
ON 
(
   NAME = HPCMonitoring_data,
   FILENAME = ''' + @data_path + 'HPCMonitoring.mdf'',
   size = 256MB,
   FILEGROWTH  = 10% )
LOG ON
( 
   NAME = HPCMonitoring_log,
   FILENAME = ''' + @log_path +'HPCMonitoring.ldf'',
   size = 64MB,
   FILEGROWTH  = 10% )'
);
GO