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
            git clone $remote $path -b $b --single-branch -q
        }
        else
        {
            Write-host "Updating $path to branch $b"
            Set-Location $path
            if ($clean)
            {
                git clean -f
            }                
            git checkout $b -q
            git pull            
        }
    }
    
    $jobs = @()
    
    if ($Secrets)
    {
        $jobs += Update "$env:InetRoot\carbon-secrets" "https://carbonproject.visualstudio.com/carbonium/_git/carbon-secrets" "master"
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

function Sync-CarbonVcs {
    
    param(    
        [string] $CommitMessage = $null
    )    

    $jobs = @()
    $paths = gci "$env:InetRoot" -Directory -Filter carbon-* | Select -ExpandProperty "FullName"
    $paths += "$env:InetRoot"

    $paths | % {    
        $jobs += Start-Job -ScriptBlock { 
            Set-Location $args[0]
            $CommitMessage = $args[1]
            
            if ($CommitMessage)
            {
                git commit -m $CommitMessage -a
            }            
            
            git pull --rebase
            git push origin
        } -ArgumentList ($_),$CommitMessage
    }

    $jobs | Receive-job -Wait -AutoRemoveJob
}