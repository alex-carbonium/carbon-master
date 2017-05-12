function RunTools($params)
{
    try
    {
        Push-Location $Env:InetRoot\carbon-server\Carbon.Tools\bin\debug
        & .\Carbon.Tools.exe $params
    }
    finally
    {
        Pop-Location
    }
}

function Get-CarbonProjectLog
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $CompanyId,
        [Parameter(Mandatory=$true)]
        [string] $ModelId,
        [string] $Host = 'http://dev.carbonium.io'
    )

    $p = @('downloadLog', '-c', $CompanyId, '-m', $ModelId, '-h', $Host)
    RunTools $p
}

function Get-CarbonProjectLogLocal
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $CompanyId,
        [Parameter(Mandatory=$true)]
        [string] $ModelId
    )

    Get-CarbonProjectLog -CompanyId $CompanyId -ModelId $ModelId -Host "http://localhost:9000"
}

function Test-CarbonProjectLog
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $CompanyId,
        [Parameter(Mandatory=$true)]
        [string] $ModelId,
        [string] $Filter = $null
    )

    $p = @('testLog', '-c', $CompanyId, '-m', $ModelId)
    if ($Filter)
    {
        $p += @('-f', $Filter)
    }
    Clear-Host
    RunTools $p
}

Export-ModuleMember -Function "*-*"