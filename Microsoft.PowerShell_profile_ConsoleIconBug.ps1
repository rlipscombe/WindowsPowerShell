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

function prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Put the path in the title, so that it appears in the task bar:
    [System.Console]::Title = "{0} - {1}" -f $PWD, $PromptTitleTemplate

    # In case some app leaves it broken.
    [Console]::ResetColor()

    # Now for the actual prompt: working directory
    Write-Host $PWD -nonewline -foregroundcolor Yellow

    # Blank line
    Write-Host 
    Write-Host ">" -nonewline -foregroundcolor Yellow

    # This doesn't work reliably on Ultramon taskbars.
    Update-ConsoleIcon

    $LASTEXISTCODE = $realLASTEXITCODE
    
    # This is the actual prompt -- it's printed in the default console colours.
    return " "
}

$ProfilePath = Split-Path $PROFILE
. "$ProfilePath\Icons\Set-ConsoleIcon.ps1"

$isAdministrator = Is-Administrator

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
