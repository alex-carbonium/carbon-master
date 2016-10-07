param(
    [string] $FileName = 'idsrv-release.pfx'
)

Import-Module .\New-SelfSignedCertificateEx.ps1

$pfxPassword = Read-Host -assecurestring "Please choose pfx password"                
New-SelfSignedCertificateEx -Subject "CN=https://ppanda" -EKU "Code Signing" -KeySpec "Signature" -KeyUsage "DigitalSignature"`
    -NotAfter $([datetime]::now.AddYears(50)) -Path (Join-Path $PSScriptRoot "..\..\carbon-secrets\$FileName") -Password $pfxPassword -Exportable