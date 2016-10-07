param(
    [Parameter(Mandatory=$true)]
    [string] $serviceName,

    [Parameter(Mandatory=$true)]
    [string] $slot
)

$Deployment = Get-AzureDeployment -Slot $slot -ServiceName $serviceName
if ($Deployment -ne $null -AND $Deployment.DeploymentId  -ne $null)
{
    Write-Output ("Current status of $serviceName")
    $Deployment
    $Status = Remove-AzureDeployment -ServiceName $serviceName -Slot $slot -Force
    Write-Output ("Delete of $serviceName status: " + $Status.OperationStatus)

    if ($Status.OperationStatus -ne "Succeeded"){
        exit 1
    }
}
else
{
    Write-Output ("There is no deployment in slot $slot of $serviceName.")
    exit 1
}