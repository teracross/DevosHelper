# DevosHelper
Automated devotional helper tool for use with daily devotional from https://bible.alpha.org/ and Google Keep Notes. For educational use only. 

Rights to all content from devotionals belong to their respective owners and Alpha International.

## NOTE
Apparently the Google Keep API is for Enterprise access only. So instead this app will aim to create a copyable text file artifact that is generated daily via GithubAction workflow. 

## How to Run Web Scraper Locally
1) ``` npm run build ```
2) ``` npm run start ```

## Local Automation 
Utilizing the [scripts/automation.sh](./scripts/automation.sh) bash script can sync latest devotional entry template [current.md](./current.md) from the GitHub repo and open it in VSCode. 

Example - Running this command in VSCode through WSL on Windows system (): 
```C:\Windows\System32\cmd.exe /k "wsl -d Ubuntu -- bash -lxc '/DevosHelper/scripts/automation.sh'"```

## TODOs
- [x] create application to parse and organize data
- [x] create automated workflow to generate txt artifacts with the organized data
- [] add customization to workflow to allow for timezone switching via config