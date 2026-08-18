Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe' -OutFile 'C:\gitinstaller.exe'
Start-Process -FilePath 'C:\gitinstaller.exe' -ArgumentList '/VERYSILENT' -Wait
$env:Path += ';C:\Program Files\Git\cmd'

New-Item -Path 'C:\deploy' -ItemType Directory -Force
$syncScript = @'
$repoUrl = "https://github.com/<yourusername>/my-azure-site.git"
$sitePath = "C:\inetpub\wwwroot"
$appPoolName = "DefaultAppPool"
git config --global --add safe.directory C:/inetpub/wwwroot
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

git config --global --add safe.directory C:/inetpub/wwwroot
powershell.exe -ExecutionPolicy Bypass -File 'C:\deploy\deploy-sync.ps1'

schtasks /create /tn "CodeSync" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\deploy\deploy-sync.ps1" /sc minute /mo 3 /ru SYSTEM /f
