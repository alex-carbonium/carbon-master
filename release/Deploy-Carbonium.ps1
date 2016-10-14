# This script operates on artifacts only, must be started from the root
param(    
    [string] $Environment = "local",
    [string] $Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$Env:InetRoot = Get-Location

try
{
    Push-Location $PSScriptRoot

    .\Copy-CarbonApp.ps1 -SourceMaps:($Configuration -eq "Debug")        

    $envs = ""
    switch ($Environment)
    {
        'QA' { $envs = "qa1","qa2" }    
        'local' { $envs = "local" }    
    }

    if ($envs)
    {
        Remove-Module Environment -ErrorAction Ignore
        Import-Module .\Environment.psm1

        #.\Deploy-CarbonTopology.ps1 -Environments $envs    
        .\Deploy-CarbonServiceFabric.ps1 -Environments $envs -Configuration $Configuration -Upgrade -ReplaceDevPort -Bump    
    }
}
finally
{
    Pop-Location
}
