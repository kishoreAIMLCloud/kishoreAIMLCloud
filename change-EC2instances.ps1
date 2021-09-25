<#	
	.NOTES
	===========================================================================
	 Created on:   	12/22/2016
	 Created by:   	Kishore Kesanapally
	 Filename:  change-EC2instances.ps1
	 Warning:	This script wiil change AWS EC2 instance types
	===========================================================================
	*** to run this, you must have the appropriate IAM account with elevated rights
	*** store this credentials on this server while logged on as yourself. to store:
	    open AWS PowerShell and run:
		Set-AWSCredentials -AccessKey YOURACCESSKEY -SecretKey YOURSECRETKEY -StoreAs YOURCREDNAME
	    then use that stored credentials as follows:
		Set-AWSCredentials -StoredCredentials YOURCREDNAME
	===========================================================================
	.PARAMETER newEC2type
		The EC2 type to convert the AWS nodes to
	.PARAMETER HPCnodesFile
		The list of HPC nodes (NetBIOS names). Each node name must be placed on its own line. 
                These are the compute node names for the QRM HPC cluster
	example:
        Site Specific settings are the active ones.
		[string]$newEC2type = "m4.xlarge",
		[string]$HPCnodesFile = "C:\AWS\HPCnodes.conf"
#>

[CmdletBinding()]
param (
	
	# Interval in seconds between HPC checks
	
	[Parameter(Mandatory = $false, Position = 1)]
	[string]$newEC2type = "r4.xlarge",
	[Parameter(Mandatory = $false, Position = 2)]
	[string]$HPCnodesFile = "C:\AWSFRMHPC\HPCnodes.conf"
)



Add-PSSnapIn Microsoft.HPC
Import-Module AWSPowerShell

	
	if (!($HPCNodeIDs = Get-Content -Path $HPCnodesFile -ErrorAction Stop))
	{
		
		"Cannot open file $($HPCnodesFile)"
		throw "Cannot open file $($HPCnodesFile)"
		
	}
	
	
	foreach ($nodeID in $HPCNodeIDs)
	{
		
        "NodeID is $nodeID"
        
        $InstID = (Get-EC2Tag -filter @{ Name="key";Values="Name" },@{ Name="value";Values="$($nodeID)" }).ResourceID

        "$($(Get-Date).ToUniversalTime()) The node  $($nodeID) instanceID is $InstID"   
        
        $InstState = (Get-EC2Instance $($InstID)).Instances.State.Name    
        $InstType = (Get-EC2InstanceAttribute -InstanceID $($InstID) -Attribute InstanceType).InstanceType
                
        "The instance $InstID is of type $InstType, current state is $InstState" 
        ".. changing to $NewEC2Type ..."
        Edit-EC2InstanceAttribute -InstanceID $($InstID) -InstanceType $newEC2type

        $NewInstType = (Get-EC2InstanceAttribute -InstanceID $($InstID) -Attribute InstanceType).InstanceType
                
        "The instance $InstID is now of type $NewInstType, current state is $InstState" 

	}
