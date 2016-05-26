# Change logging size during WinPE phase of task sequences
# Written by: Dan Sonnenburg

# Setup the variables
$smstsini = "\\server\path\smsts.ini"
$ParentDir = "C:\WinPEMount"
$X86Dir = "C:\WinPEMount\X86"
$X64Dir = "C:\WinPEMount\X64"
$X86WIM = "\\server\Source\Boot\WinPE50x86\winpe.wim"
$X64WIM = "\\server\configmgr\Source\Boot\WinPE50x64\winpe.wim"
$DismDir = "C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"
$Dism10Dir = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"

# Import the DISM module
if (test-path -pathtype container $Dism10Dir) {
    import-module $Dism10Dir -Verbose
} elseif (test-path -pathtype container $DismDir) {
    import-module $DismDir -Verbose
} else {
    Write-Warning "Aborting script...DISM not found."
    Break
}

# Make a backup of the original boot images
get-item $X86WIM | Copy-Item -Destination "$X86WIM.bak"
get-item $X64WIM | Copy-Item -Destination "$X64WIM.bak"

# Create temporary directories to mount image

if ( ! (test-path -pathtype container C$X86Dir)) {
    New-Item -ItemType Directory -Path $X86Dir
}
if ( ! (test-path -pathtype container $X64Dir)) {
    New-Item -ItemType Directory -Path $X64Dir
}

# Do some work on the X86 WinPE image

# Mount X86 WinPE image with DISM
Mount-WindowsImage -ImagePath $X86WIM -Index 1 -Path $X86Dir
# Copy the smsts.ini file to the mounted image
Copy-Item -Path $smstsini -Destination "$X86Dir\Windows" -Verbose
# Commit changes and Dismount image
Dismount-WindowsImage -Path $X86Dir -Save

# Do some work on the X64 WinPE image

# Mount X64 WinPE image with DISM
Mount-WindowsImage -ImagePath $X64WIM -Index 1 -Path $X64Dir
# Copy the smsts.ini file to the mounted image
Copy-Item -Path $smstsini -Destination "$X64Dir\Windows" -Verbose
# Commit changes and Dismount image
Dismount-WindowsImage -Path $X64Dir -Save

# Cleanup
Remove-Item $ParentDir -Recurse