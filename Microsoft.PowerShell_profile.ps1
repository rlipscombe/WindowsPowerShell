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
    	Write-VcsStatus
    }

    # Blank line
    Write-Host 
    Write-Host ">" -nonewline -foregroundcolor $PromptForegroundColor

    $LASTEXISTCODE = $realLASTEXITCODE
    
    # This is the actual prompt -- it's printed in the default console colours.
    return " "
}

$profile_modules = @(
        @{ Name = 'PsGet';
           OnSuccess = { $global:PsGetDestinationModulePath = $null };
           OnMissing = { Write-Warning "See http://psget.net/" }
        },
        @{ Name = 'Posh-Hg';
           OnSuccess = { $global:HgPromptSettings.ModifiedForegroundColor = [ConsoleColor]::Cyan };
           OnMissing = {}
        },
        @{ Name = 'Posh-Git';
           OnSuccess = {
             $global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Cyan
             $global:GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Cyan
           };
           OnMissing = {}
        },
        @{ Name = 'psake';
           OnSuccess = { New-Alias -Force psake Invoke-psake };
           OnMissing = {}
        },
        @{ Name = 'pscx';
           OnSuccess = { $Pscx:Preferences['CD_EchoNewLocation'] = $false };
           OnMissing = {}
        },
        @{ Name = 'psbits';
           OnSuccess = {};
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

# TODO: Put this in psbits.
function Download-String([string]$url)
{
    $web = New-Object System.Net.WebClient
    $web.DownloadString($url)
}

New-Alias wget Download-String

$ProfilePath = Split-Path $PROFILE
$env:PATH += ";${env:USERPROFILE}\Bin"
$env:PATH += ";${env:USERPROFILE}\Bin\Scripts"
$env:PATH += ";$ProfilePath\Bin"
$env:PATH += ";$ProfilePath\Scripts"
VsVars32

$isAdministrator = Is-Administrator

if ($isAdministrator) {
    Write-Host -ForegroundColor $ProgressForegroundColor "Loading System Modules."
    ImportSystemModules
    [System.Console]::Title = [System.Console]::Title + " (System Modules)"
}

# Capture the current console title so that we can use it in "prompt", above.
$PromptTitleTemplate = [System.Console]::Title

# This removes the paging from 'help'. I prefer to scroll using the (gasp) scroll bar.
New-Alias -Force help Get-Help

$gvim = Join-Path ${env:ProgramFiles(x86)} 'Vim\vim73\gvim.exe'
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
