<#	
	.NOTES
	===========================================================================
	 Created on:   	01/23/2017
	 Created by:   	Kishore Kesanapally 
	 Purpose: 	see below
	===========================================================================
	
    When a new server is built, it needs to be:
    - joined to the domain
    - applied a node template
    - online the node
    - assign to a job group

    This script assumes the nodes are already joined to the domain 
    so it will : 
    - apply the "Default ComputeNode Template"
    - set node state to "Online"
    - add the node to the " FRM Analytics" group
    - shut it down (so we can apply set-subscribedcores)
	===========================================================================
	.PARAMETER TemplateName
		Job Template Name, the default os "Default ComputeNode Template"
	.PARAMETER Cores
		The SubscribedCores value to set to, default is 16
#>

[CmdletBinding()]
param (
	
	# Interval in seconds between HPC checks
	
	[Parameter(Mandatory = $false, Position = 1)]
	[string]$TemplateName = "Default ComputeNode Template",
	[Parameter(Mandatory = $false, Position = 2)]
	[string]$GroupName = "FRM Analytics"
)


Add-PSSnapIn Microsoft.HPC
Import-Module AWSPowerShell

$Nodelist = Get-HpcNode -state Unknown

$ErrorActionPreference = "Continue"

foreach ($node in $Nodelist)
{
	Assign-HpcNodeTemplate -Node $node -Name $TemplateName -Confirm:$False
    set-HPCNodeState -Node $node -State online
    Add-HPCGroup -Node $node -Name $GroupName
    $InstID = (Get-EC2Tag -filter @{ Name="key";Values="Name" },@{ Name="value";Values="$($node)" }).ResourceID
    Stop-EC2Instance -InstanceID $InstID
    $InstType = (Get-EC2InstanceAttribute -instanceID $InstID -Attribute InstanceType).InstanceType
    if ( $InstType -in ("m3.large","m4.large","r3.large","r4.large","c3.large","c4.large")
    {
        set-HpcNodeState -Name $node -State Offline
	    set-HpcNode -Name $node -SubscribedCores 2
	    set-HpcNodeState -Name $node -State Online
    }
    if ( $InstType -in ("m3.xlarge","m4.xlarge","r3.xlarge","r4.xlarge","c3.xlarge","c4.xlarge")
    {
        set-HpcNodeState -Name $node -State Offline
	    set-HpcNode -Name $node -SubscribedCores 4
	    set-HpcNodeState -Name $node -State Online
    }
}
