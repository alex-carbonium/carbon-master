param(    
    [string] $Branch = "dev"    
)

    $pass = ConvertTo-SecureString "ssl-debug" -AsPlainText -Force     
    Import-PfxCertificate -CertStoreLocation Cert:\LocalMachine\My -FilePath ".\carbon-secrets\secrets\ssl-debug.pfx" -Password $pass
    

#.\Copy-App.ps1 -SourceMaps:($Configuration -eq "DEBUG")

#if ($envs)
#{
#    .\deployServiceFabric.ps1 -Environments $envs -Build -Configuration $Configuration -Upgrade -ReplaceDevPort -Bump
#}