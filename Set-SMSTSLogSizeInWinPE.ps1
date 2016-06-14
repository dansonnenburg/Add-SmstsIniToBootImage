# Increases smsts.log size to 5MB in WinPE
# Written by: Dan Sonnenburg

Function Set-SMSTSLogSizeInWinPE {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true)][string]$WinPEWim
    )
    $MountPoint = "${env:SystemDrive}\WinPEMount"

    Try {
        # Import the DISM module
        If (test-path -PathType Container "${env:ProgramFiles(x86)}\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"){
            import-module "${env:ProgramFiles(x86)}\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"
        } elseIf(test-path -PathType Container "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"){
            Import-Module "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"
        } else {
            Write-Warning "Aborting script. DISM not found."
            Break
        }
    } Catch {
    }
  
    Backup-Wim -WinPEWim $WinPEWim

    # Create temporary directories to mount image
    if (!(test-path -pathtype container $MountPoint)) {
        New-Item -ItemType Directory -Path $MountPoint
    }

    $inifile = New-SmstsIniFile

    # Mount WinPE image with DISM
    Mount-WindowsImage -ImagePath $WinPEWim -Index 1 -Path $MountPoint
    # Copy the smsts.ini file to the mounted image
    Copy-Item -Path $inifile -Destination "${MountPoint}\Windows" -Verbose
    # Commit changes and Dismount image
    Dismount-WindowsImage -Path $MountPoint -Save

    # Cleanup
    Remove-Item $MountPoint -Recurse
    Remove-Item $inifile
}

Function New-SmstsIniFile {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        $LogLevel = 0,
        $LogMaxSize = 5242880,
        $LogMaxHistory = 3,
        $DebugLogging = 1,
        $EnableLogging = 'True'
    )
    # Create temporary ini file
    $tempPath = [System.IO.Path]::GetTempPath()
    $inifile = join-path $tempPath smsts.ini
    try {
        If (Test-Path $inifile) {
            Remove-Item $inifile
        }
        New-Item -Name 'smsts.ini' -Path $tempPath -ItemType File
        $text = 
        "[Logging]
        LOGLEVEL=$LogLevel
        LOGMAXSIZE=$LogMaxSize
        LOGMAXHISTORY=$LogMaxHistory
        DEBUGLOGGING=$DebugLogging
        ENABLELOGGING=$EnableLogging" | out-file -FilePath $inifile
        return $inifile
    } catch {
        throw "error in process"
    }
}

Function Backup-Wim {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory = $true)][string]$WinPEWim
    )
    # Make a backup of the original boot images
    get-item $WinPEWim | Copy-Item -Destination "$WinPEWim.bak"
}