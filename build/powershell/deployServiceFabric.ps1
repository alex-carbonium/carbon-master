param(    
    [string[]] $Environments = "local",

    [string] $TopologyPath = '..\..\carbon-secrets\topology.json',

    [switch] $Build = $false,

    [string] $Configuration = "Release",

    [switch] $ForceNew = $false,

    [switch] $Bump = $false,

    [switch] $SourceMaps = $false,

    [switch] $ReplaceDevPort = $false,

    [switch] $Upgrade = $false
)

$ErrorActionPreference = "Stop"

function Deploy($env, $fabric)
{
    try
    {
        $versionFile = Resolve-Path ..\version.json
        Push-Location ..\..\carbon-server\Carbon.Fabric\Scripts

        $appParams = @{}

        if ($fabric.requiredSecrets)
        {
            Connect-Environment $env

            $cert = $fabric.certificates | where {$_.type -eq "Encrypt"} | select -First 1
            foreach ($secret in $fabric.requiredSecrets)
            {
                $vaultKey = "$($secret.name)-$($secret.environment)"                
                $s = Get-AzureKeyVaultSecret -VaultName "carbon-vault-$($env.name)" -Name $vaultKey
                $encrypted = Invoke-ServiceFabricEncryptText -CertStore -CertThumbprint $cert.thumbprint -Text $s.SecretValueText -StoreLocation LocalMachine -StoreName My
                $appParams.Add($secret.parameter, $encrypted)
            }
        }
       
        if ($fabric.certificates)
        {
            $clusterCertificate = $fabric.certificates | where {$_.type -eq "Cluster"} | Select-Object -First 1
            if ($clusterCertificate)
            {            
                Write-Host "Connecting to $($fabric.endpoint)"
                Connect-ServiceFabricCluster -ConnectionEndpoint $fabric.endpoint `
                    -X509Credential -ServerCertThumbprint $clusterCertificate.thumbprint `
                    -FindType FindByThumbprint -FindValue $clusterCertificate.thumbprint -StoreLocation CurrentUser -StoreName My            
            }

            foreach ($cert in ($fabric.certificates | where {$_.type -ne "Cluster"}))
            {
                $appParams.Add("Certificates_$($cert.type)", $cert.thumbprint)
            }
        }
        else
        {
            Connect-ServiceFabricCluster
        }        

        .\Deploy-FabricApplication.ps1 -PublishProfileFile "..\PublishProfiles\$($fabric.profile)" `
            -UseExistingClusterConnection            `
            -ApplicationPackagePath "..\pkg\$Configuration\" `
            -Configuration $Configuration `
            -ApplicationParameter $appParams `
            -UnregisterUnusedApplicationVersionsAfterUpgrade $true `
            -VersionFile $versionFile `
            -ForceNew $ForceNew `
            -Bump $Bump `
            -ReplaceDevPort $ReplaceDevPort `
            -Upgrade $Upgrade
    }
    finally
    {
        Pop-Location
    }
}

function Run()
{
    Remove-Module helpers -ErrorAction Ignore
    Import-Module .\helpers.psm1

    if ($Build)
    {
        Write-Host "Packaging project..."        

        .\Copy-App

        $msbuild = Invoke-MsBuild -Path ..\..\carbon-server\Carbon.Fabric\Carbon.Fabric.sfproj -MsBuildParameters "/target:Package /property:Platform=x64;Configuration=$Configuration"    
        if ($msbuild.BuildSucceeded -ne $true)
        {
            throw "Build failed"
        }        
    }   
    
    $topology = ConvertFrom-Json (Get-Content $TopologyPath -Raw)

    foreach ($envName in $Environments)
    {
        $env = $topology.environments | where {$_.name -eq $envName}
        if ($env -eq $null)
        {
            Write-Error "Unknown environment $envName"
            continue
        }                    

        $groups = $env.groups | where {$_.fabric}
        foreach ($group in $groups)
        {                                             
            Deploy $env $group.fabric
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