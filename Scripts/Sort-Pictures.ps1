param(
    [Parameter(Mandatory = $true)]
    $Path
)

Import-Module exif

Get-ChildItem $Path -Recurse -Include *.jpg | where { ! $_.PSIsContainer } | Get-DateTaken |
    where { $_.DateTaken } | 
    % {
        $source = $_.ProviderPath
        
        $parent = Split-Path -Parent $_.ProviderPath
        $folders = Join-Path $_.DateTaken.ToString('yyyy') $_.DateTaken.ToString('yyyy-MM-dd')
        $leaf = Split-Path -Leaf $_.ProviderPath
        
        $destination = Join-Path ( Join-Path $Path $folders ) $leaf
        if ( $source -ne $destination ) {        
            if ( ! ( Test-Path ( Split-Path $destination ) ) ) {
                mkdir ( Split-Path $destination ) | Out-Null
            }
            
            Write-Verbose "Renaming '${source}' to '${destination}'."
            Move-Item $source $destination
        } else {
            Write-Verbose "Skipping '${source}'"
        }
    }