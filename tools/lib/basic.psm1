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


function Start-Carbon {
    Set-Location $env:InetRoot\build
    npm start
}

function Edit-CarbonTools {
    code $env:InetRoot\tools
}

function Edit-CarbonServer {
    & $env:InetRoot\carbon-server\CarbonServer.sln
}

Export-ModuleMember -Function "Reset-CarbonRoot"
Export-ModuleMember -Function "Start-Carbon"
Export-ModuleMember -Function "Start-StorageEmulator"
Export-ModuleMember -Function "Edit-CarbonTools"
Export-ModuleMember -Function "Edit-CarbonServer"
