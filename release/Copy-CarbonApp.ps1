param(        
    [Boolean] $SourceMaps = $false
)

function Run()
{    
    $dataPackage = "$Env:InetRoot\carbon-server\target\Carbon.Services.FabricHostPkg\Client"
    Remove-Item (Join-Path $dataPackage target) -Recurse -ErrorAction Ignore
    New-Item (Join-Path $dataPackage target) -ItemType Directory

    if ($SourceMaps)
    {
        Copy-Item -Path $Env:InetRoot\carbon-ui\target\* -Destination (Join-Path $dataPackage target) -Force -Recurse
    }
    else
    {
        Copy-Item -Path $Env:InetRoot\carbon-ui\target\* -Destination (Join-Path $dataPackage target) -Force -Exclude *.map -Recurse
    }    
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