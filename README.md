My personal collection of scripts and tools used in day-to-day SRE and Cloud work.

## My tech stack

* PowerShell – Azure automation, Windows administration, IT administrative tasks
* Python – log parsing, monitoring
* Kubernetes – manifests, jobs, RBAC configurations, infrastructure automation

## Structure

Folder | Description

* Powershell | Azure automation, Windows administration, IT administrative tasks
* Python | Scripting, data processing and monitoring
* Kubernetes | K8s workloads & infrastructure automation

## Latest scripts

Script | Language | Description

* ping_checker.py | Python | ICMP ping checker with logging, cross-platform

## Coming soon

* Terraform modules (Azure + AWS)
* PowerShell – Entra ID automation
* Azure resource health checks
* n8n workflow automation examples

## Usage

All of my scripts has its own README with requirements, parameters and usage examples and deep explanation why I commit any change.

### PasswordRequest.ps1
PowerShell script for home workgroup computers (no AD/Azure AD required).
Generates a one-time random password for the local Administrator account and delivers it to the owner via Gmail. Password expires automatically after 60 minutes and the Administrator account is then disabled.
Triggered via Task Scheduler by a standard user through a VBScript desktop shortcut.

### PasswordRequest-launcher.vbs
VBScript launcher that allows a standard user to trigger `PasswordRequest.ps1` via Windows Task Scheduler without requiring admin credentials.

## Notes

* Never commit secrets, tokens or kubeconfig files — covered by .gitignore
* Scripts are tested on the versions listed in each script's README
* All scripts are written for real operational use cases

## Author

Marek Łyszczarz – Automation Engineer - www.linkedin.com/in/marek-lyszczarz

Follow the journey — building this repo in public.
Progress updates on Instagram: [@tech.cloud.automation](https://instagram.com/tech.cloud.automation)
