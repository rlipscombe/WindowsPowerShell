function Set-Encoding($file) {
	$file.GetType().GetField("encoding", "NonPublic, Instance").SetValue($file, [Text.Encoding]::UTF8)
}

Register-ObjectEvent `
	$psISE.CurrentPowerShellTab.Files `
    CollectionChanged `
	-Action {
		$event.Sender | % {
			Set-Encoding $_ [System.Text.Encoding]::UTF8
		}
	}

$psISE.CurrentPowerShellTab.Files | % {
	Set-Encoding $_ [System.Text.Encoding]::UTF8
}
