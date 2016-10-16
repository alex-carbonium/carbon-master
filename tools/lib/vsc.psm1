function Initialize-CarbonVcs{
    param(    
        [string] $Branch = "master",
        [switch] $Server = $false,
        [switch] $Core = $false,
        [switch] $UI = $false,
        [switch] $Secrets = $false,
        [switch] $Clean = $false
    )

    $ErrorActionPreference = "Stop"    

    function Update($path, $remote, $b = $Branch, $clean = $true)
    {                            
        if (-not (Test-Path $path))
        {            
            Write-host "Cloning branch $b in $path"
            git clone $remote $path -b $b
        }
        else
        {
            Write-host "Updating $path to branch $b"
            Set-Location $path            
            if ($clean)
            {
                git clean -f
            }                
            git pull                                  
            git checkout $b          
        }
    }
    
    $jobs = @()
    
    if ($Secrets)
    {
        $jobs += Update "$env:InetRoot\carbon-secrets" "https://carbonproject.visualstudio.com/carbonium/_git/carbon-secrets"
    }   
    if ($Server)    
    {
        $jobs += Update "$env:InetRoot\carbon-server" "https://carbonproject.visualstudio.com/carbonium/_git/carbon-server"
    }
    if ($Core)    
    {
        $jobs += Update "$env:InetRoot\carbon-core" "https://carbonproject.visualstudio.com/carbonium/_git/carbon-core"
    }   
    if ($UI)    
    {
        $jobs += Update "$env:InetRoot\carbon-ui" "https://carbonproject.visualstudio.com/carbonium/_git/carbon-ui"
    }  
    
    $jobs | % {$_ | Receive-job -Wait -AutoRemoveJob}
}

function Get-CarbonRepositories(
    [switch] $Master = $true,
    [switch] $Server = $true,
    [switch] $Core = $true,
    [switch] $UI = $true,
    [switch] $Secrets = $true)
{
    $paths = @()
    if ($Master)
    {
        $paths += "$env:InetRoot"
    }
    if ($Server -and (Test-Path "$env:InetRoot\carbon-server"))
    {
        $paths += "$env:InetRoot\carbon-server"
    }
    if ($Core -and (Test-Path "$env:InetRoot\carbon-core"))
    {
        $paths += "$env:InetRoot\carbon-core"
    }
    if ($UI -and (Test-Path "$env:InetRoot\carbon-ui"))
    {
        $paths += "$env:InetRoot\carbon-ui"
    }
    if ($Secrets -and (Test-Path "$env:InetRoot\carbon-secrets"))
    {
        $paths += "$env:InetRoot\carbon-Secrets"
    }
    return $paths
}

function Sync-CarbonVcs {
    
    param(    
        [string] $CommitMessage = $null
    )    

    $jobs = @()    

    Get-CarbonRepositories | % {    
        $jobs += Start-Job -ScriptBlock { 
            Set-Location $args[0]
            $CommitMessage = $args[1]
            
            if ($CommitMessage)
            {
                git commit -m $CommitMessage -a
            }            
            $branch = git rev-parse --abbrev-ref HEAD
            git pull --rebase
            git push --set-upstream origin $branch
        } -ArgumentList ($_),$CommitMessage
    }

    $jobs | Receive-job -Wait -AutoRemoveJob
}

function New-CarbonBranch {    
    param(    
        [Parameter(Mandatory=$true)]
        [string] $Name,
        [switch] $Master = $false,
        [switch] $Server = $false,
        [switch] $Core = $false,
        [switch] $UI = $false,
        [switch] $Secrets = $false
    )    

    $jobs = @()    

    Get-CarbonRepositories -Master:$Master -Core:$Core -Server:$Server -UI:$UI -Secrets:$Secrets | % {    
        $jobs += Start-Job -ScriptBlock { 
            Set-Location $args[0]
            git branch $args[1]
            git checkout $args[1]
        } -ArgumentList ($_),$Name
    }

    $jobs | Receive-job -Wait -AutoRemoveJob
}