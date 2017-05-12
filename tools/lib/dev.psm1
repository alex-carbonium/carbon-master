function Start-Carbon{
    Set-Location $env:InetRoot\carbon-ui\
    npm start
}

function Get-CarbonLatestCore()
{
    Remove-Item $env:InetRoot\carbon-ui\target\carbon-core-* -ErrorAction SilentlyContinue
    Remove-Item $env:InetRoot\carbon-ui\target\carbon-api-* -ErrorAction SilentlyContinue
    Remove-Item $env:InetRoot\carbon-ui\target\carbon-*.d.ts -ErrorAction SilentlyContinue
    $build = Get-CarbonLastSuccessfulBuild 'carbon-core' 'refs/heads/master'
    Get-CarbonArtifact $build.id $env:InetRoot\carbon-ui\
    Write-Host "Got core bits from build $($build.id)"
}

function Start-CarbonUI{
    Set-Location $env:InetRoot\carbon-ui\
    npm run start
}

function Build-CarbonServer
{
    param(
        [string] $Configuration = "Debug"
    )
    try
    {
        Push-Location $env:InetRoot\carbon-server
        $msbuild = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MSBuild.exe"

        $params = @(".\CarbonServer.sln", "/p:Configuration=$Configuration;Platform=x64", "/v:m")
        & $msbuild $params
        if ($LASTEXITCODE -ne 0)
        {
            throw "Build failed";
        }
    }
    finally
    {
        Pop-Location
    }
}

function Start-CarbonServer
{
    Set-Location $env:InetRoot\carbon-server\Carbon.Console\bin\x64\debug\
    .\Carbon.Console.exe
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

    if (Test-Path $Env:InetRoot\carbon-functions)
    {
        Set-Location $Env:InetRoot\carbon-functions
        .\Restore-Packages.ps1
    }
}

function Enable-CarbonPorts
{
    function EnablePort($port)
    {
        $params = @("http", "add", "urlacl", "url=http://+:$port/", "user=Everyone")
        & netsh $params

        # $params = @("http", "add", "urlacl", "url=https://+:$port/", "user=Everyone")
        # & netsh $params

        # $params = @("http", "add", "sslcert", "ipport=0.0.0.0:$port", "certhash=3C6C98A08678F2BEDFD558B24F4122AF12D1097B", "appid={00000000-0000-0000-0000-000000000000}")
        # & netsh $params
    }

    EnablePort 9000
    EnablePort 9100
}

function Clear-CarbonCache
{
    if (Test-Path $Env:InetRoot\carbon-core\.awcache)
    {
        Remove-Item -Path $Env:InetRoot\carbon-core\.awcache -Recurse
        Write-Host "Deleted $Env:InetRoot\carbon-core\.awcache"
    }
    if (Test-Path $Env:InetRoot\carbon-ui\.awcache)
    {
        Remove-Item -Path $Env:InetRoot\carbon-ui\.awcache -Recurse
        Write-Host "Deleted $Env:InetRoot\carbon-ui\.awcache"
    }
}