function Invoke-CarbonBuildApi($url, $data, $area = "")
{
    $base = "https://carbonproject.${area}visualstudio.com"
    
    $cred = Get-StoredCredential -Target "git:https://carbonproject.visualstudio.com"
    if (-not $cred)
    {
        throw "Could not find stored credential for git"
    }
    $nc = $cred.GetNetworkCredential()
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $nc.UserName, $nc.Password)))    
    if ($data)
    {
        $response = Invoke-RestMethod -Method Post -Uri "$base/DefaultCollection/carbonium$url" -Body (ConvertTo-Json $data -Depth 100) -Headers @{Authorization=("Basic {0}" -f $auth)} -ContentType 'application/json'
    }
    else
    {
        $response = Invoke-RestMethod -Method Get -Uri "$base/DefaultCollection/carbonium$url" -Headers @{Authorization=("Basic {0}" -f $auth)} -ContentType 'application/json'
    }    
    return $response
}

function Get-CarbonLastSuccessfulBuild($buildName)
{
    $def = Invoke-CarbonBuildApi "/_apis/build/definitions?api-version=2.0&name=$buildName"
    $build = Invoke-CarbonBuildApi "/_apis/build/builds?definitions=$($def.value.id)&statusFilter=completed&resultFilter=succeeded&`$top=1"
    return $build.value
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
    $r = Invoke-CarbonBuildApi "/_apis/release/releases/11?api-version=3.0-preview.1&`$top=1" -area "vsrm."
    return Invoke-CarbonBuildApi "/_apis/release/releases?api-version=3.0-preview.1" @{definitionId = $def.value.id; artifacts = @(`
        @{alias = "carbon-ui"; instanceReference = @{id = "$($ui.id)"}},`
        @{alias = "carbon-server"; instanceReference = @{id = "$($server.id)"}},`
        @{alias = "carbon-master"; instanceReference = @{id = "$($master.id)"}},`
        @{alias = "carbon-secrets"; instanceReference = @{id = "$($secrets.id)"}}`
        )} `
        "vsrm."
    
}