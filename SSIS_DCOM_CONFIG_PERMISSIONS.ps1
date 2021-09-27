$user = "DBADMIN"
$domain = "FHLBSF"
$appdesc = "Microsoft SQL Server Integration Services 11.0"
$app = get-wmiobject -query ('SELECT * FROM Win32_DCOMApplicationSetting WHERE Description = "' + $appdesc + '"') -enableallprivileges
#$appid = "{83B33982-693D-4824-B42E-7196AE61BB05}"
#$app = get-wmiobject -query ('SELECT * FROM Win32_DCOMApplicationSetting WHERE AppId = "' + $appid + '"') -enableallprivileges
$sdRes = $app.GetLaunchSecurityDescriptor()
$sd = $sdRes.Descriptor
$trustee = ([wmiclass] 'Win32_Trustee').CreateInstance()
$trustee.Domain = $domain
$trustee.Name = $user
$fullControl = 31
$localLaunchActivate = 11
$ace = ([wmiclass] 'Win32_ACE').CreateInstance()
$ace.AccessMask = $localLaunchActivate
$ace.AceFlags = 0
$ace.AceType = 0
$ace.Trustee = $trustee
[System.Management.ManagementBaseObject[]] $newDACL = $sd.DACL + @($ace)
$sd.DACL = $newDACL
$app.SetLaunchSecurityDescriptor($sd)