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