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

$password = [Guid]::NewGuid().ToString()

$azureAdApplication = New-AzureRmADApplication -DisplayName $CommonName -HomePage "https://$CommonName" -IdentifierUris "https://$CommonName" -Password $password
Write-Host "Creating principal..."
New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId
Write-Host "Waiting for async command to finish..."
Start-Sleep -s 15
New-AzureRmRoleAssignment -RoleDefinitionName $Role -ServicePrincipalName "https://$CommonName"

Write-Host "tenantId: ""$tenant"","
Write-Host "appId: ""$($azureAdApplication.ApplicationId)"","
Write-Host "password: ""$password"""
Write-Host "Run this: Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -ServicePrincipalName https://$CommonName -PermissionsToKeys all -PermissionsToSecrets all"
