function Reset-CarbonRoot {
    Set-Location -Path $env:InetRoot
}


function Start-StorageEmulator {
    $job = Start-Job {
        cd "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\Storage Emulator\"
        .\StartStorageEmulator.cmd
    }

    Receive-Job $job -WriteJobInResults -Wait | Out-Null
}

function Edit-CarbonTools {
    code $env:InetRoot\tools
}

function Edit-CarbonServer {
    & $env:InetRoot\carbon-server\CarbonServer.sln
}

function Get-CarbonTmpFolder()
{
    return "$env:InetRoot\tmp"
}

function Get-CarbonTmpProjectsFolder()
{
    Join-Path (Get-CarbonTmpFolder) "Projects"
}

foreach ($tmp in (Get-CarbonTmpFolder),(Get-CarbonTmpProjectsFolder))
{
    if (-not (Test-Path $tmp))
    {
        mkdir $tmp
    }
}

function Copy-Stream()
{
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string] $File,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.IO.Stream[]] $Streams
    )
    Process
    {
        foreach ($stream in $Streams)
        {
            try
            {
                $path = Join-Path $pwd $File

                $stream.Position = 0
                $out = [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate)
                $stream.CopyTo($out)
            }
            finally
            {
                $stream.Dispose()
                $out.Dispose()
            }
        }
    }
}

Export-ModuleMember -Function "*-*"