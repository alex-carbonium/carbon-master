function Start-Carbon{
    Set-Location $env:InetRoot\carbon-ui\
    npm start
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