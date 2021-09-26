# Restore Multiple databases Powershell script:
# ***********************************************

# Below script helps restore several databases on to a SQL Server instance in one go. We just have to place all the .bak files in a folder and execute the script. before running the script, its required to import SQLPS in the powershell prompt as below.
# ***********************************************************************************************************************************************************

# Import-Module SQLPS -DisableNameChecking

Import-Module SQLPS -DisableNameChecking

# Save below script as restore_all.ps1

#*---------------------------------------------------------------------------------------------------------------------------- 

#  Filename       : mssql_AutoRestoreMultipleDatabasesInOneGo.ps1 

#  Purpose        : Script to restore all databases from a backup folder on to a SQL Server. 

#  Schedule       : Ad-Hoc 

#  Version        : 1 

# 

#  Important --arks:     

#  INPUT          : $path = Backup folder, $sqlserver = Destination SQL Server instance name, $datafolder = datafilelocation, $logfolder = logfilelocation 

#  VARIABLE       : NONE 

#  PARENT         : NONE 

#  CHILD          : NONE 

#  NOTE           : The database path will be retrieved from SQL Server database settings 

#---------------------------------------------------------------------------------------------------------------------------*/ 

# Usage: 

# ./mssql_AutoRestoreMultipleDatabasesInOneGo.ps1 "E:\database_Backup_Source_Folder\" "hostname\instancename" "destinationdatafolderpath" "destinationtransactionlogfolderpath" 

#  
param($path, $sqlserver, $datafolder, $logfolder) 
foreach($bkpfile in Get-ChildItem $path "*.bak" | Select-Object basename) 
{ 
    $bkpfile = $bkpfile.BaseName 
    $server = New-Object     Microsoft.SqlServer.Management.Smo.Server($sqlserver) 
    $restore = New-Object     Microsoft.SqlServer.Management.Smo.Restore 
    $restore.Devices.AddDevice($path+'\'+$bkpfile+'.bak',  
      [Microsoft.SqlServer.Management.Smo.DeviceType]::File) 
    $header = $restore.ReadBackupHeader($server) 
    if($header.Rows.Count -eq 1) 
    { 
      $dbname = $header.Rows[0]["DatabaseName"] 
    } 
    # .\001_restore.ps1 . $path"\"$bkpfile".bak" $dbname 
    # param($sqlserver, $bkfilepath, $dbname) 
        $bkfilepath = $path + "\"+ $bkpfile + ".bak" 
# Connect to the specified instance 
$srv = new-object ('Microsoft.SqlServer.Management.Smo.Server') $sqlserver 
# Get the default file and log locations 
# (If DefaultFile and DefaultLog are empty, use the MasterDBPath and MasterDBLogPath values) 

if(!$datafolder) 
{ 
    $fileloc = $srv.Settings.DefaultFile 
} 
else { $fileloc = $datafolder} 
if(!$logfolder) 

{ 
    $logloc = $logloc = $srv.Settings.DefaultLog 
} 
else { $logloc = $logfolder} 
if ($fileloc.Length -eq 0) { 
    $fileloc = $srv.Information.MasterDBPath 
    } 
if ($logloc.Length -eq 0) { 
    $logloc = $srv.Information.MasterDBLogPath 
    } 
# Identify the backup file to use, and the name of the database copy to create 

$bckfile = $bkfilepath 
$dbname = $dbname 

# Build the physical file names for the database copy 
if($fileloc -eq $logloc) 
{ 
    $dbfile = $fileloc + '\Data\'+ $dbname + '_Data.mdf' 
    $logfile = $logloc + '\Log\'+ $dbname + '_Log.ldf' 
} 
else 
{ 
    $dbfile = $fileloc + '\'+ $dbname + '_Data.mdf' 
    $logfile = $logloc + '\'+ $dbname + '_Log.ldf' 

} 

# Use the backup file name to create the backup device 
$bdi = new-object ('Microsoft.SqlServer.Management.Smo.BackupDeviceItem') ($bckfile, 'File') 
# Create the new restore object, set the database name and add the backup device 
$rs = new-object('Microsoft.SqlServer.Management.Smo.Restore') 
$rs.Database = $dbname 
$rs.Devices.Add($bdi) 
# Get the file list info from the backup file 

$fl = $rs.ReadFileList($srv) 
$rfl = @() 
foreach ($fil in $fl) { 
    $rsfile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile') 
    $rsfile.LogicalFileName = $fil.LogicalName 
    if ($fil.Type -eq 'D') { 
        $rsfile.PhysicalFileName = $dbfile 
         } 
    else { 
        $rsfile.PhysicalFileName = $logfile 
        } 
    $rfl += $rsfile 
    } 
# Restore the database 
Restore-SqlDatabase -ServerInstance $sqlserver -Database $dbname -BackupFile $bkfilepath -RelocateFile $rfl -NoRecovery 
}
