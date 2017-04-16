function GetAuthHeaders()
{
    $password = ""
    if (Get-Command Get-StoredCredential -ErrorAction SilentlyContinue)
    {
        $cred = Get-StoredCredential -Target "git:https://carbonproject.visualstudio.com"
        if (-not $cred)
        {
            throw "Could not find stored credential for git"
        }
        $nc = $cred.GetNetworkCredential()
        $password = $nc.Password
    }
    else
    {
        $password = security find-generic-password -a "Personal Access Token" -s gcm4ml:git:https://carbonproject.visualstudio.com -w
    }

    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "Personal Access Token", $password)))
    return @{Authorization=("Basic {0}" -f $auth)}
}

function Invoke-CarbonBuildApi($url, $data, $area = "", $method)
{
    $base = "https://carbonproject.${area}visualstudio.com"
    $headers = GetAuthHeaders

    $m = 'Get'
    if ($data)
    {
        $m = 'Post'
    }
    if ($method)
    {
        $m = $method
    }

    if ($data)
    {
        $response = Invoke-RestMethod -Method $m -Uri "$base/DefaultCollection/carbonium$url" -Body (ConvertTo-Json $data -Depth 100) -Headers $headers -ContentType 'application/json'
    }
    else
    {
        $response = Invoke-RestMethod -Method $m -Uri "$base/DefaultCollection/carbonium$url" -Headers $headers -ContentType 'application/json'
    }
    return $response
}

function Add-CarbonBuildTag($BuildId, $Tag)
{
    Invoke-CarbonBuildApi "/_apis/build/builds/$BuildId/tags/${Tag}?api-version=2.0" -method Put
}

function Get-CarbonLastSuccessfulBuild($buildName, $tag)
{
    $def = Invoke-CarbonBuildApi "/_apis/build/definitions?api-version=2.0&name=$buildName"
    $url = "/_apis/build/builds?definitions=$($def.value.id)&statusFilter=completed&resultFilter=succeeded&`$top=1"
    if ($tag)
    {
        $url += "&tagFilters=$tag"
    }
    $build = Invoke-CarbonBuildApi $url
    return $build.value
}

function Get-CarbonArtifact($buildId, $targetFolder)
{
    $artifacts = Invoke-CarbonBuildApi "/_apis/build/builds/$buildId/artifacts"
    $url = $artifacts.value.resource.downloadUrl

    $headers = GetAuthHeaders

    $file = [System.IO.Path]::GetTempFileName()
    Invoke-WebRequest -uri $url -OutFile $file -Headers $headers

    Add-Type -assembly 'system.io.compression.filesystem'
    [io.compression.zipfile]::ExtractToDirectory($file, $targetFolder)
}

function New-CarbonPullRequest($From, $To,
    [switch] $Master = $false,
    [switch] $Server = $false,
    [switch] $Core = $false,
    [switch] $UI = $false,
    [switch] $Secrets = $false)
{
    $def = Invoke-CarbonBuildApi "/_apis/git/repositories/?api-version=1.0"

    function Create($repoName)
    {
        $repoId = ($def.value | where {$_.name -eq $repoName}).id
        $r = Invoke-CarbonBuildApi "/_apis/git/repositories/$repoId/pullRequests?api-version=1.0"`
            @{"sourceRefName" = $From; "targetRefName" = $To; "title" = "Merging $From into $To"}

        $url = "https://carbonproject.visualstudio.com/carbonium/_git/$repoName/pullrequest/$($r.pullRequestId)?_a=files"
        if (Get-Command open -ErrorAction SilentlyContinue)
        {
            open $url
        }
        else
        {
            Start-Process -FilePath
        }
    }

    if ($Master)
    {
        Create "carbon-master"
    }
    if ($Core)
    {
        Create "carbon-core"
    }
    if ($UI)
    {
        Create "carbon-ui"
    }
    if ($Server)
    {
        Create "carbon-server"
    }
    if ($Secrets)
    {
        Create "carbon-secrets"
    }
}

function New-CarbonPullRequestQA(
    [switch] $Master = $false,
    [switch] $Server = $false,
    [switch] $Core = $false,
    [switch] $UI = $false,
    [switch] $Secrets = $false)
{
    New-CarbonPullRequest -From 'refs/heads/master' -To 'refs/heads/releases/qa' -Master:$Master -Server:$Server -Core:$Core -UI:$UI -Secrets:$Secrets
}

function New-CarbonBuild($buildName, $branch)
{
    $def = Invoke-CarbonBuildApi "/_apis/build/definitions?api-version=2.0&name=$buildName"
    return Invoke-CarbonBuildApi "/_apis/build/builds?api-version=2.0" @{definition = @{id = $def.value.id}; sourceBranch = $branch}
}

function New-CarbonRelease()
{
    $ui = Get-CarbonLastSuccessfulBuild "carbon-ui-qa"
    $server = Get-CarbonLastSuccessfulBuild "carbon-server-qa"
    $master = Get-CarbonLastSuccessfulBuild "carbon-master-qa"
    $secrets = Get-CarbonLastSuccessfulBuild "carbon-secrets-qa"

    write-host "Server version $($server.buildNumber), Client version $($ui.buildNumber)"

    $def = Invoke-CarbonBuildApi "/_apis/release/definitions?api-version=3.0-preview.1" -area "vsrm."    
    return Invoke-CarbonBuildApi "/_apis/release/releases?api-version=3.0-preview.1" @{definitionId = $def.value.id; artifacts = @(`
        @{alias = "carbon-ui"; instanceReference = @{id = "$($ui.id)"}},`
        @{alias = "carbon-server"; instanceReference = @{id = "$($server.id)"}},`
        @{alias = "carbon-master"; instanceReference = @{id = "$($master.id)"}},`
        @{alias = "carbon-secrets"; instanceReference = @{id = "$($secrets.id)"}}`
        )} `
        "vsrm."

}