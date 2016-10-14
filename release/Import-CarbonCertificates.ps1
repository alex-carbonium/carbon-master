param(
    [Parameter(Mandatory=$true)]
    [string] $pwd_subscription_qa1,

    [Parameter(Mandatory=$true)]
    [string] $pwd_subscription_qa2,

    [Parameter(Mandatory=$true)]
    [string] $pwd_encrypt,
    
    [Parameter(Mandatory=$true)]
    [string] $pwd_cluster_qa2,
    
    [Parameter(Mandatory=$true)]
    [string] $pwd_idsrv_release,
    
    [Parameter(Mandatory=$true)]
    [string] $pwd_ssl_debug
)

function Import($path, $password)
{
    $p = ConvertTo-SecureString $password -AsPlainText -Force
    Import-PfxCertificate -FilePath $path -CertStoreLocation Cert:\CurrentUser\My -Password $p
}

Import .\carbon-secrets\azure\subscription-qa1.pfx $pwd_subscription_qa1
Import .\carbon-secrets\azure\subscription-qa2.pfx $pwd_subscription_qa2
Import .\carbon-secrets\azure\encrypt.pfx $pwd_encrypt
Import .\carbon-secrets\azure\cluster-qa2.pfx $pwd_cluster_qa2
Import .\carbon-secrets\azure\idsrv-release.pfx $pwd_idsrv_release

Import .\carbon-secrets\ssl-debug.pfx $pwd_ssl_debug