param(    
    [string] $Branch = "qa2",
    [string] $Configuration = "Release",
    [switch] $SkipInit = $false,
    [switch] $SkipPack = $false,
    [switch] $SkipTest = $false
)

$ErrorActionPreference = "Stop"

remove-module helpers -ErrorAction SilentlyContinue
import-module .\powershell\helpers.psm1
get-environment -Name qa1 | Connect-Environment
get-environment -Name qa2 | Connect-Environment

throw "Stop here"

Remove-Item .\TestResults\* -Recurse 
Remove-Item ..\carbon-ui\Sketch.Frontend\target\* -Recurse

if (-not $SkipInit)
{
    .\devInit.ps1
}

# Build and test
$jobs = @()

if (-not $SkipPack)
{
    $jobs += Start-Job -ScriptBlock { 
        Set-Location $args[0]
        $params = @("run", "pack", "--", "--noColors")
        if ($args[1] -eq "Debug")
        {
            $params += "--sourceMaps"
        }        
        if ($args[2] -eq "qa2")
        {
            $params += "--host"
            $params += "//carbonstatic.azureedge.net/app"
        }
        & "npm" $params

        # cdn upload
        if ($args[2] -eq "qa2")
        {
            Set-Location ..\..\build           
            Import-Module .\powershell\helpers.psm1
            Connect-Environment (Get-Environment -Name "qa1")
            $keys = Get-AzureRmStorageAccountKey -ResourceGroupName "carbon-common" -Name "carbonstatic"        
        
            $params = @("./scripts/uploadAzureFolder.js", "--container", "app", "--folder", (Resolve-Path ..\carbon-ui\Sketch.Frontend\target), "--account", "carbonstatic", "--key", $keys[0].Value)
            & "node" $params
        }        
    } -ArgumentList (Join-Path $PSScriptRoot ..\carbon-ui\build),$Configuration,$Branch
}

if (-not $SkipTest)
{
    $jobs += Start-Job -ScriptBlock {
        Set-Location $args[0]
        npm test
    } -ArgumentList $PSScriptRoot

    $jobs += Start-Job -ScriptBlock {        
        Set-Location $args[0]
        $config = $args[1]                 
        
        $params = @("..\carbon-server\CarbonServer.sln", "/p:Configuration=$config;Platform=""x64""", "/v:m")
        & "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe" $params               
        if ($LASTEXITCODE -ne 0)
        {
            throw "Build failed";
        }

        $params = @("..\carbon-server\Carbon.Test.Unit\bin\$config\Carbon.Test.Unit.dll",`
             "..\carbon-server\Carbon.Test.Integration\bin\$config\Carbon.Test.Integration.dll",`
             "..\carbon-server\Carbon.Test.Performance\bin\$config\Carbon.Test.Performance.dll",`
             "/platform:x64", "/parallel", "/logger:trx")        
                             
        & "$env:VS140COMNTOOLS..\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe" $params
    } -ArgumentList $PSScriptRoot,$Configuration       
}

# Pack app and deploy topology
$jobs | % {$_ | Receive-job -Wait -AutoRemoveJob}
$jobs = @()

$envs = ""
switch ($Branch)
{
    'qa2' { $envs = "qa1","qa2" }    
}

if ($envs)
{
    $jobs += Start-Job -ScriptBlock {
        Set-Location $args[0]
        .\powershell\deployTopology.ps1 -Environments $args[1] 
    } -ArgumentList $PSScriptRoot,$envs
}


$jobs | % {$_ | Receive-job -Wait -AutoRemoveJob}

# Deploy app
.\powershell\Copy-App.ps1 -SourceMaps:($Configuration -eq "DEBUG")

if ($envs)
{
    .\powershell\deployServiceFabric.ps1 -Environments $envs -Build -Configuration $Configuration -Upgrade -ReplaceDevPort -Bump
}

