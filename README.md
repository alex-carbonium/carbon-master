# Deployment URLS:
1. Latest dev build: http://dev.carbonium.io

# Getting started

## Download prerequisites
- Latest [git](https://git-scm.com/downloads) version
- Latest [PowerShell](https://www.microsoft.com/en-us/download/details.aspx?id=50395)
- Git [Credentials Manager](https://github.com/Microsoft/Git-Credential-Manager-for-Windows/releases/tag/v1.7.0)
- Install Credentials Manager in PowerShell
```PowerShell
Install-Module -Scope CurrentUser CredentialManager
```

## (Optional) Create credentials
```PowerShell
New-StoredCredential -Target git:https://carbonproject.visualstudio.com -UserName Token -Password <Your token> -Type Generic -Persist LocalMachine
```

## Clone and run
1. Log in with your Live ID
2. Clone master project
    ```cmd
    git clone https://carbonproject.visualstudio.com/carbonium/_git/carbon-master
    ```
3. Go to repository
    ```
    cd carbon-master
    ```
4. Initialize enlistment
    ```cmd
    .\tools\carbon.cmd
    ```
5. Clone repositories you need
    ```PowerShell
    Initialize-CarbonVcs [-Core] [-UI] [-Server] [-Secrets]
    ```
6. Set up all dependencies (npm install and nuget restore)
    ```PowerShell
    Initialize-CarbonModules [-Clean]
    ```
7. Start development server (or just run npm run &lt;script&gt; in respective repo).
   If you are working with the core product:
    ```PowerShell
    Start-Carbon
    ```

8. Start the browser and go to:
   ```PowerShell
   http://localhost:8080/app?serverless
   ```
   If you want to connect to existing QA server, open:
   ```PowerShell
   http://localhost:8080/app?backend=qa
   ```

## Run core tests
### Run tests from VSCode
```VSCode
>Run test task
```

### Run core examples from VSCode
```VSCode
>Run task
core examples
```

### Run tests from command line
```PowerShell
cd carbon-core
npm test -- --watch
```

### Run tests once in PhantomJS
```PowerShell
cd carbon-core
npm test
```
This is what the build does, the results are in the .trx file

# Working with VSC
### Create local branches using
```PowerShell
New-CarbonBranch -Name <name> [-Core] [-UI] [-Server] [-Master] [-Secrets]
```

### Commit, rebase and pull using:
```PowerShell
Sync-CarbonVcs [-CommitMessage <message>]
```
This command does:
```PowerShell
git commit -a -m <message> (if requested)
git pull --rebase
git push --set-upstream origin <current branch>
```

# Making a release
1. Merge into QA branch:
    ```PowerShell
    New-CarbonPullRequestQA [-Core] [-UI] [-Server] [-Master] [-Secrets]
    ```
2. Wait for builds to finish, watch Slack channel [#releases](https://project-panda.slack.com/messages/releases/)
3. Note: If you changed BOTH carbon-core and carbon-ui, carbon-ui will be built TWICE.
This is because core artifacts are taken from carbon-ui build. Wait for both of them to finish.
4. Launch the release:
    ```PowerShell
    New-CarbonRelease
    ```
5. Wait for release to finish, message will be posted to the same channel [#releases](https://project-panda.slack.com/messages/releases/)

# Testing a release locally
Release scripts run on all build artifacts, e.g. contents of \target folder in each repository.
You can run release locally like this:
```PowerShell
root
.\release\Import-CarbonCertificates.ps1 [and provide all passwords]
.\carbon-core\Build-Core.ps1 -Debug
.\carbon-ui\Build-UI.ps1 -BuildNumber 1.0.0 -CopyCore -SkipCdn -Debug
.\carbon-server\Build-Server.ps1 -BuildNumber 1.0.0 -SkipTest -SkipInit
.\release\Deploy-Carbonium.ps1 -Environment Local -SkipTopology -SkipInit
```