param(
    [string[]] $Environments = "local",

    [Switch] $ForceUpdateSecrets = $false
)

$ErrorActionPreference = "Stop"

function DeployResourceGroup($group, $location, $templateFile, $paramFile)
{
    $groupName = $group.name
    $g = Get-AzureRmResourceGroup -Name $groupName -Location $location -ErrorAction Ignore
    if ($g -eq $null)
    {
        New-AzureRmResourceGroup -Location $location -Name $groupName
    }
    else
    {
        $g
    }

    Write-Host "Deploying group $groupName..."
    return New-AzureRmResourceGroupDeployment -ResourceGroupName $groupName -TemplateFile $templateFile -TemplateParameterFile $paramFile -Name $groupName
}

function ExportSecrets($env, $group, $outputs)
{
    $values = @{}

    foreach ($s in $group.exportedSecrets)
    {
        switch ($s.type)
        {
            "sqlConnectionString" {
                $passwordRef = $outputs.sqlPasswordRef.value
                if (-not $passwordRef)
                {
                    throw "SQL password reference not specified"
                }

                $vaultName = "carbon-vault-$($env.name)"
                $secret = Get-AzureKeyVaultSecret -VaultName $vaultName -Name $passwordRef -ErrorAction Stop

                $cs = "Server=tcp:$($outputs.sqlServer.value).database.windows.net,1433;`
Initial Catalog=$($outputs.sqlDatabase.value);`
Persist Security Info=True;`
User ID=$($outputs.sqlLogin.value);`
Password=$($secret.SecretValueText);`
MultipleActiveResultSets=False;`
Encrypt=True;`
TrustServerCertificate=False;`
Connection Timeout=30;" -replace '\r\n',''

                $values.Add("$($s.type)-$($env.name)", (ConvertTo-SecureString -AsPlainText -Force $cs))
            }

            "nosqlConnectionString" {
                $account = $outputs.nosqlAccount.value
                if (-not $account)
                {
                    throw "No storage account returned"
                }

                $key = (Get-AzureRmStorageAccountKey -ResourceGroupName $group.name -Name $account)[0].Value

                $cs = "DefaultEndpointsProtocol=https;AccountName=$account;AccountKey=$key"

                $values.Add($s.name, (ConvertTo-SecureString -AsPlainText -Force $cs))
            }
        }
    }

    Update-CarbonSecrets (Get-CarbonEnvironment | where {$_.needsVault}) "carbon-vault" $values $ForceUpdateSecrets
}

function Run()
{
    $topology = Get-CarbonTopology
    if (-not $topology.dirty)
    {
        Write-Host "Topology deployment skipped"
        return
    }

    foreach ($envName in $Environments)
    {
        $env = Get-CarbonEnvironment -Name $envName
        if ($env -eq $null)
        {
            Write-Error "Unknown environment $envName"
            continue
        }
        if (-not $env.connection)
        {
            Write-Warning "Nothing to deploy for environment $envName"
            continue
        }

        $templateRoot = "$env:InetRoot\carbon-server\target\Templates"

        foreach ($group in $env.groups)
        {
            $env | Connect-CarbonEnvironment #exporting secrets can reconnect

            $templateFile = (Join-Path $templateRoot $group.templateFile)
            $paramFile = (Join-Path $templateRoot $group.paramFile)
            $param = (Get-Content $paramFile -Raw) -replace '{subscriptionId}',$env.connection.subscriptionId `
                -replace '{keyVaultName}',"carbon-vault-$envName" `

            if ($group.fabric -and $group.fabric.certificates)
            {
                foreach ($cert in $group.fabric.certificates)
                {
                    $param = $param -replace "{$($cert.type)CertificateVersion}",$cert.secretVersion `
                        -replace "{$($cert.type)CertificateThumbprint}",$cert.thumbprint `
                        -replace "{$($cert.type)CertificateName}",$cert.fileName
                }
            }

            $tempParamFile = New-TemporaryFile
            Set-Content -Path $tempParamFile.FullName -Value $param -Encoding Unicode

            try
            {
                $d = DeployResourceGroup $group $env.location $templateFile $tempParamFile
                if ($group.exportedSecrets)
                {
                    ExportSecrets $env $group $d.Outputs
                }
            }
            finally
            {
                Remove-Item -Path $tempParamFile.FullName
            }
        }
    }
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