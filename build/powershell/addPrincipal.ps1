param(
    [Parameter(Mandatory=$true)]
    [string] $SubscriptionId,

    [Parameter(Mandatory=$true)]
    [string] $CommonName,
    
    [string] $Role = "Contributor",
    
    [Switch] $NoLogin = $false
)

$ErrorActionPreference = "Stop"

if ($NoLogin -eq $false)
{
    add-azurermaccount
}
Set-AzureRmContext -SubscriptionId $SubscriptionId

$tenant = (Get-AzureRmSubscription -SubscriptionId $SubscriptionId).TenantId

$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject "CN=https://$CommonName" -KeySpec KeyExchange -NotAfter (Get-Date).AddYears(5)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())

$azureAdApplication = New-AzureRmADApplication -DisplayName $CommonName -HomePage "https://$CommonName" -IdentifierUris "https://$CommonName" -CertValue $keyValue -EndDate $cert.NotAfter
Write-Host "Creating principal..."
New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
Write-Host "Waiting for async command to finish..."
Start-Sleep -s 15
New-AzureRmRoleAssignment -RoleDefinitionName $Role -ServicePrincipalName "https://$CommonName"

$pfxPassword = Read-Host -assecurestring "Please choose pfx password"
Get-ChildItem -Path "cert:\CurrentUser\my\$($cert.Thumbprint)" | Export-PfxCertificate -FilePath "$CommonName.pfx" -Password $pfxPassword

Write-Host "tenantId: ""$tenant"","
Write-Host "appId: ""$($azureAdApplication.ApplicationId)"","
Write-Host "thumbprint: ""$($cert.Thumbprint)"""
Write-Host "Run this: Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName https://$CommonName -PermissionsToKeys all -PermissionsToSecrets all"