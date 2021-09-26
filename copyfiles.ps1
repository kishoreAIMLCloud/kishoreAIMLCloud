#Import-Module -Name AWSPowerShell
import-module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"

set-DefaultAWSRegion us-west-2

$localPath = "E:\sql\" 
$BucketName="<FRM>"

# Should be "*.bak" or "*.trn"
#if ( $args[0] -eq "*.bak") { $backuptype = $args[0] } else { exit 1 }

# Go to base backup location
$location=Get-S3Object -BucketName $BucketName -KeyPrefix "sql-server-backups/" -region us-west-2


# Loop thru the subdirectories for each database
Foreach($object in $location) {

     if ($_.PSIsContainer) {

        # Set the prefix for the S3 key
        $eyPrefix = $object.key + $_.name
          $s3Keyname = $keyprefix +"/"

        # Switch to database subdirectory
        Set-Location $s3keyname;



   # Get the newest file in the list
      #  $backupName = Get-ChildItem $backuptype | Sort-Object -Property LastAccessTime | Select-Object -Last 1

 $backupName= get-s3object -bucketname "fhlbsf-qrm" -region us-west-2 -key $s3keyname | Sort-Object -LastModified -Descending | Select-Object -First 1 | select Key

        # Copy the file out to Amazon S3 storage       
Read-s3Object -BucketName "fhlbsf-qrm" -keyPrefix $s3keyname -Folder "d:\Temp" -region us-west-2
 
       # Go back to the base backup location
       Set-Location $s3keyname;
    }
  }