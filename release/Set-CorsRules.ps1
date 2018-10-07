Get-CarbonEnvironment -Name 'qa-3' | Connect-CarbonEnvironment

$StorageAccountName = 'carbonstatic3'
$Keys = Get-AzureRmStorageAccountKey -ResourceGroupName "carbon-common" -Name $StorageAccountName
$Context = New-AzureStorageContext -StorageAccountKey $keys[0].Value -StorageAccountName $StorageAccountName
$CorsRules = (@{
    AllowedHeaders=@("*");
    AllowedOrigins=@("*");
    ExposedHeaders=@("content-length");
    MaxAgeInSeconds=200;
    AllowedMethods=@("Get","Connect", "Head", "Options")})
Set-AzureStorageCORSRule -ServiceType Blob -CorsRules $CorsRules -Context $Context
$CORSrule = Get-AzureStorageCORSRule -ServiceType Blob -Context $Context
echo "Current CORS rules: "
echo $CORSrule