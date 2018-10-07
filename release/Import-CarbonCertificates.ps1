param(
    [Parameter(Mandatory=$true)]
    #password to qa3, in order not to change VSO variables
    [string] $pwd_subscription_qa1,

    [Parameter(Mandatory=$true)]
    [string] $pwd_subscription_qa2,

    [Parameter(Mandatory=$true)]
    [string] $pwd_encrypt,

    [Parameter(Mandatory=$true)]
    [string] $pwd_cluster_qa2
)

function Import($path, $password)
{
    $p = ConvertTo-SecureString $password -AsPlainText -Force
    Import-PfxCertificate -FilePath $path -CertStoreLocation Cert:\CurrentUser\My -Password $p
}

Import .\carbon-secrets\azure\subscription-qa3.pfx $pwd_subscription_qa1
Import .\carbon-secrets\azure\subscription-qa2.pfx $pwd_subscription_qa2
Import .\carbon-secrets\azure\encrypt.pfx $pwd_encrypt
Import .\carbon-secrets\azure\cluster-qa2.pfx $pwd_cluster_qa2