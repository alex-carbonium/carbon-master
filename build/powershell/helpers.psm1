function Get-Environment([string] $Name, [string] $TopologyPath = (join-path $PSScriptRoot '..\..\carbon-secrets\topology.json'))
{
    $topology = ConvertFrom-Json (Get-Content $TopologyPath -Raw)
    $env = $topology.environments | where {$_.name -eq $Name}
    $env
}

function Connect-Environment()
{
    process
    {        
        $pass = ConvertTo-SecureString ([System.Environment]::GetEnvironmentVariable($_.connection.passwordVar)) -AsPlainText –Force
        $cred = New-Object -TypeName pscredential –ArgumentList "$($_.connection.appId)@$($_.connection.ad)",$pass
        Login-AzureRmAccount -Credential $cred -ServicePrincipal –Tenantid $_.connection.tenantId
        Set-AzureRmContext -SubscriptionId $_.connection.subscriptionId | Out-Null
        Write-Host "Connected to $($_.name) $($_.owner)"
    }    
}

function Update-CarbonSecrets($envs, $vaultPrefix, $values, $force)
{
    Write-Host "Updating secret values..."    
    foreach ($env in $envs)
    {
        Connect-Environment $env
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

function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}