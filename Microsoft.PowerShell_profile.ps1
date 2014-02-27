$ProgressForegroundColor = 'Cyan'
$PromptForegroundColor = 'Yellow'
$PromptCwdForegroundColor = 'DarkGray'
$PromptTitleTemplate = [System.Console]::Title

<#
.SYNOPSIS

Run a batch file and capture the output environment.
#>
function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

<#
.SYNOPSIS

Is the current user running as administrator?
#>
function Is-Administrator() {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    
    $role = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $isAdministrator = $principal.IsInRole($role)

    $isAdministrator
}

<#
.SYNOPSIS

Set the environment for using Visual Studio tools. By default, this uses Visual Studio 2012.
#>
function VsVars32($version = "11.0") {
    $key = "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\" + $version
    if ( $(Test-Path $key) -eq $true ) {
        $VsKey = get-ItemProperty $key
        if ( $VsKey ) {
            $VsInstallPath = [System.IO.Path]::GetDirectoryName($VsKey.InstallDir)
            $VsToolsDir = [System.IO.Path]::GetDirectoryName($VsInstallPath)
            $VsToolsDir = [System.IO.Path]::Combine($VsToolsDir, "Tools")
            $BatchFile = [System.IO.Path]::Combine($VsToolsDir, "vsvars32.bat")
            Get-Batchfile $BatchFile
            Write-Host -ForegroundColor $ProgressForegroundColor "Setting environment for using Visual Studio $version tools."
        
            [System.Console]::Title = [System.Console]::Title + " - Visual Studio " + $version
        }
    }
}

function prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Put the path in the title, so that it appears in the task bar:
    [System.Console]::Title = "{0} - {1}" -f $PWD, $PromptTitleTemplate
    Update-ConsoleIcon

    # In case some app leaves it broken.
    [Console]::ResetColor()

    # Make .NET's current directory follow PowerShell's current directory, if possible.
    if ($PWD.Provider.Name -eq 'FileSystem') {
        [System.IO.Directory]::SetCurrentDirectory($PWD)
    }

    # Now for the actual prompt: working directory
    Write-Host $PWD -nonewline -foregroundcolor $PromptCwdForegroundColor

    # VCS (git, hg) status
    if (($PWD.Provider.Name -eq 'FileSystem') -and (Test-Path function:Write-VcsStatus)) {
        try {
            Write-VcsStatus
        } catch {
            # Ignore it.
        }
    }

    # Blank line
    Write-Host 
    Write-Host ">" -nonewline -foregroundcolor $PromptForegroundColor

    $LASTEXISTCODE = $realLASTEXITCODE
    
    # This is the actual prompt -- it's printed in the default console colours.
    return " "
}

$ProfilePath = Split-Path $PROFILE
$env:PATH += ";${env:USERPROFILE}\Bin"
$env:PATH += ";${env:USERPROFILE}\Bin\Scripts"
$env:PATH += ";$ProfilePath\Bin"
$env:PATH += ";$ProfilePath\Scripts"

# Console Colours
Add-Type -Path (Join-Path $ProfilePath "ConsoleColors.dll")

# Note: This assumes that you're using the default PowerShell background/foreground colour slots.
[ConsoleColors.ConsoleEx]::SetColor('DarkMagenta', 'Black')
[ConsoleColors.ConsoleEx]::SetColor('DarkYellow', 'Orange')

# Aside: gnome-terminal "Tango" colour scheme:
#
# Black: 0,0,0
# DarkRed: 204,0,0
# DarkGreen: 78,154,6
# DarkYellow: 196,160,0
# DarkBlue: 52,101,164
# DarkMagenta: 117,80,123
# DarkCyan: 6,152,154
# LightGray: 211,215,207
# DarkGray: 85,87,83
# LightRed: 239,41,41
# LightGreen: 138,226,52
# LightYellow: 252,233,79
# LightBlue: 134,179,227
# LightMagenta: 173,127,168
# LightCyan: 52,226,226
# White: 238,238,236
#
# Note that these don't map directly to the colour slots used by Windows, so that could be interesting.

$profile_modules = @(
        @{ Name = 'PsGet';
           OnSuccess = { $global:PsGetDestinationModulePath = $null };
           OnMissing = { Write-Warning "See http://psget.net/" }
        },
        @{ Name = 'Posh-Git';
           OnSuccess = {
             $global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Cyan
             $global:GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Cyan
             $global:GitPromptSettings.EnableWindowTitle = $null
           };
           OnMissing = {}
        },
        @{ Name = 'pscx';
           OnSuccess = { $Pscx:Preferences['CD_EchoNewLocation'] = $false };
           OnMissing = {}
        }
    )

$profile_modules | % {
    if (Get-Module -ListAvailable $_.Name) {
	Import-Module $_.Name -DisableNameChecking
        Write-Host -ForegroundColor $ProgressForegroundColor "Loaded $($_.Name)"
        & $_.OnSuccess
    } else {
        Write-Warning "Missing $($_.Name) module."
        & $_.OnMissing
    }
}

VsVars32

. "$ProfilePath\Icons\Set-ConsoleIcon.ps1"

$isAdministrator = Is-Administrator

if ($isAdministrator) {
    Write-Host -ForegroundColor $ProgressForegroundColor "Loading System Modules."
    ImportSystemModules
    [System.Console]::Title = [System.Console]::Title + " (System Modules)"
}

# Capture the current console title so that we can use it in "prompt", above.
$PromptTitleTemplate = [System.Console]::Title

function Update-ConsoleIcon
{
    if ($PromptTitleTemplate -like '*Administrator*Visual Studio 11.0*') {
        Set-ConsoleIcon "$ProfilePath\Icons\admin_vs11powershell.ico"
    }
    elseif ($PromptTitleTemplate -like '*Visual Studio 11.0*') {
        Set-ConsoleIcon "$ProfilePath\Icons\vs11powershell.ico"
    }
    elseif ($PromptTitleTemplate -like '*Administrator*') {
        Set-ConsoleIcon "$ProfilePath\Icons\admin_powershell.ico"
    }
}

# This removes the paging from 'help'. I prefer to scroll using the (gasp) scroll bar.
New-Alias -Force help Get-Help

# gvim alias
$gvim = Join-Path ${env:ProgramFiles(x86)} 'Vim\vim74\gvim.exe'
if ( !(Test-Path $gvim) ) {
  $gvim = Join-Path $env:ProgramFiles 'Vim\vim73\gvim.exe'
}
if ( Test-Path $gvim ) {
  New-Alias gvim $gvim
}

# Because.
Set-StrictMode -Version $PSVersionTable.PSVersion

# For Administrator logins, PoSh starts in C:\Windows\System32. Fix that.
Set-Location $HOME