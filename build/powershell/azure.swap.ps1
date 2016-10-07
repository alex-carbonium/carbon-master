param(
    [Parameter(Mandatory=$true)]
    [string] $serviceName,

    [Parameter(Mandatory=$true)]
    [string] $slot
)

$Deployment = Get-AzureDeployment -Slot $slot -ServiceName $serviceName
if ($Deployment -ne $null -AND $Deployment.DeploymentId  -ne $null)
{
    Write-Output (" Current Status of staging with $serviceName")
    $Deployment
    $MoveStatus = Move-AzureDeployment -ServiceName $serviceName
    Write-Output ("Swap of $serviceName status: " + $MoveStatus.OperationStatus)

    if ($MoveStatus.OperationStatus -ne "Succeeded"){
        exit 1
    }
}
else
{
    Write-Output ("There is no deployment in slot $slot of $serviceName to swap.")
    exit 1
}