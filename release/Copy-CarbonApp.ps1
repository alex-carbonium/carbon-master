param(        
    [Boolean] $SourceMaps = $false
)

function EnsureCleanDir([string]$dir)
{
    if (Test-Path $dir)
    {
        if ($dir.IndexOf('Data\app') -eq -1)
        {
            throw "Could not clean dir $dir"
        }
        Remove-Item "$dir\*" -Recurse
    }
    else
    {
        New-Item $dir -ItemType Directory
    }
}

function Run()
{
    $dataPackage = "..\..\carbon-server\Carbon.Services.FabricHost\PackageRoot\Data\app"
    EnsureCleanDir (Join-Path $dataPackage target)        
    EnsureCleanDir (Join-Path $dataPackage fonts\apache\opensans)

    if ($SourceMaps)
    {
        Copy-Item -Path ..\..\carbon-ui\Sketch.Frontend\target\* -Destination (Join-Path $dataPackage target) -Force -Recurse       
    }
    else
    {
        Copy-Item -Path ..\..\carbon-ui\Sketch.Frontend\target\* -Destination (Join-Path $dataPackage target) -Force -Exclude *.map -Recurse
    }

    Copy-Item -Path ..\..\carbon-ui\Sketch.Frontend\fonts\apache\opensans\* -Destination (Join-Path $dataPackage fonts\apache\opensans) -Force
    Copy-Item -Path ..\..\carbon-ui\Sketch.Frontend\*.html -Destination $dataPackage -Force
}

try
{
    Push-Location $PSScriptRoot
    Run
}
finally
{
    Pop-Location
}