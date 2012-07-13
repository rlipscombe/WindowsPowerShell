$ProgressForegroundColor = 'Cyan'
$PromptForegroundColor = 'Yellow'

function Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

function Is-Administrator() {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    
    $role = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $isAdministrator = $principal.IsInRole($role)

    $isAdministrator
}

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
#        Write-Host($PWD.Provider.Name) -foregroundcolor Red -nonewline
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

if ( (Get-Module -ListAvailable PsGet) -ne $null ) {
    Import-Module PsGet
} else {
    Write-Warning "Missing PsGet module. See http://psget.net/ for details."
}

if ( (Get-Module -ListAvailable Posh-Hg) -ne $null ) {
    Import-Module Posh-Hg
    $global:HgPromptSettings.ModifiedForegroundColor = [ConsoleColor]::Cyan
    Write-Host -ForegroundColor $ProgressForegroundColor "Loaded Posh-Hg."
} else {
    Write-Warning "Missing Posh-Hg module."
}

if ( (Get-Module -ListAvailable Posh-Git) -ne $null ) {
    Import-Module Posh-Git
    $global:GitPromptSettings.WorkingForegroundColor = [ConsoleColor]::Cyan
    $global:GitPromptSettings.UntrackedForegroundColor = [ConsoleColor]::Cyan
    Write-Host -ForegroundColor $ProgressForegroundColor "Loaded Posh-Git."
} else {
    Write-Warning "Missing Posh-Git module."
}

if ( (Get-Module -ListAvailable psake) -ne $null ) {
    Import-Module psake
    New-Alias psake Invoke-psake
    Write-Host -ForegroundColor $ProgressForegroundColor "Loaded psake."
} else {
    Write-Warning "Missing psake module."
}

if ( (Get-Module -ListAvailable Pscx) -ne $null ) {
    Import-Module Pscx

    # Undo some Pscx badness.
    Remove-Item alias:cd
    New-Alias cd Set-Location
    Remove-Item alias:touch

    Write-Host -ForegroundColor $ProgressForegroundColor "Loaded Pscx."
} else {
    Write-Warning "Missing Pscx module."
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
. (Join-Path $ScriptDirectory .\Scripts\PathCmdlets.ps1)
. (Join-Path $ScriptDirectory .\Scripts\MediaCmdlets.ps1)
. (Join-Path $ScriptDirectory .\Scripts\ModuleCmdlets.ps1)
. (Join-Path $ScriptDirectory .\Scripts\Get-Netstat.ps1)


$gvim = Join-Path ${env:ProgramFiles(x86)} 'Vim\vim73\gvim.exe'
if ( !(Test-Path $gvim) ) {
  $gvim = Join-Path $env:ProgramFiles 'Vim\vim73\gvim.exe'
}
if ( Test-Path $gvim ) {
  New-Alias gvim $gvim
}

# For Administrator logins, PoSh starts in C:\Windows\System32. Fix that.
Set-Location $HOME
