#Variables
$TaskName = "HPC Metrics"
$username ="SYSTEM"

#Create Scheduled Task
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "c:\Scripts\bin\Validate-FRM-HPC.ps1 c:\Scripts\log\Log-FRM-HPC-Validation.txt”
$Trigger = New-ScheduledTaskTrigger -AtStartup
$ScheduledTask = New-ScheduledTask -Action $action -Trigger $trigger 
 
Register-ScheduledTask -TaskName $TaskName -InputObject $ScheduledTask -User $username

Start-Sleep -s 180

Unregister-ScheduledTask -TaskName $TaskName

