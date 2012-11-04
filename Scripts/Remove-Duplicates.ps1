function Get-Duplicates
{
param(
    [Parameter(Mandatory = $true)]
    $Path
    
}

Get-ChildItem . -Recurse |
    where { ! $_.PSIsContainer } |
    Get-Hash -Algorithm MD5 |
    % { Write-Progress -Activity 'Looking for duplicates' -Status $_.Path } |
    group HashString |
    where { $_.Count -gt 1 } |
    % {
        $group = $_.Group
        $duplicates = $group | % { $_.Path }
        
        $duplicates = $duplicates | Get-
        
        $keep = $duplicates | select -First 1
        $victims = $duplicates | select -Last ( $duplicates.Count - 1 )
        
        Write-Host "Keeping  : ${keep}"
        Write-Host "Removing : ${victims}"
        
        $victims | Remove-Item
    } 
