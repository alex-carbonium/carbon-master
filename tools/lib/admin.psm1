$ErrorActionPreference = "Stop"

function New-CarbonProxySession(
    [ValidateSet("local", "dev", "prod")]
    [System.String] $Server,

    [switch] $Force = $false)
{
    Import-Module (Join-Path (Get-CarbonTmpFolder) ApiProxy\src\IO.Swagger\IO.Swagger.psd1) -Global

    $url = Get-CarbonBaseUrl $Server
    $cred = Get-CarbonCredentials $Server -Force:$Force

    [IO.Swagger.Client.Configuration]::Default.ApiClient.RestClient.BaseUrl = "$url/api"
    [IO.Swagger.Client.Configuration]::Default.DefaultHeader["Authorization"] = "Bearer $($cred.Password)"

    Write-Host "Token obtained for $($cred.UserName)"
}

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

    $p = @('testLog', '-c', $CompanyId, '-m', $ModelId, '-t', (Get-CarbonTmpProjectsFolder))
    if ($Filter)
    {
        $p += @('-f', $Filter)
    }
    Clear-Host
    Write-Host "Running with params $p"
    RunTools $p
}

function Initialize-CarbonProxy([switch] $Force = $false)
{
    $folder = Join-Path (Get-CarbonTmpFolder) "ApiProxy"
    if (Test-Path $folder)
    {
        if ($Force)
        {
            gci $folder -Exclude "*.jar" | remove-item -Recurse -Force
        }
    }
    else
    {
        mkdir $folder
        wget http://central.maven.org/maven2/io/swagger/swagger-codegen-cli/2.2.3/swagger-codegen-cli-2.2.3.jar -O $folder\swagger-codegen-cli.jar
    }

    try
    {
        Push-Location $folder

        java -jar swagger-codegen-cli.jar generate -i http://localhost:9000/api/swagger/docs/v1 -l csharp -o .\csharp\SwaggerClient
        java -jar swagger-codegen-cli.jar generate -i http://localhost:9000/api/swagger/docs/v1 -l powershell -o .
        .\Build.ps1

        Import-Module .\src\IO.Swagger\IO.Swagger.psd1 -Verbose -Global
    }
    finally
    {
        Pop-Location
    }
}

function Save-CarbonProjectLog()
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.FileStream[]] $FileStreams
    )
    Process
    {
        $outDir = Get-CarbonTmpProjectsFolder

        foreach ($stream in $FileStreams)
        {
            try
            {
                $fileName = [IO.Path]::GetFileNameWithoutExtension($stream.Name)
                $path = Join-Path $outDir "$fileName.zip"

                $stream.Position = 0
                $out = [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate)
                $stream.CopyTo($out)
                $out.Dispose()

                $split = $fileName.split("_")
                $projectDir = Join-Path $outDir "$($split[1])_$($split[2])"
                mkdir $projectDir -Force
                Expand-Archive $path $projectDir -Force
            }
            finally
            {
                $stream.Dispose()
            }
        }
    }
}

Export-ModuleMember -Function "*-*"