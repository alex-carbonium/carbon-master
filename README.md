# Deployment URLS:
1. Latest dev build: http://carbon-qa2.westeurope.cloudapp.azure.com

# Getting started

1. Log in with your Live ID
2. Go to [Security](https://carbonproject.visualstudio.com/_details/security/tokens) and set up personal access token
(or Alternate authentication credentials, does not matter)
3. Clone master project
    ```cmd
    git clone https://carbonproject.visualstudio.com/carbonium/_git/carbon-master
    ```
4. Go to repository
    ```
    cd carbon-master
    ```
5. Initialize enlistment
    ```cmd
    .\tools\carbon.cmd
    ```
6. Clone repositories you need
    ```PowerShell
    Initialize-CarbonVcs [-Core] [-UI] [-Server] [-Secrets]
    ```
7. Set up all dependencies (npm install and nuget restore)
    ```PowerShell
    Initialize-CarbonModules [-Clean]
    ```
8. Start development server (or just run npm run &lt;script&gt; in respective repo)
    ```PowerShell
    Start-Carbon
    ```
    
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