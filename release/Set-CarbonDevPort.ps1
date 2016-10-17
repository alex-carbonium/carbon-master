param([string]$packagePath)

Write-Host "Replacing main port to 80/443"
$serviceManifest = join-path $packagePath "Carbon.Services.FabricHostPkg\ServiceManifest.xml"            
$xml = [xml](Get-Content $serviceManifest)
    
$endpoint = $xml.ServiceManifest.Resources.Endpoints.ChildNodes | where {$_.Name -eq "ServiceEndpoint"}
$endpoint.Port = "80"

$endpoint = $xml.ServiceManifest.Resources.Endpoints.ChildNodes | where {$_.Name -eq "SslServiceEndpoint"}
$endpoint.Port = "443"
    
$xml.Save($serviceManifest)