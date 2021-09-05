[CmdletBinding()]
param(
    [switch]$help,
    # [switch]$list,
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

    $ApplicationsObj | Sort-Object DisplayName | Format-Table -Property @{L = "Name"; E = { $_.DisplayName } }, @{L = "ID"; E = { $_.PSChildName } }, @{L = "Version"; E = { $_.DisplayVersion } }, @{L = "ustring"; E = { $_.UninstallString } }
}

Function Get-Application {
    ForEach ($App in $Applicationsobj) {
        If ($App.PsChildName -eq $id) {
            Return $App
        }
    }
}

Function Get-UninstallStatus() {
    $AllUsersAppUninstall = Get-ItemProperty $AllUsersAppsPaths | Where-object { $_.PSChildName -match $id }
    Return $AllUsersAppUninstall
}

Function Get-UninstallProcess {
    start-sleep 1
                    
    $procsWithParent = Get-WmiObject -ClassName "win32_process" | Select-Object ProcessId, ParentProcessId
    $orphaned = $procsWithParent | Where-Object -Property ParentProcessId -NotIn $procsWithParent.ProcessId
    # $UninstallProcesses = Get-Process | Where-Object -Property Id -In $orphaned.ProcessId
    $nowtime = get-date
    $p = ForEach ($Process in Get-Process | Where-Object -Property Id -In $orphaned.ProcessId) {
        If (($nowtime - $Process.StartTime).totalSeconds -le 5) {
            $Process.ID
        }
    }

    Do {
        $UninstallTest = Get-UninstallStatus
        
        If ($p) {
            $UninstallProcess = Get-Process -Id $p
            

        }
        Else {
            $UninstallProcess = Get-Process -Id $proc.Id
            
        }

    }Until(!$UninstallProcess -Or !$UninstallTest)
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

            Get-UninstallProcess
            Start-Sleep 3
            $Uninstalled = Get-UninstallStatus
            If ($Uninstalled) {
                If ($proc.ExitCode) {
                    Write-Warning "$($App.DisplayName) was not uninstalled, exited with error code $($proc.ExitCode)."
                    Write-Output "`r"
                    # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'                    
                }
                Else {
                    Write-Warning "$($App.DisplayName) was not uninstalled, no error code was provided."
                    Write-Output "`r"
                    # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue' 
                }
            
            }
            Else {
                Write-Output "$($App.DisplayName) was uninstalled successfully."
                Write-Output "`r"
                # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'
            
            }
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
                Write-Output "quotes no args"
                $proc = Start-Process -FilePath $Path -ArgumentList $($SilentUninstallArguments) -PassThru
                Wait-Process -InputObject $proc

                Get-UninstallProcess
                Start-Sleep 3
                $Uninstalled = Get-UninstallStatus
                If ($Uninstalled) {
                    If ($proc.ExitCode) {
                        Write-Warning "$($App.DisplayName) was not uninstalled, exited with error code $($proc.ExitCode)."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'                    
                    }
                    Else {
                        Write-Warning "$($App.DisplayName) was not uninstalled, no error code was provided."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue' 
                    }
                
                }
                Else {
                    Write-Output "$($App.DisplayName) was uninstalled successfully."
                    Write-Output "`r"
                    # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'
                
                }
            }
            ElseIf ($UninstallString -Match '"' -And $Arguments) {
                write-output "quotes args"
                $proc = Start-Process -Filepath $Path -ArgumentList $Arguments -PassThru
                Wait-Process -InputObject $proc

                Get-UninstallProcess
                Start-Sleep 3
                $Uninstalled = Get-UninstallStatus
                If ($Uninstalled) {
                    If ($proc.ExitCode) {
                        Write-Warning "$($App.DisplayName) was not uninstalled, exited with error code $($proc.ExitCode)."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'                    
                    }
                    Else {
                        Write-Warning "$($App.DisplayName) was not uninstalled, no error code was provided."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue' 
                    }
                
                }
                Else {
                    Write-Output "$($App.DisplayName) was uninstalled successfully."
                    Write-Output "`r"
                    # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'
                
                }
            }
            ElseIf ($uninstallString -NotMatch '"' -And $Arguments) {
                Write-Output "no quotes args"

                $proc = Start-Process -Filepath $Path -PassThru
                Wait-Process -InputObject $proc

                Get-UninstallProcess
                Start-Sleep 3
                $Uninstalled = Get-UninstallStatus
                If ($Uninstalled) {
                    If ($proc.ExitCode) {
                        Write-Warning "$($App.DisplayName) was not uninstalled, exited with error code $($proc.ExitCode)."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'                    
                    }
                    Else {
                        Write-Warning "$($App.DisplayName) was not uninstalled, no error code was provided."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue' 
                    }
                
                }
                Else {
                    Write-Output "$($App.DisplayName) was uninstalled successfully."
                    Write-Output "`r"
                    # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'
                
                }
                
            
            }
            ElseIf ($uninstallString -NotMatch '"' -And !$Arguments) {
                
                Write-Output "no quotes no args"
                $proc = Start-Process -Filepath $UninstallString -ArgumentList $($SilentUninstallArguments) -PassThru
                Wait-Process -InputObject $proc

                Get-UninstallProcess
                Start-Sleep 3
                $Uninstalled = Get-UninstallStatus
                If ($Uninstalled) {
                    If ($proc.ExitCode) {
                        Write-Warning "$($App.DisplayName) was not uninstalled, exited with error code $($proc.ExitCode)."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'                    
                    }
                    Else {
                        Write-Warning "$($App.DisplayName) was not uninstalled, no error code was provided."
                        Write-Output "`r"
                        # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue' 
                    }
                
                }
                Else {
                    Write-Output "$($App.DisplayName) was uninstalled successfully."
                    Write-Output "`r"
                    # Stop-Process -Name $proc.ProcessName -Force -ErrorAction 'SilentlyContinue'
                
                }
            }
        }

    }
    Else {

        Write-Output "App doesn't exist."
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
