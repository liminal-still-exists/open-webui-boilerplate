$ErrorActionPreference = "Stop"

$config = . (Join-Path $PSScriptRoot "open_webui_config.ps1")

$serviceName = $config.ServiceName
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if (-not $service) {
    throw "서비스를 찾을 수 없습니다: $serviceName"
}

if ($service.Status -eq "Running") {
    Restart-Service -Name $serviceName -Force
}
else {
    Start-Service -Name $serviceName
}

$updatedService = Get-Service -Name $serviceName

Write-Host ""
Write-Host "서비스 작업이 완료되었습니다." -ForegroundColor Green
Write-Host "서비스 이름: $serviceName"
Write-Host "현재 상태: $($updatedService.Status)"
