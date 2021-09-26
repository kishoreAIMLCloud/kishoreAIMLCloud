<#	
	.NOTES
	===========================================================================
	 Created on:   	04/13/2017
	 Created by:   	Kishore Kesanapally
	  Filename:  stopCOMNodesAfterPatching.ps1
	 Warning:	This script will stop AWS EC2 instances to reduce AWS charges.
	 Purpose: 	FRM Compute Nodes will be named AW<r>W<z>FRMCOMxxx where
	   <r> = D (DEV), T (TEST), P (PROD)
	   <z> = A (AWS AZ1), B (AWS AZ2), C (AWS AZ3)
	   xxx = some number from 01 to 999
	            This script will stop ALL compute nodes which name begins with
				the same AW<r>W<z>FRM as the HEAD NODE
	 ex: this head node is named AWPWAFRMHEAD, and script running on this node will
	     stop all nodes named AWPWAFRMCOMxxx
         it simply queries the AWS EC2 NAME tag which start with "AWPWAFRMCOM" for
		 the instanceIDs
	===========================================================================
	.PARAMETER Logfile
		The log file for script actions. Every time the script is restarted, it will create or overwrite the file with given name.
		During runtime all records are added to the end of the file.
#>
<#	
	.NOTES
	===========================================================================
	 Created on:   	10/31/2017
	 Created by:   	Kishore Kesanapally
	 ===========================================================================
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory = $false, Position = 1)]
	[string]$logfile = "D:\AWSFRMHPC\logs\stopCOMNodes.log"
)

Add-PSSnapIn Microsoft.HPC
Import-Module AWSPowerShell

$HeadNode = $env:COMPUTERNAME
$ComNodePrefix = $HeadNode.Substring(0,$HeadNode.Length-4)+"COM*"
$InstIDs = (Get-EC2Tag -filter @{ Name="key";Values="Name" },@{ Name="value";Values="$($ComNodePrefix)" }).ResourceID

Function Stop-AWS-ComputeNodes
{	
	foreach ($InstID in $InstIDs)
	{
		$instancestate = (Get-EC2Instance $($InstID)).Instances.State.Name 
		"$($(Get-Date).ToUniversalTime()) $($nodeID), Instance is $($InstID), State is $($instancestate)"  | Out-File -FilePath $logfile -Append                

		If ($instancestate -eq "running")
		{
			"`n ***SHUTDOWN***   $($(Get-Date).ToUniversalTime()) Stopping node $($nodeID), instanceID $($InstID)`n" | Out-File -FilePath $logfile -Append
			Stop-EC2Instance $InstID
		}

	}
}
	
$allidlenodes = @()

"Script started at $($(Get-Date).ToUniversalTime())" | Out-file -Filepath $logfile
enable-ScheduledTask -TaskName "FRMinc AutoStart-Stop"
enable-ScheduledTask -TaskName "FRMFvar AutoStart-Stop"
start-sleep 5

start-ScheduledTask -TaskName "FRMinc AutoStart-Stop"
start-ScheduledTask -TaskName "FRMFvar AutoStart-Stop"
