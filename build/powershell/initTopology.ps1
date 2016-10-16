param(
)

$ErrorActionPreference = "Stop"

function SyncInitialSecrets($vaultPrefix)
{    
    Write-Host "Searching for secret values..."    
    $topology = Get-CarbonTopology
    $envs = Get-CarbonEnvironment | where {$_.needsVault}
    $values = @{}
    foreach ($secret in $topology.initialSecrets)
    {
        $values.Add($secret, "")
        foreach ($env in $envs)
        {
            $env | Connect-CarbonEnvironment
            $vaultName = "$vaultPrefix-$($env.name)"
            $v = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $secret -ErrorAction Ignore
            if ($v)
            {
                $values[$secret] = $v.SecretValue
                break
            }
        }
    }    
    
    foreach ($kv in ($values.GetEnumerator() | where {-not $_.Value}))
    {        
        $v = Read-Host -assecurestring "Choose a value for secret $($kv.Name)"
        $values[$kv.Name] = $v
    }

    Update-CarbonSecrets $envs $vaultPrefix $values
}

function Run()
{
    Remove-Module Environment -ErrorAction Ignore
    Import-Module $Env:InetRoot\release\Environment.psm1
    
    $envs = Get-CarbonEnvironment | where {$_.needsVault}

    $vaultPrefix = "carbon-vault"    

    $groupName = "carbon-initial"    

    foreach ($env in $envs)
    {    
        $env | Connect-CarbonEnvironment

        $vaultName = "$vaultPrefix-$($env.name)"    
    
        $g = Get-AzureRmResourceGroup -Name $groupName -Location $env.location -ErrorAction Ignore
        if ($g -eq $null)
        {
            New-AzureRmResourceGroup -Name $groupName -Location $env.location
        }       

        $v = Get-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $groupName -ErrorAction Ignore
        if ($v -eq $null)
        {
            New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $groupName -Location $env.location -EnabledForDeployment -EnabledForTemplateDeployment -EnabledForDiskEncryption
        }                                

        $groups = $env.groups | where {$_.fabric -and $_.fabric.certificates}

        foreach ($group in $groups)
        {   
            foreach ($cert in $group.fabric.certificates)
            {
                $k = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $cert.fileName -ErrorAction Ignore
                if ($k -eq $null)
                {
                    $secretsPath = "$Env:InetRoot\carbon-secrets\azure"
                    $certPath = join-path $secretsPath "$($cert.fileName).pfx"
                    Push-Location .\ServiceFabricRPHelpers
                    import-module .\ServiceFabricRPHelpers.psm1

                    if (Test-Path $certPath)
                    {
                        $pfxPassword = Read-Host -assecurestring "Please enter pfx password for file $($cert.fileName).pfx"                
                        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxPassword)
                        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                        Invoke-AddCertToKeyVault -SubscriptionId $env.connection.subscriptionId `
                            -ResourceGroupName $groupName -Location "$($env.location)" -VaultName $vaultName `
                            -CertificateName $cert.fileName `
                            -UseExistingCertificate -ExistingPfxFilePath "$certPath" -Password $plainPassword                        
                    }   
                    else
                    {
                        $pfxPassword = Read-Host -assecurestring "Please choose password for certificate $($cert.fileName)"                
                        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxPassword)
                        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                        Invoke-AddCertToKeyVault -SubscriptionId $env.connection.subscriptionId `
                            -ResourceGroupName $groupName -Location "$($env.location)" -VaultName $vaultName `
                            -CertificateName $cert.fileName `
                            -CreateSelfSignedCertificate -Password $plainPassword -DnsName "https://$($group.fabric.endpoint)" -OutputPath $secretsPath
                    }                 
                    Pop-Location
                }
            }                                                        
        }
    } 

    SyncInitialSecrets $vaultPrefix

    Write-Host "Run service-fabric-aad to grant access to service fabric explorer"
    Write-Host ".\SetupApplications.ps1 -TenantId '690ec069-8200-4068-9d01-5aaf188e557a' -ClusterName 'mycluster' -WebApplicationReplyUrl 'https://mycluster.westus.cloudapp.azure.com:19080/Explorer/index.html'"
}

try
{
    Push-Location $PSScriptRoot
    Run
}
finally
{
    Pop-Location
}