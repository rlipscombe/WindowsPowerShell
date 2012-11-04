$ProgressForegroundColor = 'Cyan'
$PromptForegroundColor = 'Yellow'

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

Set the environment for using Visual Studio tools. By default, this uses Visual Studio 2010.
#>
function VsVars32($version = "10.0") {
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

    # In case some app leaves it broken.
    [Console]::ResetColor()

    # Make .NET's current directory follow PowerShell's current directory, if possible.
    if ($PWD.Provider.Name -eq 'FileSystem') {
        [System.IO.Directory]::SetCurrentDirectory($(Get-Location))
    }

    # Now for the actual prompt.
    Write-Host($PWD) -nonewline -foregroundcolor $PromptForegroundColor

    if (($PWD.Provider.Name -eq 'FileSystem') -and (Test-Path function:Write-VcsStatus)) {
    	Write-VcsStatus
    }

    Write-Host(">") -nonewline -foregroundcolor $PromptForegroundColor

    $LASTEXISTCODE = $realLASTEXITCODE
    return " "
}

$modules = @(
        @{ Name = 'PsGet'; OnSuccess = {}; OnMissing = { Write-Warning "See http://psget.net/" } },
        @{ Name = 'Posh-Hg'; OnSuccess = { $global:HgPromptSettings.ModifiedForegroundColor = [ConsoleColor]::Cyan }; OnMissing = {} },
        @{ Name = 'Posh-Git'; OnSuccess = {
            $global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Cyan
            $global:GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Cyan
            }; OnMissing = {  } },
        @{ Name = 'psake'; OnSuccess = { New-Alias -Force psake Invoke-psake }; OnMissing = {  } },
        @{ Name = 'pscx'; OnSuccess = {
            $Pscx:Preferences['CD_EchoNewLocation'] = $false
            }; OnMissing = {  } },
        @{ Name = 'psbits'; OnSuccess = {  }; OnMissing = {  } }
    )

$modules | % {
    if (Get-Module -ListAvailable $_.Name) {
	Import-Module $_.Name -DisableNameChecking
        Write-Host -ForegroundColor $ProgressForegroundColor "Loaded $($_.Name)"
        & $_.OnSuccess
    } else {
        Write-Warning "Missing $($_.Name) module."
        & $_.OnMissing
    }
}

$env:PATH = "$env:PATH;$env:USERPROFILE\Bin"
VsVars32

$isAdministrator = Is-Administrator

if ($isAdministrator) {
    Write-Host -ForegroundColor $ProgressForegroundColor "Loading System Modules."
    ImportSystemModules
    [System.Console]::Title = [System.Console]::Title + " (System Modules)"
}

# This removes the paging from 'help'. I prefer to scroll using the (gasp) scroll bar.
New-Alias -Force help Get-Help

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDirectory .\Scripts\MediaCmdlets.ps1)

$gvim = Join-Path ${env:ProgramFiles(x86)} 'Vim\vim73\gvim.exe'
if ( !(Test-Path $gvim) ) {
  $gvim = Join-Path $env:ProgramFiles 'Vim\vim73\gvim.exe'
}
if ( Test-Path $gvim ) {
  New-Alias gvim $gvim
}

# For Administrator logins, PoSh starts in C:\Windows\System32. Fix that.
Set-Location $HOME
