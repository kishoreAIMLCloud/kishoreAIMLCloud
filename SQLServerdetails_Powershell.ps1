# Param ([String[]] $SQLServerList)
$SQLServerList ="<DB server name>"
$Module = Get-Module | where-object {$_.Name -like ‘SQLPS’} | Select-Object Name
IF ($Module -ne “SQLPS”)
{
Import-Module Sqlps -DisableNameChecking;
}
foreach ($SQLServer in $SQLServerList)
{
if ([array]::indexof($SqlServerList ,$SqlServer)%2 -eq 0)
{
$C =”Green”
$D = “Black”
}
ELSE
{
$C= “DarkGreen”
$D = “Yellow”
}
$a=new-object Microsoft.SQLServer.Management.Smo.Server $SQLServer
Write-Host -ForeGroundColor $C -BackGroundColor $D $SQLServer ‘Server Information’
$a.Information|Select-object Parent,Version,Processors,ComputerNamePhysicalNetBios,Product,ProductLevel,Edition,PhysicalMemory,MasterDBLogPath,MasterDBPath,RootDirectory,ErrorLogPath
}
