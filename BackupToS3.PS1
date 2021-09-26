#
# SQL Server Backup to S3
#
# Get the AWS Stuff
#Import-Module -Name AWSPowerShell
import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

set-DefaultAWSRegion us-west-2

# Should be "*.bak" or "*.trn"
if ( $args[0] -eq "*.bak") { $backuptype = $args[0] } else { exit 1 }

# Go to base backup location
Set-Location E:\FRM_Backup

# Loop thru the subdirectories for each database
Get-ChildItem | Foreach-Object {
     if ($_.PSIsContainer) {

        # Set the prefix for the S3 key
        $keyPrefix = "sql-server-backups/" + $_.name

        # Switch to database subdirectory
        Set-Location $_.name;

   # Get the newest file in the list
        $backupName = Get-ChildItem $backuptype | Sort-Object -Property LastAccessTime | Select-Object -Last 1
       $s3Keyname = $keyPrefix + "/" + $backupName.Name

 # Copy the file out to Amazon S3 storage
        Write-S3Object -Bucketname "fhlbsf-qrm" -key $s3keyname -File $backupName 

        # Go back to the base backup location
        Set-Location E:\QRM_Backup
    }
  }