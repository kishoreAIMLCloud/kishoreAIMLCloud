# Get all server names from the saved txt file
# $servers = "<DBServername>";

$servers= get-content N:\AWS\servers.txt
 
# Loop through each server 
foreach ($server in $servers) {
 
    $out = $null;
 
    # Check if computer is online
    if (test-connection -computername $server -count 1 -ea 0) {
 
        try {
            # Define SQL instance registry keys
            $type = [Microsoft.Win32.RegistryHive]::LocalMachine;
            $regconnection = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $server) ;
            $instancekey = "SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL";
 
            try {
                # Open SQL instance registry key
                $openinstancekey = $regconnection.opensubkey($instancekey);
            }
            catch { $out = $server + ",No SQL registry keys found"; }
 
            # Get installed SQL instance names
            $instances = $openinstancekey.getvaluenames();
 
            # Loop through each instance found
            foreach ($instance in $instances) {
 
                # Define SQL setup registry keys
                $instancename = $openinstancekey.getvalue($instance);
                $instancesetupkey = "SOFTWARE\Microsoft\Microsoft SQL Server\" + $instancename + "\Setup"; 
 
                # Open SQL setup registry key
                $openinstancesetupkey = $regconnection.opensubkey($instancesetupkey);
 
                $edition = $openinstancesetupkey.getvalue("Edition")
 
                # Get version and convert to readable text
                $version = $openinstancesetupkey.getvalue("Version");
 
                switch -wildcard ($version) {
                    "12*" {$versionname = "SQL Server 2014";}
                    "11*" {$versionname = "SQL Server 2012";}
                    "10.5*" {$versionname = "SQL Server 2008 R2";}
                    "10.4*" {$versionname = "SQL Server 2008";}
                    "10.3*" {$versionname = "SQL Server 2008";}
                    "10.2*" {$versionname = "SQL Server 2008";}
                    "10.1*" {$versionname = "SQL Server 2008";}
                    "10.0*" {$versionname = "SQL Server 2008";}
                    "9*" {$versionname = "SQL Server 2005";}
                    "8*" {$versionname = "SQL Server 2000";}
                    default {$versionname = $version;}
                }
 
                # Output results 
                $out =  $server + "," + $instancename + "," + $edition + "," + $versionname; 
 
            }
 
        }
        catch { $out = $server + ",Could not open registry"; }       
 
    }
    else {
    $out = $server + ",Not online"
    }
 
    write-host "SQL Server $out is Installed" -Foregroundcolor Green;
}