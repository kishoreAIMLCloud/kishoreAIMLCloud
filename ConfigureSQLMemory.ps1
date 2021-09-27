# Adds SQLPS module to the current session and suppresses the warning. 
# to be run on the computer hosting the SQLServer and applies against the DEFAULT INSTANCE
# (COMPUTERNAME\MSSQLSERVER)
# Specify mandatory parameters required for the current session. 

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string]$logfolder
)

Import-Module SQLPS -DisableNameChecking

$Instance = $env:COMPUTERNAME
$logfile = $logFolder + "\ConfigureSQLMemory.log"

# Write-Log Function makes it easy to write messages to a log file that is parseable and based on a standard log format

Function Write-Log {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$True)]
    [string]$Message,

    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]$Level = "INFO",

    [Parameter(Mandatory=$False)]
    [string]$logfile
  )

  $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss:fff")
  $Line = $Stamp + "," +  $Level  + "," + '"' + $Message + '"'
  If($logfile) {
        Add-Content $logfile -Value $Line
  }
  Else {
        Write-Output $Line   # used when a logfile name is not passed to Write-Log, Write to the Standard Output, the console.
  }
}

# Retrieves the total amount of physical memory (MB) on the host. 

$TotalPhysicalMemory = [Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1MB)

# write-debug "$($TotalPhysicalMemory)"

$Max = 0.8
$rest = 1 - $Max

$SQLmemorydisplayinMB = [math]::round((($($Max) * ($TotalPhysicalMemory))))
$OSmemorydisplayinMB = [math]::round((($($rest) * ($TotalPhysicalMemory))))

# Conditional logic to determine the amount of total physical memory and the calculation for configuring SQL Server maximum memory.

If ($TotalPhysicalMemory -ge  $SQLmemorydisplayinMB) { 
    $MaximumMemory=$SQLmemorydisplayinMB
} 
Else { 
    $MaximumMemory  = ($TotalPhysicalMemory  - $OSmemorydisplayinMB)
} 

# Configures the SQL server maximum memory value.
Try {   
    $logMsg = "Configuring Maximum Memory for SQL Server $($Instance) successful - Max set to $($Max)"
    Write-Log $logMsg "INFO" $logfile
	$logMsg = "Total Physical Memory = $($TotalPhysicalMemory) MB, SQLServer = $($SQLmemorydisplayinMB) MB, OS = $($OSmemorydisplayinMB) MB"
	Write-Log $logMsg "INFO" $logfile

    Invoke-SQLCmd -ServerInstance $Instance -Query ("EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE")
    Invoke-SQLCmd -ServerInstance $Instance -Query ("EXEC sys.sp_configure N'max server memory (MB)', N'" + [math]::truncate($MaximumMemory) + "'")
}
Catch [System.Exception] { 
    $logMsg= "Configuring Maximum Memory for SQL Server $($instance) failed"
    Write-Log $logMsg "ERROR" $logfile
} 

# not needed - we will restart the server after SQL installation
# restart-service MSSQLSERVER -Force
# restart-service SQLSERVERAGENT
