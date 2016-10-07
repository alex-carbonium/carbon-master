param(
    [Parameter(Mandatory=$true)]
    [string] $cspkg,

    [Parameter(Mandatory=$true)]
    [string] $cscfg,

    [Parameter(Mandatory=$true)]
    [string] $serviceName,

    [Parameter(Mandatory=$true)]
    [string] $label,

    [Parameter(Mandatory=$true)]
    [string] $slot,

    [Parameter(Mandatory=$false)]
    [string] $resultFile="")

$Deployment = Get-AzureDeployment -Slot $slot -ServiceName $serviceName
if ($Deployment -ne $null -AND $Deployment.DeploymentId -ne $null)
{
    Write-Output ("Deployment slot occupied, cleaning...")
    $Status = Remove-AzureDeployment -ServiceName $serviceName -Slot $slot -Force
    Write-Output ("Delete status: $($Status.OperationStatus)")

    if ($Status.OperationStatus -ne "Succeeded"){
        exit 1
    }
}

$status = New-AzureDeployment -ServiceName $serviceName -Package $cspkg -Configuration $cscfg -Label $label -Slot $slot
write-host "Deployment finished with status $($status.OperationStatus)"

if ($status.OperationStatus -ne "Succeeded"){
    exit 1
}
if ($resultFile -ne ""){
    $newDeployment = Get-AzureDeployment -Slot $slot -ServiceName $serviceName
    $res = "{""url"":""$($newDeployment.Url)""}"
    "$res" | out-file -filePath $resultFile -encoding "ASCII"
}