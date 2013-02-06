$defaultEncoding = [Text.Encoding]::ASCII

function Set-Encoding($file, $encoding) {
    Write-Host "Setting $($file.FullPath) to $encoding"
	$file.GetType().GetField("encoding", "NonPublic, Instance").SetValue($file, $encoding)
}

# Any new files should have their encoding set.
Register-ObjectEvent `
	$psISE.CurrentPowerShellTab.Files `
    CollectionChanged `
	-Action {
		$event.Sender |
            where { $_.IsUntitled } |
            where { $_.Encoding -ne $defaultEncoding } |
            foreach { Set-Encoding $_ $defaultEncoding }
	}

#function Log-PropertyChanged($event) {
#    $sender = [Microsoft.PowerShell.Host.ISE.PowerShellTab] $event.Sender
#    $pcea = [System.ComponentModel.PropertyChangedEventArgs] $event.SourceEventArgs
#    
#    Write-Host $pcea.PropertyName
#}
#    
#Register-ObjectEvent `
#    $psISE.CurrentPowerShellTab `
#    PropertyChanged `
#    -Action {
#        Log-PropertyChanged $event
#    }

# Any files that are already opened should have their encoding set.
$psISE.CurrentPowerShellTab.Files |
    where { $_.IsUntitled } |
    where { $_.Encoding -ne $defaultEncoding } |
    foreach { Set-Encoding $_ $defaultEncoding }
    
function Close-All {
    $files = @()
    $psISE.CurrentPowerShellTab.Files |
        where { $_.IsSaved } |
        foreach {
            $files += $_
        }
        
    $files | % { $psISE.CurrentPowerShellTab.Files.Remove($_) }
}

function Save-All([switch] $Force) {
    $psISE.CurrentPowerShellTab.Files |
        where { ! $_.IsUntitled } |
        where { $Force -or (! $_.IsSaved) } |
        foreach {
            $_.Save()
        }
}

function Check-Out {
    Push-Location (Split-Path $psISE.CurrentFile.FullPath)
    & p4 edit $psISE.CurrentFile.FullPath
    Pop-Location
}

# $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Clear()
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Save All", {Save-All}, "Ctrl+Shift+S") | Out-Null
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Close All", {Close-All}, $null) | Out-Null
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Check Out", {Check-Out}, $null) | Out-Null

function Edit-File([string] $path) {
    $path = Resolve-Path $path
    $psISE.CurrentPowerShellTab.Files.Add($path)
}

New-Alias edit Edit-File
