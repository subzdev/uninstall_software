<#
.Synopsis
Allows listing, finding and uninstalling most software on Windows. There will be a best effort to uninstall silently if there is no silent uninstall string provided.
  
.DESCRIPTION
Allows listing, finding and uninstalling most software on Windows. There will be a best effort to uninstall silently if there is no silent uninstall string provided.

.INPUTS
The following script arguments are available:
         -help                   What you are reading now
         -id                     Filter installed software by ID
         -uninstall              Uninstall a specific software based on ID
Examples:
         -id '{0D34D278-5FAF-4159-A4A0-4E2D2C08139D}_is1'
         -id '{0D34D278-5FAF-4159-A4A0-4E2D2C08139D}_is1' -uninstall
         
  .NOTES
  See https://github.com/subzdev/uninstall_software/blob/main/uninstall_software.ps1 . If you have extra additions please feel free to contribute and create PR
  v3.0 - 9/5/2021
#>

[CmdletBinding()]
param(
    [switch]$help,
    [string]$id,
    [switch]$uninstall,
    [switch]$force
)
# $ErrorActionPreference = 'silentlycontinue'
$UsernameObj = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object username).username -Split "\\"
$Username = $UsernameObj[1]
$SID = (Get-WmiObject -Class Win32_UserAccount -Filter "Domain = '$env:userdomain' AND Name = '$Username'").SID

$UserAppsPath = Get-ItemProperty Registry::\HKEY_USERS\$SID\software\microsoft\windows\currentversion\uninstall\*
$AllUsersAppsPaths = @("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*")
$ApplicationsObj = New-Object System.Collections.ArrayList

Function Get-Applications {
    ForEach ($App in $UserAppsPath) {
        
        $ApplicationsObj.Add($App) | Out-Null
    }

    ForEach ($App in Get-ItemProperty $AllUsersAppsPaths) {
        If (!$App.SystemComponent -And $App.UninstallString) {
            
            $ApplicationsObj.Add($App) | Out-Null
        }
    }

    $ApplicationsObj | Sort-Object DisplayName | Format-Table -Property @{L = "Name"; E = { $_.DisplayName } }, @{L = "ID"; E = { $_.PSChildName } }, @{L = "Version"; E = { $_.DisplayVersion } }
}

Function Get-Application {
    ForEach ($App in $Applicationsobj) {
        If ($App.PsChildName -eq $id) {
            Return $App
        }
    }
}

Function Get-UninstallStatus ($App) {
    Start-Sleep 1
                    
    $procsWithParent = Get-WmiObject -ClassName "win32_process" | Select-Object ProcessId, ParentProcessId
    $orphaned = $procsWithParent | Where-Object -Property ParentProcessId -NotIn $procsWithParent.ProcessId
    $nowtime = get-date
    $p = ForEach ($Process in Get-Process | Where-Object -Property Id -In $orphaned.ProcessId) {
        If (($nowtime - $Process.StartTime).totalSeconds -le 5) {
            $Process.ID

        }
    }

    Do {
        If ($p) {
            $UninstallProcess = Get-Process -Id $p
            $AllUsersAppUninstall = Get-ItemProperty $AllUsersAppsPaths | Where-object { $_.PSChildName -match $id }

        }
        Else {
            $UninstallProcess = Get-Process -Id $proc.Id
            $AllUsersAppUninstall = Get-ItemProperty $AllUsersAppsPaths | Where-object { $_.PSChildName -match $id }

        }

    }Until(!$UninstallProcess -Or !$UninstallTest)
    
    If ($AllUsersAppUninstall) {
        If ($proc.ExitCode) {
            Write-Warning "$($App.DisplayName) was not uninstalled, exited with error code $($proc.ExitCode)."
            Write-Output "`r"

        }
        Else {
            Write-Warning "$($App.DisplayName) was not uninstalled, no error code was provided."
            Write-Output "`r"

        }
    }
    Else {
        Write-Output "$($App.DisplayName) was uninstalled successfully."
        Write-Output "`r"
    
    }
}

Function Uninstall-Application($App, $UninstallString) {
    If ($App) {
        $SilentUninstallArguments = "/S /SILENT /VERYSILENT /NORESTART"
        Write-Output "Found $($App.DisplayName) [$($App.PSChildName)]"
        Write-Output "Attempting best effort silent uninstall..."
        Write-Output "`r"

        If ($App.WindowsInstaller) {
            $MsiArguments = $UninstallString -Replace "MsiExec.exe /I", "/X" -Replace "MsiExec.exe ", ""

            $proc = Start-Process -FilePath msiexec -ArgumentList "$MsiArguments /quiet" -PassThru
            Wait-Process -InputObject $proc
            Start-Sleep 3
            Get-UninstallStatus $App

        }

        If (!$App.WindowsInstaller) {
            If ($UninstallString -Match '"') {
                $UninstallStringObj = $UninstallString -Split ('"')
                $Path = $UninstallStringObj[1].Trim()
                $ArgumentsObj = for ($i = 2; $i -le $UninstallStringObj.Count - 1; $i++) { $UninstallStringObj[$i] }
                $Arguments = $ArgumentsObj.Trim()

            }
            ElseIf ($UninstallString -NotMatch '"') {
                $UninstallStringObj = $UninstallString.IndexOf("/")
                If ($UninstallStringObj -eq -1) {
                    $Path = $UninstallString

                }
                Else {
                    $Path = $UninstallString.Substring(0, $UninstallStringObj)
                    $ArgumentsObj = $UninstallString.Substring($UninstallStringObj + 1)
                    $Arguments = "/" + $ArgumentsObj

                }
            }

            If ($UninstallString -Match '"' -And !$Arguments) {
                $proc = Start-Process -FilePath $Path -ArgumentList $($SilentUninstallArguments) -PassThru
                Wait-Process -InputObject $proc
                Start-Sleep 3
                Get-UninstallStatus $App

            }
            ElseIf ($UninstallString -Match '"' -And $Arguments) {
                $proc = Start-Process -Filepath $Path -ArgumentList $Arguments -PassThru
                Wait-Process -InputObject $proc
                Start-Sleep 3
                Get-UninstallStatus $App

            }
            ElseIf ($uninstallString -NotMatch '"' -And $Arguments) {
                $proc = Start-Process -Filepath $Path -PassThru
                Wait-Process -InputObject $proc
                Start-Sleep 3
                Get-UninstallStatus $App
                
            }
            ElseIf ($uninstallString -NotMatch '"' -And !$Arguments) {
                $proc = Start-Process -Filepath $UninstallString -ArgumentList $($SilentUninstallArguments) -PassThru
                Wait-Process -InputObject $proc
                Start-Sleep 3
                Get-UninstallStatus $App
            }
        }

    }
    Else {
        Write-Output "`r"
        Write-Output "The application associated with the specified ID is not installed on $env:computername."
        Write-Output "`r"
    }

}

If (!$id -And !$uninstall -And !$force) {
    
    $Apps = Get-Applications
    Write-Output "$(($ApplicationsObj | Measure-Object).Count) results"
    $Apps

}
If ($id -And !$uninstall -And !$force) {
    Get-Applications | Out-Null
    $App = Get-Application
    $App | Sort-Object DisplayName | Format-List -Property @{L = "Name"; E = { $_.DisplayName } }, @{L = "ID"; E = { $_.PSChildName } }, @{L = "Version"; E = { $_.DisplayVersion } }, @{L = "UninstallString"; E = { If ($_.QuietUninstallString) { $_.QuietUninstallString } Else { $_.UninstallString } } }

}
If ($id -And $uninstall -And !$force) {
    Get-Applications | Out-Null
    $App = Get-Application
    $UninstallString = If ($App.QuietUninstallString) { $App.QuietUninstallString } Else { $App.UninstallString }
    Uninstall-Application $App $UninstallString

}
If ($help -And !$id -And !$uninstall -And !$force) {
    Write-Output "`r"
    Write-Output "The following script arguments are available:"
    Write-Output "`t -help `t `t `t What you are reading now"
    Write-Output "`t -id `t `t `t Filter installed software by ID"
    Write-Output "`t -id -uninstall `t Uninstall a specific software based on ID"
    Write-Output "`r"
    Write-Output "Examples:"
    Write-Output "`t -id '{0D34D278-5FAF-4159-A4A0-4E2D2C08139D}_is1'"
    Write-Output "`t -uninstall -id '{0D34D278-5FAF-4159-A4A0-4E2D2C08139D}_is1'"
    Write-Output "`r"
    Write-Output "`r"
}
