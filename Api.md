# Using Carbon Api from PowerShell
Step-by-step guide to generate a local client for calling Carbon API on any server.

# One time setup
- Build and start the server
    ```PowerShell
    Build-CarbonServer
    Start-CarbonServer
    ```

- Initialize proxy to generate client code. The client is always generated from the debug server running locally.
    ```PowerShell
    Initialize-CarbonProxy
    ```

# Session
Before calling API, an access token needs to be obtained and stored in the current powershell session.

- Get access token from the server and start a session.
    ```PowerShell
    New-CarbonProxySession -Server dev
    ```
    Log in with your username/password.

    `Important`. When the access token expires, run the same command with `-Force` parameter.

- Download the project log given that you have admin permissions.
    ```PowerShell
    Invoke-AdminApiProjectLog -companyId b6f693890f0447bd8c88fa09fcbd34a0 -modelId 46 | Save-CarbonProjectLog
    ```

- Replay the log and filter what you need.
    ```PowerShell
    Test-CarbonProjectLog -companyId b6f693890f0447bd8c88fa09fcbd34a0 -modelId 46 -Filter b676d62e8488591d59e02a25f6fb29ee
    ```

- When the Model.json file is ready, it can be imported to the account of the current user.
    ```PowerShell
    Import-CarbonProject -companyId b6f693890f0447bd8c88fa09fcbd34a0 -modelId 46
    ```