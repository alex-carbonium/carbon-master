$ErrorActionPreference = "Stop"

function Unprotect($secureString)
{
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))
}

function ObtainAccessToken($url, $lastEmail = $null)
{
    $endpoint = "$url/idsrv/connect/token"

    while ($true)
    {
        $prompt = "Your email"
        if ($lastEmail)
        {
            $prompt = "$prompt ($lastEmail)"
        }

        $email = Read-Host -Prompt $prompt

        if (!$email)
        {
            $email = $lastEmail
        }

        if (!$email)
        {
            continue
        }

        $password = Read-Host -AsSecureString -Prompt "Your password"
        $passwordPlain = Unprotect $password

        try
        {
            $response = Invoke-RestMethod -Method Post -Uri $endpoint -Body @{
                grant_type = "password";
                client_id = "auth";
                client_secret = "nopassword";
                scope = "account";
                username = $email;
                password = $passwordPlain
            }

            return New-Object System.Net.NetworkCredential -ArgumentList @($email, $response.access_token)
        }
        catch
        {
            $_.Exception | Out-Host
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.BaseStream.Position = 0
            $reader.ReadToEnd() | Out-Host
        }
    }
}

function GetCred($Url)
{
    return Get-StoredCredential -Type Generic -Target "carbon:$url" -ErrorAction Ignore
}

function StoreCred($url, $cred)
{
   Remove-StoredCredential -Type Generic -Target "carbon:$url" -ErrorAction Ignore
   New-StoredCredential -Type Generic -Target "carbon:$url" -UserName $cred.UserName -Password $cred.Password -Persist LocalMachine -ErrorAction Ignore | Out-Null
}

function Get-CarbonBaseUrl(
    [ValidateSet("local", "dev", "prod")]
    [System.String] $Server)
{

    switch ($Server)
    {
        "local" {return "http://localhost:9000"}
        "dev" {return "http://dev.carbonium.io"}
        "dev" {return "http://carbonium.io"}
    }

    throw "Unknown server $Server"
}

function Get-CarbonCredentials(
    [ValidateSet("local", "dev", "prod")]
    [string] $Server,

    [switch] $Force)
{
    $url = Get-CarbonBaseUrl $Server

    $cred = GetCred $url
    if (!$cred)
    {
        $cred = ObtainAccessToken $url
        StoreCred $url $cred
        return $cred
    }

    if ($Force)
    {
        $cred = ObtainAccessToken $url $cred.UserName
        StoreCred $url $cred
        return $cred
    }

    return New-Object System.Net.NetworkCredential -ArgumentList @($cred.UserName, (Unprotect $cred.Password))
}