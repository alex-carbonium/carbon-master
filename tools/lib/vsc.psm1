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

function Sync-Vcs {
    
    param(    
        [string] $Branch = "default"
    )

    $ErrorActionPreference = "Stop"

    $jobs = @()

    "$env:InetRoot\carbon-server","$env:InetRoot\carbon-ui","$env:InetRoot" | % {    
        $jobs += Start-Job -ScriptBlock { 
            Set-Location $args[0]
            hg pull --rebase
            hg push
        } -ArgumentList ($_),$b
    }

    $jobs | Receive-job -Wait -AutoRemoveJob
}