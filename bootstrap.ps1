Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe' -OutFile 'C:\gitinstaller.exe'
Start-Process -FilePath 'C:\gitinstaller.exe' -ArgumentList '/VERYSILENT' -Wait
$env:Path += ';C:\Program Files\Git\cmd'

New-Item -Path 'C:\deploy' -ItemType Directory -Force
$syncScript = @'
$repoUrl = "https://github.com/Isharohira/my-azure-site.git"
$sitePath = "C:\inetpub\wwwroot"
$appPoolName = "DefaultAppPool"
if (!(Test-Path "$sitePath\.git")) {
  Remove-Item "$sitePath\*" -Recurse -Force -ErrorAction SilentlyContinue
  git clone $repoUrl $sitePath
} else {
  Set-Location $sitePath
  git pull
}
Import-Module WebAdministration
Restart-WebAppPool -Name $appPoolName
'@
Set-Content -Path 'C:\deploy\deploy-sync.ps1' -Value $syncScript

powershell.exe -ExecutionPolicy Bypass -File 'C:\deploy\deploy-sync.ps1'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File C:\deploy\deploy-sync.ps1'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 3) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName 'CodeSync' -Action $action -Trigger $trigger -RunLevel Highest -User 'SYSTEM'
