 

param( 
[string]$DatabaseDir="G:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data"
) 
# $(throw -DatabaseDir) 
#Load the SQL Assembly 
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | out-null 
#Connect to the local SQL Server Instance, change the (local) parameter if needed 
$server = new-Object Microsoft.SqlServer.Management.Smo.Server("(local)") 
if ($server -eq $null){ 
    Write-host -foreground red "Unable to connect to the SQL Server" 
    return -1 
} 
$items = get-childitem $DatabaseDir *.mdf 
 
foreach ($item in $items){ 
    [bool]$ErrorExists = $false 
    $Item.name 
  
    try    { 
        $DBName = $server.DetachedDatabaseInfo($($item.fullname)).rows[0].value 
    }  
    catch { 
        Write-host -foregroundcolor red "File was not able to be read. It is most likely already mounted or in use by another application" 
        $ErrorExists = $true 
    } 
 
    if ($ErrorExists -eq $false){ 
        foreach ($db in $server.databases){ 
            if ($db.name.Equals($DBName)){ 
                write-host -foreground Green "THIS DATABASE IS ALREADY EXISTS ON THIS SERVER" 
                $ErrorExists = $true 
            } 
        } 
        if ($ErrorExists -eq $false){ 
            $DbLocation = new-object System.Collections.Specialized.StringCollection 
            $DbLocation.Add($item.fullname) 
            $attach = $server.AttachDatabase($DBName, $DbLocation) 
        } 
    } 
} 
