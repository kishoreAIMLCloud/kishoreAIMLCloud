<#	
	.NOTES
	===========================================================================
	 Created on:   	11/01/2017
	 Created by:   	KISHORE KESANAPALLY
	 Filename:  HPC_AutoStart-Stop.ps1
	 Warning:	This script wiil start AWS EC2 instances which results in AWS charges.
	 Purpose: 	This script is provided as an example to help with development of your own
				Microsoft HPC cluster compute nodes automation management in AWS.
	 Added extra parameter position 1: incsim or mvar to allow this to be split up to
	 monitor the different jobs to run on different set of nodes
	===========================================================================
	.DESCRIPTION
		Modified for use in the FHLBSF environment
		This script runs every X seconds ($Interval) via Task Scheduler and checks for QRM jobs.
		If there are pending tasks, it will query AWS to get the instanceID of the available nodes
		(get-instanceID) and invoke AWS command start-EC2Instance (needing the instanceID for this).
		If there are idle nodes, it will invoke HPC Command Shutdown-HpcNode
	===========================================================================
	.PARAMETER Interval
		The interval in seconds between checks to shutdown compute nodes. Default = 300.
	.PARAMETER Idlecount
		Reserved for future functionality.
	.PARAMETER Logfile
		The log file for script actions. Every time the script is restarted, it will create or overwrite the file with given name.
		During runtime all records are added to the end of the file.
	.PARAMETER ETLtemplatename	 
		The name of the ETL template. Jobs submitted for this template are excluded from monitoring.
#>


[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$jobtype,
    [Parameter(Mandatory = $true, Position = 2)]
    [string]$CoresPerNode,	
	[Parameter(Mandatory = $false, Position = 3)]
	[string]$Interval = 300,
	[Parameter(Mandatory = $false, Position = 4)]
	[string]$idelecount = 2
)

Add-PSSnapIn Microsoft.HPC
Import-Module AWSPowerShell

Function Get-HPC-Metrics
{
	param (
		[string] $hpctemplatename,
		[string] $hpcgroupname
	)
	$When = Get-Date -Format F
    [string]$time = $When
    $time = $time + " LOCAL/PST"
	
	$jobs = Get-HpcJob -ErrorAction SilentlyContinue | ? { $_.template -eq $hpctemplatename }
	$queuedJobs = @($jobs | ? { $_.State -eq 'Queued' })
	$tasks = ($jobs | Get-HpcTask -State Running, Queued -ErrorAction SilentlyContinue)
	$queuedTasks = @($tasks | ? { $_.State -eq 'Queued' })
	$nodes = (Get-HpcNode -groupName $hpcgroupname -ErrorAction SilentlyContinue)
	$upnodes = (Get-HpcNode -groupName $hpcgroupname -Health OK -ErrorAction SilentlyContinue)
	$idleNodes = @();
	
	foreach ($node in $upnodes.NetBiosName)
	{
	  if ( $node.length -gt 10 -and $node.substring(5,6) -eq "QRMCOM")
      {
		$jobThisNode = (Get-HpcJob -NodeName $node -ErrorAction SilentlyContinue).Count;	
		if ($jobThisNode -eq 0)
		{			
			$idleNodes += $node	
		}
	  }
	}

	$coresPerMachine = ($nodes | Measure-Object -Property SubscribedCores -Average).Average
	
	return @{
		jobCount = $jobs.Count;
		queuedJobCount = $queuedJobs.Count;
		taskCount = $tasks.Count;
		queuedTaskCount = $queuedTasks.Count;
        nodes = $nodes.NetBiosName;
		nodeCount = $nodes.Count;
		coresPerMachine = $coresPerMachine;
        upnodes = $upnodes.NetBiosName;
        upnodeCount = $upnodes.Count;
		idlenodes = $idleNodes;
        idlenodeCount = $idleNodes.Count;
		time = $time
	}
	
}

Function Stop-HPC-ComputeNodes
{
	param (
		[string[]]$idleNodes,
		[string]$logfile
	)

	foreach ($node in $idleNodes)
	{
    	$jobThisNode = (Get-HpcJob -NodeName $node -ErrorAction SilentlyContinue).Count;	
		"node $node ... jobthisnode = $jobThisNode" | Out-file -Filepath $logfile -Append
		
		if ($jobThisNode -eq 0)
		{
            Write-Host "***POWEROFF***   $($(Get-Date).ToLocalTime()) Shutting down node $($node)"			
			"  ***POWEROFF***   $($(Get-Date).ToLocalTime()) Shutting down node $($node)" | Out-file -Filepath $logfile -Append
			Shutdown-HpcNode -Name $node -Confirm:$false			
		}
	}	
}

Function Start-AWS-ComputeNodes
{	
	param (
		[string]$hpcgroupname,
		[int]$queuedTasks,
		[int]$CoresPerNode,
		[string]$logfile
	)

	$nodes = (Get-HpcNode -groupName $hpcgroupname -ErrorAction SilentlyContinue)	
	$nodecount = [Math]::Ceiling($queuedTasks/$CoresPerNode)
	if ( $nodecount -gt $nodes.Count) { $nodecount = $nodes.Count }
	
	foreach ($node in $nodes.NetBiosName)
	{
	  if ( $node.length -gt 10 -and $node.substring(5,6) -eq "QRMCOM")
	  {	
        $InstID = (Get-EC2Tag -filter @{ Name="key";Values="Name" },@{ Name="value";Values="$($node)" }).ResourceID
		$instancestate = (Get-EC2Instance $($InstID)).Instances.State.Name 
        "$($(Get-Date).ToLocalTime()) $($node), Instance is $($InstID), State is $($instancestate.Value) and nodecount is $($nodecount)" | Out-File -FilePath $logfile -Append          

		If ($instancestate.Value -eq "stopped" -and $nodecount -gt 0)
		{
			"  ***STARTUP***   $($(Get-Date).ToLocalTime()) Starting node $($node), instanceID $($InstID)" | Out-File -FilePath $logfile -Append
			Start-EC2Instance $InstID
			$nodecount--
		}
	  }
	}
}

$allidlenodes = @()
$logfile = "C:\AWSQRMHPC\logs\" + $jobtype + ".log"
$logfilebck = "C:\AWSQRMHPC\logs\" + $jobtype + (get-date -format yyyyMMddhhmm) + "bkup.log"
$templatename = switch ($jobtype) { "incsim" {"QRM Default"} "FM" {"FM Job Template"} }
$nodegroup = switch ($jobtype) { "incsim" {"FRM Analytics"} "FM" {"FM "} }

if ([IO.file]::exists($logfile)) { rename-item $logfile $logfilebck }
"Script started at $($(Get-Date).ToLocalTime())" | Out-file -Filepath $logfile

while ($true)
{

	$ErrorActionPreference = "Continue"
	$HPCmetrics = Get-HPC-Metrics -hpctemplatename $templatename -hpcgroupname $nodegroup
	$HPCmetrics
	
	"***$($(Get-Date).ToLocalTime()) PST - Current HPC cluster State:" | Out-File -FilePath $logfile -Append
	$HPCmetrics | Out-file -FilePath $logfile -Append
	
	if ($HPCmetrics.queuedTaskCount -gt 0)
	{		
		Start-AWS-ComputeNodes -hpcgroupname $nodegroup -queuedTasks $HPCmetrics.queuedTaskCount -CoresPerNode $HPCmetrics.coresPerMachine -logfile $logfile		
	}	
	"*** Waiting for $($Interval) seconds ***" | Out-File -FilePath $logfile -Append
	
	Write-Host "***************$($(Get-Date).ToLocalTime())***************"
	Write-Host "*** Waiting for $($Interval) seconds ***"
	Write-Host "*******************************"
	
	Start-Sleep -Seconds $Interval
	
	if ($HPCMetrics.idlenodeCount -gt 0) 
    { 
        Stop-HPC-ComputeNodes -idleNodes $HPCmetrics.idlenodes -logfile $logfile 
    }
}
