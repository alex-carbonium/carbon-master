function Start-Carbon{
    Set-Location $env:InetRoot\carbon-ui\
    npm start
}

function Get-CarbonLatestCore()
{
    Remove-Item $env:InetRoot\carbon-ui\target\carbon-core-* -ErrorAction SilentlyContinue
    Remove-Item $env:InetRoot\carbon-ui\target\carbon-api-* -ErrorAction SilentlyContinue
    $build = Get-CarbonLastSuccessfulBuild 'carbon-core' 'refs/heads/master'    
    Get-CarbonArtifact $build.id $env:InetRoot\carbon-ui\
    Write-Host "Got core bits from build $($build.id)"
}

function Start-CarbonUI{
    Set-Location $env:InetRoot\carbon-ui\
    npm run 
}

function Initialize-CarbonModules{
    param(    
        [Switch] $Clean = $false
    )

    if ($Clean)
    {
        Remove-Item -Path $Env:InetRoot\carbon-core\node_modules -Recurse -ErrorAction Ignore
        Remove-Item -Path $Env:InetRoot\carbon-ui\node_modules -Recurse -ErrorAction Ignore
        Remove-Item -Path $Env:InetRoot\carbon-server\packages -Recurse -ErrorAction Ignore
    }
    
    if (Test-Path $Env:InetRoot\carbon-core)
    {
        Set-Location $Env:InetRoot\carbon-core
        npm install
    }        

    if (Test-Path $Env:InetRoot\carbon-ui)
    {
        Set-Location $Env:InetRoot\carbon-ui
        npm install
    }        

    if (Test-Path $Env:InetRoot\carbon-server)
    {
        Set-Location $Env:InetRoot\carbon-server
        .\Restore-Packages.ps1
    }    
}