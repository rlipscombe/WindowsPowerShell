$defaultEncoding = [Text.Encoding]::ASCII

function Set-Encoding($file, $encoding) {
    Write-Host "Setting $($file.FullPath) to $encoding"
	$file.GetType().GetField("encoding", "NonPublic, Instance").SetValue($file, $encoding)
}

# Any files opened in future should have their encoding set.
# BUG: This should be restricted to *new* files
Register-ObjectEvent `
	$psISE.CurrentPowerShellTab.Files `
    CollectionChanged `
	-Action {
		$event.Sender | % {
			Set-Encoding $_ $defaultEncoding
		}
	}

# Any files that are already opened should have their encoding set.
$psISE.CurrentPowerShellTab.Files | % {
	Set-Encoding $_ $defaultEncoding
}

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
    & p4 edit $psISE.CurrentFile.FullPath
}

# $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Clear()
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Save All", {Save-All}, "Ctrl+Shift+S")
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Close All", {Close-All}, $null)
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Check Out", {Check-Out}, $null)

function Edit-File([string] $path) {
    $path = Resolve-Path $path
    $psISE.CurrentPowerShellTab.Files.Add($path)
}

New-Alias edit Edit-File
