function Initialize-Vcs{
    param(    
        [string] $Branch,
        [switch] $Clean = $false
    )

    $ErrorActionPreference = "Stop"    

    function Update($path, $remote, $b = $Branch, $clean = $true)
    {                            
        Start-Job -ScriptBlock {
            $path = $args[0]
            $remote = $args[1]
            $b = $args[2]
            $clean = $args[3]
            
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
        } -ArgumentList $path, $remote, $b, $clean
    }

    $user = $Env:GIT_USER
    $password = $Env:GIT_PASSWORD
    $jobs = @()
    
    $jobs += Update "$env:InetRoot\carbon-secrets1" "https://${user}:${password}@carbonproject.visualstudio.com/carbonium/_git/carbon-secrets" "master"
    
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