$FLAC_PATH = 'C:\Program Files (x86)\FLAC\bin\flac.exe'
$LAME_PATH = 'C:\Program Files (x86)\LAME\lame.exe'

$ProfilePath = (Split-Path $PROFILE)
Add-Type -Path (Join-Path $ProfilePath 'Bin\taglib-sharp.dll')
[TagLib.Id3v2.Tag]::DefaultVersion = 3
[TagLib.Id3v2.Tag]::ForceDefaultVersion = $true

function Is-Newer {
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$source,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$dest
);

    # If destination does not exist, or if the source is older than the destination.
    if (!$(Test-Path -LiteralPath $dest) -or ((Get-Item -LiteralPath $source).LastWriteTime -gt (Get-Item -LiteralPath $dest).LastWriteTime)) {
        $true
    } else {
        $false
    }
}

function Encode-Music {
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$sourceFolder,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$destinationFolder
);

    if (!$(Test-Path $FLAC_PATH)) {
        Throw "Missing $FLAC_PATH"
    }

    Get-ChildItem $sourceFolder -Include '*.wav' -Recurse | foreach {
        $source = $_

        $dest = Join-Path $destinationFolder $(Get-RelativePath $sourceFolder $source)
        $dest = [IO.Path]::ChangeExtension($dest, '.flac')
          
        Write-Verbose "Converting $source to $dest"

        $destDir = Split-Path $dest
        if ( ! $(Test-Path $destDir) ) {
            [void] (mkdir $destDir)
        }

        if (Is-Newer $source $dest) {
            & cmd /c " ""$FLAC_PATH"" --silent --best -o ""$dest"" ""$source"""
        } else {
            Write-Output "$dest is up-to-date."
        }
    }
}

function Copy-Tags
{
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$source,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$dest
);

    $sourceTags = [TagLib.File]::Create($source)
    $destTags = [TagLib.File]::Create($dest)
    
    # Possibly we should be using reflection here.
    $destTags.Tag.Clear()
    
    $destTags.Tag.Title = $sourceTags.Tag.Title
    $destTags.Tag.Artists = $sourceTags.Tag.Artists
    $destTags.Tag.Album = $sourceTags.Tag.Album
    $destTags.Tag.Genres = $sourceTags.Tag.Genres
    $destTags.Tag.Year = $sourceTags.Tag.Year
    $destTags.Tag.Track = $sourceTags.Tag.Track 
    $destTags.Tag.TrackCount = $sourceTags.Tag.TrackCount
    
    $destTags.Save()
}

function Transcode-Music
{
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$sourceFolder,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$destinationFolder
);

    if (!$(Test-Path $FLAC_PATH)) {
        Throw "Missing $FLAC_PATH"
    }

    if (!$(Test-Path $LAME_PATH)) {
        Throw "Missing $LAME_PATH"
    }

    Get-ChildItem $sourceFolder -Include '*.flac' -Recurse | foreach {
        $source = $_

        $dest = Join-Path $destinationFolder $(Get-RelativePath $sourceFolder $source)
        $dest = [IO.Path]::ChangeExtension($dest, '.mp3')
          
        $destDir = Split-Path $dest
        if ( ! $(Test-Path $destDir) ) {
            [void] (mkdir $destDir)
        }

        if (Is-Newer $source $dest) {
            Write-Verbose "Converting $source to $dest"
            $command = " ""$FLAC_PATH"" --silent --decode --stdout ""$source"" | ""$LAME_PATH"" --silent --preset standard --id3v2-only --pad-id3v2-size 256 - ""$dest"" "
            Write-Verbose $command
            & cmd /c $command
            Start-Sleep 1
            
            Copy-Tags $source $dest
        }
        else {
            Write-Output "$dest is up-to-date."
        }
    }
}
