param(
    [switch] $Initial = $false
)

Write-Host "Setting up carbon environment..."

$env:InetRoot = [System.IO.Path]::GetFullPath("$PSScriptRoot\..")
$modules = Get-ChildItem -Path "$env:InetRoot\tools\Lib" -Filter *.psm1
$modules += Get-ChildItem -Path "$env:InetRoot\release" -Filter *.psm1

foreach($module in $modules) {
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($module.Name)
    Remove-Module $moduleName  -ErrorAction Ignore
    Import-Module $module.FullName -WarningAction Ignore
}

Write-Host "Done" -ForegroundColor Green

if ($Initial){
    Start-StorageEmulator
    Install-Module -Scope CurrentUser CredentialManager
}

Reset-CarbonRoot

New-Alias -Name root -Value Reset-CarbonRoot -Scope Local -Force
New-Alias -Name start-ui -Value Start-Carbon -Scope Local -Force
New-Alias -Name ot -Value Edit-CarbonTools -Scope Local -Force
New-Alias -Name os -Value Edit-CarbonServer -Scope Local -Force