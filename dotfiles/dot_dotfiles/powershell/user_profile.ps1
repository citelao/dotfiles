# Use this file to run your own startup commands
$startTime = Get-Date

function Log-Duration
{
    [CmdletBinding()]
    param(
        [string]
        $message
    )

    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Host "$($duration.TotalSeconds)s - $message" -Fore DarkGray
}

function Add-PathItem
{
    [CmdletBinding()]
    param(
        [string]
        $path
    )

    process {
        if (Test-Path $path) {
            $env:path += ";$path"
        } else {
            Write-Warning "Could not add '$path' to PATH"
        }
    }
}

Add-PathItem "C:\Program Files\nodejs"
Add-PathItem "C:\Program Files\git\bin"
Add-PathItem "$env:APPDATA\npm"
Add-PathItem "$env:ALLUSERSPROFILE\chocolatey\bin"

# Python UV
Add-PathItem "$env:USERPROFILE\.local\bin"

# Add-PathItem "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

$vcpkgPath = "$env:USERPROFILE\projects\vcpkg"
Add-PathItem $vcpkgPath
if (Test-Path $vcpkgPath) {
    $env:VCPKG_ROOT = $vcpkgPath
}

# vswhere.exe to find Visual Studio installations
Add-PathItem "C:\Program Files (x86)\Microsoft Visual Studio\Installer\"

Log-Duration "Path items added"

# Update path with our cmdlets
$cmdletsPath = Join-Path $PSScriptRoot "Cmdlets\"
$env:PsModulePath += ";$cmdletsPath"

# Let's not install modules in Documents anymore.
#
# https://github.com/PowerShell/PowerShell/issues/15552
# https://github.com/PowerShell/PSResourceGet/issues/1494
# https://devblogs.microsoft.com/powershell/powershell-openssh-and-dsc-team-investments-for-2025/#moving-powershell-content-folder-out-of-mydocuments
# https://github.com/PowerShell/PSResourceGet/issues/627

# Shim Install-Module to warn before use
function Install-Module {
    Write-Host "WARNING: Install-Module installs to Documents; try Save-Module instead? See `$env:BetterModulePath" -Fore Yellow
    Write-Host "Run this again to do it" -Fore DarkGray
}

# Set up a custom, non-OneDrive path for modules.
# Load it first.
$env:BetterModulePath = Join-Path $env:LOCALAPPDATA "PowerShell\Modules"
mkdir -Force $env:BetterModulePath | Out-Null
$env:PSModulePath = $env:BetterModulePath + ";" + $env:PSModulePath

Log-Duration "Updated module path"

# Set Git SSH to use native SSH
$native_ssh_path = "C:\Windows\System32\OpenSSH\ssh.exe"
if (Test-Path $native_ssh_path) {
    $env:GIT_SSH = $native_ssh_path
} else {
    Write-Warning "Could not find native SSH at $native_ssh_path"
}

Log-Duration "Git SSH set to native"

function Import-ModuleNicely
{
    [CmdletBinding()]
    param(
        $module
    )

    Log-Duration "Importing $module"
    $actualModule = Get-Module $module -ListAvailable
    Log-Duration "Found $($actualModule.Count) modules"
    if($actualModule) {
        $actualModule | Import-Module
    } else {
        Write-Warning "Please Install-Module/Package $module"
    }
}

# # Uncategorized scripts
# Import-ModuleNicely GeneriScripts

# # Quicker git commands
# Import-ModuleNicely BenGit

# # Colorize the prompt
# Import-ModuleNicely PSColor

# # Notifications!
# Import-ModuleNicely Notify

Log-Duration "Modules imported"

# Alias some commands
# Set-Alias -Name gh -Value get-help # conflict with GitHub CLI
Set-Alias vi nvim
Set-Alias l ls
Set-Alias open explorer
function which { get-command $args | select CommandType, Name, Definition, Version, Source }
Set-Alias s subl.exe
function pbcopy {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)]
        $item
    )

    $item | Set-Clipboard -AsHtml
}
Set-Alias pbpaste Get-Clipboard
Set-Alias code code-insiders.cmd
Set-Alias c code-insiders.cmd

function nod {
    New-Notification -title "Done!" -text "Command complete!"
}

function Set-Title {
    [CmdletBinding()]
    param(
        [string]
        $Title
    )
    $host.UI.RawUI.WindowTitle = $Title
}

function sln {
    [CmdletBinding()]
    param()

    $solution = @(Get-ChildItem -Filter *.sln -Recurse)
    if ($solution.Count -eq 1) {
        # Open the solution!
        . $solution[0].FullName
    } else {
        # List the solutions
        Write-Host "Multiple solutions found:"
        Write-Host ""
        $solution | ForEach-Object {
            Write-Output $_.FullName
        }
    }
}

<#
.SYNOPSIS
Get the installation path for the latest Visual Studio installation.
#>
function Get-VisualStudioPath {
    [CmdletBinding()]
    param()

    vswhere.exe -prerelease -latest -property installationPath
}

# Transform the current shell into a Visual Studio Developer Command Prompt
#
# https://learn.microsoft.com/en-us/visualstudio/install/tools-for-managing-visual-studio-instances?view=vs-2022
# https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170#use-the-developer-tools-in-an-existing-command-window
# https://github.com/microsoft/vswhere/wiki/Start-Developer-Command-Prompt
function Start-VisualStudioPrompt {
    [CmdletBinding()]
    param()

    Write-Host "Importing Visual Studio variables..." -ForegroundColor DarkGray
    $vsPath = Get-VisualStudioPath
    if (!$vsPath) {
        throw "Could not find Visual Studio installation"
    }

    $vsdevcmd = Join-Path $vsPath "Common7\Tools\vsdevcmd.bat"
    if (!(Test-Path $vsdevcmd)) {
        throw "Could not find vsdevcmd.bat at $vsdevcmd"
    }

    Write-Verbose "Sourcing vsdevcmd.bat at $vsdevcmd"
    & "${env:COMSPEC}" /s /c "`"$vsdevcmd`" -no_logo && set" | % {
        $name, $value = $_ -split '=', 2
        Write-Verbose "Setting env var:`r`n`t$name = $value"
        Set-Content env:\"$name" $value
    }
}
Set-Alias vsdev Start-VisualStudioPrompt

Log-Duration "Aliases set"

# Prompt customization
<#
.SYNTAX
    <PrePrompt><CMDER DEFAULT>
    <PostPrompt> <repl input>
.EXAMPLE
    <PrePrompt>N:\Documents\src\cmder [master]
    <PostPrompt> |
#>

<#
.SYNOPSIS
Get the root directory for a git repository, quickly.
.DESCRIPTION
This function returns the first parent directory of the starting directory
that is a git repo.

It returns false otherwise.
#>
function Get-GitRootQuick {
    param(
        # The directory to start with.
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        $dir
    )

    $potential_root = [System.IO.Path]::Combine($dir, ".git\")

    while($dir -and !(Test-Path $potential_root)) {
        $dir = Split-Path -Parent $dir
        $potential_root = [System.IO.Path]::Combine($dir, ".git\")
    }

    if(!($dir))
    {
        return $false
    }

    return $dir
}

<#
.SYNOPSIS
Determine whether or not a given directory is GVFS, quickly.
.DESCRIPTION
This function returns $true iff the current directory is in a
git repo that is a GVFS git repo.

It returns false for all other directories.
#>
function Get-IsGvfsQuick {
    param(
        # The directory to start with.
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        $dir
    )

    $root = Get-GitRootQuick $dir

    if(!($root))
    {
        return $false
    }

    $config = [System.IO.Path]::Combine($root, ".git\config")

    (cat $config | select-string "gvfs.+true").Count -gt 0
}

function Get-GitBranchQuick {
    if (-not (Test-Path function:\Get-GitRootQuick)) {
        return $null
    }

    $git_root = Get-GitRootQuick $PWD
    if($git_root) {
        if(Get-IsGvfsQuick $git_root) {
            # we are in an enlistment
            $branch = get-content "$git_root\.git\HEAD"
            if($branch.Contains("/")) {
                # this is def not a checksum, so use the full name
                $branch.Substring(16)
            } else {
                # for checksum, take just a couple chars
                $branch.Substring(16, 16)
            }
        } else {
            # Just an ordinary git repo.
            git rev-parse --abbrev-ref HEAD
        }
    } else {
        $null
    }
}

function Get-ExecutionTimeString {
    [CmdletBinding()]
    param(
        $elapsedTime
    )

    if ($lastCommandElapsedTime.TotalSeconds -gt 3)
    {
        $color = $host.PrivateData.WarningForegroundColor
        if ($lastCommandElapsedTime.TotalSeconds -gt 3600) # greater than one hour
        {
            return ("Took {0:#0}h {1:00}m {2:00}.{3:000}s." -f (($lastCommandElapsedTime.Days * 24) + $lastCommandElapsedTime.Hours), $lastCommandElapsedTime.Minutes, $lastCommandElapsedTime.Seconds, $lastCommandElapsedTime.Milliseconds)
        }
        elseif ($lastCommandElapsedTime.TotalSeconds -gt 60) # greater than one minute
        {
            return ("Took {0:#0}m {1:00}.{2:000}s." -f $lastCommandElapsedTime.Minutes, $lastCommandElapsedTime.Seconds, $lastCommandElapsedTime.Milliseconds)
        }
        else
        {
            return ("Took {0:#0}.{1:000}s." -f $lastCommandElapsedTime.Seconds, $lastCommandElapsedTime.Milliseconds)
        }
    }
}

# https://devblogs.microsoft.com/scripting/check-for-admin-credentials-in-a-powershell-script/
function Test-IsTerminalAdmin {
    [CmdletBinding()]
    param()

    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

function Test-IsRemote {
    [CmdletBinding()]
    param()

    return Test-Path env:SSH_CLIENT;
}

function Get-ArchitectureIcon
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [string]
        $architecture
    )

    if($architecture -like "amd64*") {
        return ""
    } elseif($architecture -like "x86*") {
        return "x86"
    } elseif($architecture -like "arm64*") {
        return "arm"
    } else {
        return $architecture
    }
}

Log-Duration "Prompt functions defined"

# I don't like verbose file info
[ScriptBlock]$PrePrompt = {
    # Print command time if it takes a long time:
    $historyItem = Get-History -Count 1
    if ($historyItem.Id -ne $env:_BESTO_LAST_COMMAND_ID) {
        $env:_BESTO_LAST_COMMAND_ID = $historyItem.Id
        $lastCommandElapsedTime = $historyItem.EndExecutionTime - $historyItem.StartExecutionTime
        $elapsedString = (Get-ExecutionTimeString $lastCommandElapsedTime)
        if($elapsedString) {
            Write-Host $elapsedString -ForegroundColor Yellow

            # Play a sound, too!
            (New-Object System.Media.SoundPlayer "$env:windir\Media\Windows Ding.wav").Play()
        }
    }

    # I always accidentally cd to the wrong repo in my Razzle prompts. Print a
    # warning if that's the case:
    if ($env:SDXROOT) {
        # Thanks Jadaw1n!
        # https://www.reddit.com/r/PowerShell/comments/333lxv/how_to_check_if_a_path_is_a_child_of_another/
        if (!($PWD.Path.ToLower().StartsWith($env:SDXROOT.ToLower()))) {
            Write-Host "[Out of Razzle] " -ForegroundColor Red -NoNewLine
        }
    }

    # https://osgwiki.com/wiki/Analog_GIT_Started
    if (Get-Command "git" -erroraction SilentlyContinue) {
        $currentBranch = Get-GitBranchQuick
        if (-not ($currentBranch -eq $null)) {
            Write-Host "[$currentBranch] " -ForegroundColor Yellow -NoNewLine
        }
    }

    if(Test-Path env:_BuildArch) {
        $arch_icon = Get-ArchitectureIcon $env:_BuildArch
        if(-not ($arch_icon -eq "")) {
            Write-Host "($arch_icon) " -NoNewLine -ForegroundColor Magenta
        }
    }
}

# Replace the cmder prompt entirely with this.
[ScriptBlock]$CmderPrompt = {
    $Host.UI.RawUI.ForegroundColor = "White"

    Microsoft.PowerShell.Utility\Write-Host $pwd.ProviderPath -NoNewLine -ForegroundColor Green
}

[ScriptBlock]$PostPrompt = {
}

Log-Duration "Preprompt set"

# Jump to locations with ZLocation!
# https://github.com/vors/ZLocation/issues/45#issuecomment-415935789
# https://github.com/vors/ZLocation#install
if (Get-Module ZLocation) {
    # https://github.com/vors/ZLocation/issues/78
    Write-Warning "Skipping re-import of ZLocation"
} else {
    try
    {
        Log-Duration "Importing ZLocation"
        Import-Module ZLocation -ArgumentList @{Register = $false}
        Log-Duration "ZLocation imported"
        # Set-Alias j Jump-Location
    }
    catch
    {
        Write-Warning "Please Install-Module/Package ZLocation"
    }
}

# if(Get-Module ZLocation -ListAvailable) {
# } else {
#     Write-Warning "Please Install-Module/Package ZLocation"
# }

Log-Duration "ZLocation loaded"

# Replace ConEmu/Cmder prompt, since it does annoying things.
# Stolen from ConEmu/Cmder
Set-Item -Path function:\prompt -Options None
[ScriptBlock]$Prompt = {
    $realLASTEXITCODE = $LASTEXITCODE
    PrePrompt | Microsoft.PowerShell.Utility\Write-Host -NoNewline
    CmderPrompt

    # Prompt indicator
    Microsoft.PowerShell.Utility\Write-Host "`n" -NoNewLine -ForegroundColor "DarkGray"
    if (![Environment]::Is64BitProcess) {
        Microsoft.PowerShell.Utility\Write-Host "μ" -NoNewLine -ForegroundColor "DarkGray"
    }

    if (Test-IsRemote) {
        Microsoft.PowerShell.Utility\Write-Host "✈ " -NoNewLine -ForegroundColor "DarkGray"
    }

    if (Test-IsTerminalAdmin) {
        Microsoft.PowerShell.Utility\Write-Host "λ" -NoNewLine -ForegroundColor "DarkGray"
    } else {
        Microsoft.PowerShell.Utility\Write-Host ">" -NoNewLine -ForegroundColor "DarkGray"
    }

    PostPrompt | Microsoft.PowerShell.Utility\Write-Host -NoNewline

    if(Get-Command Update-ZLocation -ErrorAction SilentlyContinue)
    {
        Update-ZLocation $pwd
    }

    $global:LASTEXITCODE = $realLASTEXITCODE
    return " "
}

Log-Duration "Prompt set"

# Put it back in!
Set-Item -Path function:\prompt -Value $Prompt #-Options ReadOnly

# If no Cmder:
if (-not (Test-Path function:\CmderPrompt)) {
    Set-Item -Path function:\PrePrompt -Value $PrePrompt #-Options ReadOnly
    Set-Item -Path function:\CmderPrompt -Value $CmderPrompt #-Options ReadOnly
    Set-Item -Path function:\PostPrompt -Value $PostPrompt #-Options ReadOnly
}

Log-Duration "Prompt attached"

# Set the developer directory:
# $env:PSRazzleDir = "D:\Config\Razzle"

# # Trash things
# # https://stackoverflow.com/questions/502002/how-do-i-move-a-file-to-the-recycle-bin-using-powershell/502004
# if(Get-Module Recycle -ListAvailable) {
#     Import-Module Recycle
#     Set-Alias trash Remove-ItemSafely
# } else {
#     Write-Warning "Please Install-Module/Package Recycle"
# }

# Log-Duration "Trash module loaded"

# Make IXPTools load more informative
$env:IXPTOOLS_PRINT_MODULE_START = $true

# Improve history
$MaximumHistoryCount = 3000

# Hotkeys!
Set-PSReadlineKeyHandler -key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -key DownArrow -Function HistorySearchForward

# FZF
# Remember to install FZF!
$env:FZF_DEFAULT_OPTS='--height 40% --layout=reverse --inline-info --preview "pwsh.exe -noprofile -c `get-content {}"'

# UV autocomplete
if (Get-Command uv -EA Ignore)
{
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
    (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
}

# Excerpted (partly) from https://github.com/kelleyma49/PSFzf/blob/master/PSFzf.psm1
function Invoke-FzfPsReadlineHandlerSetLocation {
    $result = $null
    try
    {
        fzf | ForEach-Object { $result = $_ }
    }
    catch
    {
        # catch custom exception
    }
    if (-not [string]::IsNullOrEmpty($result)) {
        Set-Location $result
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

Set-PSReadlineKeyHandler -key 'Ctrl+t' -ScriptBlock { Write-Host "foo "}

Log-Duration "FZF loaded"