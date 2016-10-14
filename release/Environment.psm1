function Get-CarbonTopology([string] $TopologyPath = "$Env:InetRoot\carbon-secrets\topology\topology.json")
{
    $topology = ConvertFrom-Json (Get-Content $TopologyPath -Raw)
    return $topology
}

function Get-CarbonEnvironment([string] $Name = $null)
{
    $topology = Get-CarbonTopology
    $env = $topology.environments | where {-not $Name -or  $_.name -eq $Name}
    return $env
}

function Connect-CarbonEnvironment()
{
    process
    {        
        Add-AzureRmAccount -ServicePrincipal -ApplicationId $env.connection.appId -CertificateThumbprint $env.connection.thumbprint -TenantId $env.connection.tenantId | Out-Null
        Set-AzureRmContext -SubscriptionId $env.connection.subscriptionId | Out-Null
        Write-Host "Connected to $($env.name) $($env.owner)"    
    }    
}

function Update-CarbonSecrets($envs, $vaultPrefix, $values, $force)
{
    Write-Host "Updating secret values..."    
    foreach ($env in $envs)
    {
        $env | Connect-CarbonEnvironment
        $vaultName = "$vaultPrefix-$($env.name)"

        foreach ($kv in $values.GetEnumerator())
        {
            $s = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $kv.Name -ErrorAction Ignore
            if (-not $s -or $force)
            {
                Set-AzureKeyVaultSecret -VaultName $vaultName -Name $kv.Name -SecretValue $kv.Value | Out-Null                           
            }            
            Write-Host "Processed secret $($kv.Name)"
        }        
    }
}