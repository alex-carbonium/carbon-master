param([string]$packagePath)

$appManifest = Join-Path $packagePath ApplicationManifest.xml    
$manifestXml = [xml](Get-Content $appManifest)
$appType = $manifestXml.ApplicationManifest.ApplicationTypeName
        
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
    $manifestVersion = (new-object System.Version($latest.Version.Major, $latest.Version.Minor, ($latest.Version.Build+1))).ToString()
}
        
$serverVersion = [string](gc $env:InetRoot\carbon-server\target\version)
$clientVersion = [string](gc $env:InetRoot\carbon-ui\target\version)
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

