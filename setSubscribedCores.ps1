<#	
	.NOTES
	===========================================================================
	 Created on:   	12/07/2016
	 Created by:   	Kishore Kesanapally
	 Purpose: 	Change the # of subscribed cores/threads on the compute nodes specified
	            in the input file 
	 usage: setSubscribedCores cores# filecontainingnodestochange
	===========================================================================
	.PARAMETER Cores = The SubscribedCores value to set to
	.PARAMETER HPCnodesFile = file containing The list of compute node server names
	                       (see MvarNodes.conf as an example)
#>

[CmdletBinding()]
param (
	[Parameter(Mandatory = $true, Position = 1)]
	[string]$Cores,
	[Parameter(Mandatory = $true, Position = 2)]
	[string]$HPCnodesFile
)

Add-PSSnapIn Microsoft.HPC
Import-Module AWSPowerShell

if (!($Nodelist = Get-Content -Path $HPCnodesFile -ErrorAction Stop))
{
	throw "Cannot open file $($HPCnodesFile)"
}

$ErrorActionPreference = "Continue"

foreach ($node in $Nodelist)
{
	set-HpcNodeState -Name $node -State Offline
	set-HpcNode -Name $node -SubscribedCores $Cores
	set-HpcNodeState -Name $node -State Online
}
