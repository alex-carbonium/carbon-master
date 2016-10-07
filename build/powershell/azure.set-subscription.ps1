param(
    [Parameter(Mandatory=$true)]
    [string] $publishSettings,

    [Parameter(Mandatory=$false)]
    [string] $storageAccount="")

Remove-AzureSubscription BizSpark -Force -ErrorAction SilentlyContinue
Import-AzurePublishSettingsFile $publishSettings
Select-AzureSubscription -Current BizSpark

if ($storageAccount -ne "")
{
    Set-AzureSubscription -SubscriptionName BizSpark -CurrentStorageAccountName $storageAccount
}