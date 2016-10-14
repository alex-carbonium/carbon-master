function Update-CarbonVersion($packagePath, $versionFile, $configuration, $bump)
{
    $appManifest = Join-Path $packagePath ApplicationManifest.xml    
    $manifestXml = [xml](Get-Content $appManifest)
    $appType = $manifestXml.ApplicationManifest.ApplicationTypeName
    
    $versions = ConvertFrom-Json (Get-Content $versionFile -Raw)
    $build = 0             
    
    $latest = Get-ServiceFabricApplicationType -ApplicationTypeName $appType | 
        Select-Object @{Name="Version"; Expression={[System.Version]::Parse($_.ApplicationTypeVersion)}} | 
        Sort-Object Version | 
        Select-Object -Last 1
    if ($latest -eq $null)
    {        
        $manifestVersion = "1.0.0"        
    }   
    else
    {
        $build = ($latest.Version.Build+1)
        $manifestVersion = (new-object System.Version($latest.Version.Major, $latest.Version.Minor, $build)).ToString()
    }

    $codeBuild = 0
    if ($bump)
    {
        $codeBuild = $build
    }    
        
    $serverVersion = (new-object System.Version($versions.major, $versions.server.minor, $codeBuild)).ToString()
    $clientVersion = (new-object System.Version($versions.major, $versions.client.minor, $codeBuild)).ToString()
    Write-Host "Server version: $serverVersion Client version: $clientVersion Manifest version: $manifestVersion"

    $manifests = Get-ChildItem $packagePath -Filter ServiceManifest.xml -Recurse
    foreach ($m in $manifests)
    {
        $xml = [xml](Get-Content $m.FullName)
        $xml.ServiceManifest.Version = $manifestVersion
        $xml.ServiceManifest.CodePackage.Version = $serverVersion
        if ($xml.ServiceManifest.ConfigPackage)
        {
            $xml.ServiceManifest.ConfigPackage.Version = $serverVersion
        }
        if ($xml.ServiceManifest.DataPackage)
        {
            $xml.ServiceManifest.DataPackage.Version = $clientVersion
        } 
        $xml.Save($m.FullName)
    }
    
    $manifestXml.ApplicationManifest.ApplicationTypeVersion = $manifestVersion
    foreach ($import in $manifestXml.ApplicationManifest.ServiceManifestImport)
    {                
        $import.ServiceManifestRef.ServiceManifestVersion = $manifestVersion
    }    
    $manifestXml.Save($appManifest)
}

function Replace-CarbonDevPort($packagePath)
{
    Write-Host "Replacing main port to 80/443"
    $serviceManifest = join-path $packagePath "Carbon.Services.FabricHostPkg\ServiceManifest.xml"            
    $xml = [xml](Get-Content $serviceManifest)
    
    $endpoint = $xml.ServiceManifest.Resources.Endpoints.ChildNodes | where {$_.Name -eq "ServiceEndpoint"}
    $endpoint.Port = "80"

    $endpoint = $xml.ServiceManifest.Resources.Endpoints.ChildNodes | where {$_.Name -eq "SslServiceEndpoint"}
    $endpoint.Port = "443"
    
    $xml.Save($serviceManifest)
}