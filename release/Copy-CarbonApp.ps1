param(
    [switch] $All = $false
)

function Run()
{
    $dataPackage = "$Env:InetRoot\carbon-server\target\Carbon.Services.FabricHostPkg\Client"
    Remove-Item (Join-Path $dataPackage target) -Recurse -ErrorAction Ignore
    New-Item (Join-Path $dataPackage target) -ItemType Directory

    if ($All)
    {
        Copy-Item -Path $Env:InetRoot\carbon-ui\target\* -Destination (Join-Path $dataPackage target) -Force -Recurse
    }
    else
    {
        Copy-Item -Path $Env:InetRoot\carbon-ui\target\*.html -Destination (Join-Path $dataPackage target) -Force
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