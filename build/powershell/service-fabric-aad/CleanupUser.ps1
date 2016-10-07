<#
.SYNOPSIS
Cleanup user in Azure Active Directory Tenant

.PARAMETER TenantId
ID of tenant hosting Service Fabric cluster.

.PARAMETER UserName,
Username of user to be deleted.

.PARAMETER UserObjectId
Object ID of user to deleted.

.EXAMPLE
. Scripts\CleanupUser.ps1 -TenantId '7b25ab7e-cd25-4f0c-be06-939424dc9cc9' -UserName 'SFAdmin'

Delete a user by providing username

.EXAMPLE
. Scripts\CleanupUser.ps1 -TenantId '7b25ab7e-cd25-4f0c-be06-939424dc9cc9' -UserObjectId '88ff3bbf-ea1a-4a14-aad9-807d109ac2eb'

Delete a user by providing objectId
#>

Param
(
    [Parameter(ParameterSetName='UserName',Mandatory=$true)]
    [Parameter(ParameterSetName='UserId',Mandatory=$true)]
    [String]
	$TenantId,

    [Parameter(ParameterSetName='UserName',Mandatory=$true)]
	[String]
	$UserName,

    [Parameter(ParameterSetName='UserId',Mandatory=$true)]
    [String]
    $UserObjectId
)

Write-Host 'TenantId = ' $TenantId
$authString = "https://login.microsoftonline.com/" + $TenantId
$resourceUri = "https://graph.windows.net/" + $TenantId + "/{0}?api-version=1.5{1}"

. ".\Common.ps1"

if($UserName)
{
    $uri = [string]::Format($resourceUri, "users", [string]::Format('&$filter=displayName eq ''{0}''', $UserName))
    $UserObjectId = (Invoke-RestMethod $uri -Headers $headers).value.objectId
    AssertNotNull $UserObjectId 'User is not found'
}

Write-Host 'Deleting User objectId = '$UserObjectId
$uri = [string]::Format($resourceUri, [string]::Format("users/{0}",$UserObjectId), "")
Invoke-RestMethod $uri -Method DELETE -Headers $headers | Out-Null
Write-Host 'User objectId= ' $UserObjectId ' is deleted'